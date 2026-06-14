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
        .enableUpcomingFeature("ExistentialAny"),
        .enableUpcomingFeature("InternalImportsByDefault"),
        .enableUpcomingFeature("MemberImportVisibility"),
        .enableUpcomingFeature("InferIsolatedConformances"),
        .enableUpcomingFeature("ImmutableWeakCaptures"),
        .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
        .defaultIsolation(nil),
        .strictMemorySafety(),
      ],
    ),
    .testTarget(
      name: "APITests",
      dependencies: ["API"],
      swiftSettings: [
        .enableUpcomingFeature("ExistentialAny"),
        .enableUpcomingFeature("InternalImportsByDefault"),
        .enableUpcomingFeature("MemberImportVisibility"),
        .enableUpcomingFeature("InferIsolatedConformances"),
        .enableUpcomingFeature("ImmutableWeakCaptures"),
        .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
        .defaultIsolation(nil),
        .strictMemorySafety(),
      ],
    ),
  ],
  swiftLanguageModes: [.v6]
)
