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
        .package(url:"https://github.com/apple/swift-argument-parser", .exact("0.2.0")),
        .package(url: "https://github.com/erica/Swift-Mac-Utility", .exact("0.0.2")),
    ],
    targets: [
        .target(
            name: "xcopen",
            dependencies: [
              .product(name: "ArgumentParser", package: "swift-argument-parser"),
              .product(name: "MacUtility"),
            ],
            path: "xcopen/"
            ),
    ],
    swiftLanguageVersions: [
      .v5
    ]
)
