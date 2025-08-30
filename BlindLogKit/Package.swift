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
    .package(url: "https://github.com/gohanlon/swift-memberwise-init-macro.git", from: "0.5.2")
  ],
  targets: [
    .target(
      name: "BlindLogUI",
      dependencies: [
        .product(name: "MemberwiseInit", package: "swift-memberwise-init-macro"),
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
