// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "UmbraCoreExamples",
    platforms: [
        .macOS(.v13),
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "UmbraCoreExamples",
            targets: ["LoggingExamples", "CryptoExamples", "ErrorHandlingExamples", "SecurityExamples"]),
    ],
    dependencies: [
        // Since we're within the UmbraCore project structure, we reference the root package
        .package(path: "../..")
    ],
    targets: [
        .target(
            name: "LoggingExamples",
            dependencies: [
                // Reference dependencies through the root package
                .product(name: "LoggingServices", package: "UmbraCore"),
                .product(name: "LoggingAdapters", package: "UmbraCore")
            ],
            path: "Logging/Sources",
            resources: [
                .copy("../Documentation")
            ]),
        .target(
            name: "CryptoExamples",
            dependencies: [
                .product(name: "CryptoServices", package: "UmbraCore")
            ],
            path: "Crypto/Sources"),
        .target(
            name: "ErrorHandlingExamples",
            dependencies: [
                .product(name: "ErrorLoggingServices", package: "UmbraCore")
            ],
            path: "ErrorHandling/Sources",
            resources: [
                .copy("../Documentation")
            ]),
        .target(
            name: "SecurityExamples",
            dependencies: [
                .product(name: "SecurityImplementation", package: "UmbraCore"),
                .product(name: "SecurityCoreInterfaces", package: "UmbraCore")
            ],
            path: "Security/Sources")
    ]
)
