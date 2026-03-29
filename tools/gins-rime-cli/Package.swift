// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "gins-rime-cli",
    platforms: [.macOS(.v14)],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.5.0"),
    ],
    targets: [
        .executableTarget(
            name: "GinsRime",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ],
            path: "Sources/GinsRime"
        ),
    ]
)
