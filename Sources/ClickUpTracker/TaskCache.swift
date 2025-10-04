//
//  TaskCache.swift
//  ClickUpTracker
//
//  Manages local cache of ClickUp tasks for fast client-side search
//

import Foundation
import Combine

struct CachedTaskData: Codable {
    let tasks: [ClickUpTask]
    let lastUpdated: Date
    let teamID: String
}

class TaskCache: ObservableObject {
    static let shared = TaskCache()
    
    @Published var tasks: [ClickUpTask] = []
    @Published var lastUpdated: Date?
    @Published var isLoading = false
    @Published var loadingProgress: Int = 0
    @Published var totalTasks: Int = 0
    
    private let cacheURL: URL
    private var autoRefreshTimer: Timer?
    
    private init() {
        // Store cache in Application Support directory
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appDir = appSupport.appendingPathComponent("ClickUpTracker", isDirectory: true)
        
        // Create directory if it doesn't exist
        try? FileManager.default.createDirectory(at: appDir, withIntermediateDirectories: true)
        
        cacheURL = appDir.appendingPathComponent("task-cache.json")
        
        // Load cached tasks on init
        loadFromDisk()
        
        // Setup auto-refresh
        setupAutoRefresh()
    }
    
    // MARK: - Cache Management
    
    /// Load tasks from disk cache
    func loadFromDisk() {
        guard FileManager.default.fileExists(atPath: cacheURL.path) else {
            print("📦 Cache: No cached data found")
            return
        }
        
        do {
            let data = try Data(contentsOf: cacheURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            
            let cachedData = try decoder.decode(CachedTaskData.self, from: data)
            
            // Verify cache is for current team
            if cachedData.teamID == SettingsManager.shared.teamID {
                self.tasks = cachedData.tasks
                self.lastUpdated = cachedData.lastUpdated
                print("📦 Cache: Loaded \(tasks.count) tasks from disk (last updated: \(cachedData.lastUpdated))")
            } else {
                print("📦 Cache: Cached data is for different team, ignoring")
                try? FileManager.default.removeItem(at: cacheURL)
            }
        } catch {
            print("⚠️ Cache: Failed to load from disk: \(error)")
            // If cache is corrupted, delete it
            try? FileManager.default.removeItem(at: cacheURL)
        }
    }
    
    /// Save tasks to disk cache
    func saveToDisk() {
        guard !tasks.isEmpty else { return }
        
        let cachedData = CachedTaskData(
            tasks: tasks,
            lastUpdated: lastUpdated ?? Date(),
            teamID: SettingsManager.shared.teamID
        )
        
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = .prettyPrinted
            
            let data = try encoder.encode(cachedData)
            try data.write(to: cacheURL, options: .atomic)
            
            print("💾 Cache: Saved \(tasks.count) tasks to disk")
        } catch {
            print("⚠️ Cache: Failed to save to disk: \(error)")
        }
    }
    
    /// Refresh cache from ClickUp API
    @MainActor
    func refresh() async {
        guard !isLoading else {
            print("⚠️ Cache: Refresh already in progress")
            return
        }
        
        isLoading = true
        loadingProgress = 0
        totalTasks = 0
        
        print("🔄 Cache: Starting refresh...")
        
        do {
            // Fetch spaces first to get space names
            print("🔄 Cache: Fetching spaces...")
            let spaces = try await ClickUpAPI.shared.fetchSpaces()
            let spaceNameMap = Dictionary(uniqueKeysWithValues: spaces.map { ($0.id, $0.name) })
            print("✅ Cache: Fetched \(spaces.count) spaces")
            
            // Fetch all tasks
            let fetchedTasks = try await ClickUpAPI.shared.fetchAllTasks { count in
                Task { @MainActor in
                    self.loadingProgress = count
                    self.totalTasks = count
                }
            }
            
            // Enrich tasks with space names
            let enrichedTasks = fetchedTasks.map { task in
                var enrichedTask = task
                if let spaceID = task.space?.id, let spaceName = spaceNameMap[spaceID] {
                    enrichedTask.space = ClickUpTask.Space(id: spaceID, name: spaceName)
                }
                return enrichedTask
            }
            
            self.tasks = enrichedTasks
            self.lastUpdated = Date()
            self.totalTasks = enrichedTasks.count
            
            print("✅ Cache: Refresh complete. Loaded \(enrichedTasks.count) tasks")
            
            // Save to disk in background
            Task.detached { [weak self] in
                self?.saveToDisk()
            }
        } catch {
            print("❌ Cache: Refresh failed: \(error)")
        }
        
        isLoading = false
    }
    
