//
//  ClickUpAPI.swift
//  ClickUpTracker
//
//  Handles all ClickUp API interactions
//

import Foundation

struct ClickUpTask: Identifiable, Codable {
    let id: String
    let name: String
    let status: Status?
    let list: List?
    let folder: Folder?
    var space: Space?  // Make mutable so we can enrich with space name
    let milestone: Milestone?
    let textContent: String?  // Task description/content for searching
    let description: String?  // Raw description
    
    var isMilestone: Bool {
        milestone != nil
    }
    
    struct Status: Codable {
        let status: String
        let color: String?
    }
    
    struct List: Codable {
        let id: String
        let name: String
    }
    
    struct Folder: Codable {
        let id: String
        let name: String
    }
    
    struct Space: Codable {
        let id: String
        var name: String?
        
        init(id: String, name: String? = nil) {
            self.id = id
            self.name = name
        }
    }
    
    struct Milestone: Codable {
        let id: String?
    }
    
    enum CodingKeys: String, CodingKey {
        case id, name, status, list, folder, space, milestone
        case textContent = "text_content"
        case description
    }
}

struct ClickUpTasksResponse: Codable {
    let tasks: [ClickUpTask]
}

struct ClickUpSpace: Codable {
    let id: String
    let name: String
}

struct ClickUpSpacesResponse: Codable {
    let spaces: [ClickUpSpace]
}

struct ClickUpTimeEntry: Codable {
    let tid: String       // Task ID (required in new API)
    let description: String?
    let start: Int64
    let end: Int64?       // End time in milliseconds
    let duration: Int64   // Duration in milliseconds (new API uses "duration" not "time")
    let billable: Bool
    
    enum CodingKeys: String, CodingKey {
        case tid
        case description
        case start
        case end
        case duration
        case billable
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(tid, forKey: .tid)
        
        // Only encode description if it's not nil
        if let description = description {
            try container.encode(description, forKey: .description)
        }
        
        try container.encode(start, forKey: .start)
        
        // Encode end time if available
        if let end = end {
            try container.encode(end, forKey: .end)
        }
        
        try container.encode(duration, forKey: .duration)
        try container.encode(billable, forKey: .billable)
    }
}

enum ClickUpAPIError: Error {
    case invalidURL
    case invalidAPIKey
    case invalidTeamID
    case networkError(Error)
    case decodingError(Error)
    case apiError(String)
    case notConfigured
}

class ClickUpAPI {
    static let shared = ClickUpAPI()
    
    private let baseURL = "https://api.clickup.com/api/v2"
    private var apiKey: String {
        SettingsManager.shared.apiKey
    }
    private var teamID: String {
        SettingsManager.shared.teamID
    }
    
    private init() {}
    
    // MARK: - Fetch Tasks
    
    func fetchTasks(page: Int = 0) async throws -> [ClickUpTask] {
        guard !apiKey.isEmpty else {
            throw ClickUpAPIError.invalidAPIKey
        }
        guard !teamID.isEmpty else {
            throw ClickUpAPIError.invalidTeamID
        }
        
        // Fetch tasks with pagination and better query parameters
        var urlComponents = URLComponents(string: "\(baseURL)/team/\(teamID)/task")!
        urlComponents.queryItems = [
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "archived", value: "false"),
            URLQueryItem(name: "subtasks", value: "true"),
            URLQueryItem(name: "include_closed", value: "false")
        ]
        
