// swift-tools-version: 6.4

import PackageDescription

let package = Package(
  name: "MyLibrary",
  platforms: [
    .macOS(.v27),
  ],
  products: [
    .library(
      name: "API",
      targets: ["API"]
    ),
  ],
  dependencies: [
    .package(url: "https://github.com/apple/swift-http-api-proposal.git", branch: "main"),
  ],
  targets: [
    .target(
      name: "API",
      dependencies: [
        .product(name: "HTTPClient", package: "swift-http-api-proposal"),
      ],
      swiftSettings: [
        .enableUpcomingFeature("ApproachableConcurrency"),
      ],
    ),
    .testTarget(
      name: "APITests",
      dependencies: ["API"],
      swiftSettings: [
        .enableUpcomingFeature("ApproachableConcurrency"),
      ],
    ),
  ],
  swiftLanguageModes: [.v6]
)