    /// Clear cache
    func clear() {
        tasks = []
        lastUpdated = nil
        try? FileManager.default.removeItem(at: cacheURL)
        print("🗑️ Cache: Cleared")
    }
    
    // MARK: - Search
    
    /// Search tasks by query string (searches title and description)
    func search(query: String, assignedOnly: Bool = false) -> [ClickUpTask] {
        guard !query.isEmpty else {
            let filtered = filterBySelectedSpaces(tasks)
            return assignedOnly ? [] : Array(filtered.prefix(50))
        }
        
        let lowercaseQuery = query.lowercased()
        
        let results = tasks.filter { task in
            // Search in task name
            let nameMatch = task.name.lowercased().contains(lowercaseQuery)
            
            // Search in description if available
            let descriptionMatch = task.textContent?.lowercased().contains(lowercaseQuery) ?? false
            
            return nameMatch || descriptionMatch
        }
        
        // Filter by selected spaces
        let spaceFiltered = filterBySelectedSpaces(results)
        
        // Limit to 50 results for performance
        return Array(spaceFiltered.prefix(50))
    }
    
    /// Filter tasks by selected space IDs from settings
    private func filterBySelectedSpaces(_ tasks: [ClickUpTask]) -> [ClickUpTask] {
        let selectedSpaces = SettingsManager.shared.selectedSpaceIDs
        
        // If no spaces selected, return all tasks
        guard !selectedSpaces.isEmpty else {
            return tasks
        }
        
        // Filter tasks that belong to selected spaces
        return tasks.filter { task in
            guard let spaceID = task.space?.id else { return false }
            return selectedSpaces.contains(spaceID)
        }
    }
    
    /// Get list of all unique spaces from cached tasks
    func getAvailableSpaces() -> [(id: String, name: String)] {
        var spacesDict: [String: String] = [:]
        
        for task in tasks {
            if let space = task.space {
                spacesDict[space.id] = space.name ?? "Space \(space.id)"
            }
        }
        
        return spacesDict.map { (id: $0.key, name: $0.value) }.sorted { $0.name < $1.name }
    }
    
    // MARK: - Auto-refresh
    
    /// Setup auto-refresh timer based on settings
    func setupAutoRefresh() {
        // Cancel existing timer
        autoRefreshTimer?.invalidate()
        autoRefreshTimer = nil
        
        guard SettingsManager.shared.autoRefreshEnabled else {
            print("⏱️ Cache: Auto-refresh disabled")
            return
        }
        
        let interval = SettingsManager.shared.refreshInterval
        print("⏱️ Cache: Setting up auto-refresh every \(interval) seconds")
        
        autoRefreshTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.refresh()
            }
        }
    }
    
    /// Call this when settings change
    func updateAutoRefreshSettings() {
        setupAutoRefresh()
    }
    
    // MARK: - Helpers
    
    /// Check if cache needs refresh (older than refresh interval)
    func needsRefresh() -> Bool {
        guard let lastUpdated = lastUpdated else {
            return true
        }
        
        let interval = SettingsManager.shared.refreshInterval
        return Date().timeIntervalSince(lastUpdated) > interval
    }
    
    /// Get formatted last updated time
    func lastUpdatedString() -> String {
        guard let lastUpdated = lastUpdated else {
            return "Never"
        }
        
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: lastUpdated, relativeTo: Date())
    }
}
