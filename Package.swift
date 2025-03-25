// swift-tools-version:5.9
import PackageDescription

let package=Package(
  name: "UmbraCore",
  platforms: [
    .macOS("14.7")
  ],
  products: [
    .library(
      name: "UmbraCore",
      targets: ["UmbraCore"]
    ),
    .library(
      name: "UmbraXPC",
      targets: ["UmbraXPC"]
    ),
    .library(
      name: "UmbraCryptoService",
      targets: ["UmbraCryptoService"]
    ),
    .library(
      name: "UmbraBookmarkService",
      targets: ["UmbraBookmarkService"]
    ),
    .library(
      name: "UmbraKeychainService",
      targets: ["UmbraKeychainService"]
    ),
    .library(
      name: "UmbraLogging",
      targets: ["UmbraLogging"]
    ),
    .library(
      name: "ErrorHandling",
      targets: ["ErrorHandling"]
    )
  ],
  dependencies: [
    .package(url: "https://github.com/krzyzanowskim/CryptoSwift.git", from: "1.8.0"),
    .package(url: "https://github.com/SwiftyBeaver/SwiftyBeaver.git", from: "2.0.0"),
    .package(url: "https://github.com/apple/swift-syntax.git", from: "509.0.0")
  ],
  targets: [
    // Base Types
    .target(
      name: "SecurityTypes",
      dependencies: [],
      exclude: [
        "Types/BUILD.bazel",
        "Protocols/BUILD.bazel",
        "BUILD.bazel"
      ]
    ),
    .target(
      name: "SecurityUtils",
      dependencies: ["SecurityTypes"],
      exclude: [
        "BUILD.bazel",
        "Protocols/BUILD.bazel"
      ]
    ),
    .target(
      name: "CryptoTypes",
      dependencies: ["SecurityTypes", "CryptoSwift"],
      exclude: [
        "BUILD.bazel",
        "Protocols/BUILD.bazel",
        "Services/BUILD.bazel",
        "Types/BUILD.bazel",
        "Types/CredentialManager.swift" // Exclude duplicate
      ]
    ),
    .target(
      name: "ResticTypes",
      dependencies: [],
      exclude: ["BUILD.bazel"]
    ),
    .target(
      name: "ServiceTypes",
      dependencies: [],
      exclude: ["BUILD.bazel"]
    ),

    // Logging
    .target(
      name: "UmbraLogging",
      dependencies: ["SwiftyBeaver"],
      exclude: ["BUILD.bazel"]
    ),

    // Error Handling
    .target(
      name: "ErrorHandling",
      dependencies: ["UmbraLogging"],
      exclude: [
        "Protocols/BUILD.bazel",
        "Models/BUILD.bazel",
        "README.md",
        "BUILD.bazel",
        "Common/BUILD.bazel",
        "Models/ErrorContext.swift" // Exclude duplicate
      ]
    ),

    // XPC
    .target(
      name: "UmbraXPC",
      dependencies: [],
      path: "Sources/XPC/Core",
      exclude: ["BUILD.bazel", "BUILD.bazel.bak"]
    ),

    // Services
    .target(
      name: "UmbraCryptoService",
      dependencies: [
        "UmbraXPC",
        "CryptoTypes",
        "CryptoSwift"
      ],
      exclude: [
        "Resources/Info.plist",
        "Resources/UmbraCryptoService.entitlements",
        "Resources/BUILD.bazel",
        "BUILD.bazel",
        "BUILD.bazel.bak"
      ]
    ),
    .target(
      name: "UmbraBookmarkService",
      dependencies: [
        "UmbraXPC"
      ],
      exclude: ["BUILD.bazel"]
    ),
    .target(
      name: "UmbraKeychainService",
      dependencies: [
        "UmbraXPC",
        "CryptoSwift"
      ],
      exclude: ["BUILD.bazel"]
    ),
    .target(
      name: "UmbraCrypto",
      dependencies: [
        "CryptoTypes",
        "CryptoSwift"
      ],
      exclude: ["BUILD.bazel"]
    ),

    // Core
    .target(
      name: "UmbraCore",
      dependencies: [
        "SecurityTypes",
        "CryptoTypes",
        "UmbraXPC",
        "UmbraBookmarkService",
        "UmbraKeychainService",
        "UmbraLogging",
        "ErrorHandling",
        "SwiftyBeaver"
      ],
      exclude: ["BUILD.bazel", "BUILD.bazel.bak"]
    ),

    // Test Targets
    .testTarget(
      name: "UmbraCoreTests",
      dependencies: ["UmbraCore"]
    ),
    .testTarget(
      name: "XPCTests",
      dependencies: ["UmbraXPC", "UmbraCryptoService"]
    ),
    .testTarget(
      name: "BookmarkTests",
      dependencies: ["UmbraBookmarkService", "SecurityUtils"]
    ),
    .testTarget(
      name: "KeychainTests",
      dependencies: [
        "UmbraKeychainService",
        "UmbraXPC"
      ],
      resources: [
        .process("UmbraKeychainService.entitlements")
      ]
    )
  ]
)
