// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ClickUpTracker",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "ClickUpTracker",
            targets: ["ClickUpTracker"])
    ],
    targets: [
        .executableTarget(
            name: "ClickUpTracker",
            path: "Sources/ClickUpTracker"
        )
    ]
)
