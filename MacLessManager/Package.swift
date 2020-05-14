// swift-tools-version:5.0

import PackageDescription

let package = Package(
    name: "MacLessManager",
    dependencies: [
        .package(url: "https://github.com/apple/swift-log", .upToNextMinor(from: "1.2.0")),
        .package(url: "https://github.com/JohnSundell/ShellOut", .upToNextMinor(from: "2.3.0"))
    ],
    targets: [
        .target(
            name: "MacLessManager",
            dependencies: [
                .product(name: "Logging", package: "swift-log"),
                .product(name: "ShellOut", package: "ShellOut")
            ]
        )
    ]
)
