// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Infrastructure",
    platforms: [.macOS(.v15)],
    products: [
        .library(name: "Infrastructure", targets: ["Infrastructure"]),
    ],
    dependencies: [
        .package(path: "../Domain"),
        .package(path: "../../../../"),  // swift-agent-sdk ルート
    ],
    targets: [
        .target(
            name: "Infrastructure",
            dependencies: [
                .product(name: "Domain", package: "Domain"),
                .product(name: "AgentSDKClaudeCode", package: "swift-agent-sdk"),
            ]
        ),
        .testTarget(
            name: "InfrastructureTests",
            dependencies: [
                "Infrastructure",
                .product(name: "AgentSDKTesting", package: "swift-agent-sdk"),
            ]
        ),
    ]
)
