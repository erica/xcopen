// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "xcopen",
    platforms: [
      .macOS(.v10_12)
    ],
    products: [
        .executable(
            name: "xcopen",
            targets: ["xcopen"]),
    ],
    dependencies: [
      .package(
        url:"https://github.com/apple/swift-argument-parser",
        .exact("0.0.6")),
      .package(url: "https://github.com/erica/Swift-General-Utility", from: "0.0.1"),
    ],
    targets: [
        .target(
            name: "xcopen",
            dependencies: [
              .product(name: "ArgumentParser", package: "swift-argument-parser"),
              .product(name: "GeneralUtility"),
            ],
            path: "xcopen/"
            ),
    ],
    swiftLanguageVersions: [
      .v5
    ]
)
