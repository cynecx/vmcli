// swift-tools-version:5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let swiftSettings : [SwiftSetting] = []

let package = Package(
    name: "dealer",
    platforms: [
        .macOS(.v13),
    ],
    products: [
        .executable(name: "vmcli", targets: ["vmcli"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.0.0"),
    ],
    targets: [
        .executableTarget(name: "vmcli",
                dependencies: [
                    .product(name: "ArgumentParser", package: "swift-argument-parser"),
                ],
                swiftSettings: swiftSettings),
    ]
)
