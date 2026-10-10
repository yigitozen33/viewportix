// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "ViewportixKit",
    platforms: [.macOS(.v26)],
    products: [
        .library(name: "EngineCore", targets: ["EngineCore"]),
        .library(name: "DeviceCatalog", targets: ["DeviceCatalog"]),
        .library(name: "ProjectModel", targets: ["ProjectModel"]),
        .library(name: "SyncCore", targets: ["SyncCore"]),
        .library(name: "WebKitEngine", targets: ["WebKitEngine"]),
    ],
    targets: [
        .target(name: "EngineCore"),
        .target(name: "DeviceCatalog", dependencies: ["EngineCore"]),
        .target(name: "ProjectModel", dependencies: ["EngineCore", "DeviceCatalog"]),
        .target(name: "SyncCore", dependencies: ["EngineCore"], resources: [.copy("Resources/sync-agent.js")]),
        .target(name: "WebKitEngine", dependencies: ["EngineCore", "SyncCore"]),
        .testTarget(name: "DeviceCatalogTests", dependencies: ["DeviceCatalog"]),
        .testTarget(name: "ProjectModelTests", dependencies: ["ProjectModel"]),
        .testTarget(name: "SyncCoreTests", dependencies: ["SyncCore"]),
        .testTarget(name: "WebKitEngineTests", dependencies: ["WebKitEngine", "SyncCore"]),
    ]
)
