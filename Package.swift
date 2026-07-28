// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "StickyTodos",
    platforms: [
        .macOS(.v14)
    ],
    targets: [
        .executableTarget(
            name: "StickyTodos",
            path: "Sources/StickyTodos",
            swiftSettings: [
                .swiftLanguageMode(.v5)
            ]
        )
    ]
)
