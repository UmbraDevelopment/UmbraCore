// swift-tools-version: 5.9

import PackageDescription

let package=Package(
  name: "UmbraCore",
  platforms: [
    .macOS("14.7")
  ],
  dependencies: [
    .package(url: "https://github.com/krzyzanowskim/CryptoSwift.git", from: "1.8.0"),
    .package(url: "https://github.com/SwiftyBeaver/SwiftyBeaver.git", from: "2.0.0")
  ]
)
