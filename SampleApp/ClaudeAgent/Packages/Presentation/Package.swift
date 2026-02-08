// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Presentation",
    platforms: [.macOS(.v15)],
    products: [
        .library(name: "Presentation", targets: ["Presentation"]),
    ],
    dependencies: [
        .package(path: "../Domain"),
        .package(url: "https://github.com/no-problem-dev/swift-markdown-view", from: "1.0.0"),
        .package(url: "https://github.com/no-problem-dev/swift-design-system", from: "1.0.0"),
        .package(url: "https://github.com/no-problem-dev/swift-ui-routing", from: "1.0.0"),
    ],
    targets: [
        .target(
            name: "Presentation",
            dependencies: [
                .product(name: "Domain", package: "Domain"),
                .product(name: "SwiftMarkdownView", package: "swift-markdown-view"),
                .product(name: "DesignSystem", package: "swift-design-system"),
                .product(name: "UIRouting", package: "swift-ui-routing"),
            ]
        ),
        .testTarget(
            name: "PresentationTests",
            dependencies: ["Presentation"]
        ),
    ]
)
