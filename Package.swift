// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "WhisperFlow",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "WhisperFlow",
            path: "Sources/WhisperFlow",
            resources: [.copy("Resources")]
        ),
        .testTarget(
            name: "WhisperFlowTests",
            dependencies: ["WhisperFlow"],
            path: "Tests/WhisperFlowTests"
        ),
    ]
)
