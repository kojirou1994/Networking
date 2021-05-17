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
    .library(
      name: "NetworkingPublisher",
      targets: ["NetworkingPublisher"]),
  ],
  dependencies: [
    .package(url: "https://github.com/apple/swift-nio.git", from: "2.0.0"),
    .package(url: "https://github.com/swift-server/async-http-client.git", from: "1.1.0"),
    .package(url: "https://github.com/elegantchaos/DictionaryCoding.git", from: "1.0.0"),
    .package(url: "https://github.com/kojirou1994/Multipart.git", from: "0.2.0")
  ],
  targets: [
    .target(
      name: "Networking",
      dependencies: [
        .product(name: "NIOFoundationCompat", package: "swift-nio"),
        .product(name: "NIOHTTP1", package: "swift-nio"),
        .product(name: "DictionaryCoding", package: "DictionaryCoding"),
        .product(name: "Multipart", package: "Multipart")
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
        .target(name: "Networking")
    ]),
    .target(
      name: "NetworkingPublisher",
      dependencies: [
        .target(name: "Networking")
      ]),
    .testTarget(
      name: "NetworkingTests",
      dependencies: [
        .target(name: "Networking")
      ],
      swiftSettings: [
        SwiftSetting.define("NETWORKING_LOGGING")
      ]
    ),
  ]
)
