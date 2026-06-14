// swift-tools-version: 6.4

import PackageDescription

let package = Package(
  name: "VinoGuesserKit",
  platforms: [
    .macOS(.v27),
  ],
  products: [
  ],
  dependencies: [
    .package(url: "https://github.com/apple/swift-http-api-proposal.git", branch: "main"),
    .package(url: "https://github.com/square/Valet.git", from: "5.0.0"),
    .package(url: "https://github.com/sindresorhus/Defaults.git", from: "9.0.0"),
    .package(url: "https://github.com/gohanlon/swift-memberwise-init-macro.git", from: "0.6.0"),
  ],
  targets: [
    .target(
      name: "UI",
      dependencies: [
        .target(name: "API"),
        .product(name: "Valet", package: "Valet"),
        .product(name: "Defaults", package: "Defaults"),
        .product(name: "DefaultsMacros", package: "Defaults"),
      ]
    ),
    .target(
      name: "API",
      dependencies: [
        .product(name: "HTTPClient", package: "swift-http-api-proposal"),
        .product(name: "MemberwiseInit", package: "swift-memberwise-init-macro"),
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
