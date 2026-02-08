// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "swift-agent-sdk",
    platforms: [
        .macOS(.v15)
    ],
    products: [
        .library(name: "AgentSDK", targets: ["AgentSDK"]),
        .library(name: "AgentSDKClaudeCode", targets: ["AgentSDKClaudeCode"]),
        .library(name: "AgentSDKTesting", targets: ["AgentSDKTesting"]),
    ],
    targets: [
        // Protocol layer
        .target(
            name: "AgentSDK"
        ),
        // Concrete: Claude Code CLI
        .target(
            name: "AgentSDKClaudeCode",
            dependencies: ["AgentSDK"]
        ),
        // Testing utilities
        .target(
            name: "AgentSDKTesting",
            dependencies: ["AgentSDK"]
        ),
        // Tests
        .testTarget(
            name: "AgentSDKTests",
            dependencies: ["AgentSDK", "AgentSDKTesting"]
        ),
        .testTarget(
            name: "AgentSDKClaudeCodeTests",
            dependencies: ["AgentSDKClaudeCode", "AgentSDKTesting"]
        ),
        .testTarget(
            name: "IntegrationTests",
            dependencies: ["AgentSDKClaudeCode"]
        ),
    ]
)
