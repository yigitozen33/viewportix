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
        .library(name: "Capture", targets: ["Capture"]),
        .library(name: "DesignSystem", targets: ["DesignSystem"]),
    ],
    targets: [
        .target(name: "EngineCore"),
        .target(name: "DeviceCatalog", dependencies: ["EngineCore"]),
        .target(name: "ProjectModel", dependencies: ["EngineCore", "DeviceCatalog"]),
        .target(name: "SyncCore", dependencies: ["EngineCore"], resources: [.copy("Resources/sync-agent.js")]),
        .target(name: "WebKitEngine", dependencies: ["EngineCore", "SyncCore"]),
        .target(name: "Capture"),
        // DesignTokens.swift is copied from design/tokens/ unchanged; regenerate there, never edit here.
        .target(name: "DesignSystem"),
        .testTarget(name: "DeviceCatalogTests", dependencies: ["DeviceCatalog"]),
        .testTarget(name: "ProjectModelTests", dependencies: ["ProjectModel"]),
        .testTarget(name: "SyncCoreTests", dependencies: ["SyncCore", "EngineCore"]),
        .testTarget(name: "WebKitEngineTests", dependencies: ["WebKitEngine", "SyncCore"]),
        .testTarget(name: "CaptureTests", dependencies: ["Capture"]),
    ]
)
