// swift-tools-version: 6.2

import PackageDescription

let package = Package(
  name: "BlindLogKit",
  platforms: [
    .iOS(.v26),
    .macOS(.v26)
  ],
  products: [
    .library(
      name: "BlindLogUI",
      targets: ["BlindLogUI"]
    ),
  ],
  targets: [
    .target(
      name: "BlindLogUI"
    ),
    .testTarget(
      name: "BlindLogUITests",
      dependencies: [
        .target(name: "BlindLogUI")
      ]
    )
  ]
)