        guard let url = urlComponents.url else {
            throw ClickUpAPIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(apiKey, forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw ClickUpAPIError.apiError("Invalid response")
            }
            
            guard httpResponse.statusCode == 200 else {
                let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                throw ClickUpAPIError.apiError("HTTP \(httpResponse.statusCode): \(errorMessage)")
            }
            
            let tasksResponse = try JSONDecoder().decode(ClickUpTasksResponse.self, from: data)
            return tasksResponse.tasks
        } catch let error as ClickUpAPIError {
            throw error
        } catch let error as DecodingError {
            throw ClickUpAPIError.decodingError(error)
        } catch {
            throw ClickUpAPIError.networkError(error)
        }
    }
    
    // MARK: - Fetch Spaces
    
    func fetchSpaces() async throws -> [ClickUpSpace] {
        guard !apiKey.isEmpty else {
            throw ClickUpAPIError.invalidAPIKey
        }
        guard !teamID.isEmpty else {
            throw ClickUpAPIError.invalidTeamID
        }
        
        let urlString = "\(baseURL)/team/\(teamID)/space"
        guard let url = URL(string: urlString) else {
            throw ClickUpAPIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(apiKey, forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw ClickUpAPIError.apiError("Invalid response")
            }
            
            guard httpResponse.statusCode == 200 else {
                let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                throw ClickUpAPIError.apiError("HTTP \(httpResponse.statusCode): \(errorMessage)")
            }
            
            let spacesResponse = try JSONDecoder().decode(ClickUpSpacesResponse.self, from: data)
            return spacesResponse.spaces
        } catch let error as ClickUpAPIError {
            throw error
        } catch let error as DecodingError {
            throw ClickUpAPIError.decodingError(error)
        } catch {
            throw ClickUpAPIError.networkError(error)
        }
    }
    
    // MARK: - Search Tasks
    
    /// Search tasks using local cache
    /// Searches both task name and description for better results
    func searchTasks(query: String, maxResults: Int = 50) async throws -> [ClickUpTask] {
        print("🔍 API: Searching cache for '\(query)'")
        
        // Use cached search
        let results = TaskCache.shared.search(query: query, assignedOnly: false)
        
        print("✅ API: Found \(results.count) tasks in cache matching '\(query)'")
        return results
    }
    
    // MARK: - Search Assigned Tasks
    
    /// Search tasks using local cache, filtering by assigned
    func searchAssignedTasks(query: String, maxResults: Int = 50) async throws -> [ClickUpTask] {
        print("🔍 API: Searching cache for '\(query)' (assigned to me)")
        
        // Use cached search with assigned filter
        let results = TaskCache.shared.search(query: query, assignedOnly: true)
        
        print("✅ API: Found \(results.count) assigned tasks in cache matching '\(query)'")
        return results
    }
    
    // MARK: - Fetch All Tasks with Pagination
    
    func fetchAllTasks(progressCallback: ((Int) -> Void)? = nil) async throws -> [ClickUpTask] {
        var allTasks: [ClickUpTask] = []
        var page = 0
        var hasMore = true
        
        while hasMore {
            let tasks = try await fetchTasks(page: page)
            
            if tasks.isEmpty {
                hasMore = false
            } else {
                allTasks.append(contentsOf: tasks)
                page += 1
                
                // Call progress callback on main actor
                let currentCount = allTasks.count
                if let callback = progressCallback {
                    await MainActor.run {
                        callback(currentCount)
                    }
                }
                
                // If we got less than 100 tasks, we're probably done
                // (ClickUp typically returns 100 tasks per page)
                if tasks.count < 100 {
                    hasMore = false
                }
            }
        }
        
        return allTasks
    }
    
    // MARK: - Create Time Entry
    
    func createTimeEntry(taskID: String, startTime: Date, duration: TimeInterval, description: String?, billable: Bool = false) async throws {
        guard !apiKey.isEmpty else {
            throw ClickUpAPIError.invalidAPIKey
        }
        
        guard !teamID.isEmpty else {
            throw ClickUpAPIError.invalidTeamID
        }
        
        let endTime = startTime.addingTimeInterval(duration)
        
        print("⏱️ API: Creating time entry for task \(taskID)")
        print("⏱️ API: Start Time: \(startTime)")
        print("⏱️ API: End Time: \(endTime)")
        print("⏱️ API: Duration: \(duration) seconds (\(Int(duration/60)) minutes)")
        print("⏱️ API: Billable: \(billable)")
        
        // NEW API: /team/{team_id}/time_entries
        let urlString = "\(baseURL)/team/\(teamID)/time_entries"
        guard let url = URL(string: urlString) else {
            throw ClickUpAPIError.invalidURL
        }
        
        print("🌐 API: POST \(url.absoluteString)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let startMillis = Int64(startTime.timeIntervalSince1970 * 1000)
        let endMillis = Int64(endTime.timeIntervalSince1970 * 1000)
        let durationMillis = Int64(duration * 1000)
        
        let timeEntry = ClickUpTimeEntry(
            tid: taskID,           // Task ID goes in body for new API
            description: description,
            start: startMillis,
            end: endMillis,        // Include end time
            duration: durationMillis,  // New API uses "duration" field
            billable: billable
        )
        
        print("📝 API: Time entry payload:")
        print("   - tid (task): \(taskID)")
        print("   - start: \(startMillis) (\(startTime))")
        print("   - end: \(endMillis) (\(endTime))")
        print("   - duration: \(durationMillis)ms (\(duration)s)")
        print("   - description: \(description ?? "nil")")
        print("   - billable: \(billable)")
        
        do {
            let jsonData = try JSONEncoder().encode(timeEntry)
            request.httpBody = jsonData
            
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                print("📤 API: Request body: \(jsonString)")
            }
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw ClickUpAPIError.apiError("Invalid response")
            }
            
            print("📥 API: Response status: \(httpResponse.statusCode)")
            
            if let responseString = String(data: data, encoding: .utf8) {
                print("📥 API: Response body: \(responseString)")
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                print("❌ API: Time entry failed: HTTP \(httpResponse.statusCode)")
                print("❌ API: Error details: \(errorMessage)")
                throw ClickUpAPIError.apiError("HTTP \(httpResponse.statusCode): \(errorMessage)")
            }
            
            print("✅ API: Time entry created successfully")
        } catch let error as ClickUpAPIError {
            throw error
        } catch {
            print("❌ API: Network error: \(error)")
            throw ClickUpAPIError.networkError(error)
        }
    }
    
    // MARK: - Validation
    
    func validateCredentials() async -> Bool {
        do {
            _ = try await fetchTasks()
            return true
        } catch {
            return false
        }
    }
}
