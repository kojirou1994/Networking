// swift-tools-version:5.2

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
    .package(url: "https://github.com/apple/swift-nio.git", from: "2.0.0"),
    .package(url: "https://github.com/swift-server/async-http-client.git", from: "1.1.0")
  ],
  targets: [
    .target(
      name: "Networking",
      dependencies: [
        .product(name: "NIOFoundationCompat", package: "swift-nio"),
        .product(name: "NIOHTTP1", package: "swift-nio")
    ]),
    .target(
      name: "AsyncHTTPClientNetworking",
      dependencies: [
        "Networking",
        .product(name: "AsyncHTTPClient", package: "async-http-client")
    ]),
    .testTarget(
      name: "NetworkingTests",
      dependencies: ["Networking"]),
  ]
)
