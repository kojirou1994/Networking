// swift-tools-version:5.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Networking",
    products: [
        .library(
            name: "Networking",
            targets: ["Networking"]),
        .library(
            name: "AsyncHTTPClientNetworking",
            targets: ["AsyncHTTPClientNetworking"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
         .package(url: "https://github.com/apple/swift-nio.git", from: "2.0.0"),
         .package(url: "https://github.com/swift-server/async-http-client.git", from: "1.1.0")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "Networking",
            dependencies: [
                .product(name: "NIOHTTP1", package: "swift-nio")
        ]),
        .target(
            name: "AsyncHTTPClientNetworking",
            dependencies: [
                "Networking",
                .product(name: "NIOFoundationCompat", package: "swift-nio"),
                .product(name: "AsyncHTTPClient", package: "async-http-client")
        ]),
        .testTarget(
            name: "NetworkingTests",
            dependencies: ["Networking"]),
    ]
)
