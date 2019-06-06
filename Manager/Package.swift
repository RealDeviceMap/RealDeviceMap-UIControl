// swift-tools-version:4.1

import PackageDescription

let package = Package(
    name: "RDM-UIC-Manager",
    products: [],
    dependencies: [
        .package(url: "https://github.com/PerfectlySoft/Perfect-HTTPServer.git", .upToNextMinor(from: "3.0.18")),
        .package(url: "https://github.com/SwiftORM/SQLite-StORM.git", .upToNextMinor(from: "3.1.0"))
    ],
    targets: [
        .target(name: "RDM-UIC-Manager", dependencies: ["PerfectHTTPServer","SQLiteStORM"])
    ]
)
