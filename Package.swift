// swift-tools-version:5.2

import PackageDescription

let package = Package(
  name: "Networking",
  platforms: [
    .macOS(.v10_12), .iOS(.v10), .tvOS(.v10)
  ],
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
    .package(url: "https://github.com/swift-server/async-http-client.git", from: "1.1.0"),
    .package(url: "https://github.com/elegantchaos/DictionaryCoding", from: "1.0.0"),
  ],
  targets: [
    .target(
      name: "Networking",
      dependencies: [
        .product(name: "NIOFoundationCompat", package: "swift-nio"),
        .product(name: "NIOHTTP1", package: "swift-nio"),
        .product(name: "DictionaryCoding", package: "DictionaryCoding")
    ]),
    .target(
      name: "AsyncHTTPClientNetworking",
      dependencies: [
        .target(name: "Networking"),
        .product(name: "AsyncHTTPClient", package: "async-http-client")
    ]),
    .target(
      name: "EndpointTemplate",
      dependencies: [
        "Networking"
    ]),
    .testTarget(
      name: "NetworkingTests",
      dependencies: ["Networking"]),
  ]
)
