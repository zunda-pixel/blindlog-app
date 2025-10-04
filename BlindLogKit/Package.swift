// swift-tools-version: 6.2

import PackageDescription

let package = Package(
  name: "BlindLogKit",
  defaultLocalization: "en",
  platforms: [
    .iOS(.v26),
    .macOS(.v26),
  ],
  products: [
    .library(
      name: "BlindLogUI",
      targets: ["BlindLogUI"]
    )
  ],
  dependencies: [
    .package(url: "https://github.com/gohanlon/swift-memberwise-init-macro.git", from: "0.5.2"),
    .package(url: "https://github.com/apple/swift-http-types.git", from: "1.4.0"),
    .package(url: "https://github.com/square/Valet.git", from: "5.0.0"),
    .package(url: "https://github.com/sindresorhus/Defaults.git", from: "9.0.0"),
  ],
  targets: [
    .target(
      name: "BlindLogUI",
      dependencies: [
        .product(name: "MemberwiseInit", package: "swift-memberwise-init-macro"),
        .product(name: "HTTPTypesFoundation", package: "swift-http-types"),
        .product(name: "Valet", package: "Valet"),
        .product(name: "Defaults", package: "Defaults"),
        .product(name: "DefaultsMacros", package: "Defaults"),
      ]
    ),
    .testTarget(
      name: "BlindLogUITests",
      dependencies: [
        .target(name: "BlindLogUI")
      ]
    ),
  ]
)
