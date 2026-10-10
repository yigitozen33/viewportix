// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "ViewportixKit",
    platforms: [.macOS(.v26)],
    products: [
        .library(name: "EngineCore", targets: ["EngineCore"]),
        .library(name: "DeviceCatalog", targets: ["DeviceCatalog"]),
        .library(name: "ProjectModel", targets: ["ProjectModel"]),
    ],
    targets: [
        .target(name: "EngineCore"),
        .target(name: "DeviceCatalog", dependencies: ["EngineCore"]),
        .target(name: "ProjectModel", dependencies: ["EngineCore", "DeviceCatalog"]),
        .testTarget(name: "DeviceCatalogTests", dependencies: ["DeviceCatalog"]),
        .testTarget(name: "ProjectModelTests", dependencies: ["ProjectModel"]),
    ]
)
