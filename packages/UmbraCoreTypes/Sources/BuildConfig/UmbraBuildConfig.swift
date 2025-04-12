import Foundation

/**
 # UmbraBuildConfig
 
 Central configuration module for UmbraCore build settings and runtime behaviour.
 
 This module defines configuration options that control UmbraCore's behaviour
 across different environments and integration scenarios, allowing for flexible
 deployment across various backend technologies and operational environments.
 
 ## Environment Configuration
 
 Controls logging verbosity, debug features, and performance optimisations:
 - Debug: Full logging, developer tools, assertions enabled
 - Development: Internal testing environment with enhanced logging
 - Alpha: Early external testing with selected debug features
 - Beta: Pre-release environment with minimal debug features
 - Production: Release environment with optimised performance
 
 ## Backend Integration
 
 Controls which cryptographic and storage backends are used:
 - Restic: Default integration with Restic
 - RingFFI: Ring cryptography with Argon2id for generic environments
 - AppleCK: Apple CryptoKit for sandboxed environments
 
 ## Extension Management
 
 Controls extension availability to prevent duplicate definitions across modules
 */

// MARK: - Environment Configuration

/// Environment types for UmbraCore
public enum UmbraEnvironment: String, Sendable {
    /// Developer environment with full logging and debug features
    case debug
    
    /// Internal testing environment with enhanced logging
    case development
    
    /// Early external testing with selected debug features
    case alpha
    
    /// Pre-release environment with minimal debug features
    case beta
    
    /// Production release environment with optimised performance
    case production
    
    /// Whether this is a development-oriented environment
    public var isDevelopment: Bool {
        switch self {
        case .debug, .development:
            return true
        case .alpha, .beta, .production:
            return false
        }
    }
    
    /// Whether this environment should include debug features
    public var includesDebugFeatures: Bool {
        switch self {
        case .debug, .development, .alpha:
            return true
        case .beta, .production:
            return false
        }
    }
    
    /// Whether performance optimisations should be prioritised
    public var prioritizePerformance: Bool {
        switch self {
        case .debug, .development:
            return false
        case .alpha, .beta, .production:
            return true
        }
    }
}

// MARK: - Backend Integration Strategy

/// Backend strategies for cryptography and storage operations
public enum BackendStrategy: String, Sendable {
    /// Restic integration as default option
    case restic
    
    /// Ring FFI with Argon2id for generic environments
    case ringFFI
    
    /// Apple CryptoKit for sandboxed environments
    case appleCK
    
    /// Whether this backend supports Apple sandbox requirements
    public var supportsSandbox: Bool {
        switch self {
        case .appleCK:
            return true
        case .restic, .ringFFI:
            return false
        }
    }
    
    /// Whether this backend has cross-platform compatibility
    public var isCrossPlatform: Bool {
        switch self {
        case .restic, .ringFFI:
            return true
        case .appleCK:
            return false
        }
    }
}

// MARK: - Active Configuration

/// The active environment configuration
#if DEBUG
    public let activeEnvironment: UmbraEnvironment = .debug
#elseif DEVELOPMENT
    public let activeEnvironment: UmbraEnvironment = .development
#elseif ALPHA
    public let activeEnvironment: UmbraEnvironment = .alpha
#elseif BETA
    public let activeEnvironment: UmbraEnvironment = .beta
#else
    public let activeEnvironment: UmbraEnvironment = .production
#endif

/// The active backend strategy
#if BACKEND_APPLE_CRYPTOKIT
    public let activeBackendStrategy: BackendStrategy = .appleCK
#elseif BACKEND_RING_FFI
    public let activeBackendStrategy: BackendStrategy = .ringFFI
#else
    public let activeBackendStrategy: BackendStrategy = .restic
#endif

// MARK: - Feature Configuration

/// Whether to enable trace-level logging
public let enableTraceLogging: Bool = activeEnvironment.isDevelopment

/// Whether to collect performance metrics
public let collectPerformanceMetrics: Bool = true

/// Whether to use the enhanced privacy-aware logging system
public let enablePrivacyAwareLogging: Bool = true

// MARK: - Extension Management

// Control extension availability to prevent duplicates
public let UMBRA_EXTENSIONS_DEFINED = true
public let UMBRA_EXTENSIONS_DEFINED_DEFAULT_CRYPTO = true
public let UMBRA_EXTENSIONS_DEFINED_SIGNATURE_SERVICE = true
public let UMBRA_EXTENSIONS_DEFINED_EXAMPLES = true

// MARK: - Privacy Controls

/// Privacy level classifications for logging and data handling
public enum PrivacyLevel: String, Sendable {
    /// Public information (non-sensitive)
    case `public` = "Public"
    
    /// Private but not sensitive information
    case `private` = "Private"
    
    /// Sensitive information requiring redaction
    case sensitive = "Sensitive"
    
    /// Information that should be hashed for logging
    case hash = "Hash"
}

/// Logging system constants
public enum LoggingConstants {
    /// Default maximum log entry size (in characters)
    public static let maxLogEntrySize = 10_000
    
    /// Default maximum metadata entries per collection
    public static let maxMetadataEntries = 50
    
    /// Redaction behaviour for logs based on environment
    public static var redactionBehavior: RedactionBehavior {
        switch activeEnvironment {
        case .debug, .development:
            return .redactInReleaseOnly
        default:
            return .alwaysRedact
        }
    }
}

/// Behaviour for redacting sensitive information
public enum RedactionBehavior {
    /// Only redact in release builds
    case redactInReleaseOnly
    
    /// Always redact sensitive information
    case alwaysRedact
    
    /// Never redact (for debugging only)
    case neverRedact
}

// MARK: - BuildConfig Factory

/// Factory for creating environment-specific configurations
public struct BuildConfigFactory {
    
    /// Creates a configuration with custom environment and backend strategy
    /// - Parameters:
    ///   - environment: The environment to use (defaults to active environment)
    ///   - backendStrategy: The backend strategy to use (defaults to active backend)
    /// - Returns: A tuple containing the environment and backend strategy
    public static func createConfig(
        environment: UmbraEnvironment? = nil,
        backendStrategy: BackendStrategy? = nil
    ) -> (environment: UmbraEnvironment, backendStrategy: BackendStrategy) {
        return (
            environment: environment ?? activeEnvironment,
            backendStrategy: backendStrategy ?? activeBackendStrategy
        )
    }
    
    /// Creates a debug configuration
    /// - Parameter backendStrategy: Optional backend strategy override
    /// - Returns: A debug configuration
    public static func createDebugConfig(
        backendStrategy: BackendStrategy? = nil
    ) -> (environment: UmbraEnvironment, backendStrategy: BackendStrategy) {
        return createConfig(environment: .debug, backendStrategy: backendStrategy)
    }
    
    /// Creates a development configuration
    /// - Parameter backendStrategy: Optional backend strategy override
    /// - Returns: A development configuration
    public static func createDevelopmentConfig(
        backendStrategy: BackendStrategy? = nil
    ) -> (environment: UmbraEnvironment, backendStrategy: BackendStrategy) {
        return createConfig(environment: .development, backendStrategy: backendStrategy)
    }
    
    /// Creates an alpha testing configuration
    /// - Parameter backendStrategy: Optional backend strategy override
    /// - Returns: An alpha configuration
    public static func createAlphaConfig(
        backendStrategy: BackendStrategy? = nil
    ) -> (environment: UmbraEnvironment, backendStrategy: BackendStrategy) {
        return createConfig(environment: .alpha, backendStrategy: backendStrategy)
    }
    
    /// Creates a beta testing configuration
    /// - Parameter backendStrategy: Optional backend strategy override
    /// - Returns: A beta configuration
    public static func createBetaConfig(
        backendStrategy: BackendStrategy? = nil
    ) -> (environment: UmbraEnvironment, backendStrategy: BackendStrategy) {
        return createConfig(environment: .beta, backendStrategy: backendStrategy)
    }
    
    /// Creates a production configuration
    /// - Parameter backendStrategy: Optional backend strategy override
    /// - Returns: A production configuration
    public static func createProductionConfig(
        backendStrategy: BackendStrategy? = nil
    ) -> (environment: UmbraEnvironment, backendStrategy: BackendStrategy) {
        return createConfig(environment: .production, backendStrategy: backendStrategy)
    }
    
    /// Creates a sandboxed configuration using AppleCK backend
    /// - Parameter environment: Optional environment override
    /// - Returns: A sandboxed configuration
    public static func createSandboxedConfig(
        environment: UmbraEnvironment? = nil
    ) -> (environment: UmbraEnvironment, backendStrategy: BackendStrategy) {
        return createConfig(environment: environment, backendStrategy: .appleCK)
    }
    
    /// Creates a cross-platform configuration using RingFFI backend
    /// - Parameter environment: Optional environment override
    /// - Returns: A cross-platform configuration
    public static func createCrossPlatformConfig(
        environment: UmbraEnvironment? = nil
    ) -> (environment: UmbraEnvironment, backendStrategy: BackendStrategy) {
        return createConfig(environment: environment, backendStrategy: .ringFFI)
    }
}

// MARK: - Compiler Directives Utilities

/// Utility methods for working with compiler directives
public struct CompilerDirectives {
    
    /// Whether the current build is a debug build
    public static var isDebugBuild: Bool {
        #if DEBUG
            return true
        #else
            return false
        #endif
    }
    
    /// Whether the current build is a development build
    public static var isDevelopmentBuild: Bool {
        #if DEVELOPMENT
            return true
        #else
            return false
        #endif
    }
    
    /// Whether the current build is an alpha build
    public static var isAlphaBuild: Bool {
        #if ALPHA
            return true
        #else
            return false
        #endif
    }
    
    /// Whether the current build is a beta build
    public static var isBetaBuild: Bool {
        #if BETA
            return true
        #else
            return false
        #endif
    }
    
    /// Whether the current build is a production build
    public static var isProductionBuild: Bool {
        #if PRODUCTION
            return true
        #else
            return false
        #endif
    }
    
    /// Whether the current build uses AppleCK backend
    public static var usesAppleCKBackend: Bool {
        #if BACKEND_APPLE_CRYPTOKIT
            return true
        #else
            return false
        #endif
    }
    
    /// Whether the current build uses RingFFI backend
    public static var usesRingFFIBackend: Bool {
        #if BACKEND_RING_FFI
            return true
        #else
            return false
        #endif
    }
    
    /// Whether the current build uses Restic backend
    public static var usesResticBackend: Bool {
        #if BACKEND_RESTIC
            return true
        #else
            return false
        #endif
    }
    
    /// Execute code only in debug or development builds
    public static func onlyInDevelopment(_ block: () -> Void) {
        #if DEBUG || DEVELOPMENT
            block()
        #endif
    }
    
    /// Execute code only in production builds
    public static func onlyInProduction(_ block: () -> Void) {
        #if PRODUCTION
            block()
        #endif
    }
    
    /// Execute code conditionally based on environment
    public static func inEnvironment(_ environment: UmbraEnvironment, _ block: () -> Void) {
        if activeEnvironment == environment {
            block()
        }
    }
    
    /// Execute code conditionally based on backend strategy
    public static func withBackendStrategy(_ strategy: BackendStrategy, _ block: () -> Void) {
        if activeBackendStrategy == strategy {
            block()
        }
    }
}

// MARK: - Privacy-Aware Logging Configuration

/// Configuration options for privacy-aware logging
public struct PrivacyAwareLoggingConfig {
    /// Whether to enable privacy-aware logging
    public let isEnabled: Bool
    
    /// Default privacy level for unspecified log entries
    public let defaultPrivacyLevel: PrivacyLevel
    
    /// Redaction behaviour for sensitive information
    public let redactionBehavior: RedactionBehavior
    
    /// Whether to include source location in log entries
    public let includeSourceLocation: Bool
    
    /// Maximum number of metadata entries per log
    public let maxMetadataEntries: Int
    
    /// Creates a default privacy-aware logging configuration
    /// - Returns: A default configuration
    public static func createDefault() -> PrivacyAwareLoggingConfig {
        PrivacyAwareLoggingConfig(
            isEnabled: true,
            defaultPrivacyLevel: .private,
            redactionBehavior: LoggingConstants.redactionBehavior,
            includeSourceLocation: activeEnvironment.isDevelopment,
            maxMetadataEntries: LoggingConstants.maxMetadataEntries
        )
    }
    
    /// Creates a development-focused logging configuration with minimal redaction
    /// - Returns: A development logging configuration
    public static func createForDevelopment() -> PrivacyAwareLoggingConfig {
        PrivacyAwareLoggingConfig(
            isEnabled: true,
            defaultPrivacyLevel: .public,
            redactionBehavior: .redactInReleaseOnly,
            includeSourceLocation: true,
            maxMetadataEntries: LoggingConstants.maxMetadataEntries * 2
        )
    }
    
    /// Creates a production-focused logging configuration with strict privacy controls
    /// - Returns: A production logging configuration
    public static func createForProduction() -> PrivacyAwareLoggingConfig {
        PrivacyAwareLoggingConfig(
            isEnabled: true,
            defaultPrivacyLevel: .private,
            redactionBehavior: .alwaysRedact,
            includeSourceLocation: false,
            maxMetadataEntries: LoggingConstants.maxMetadataEntries
        )
    }
    
    /// Creates a custom logging configuration
    /// - Parameters:
    ///   - isEnabled: Whether to enable privacy-aware logging
    ///   - defaultPrivacyLevel: Default privacy level for unspecified log entries
    ///   - redactionBehavior: Redaction behaviour for sensitive information
    ///   - includeSourceLocation: Whether to include source location in log entries
    ///   - maxMetadataEntries: Maximum number of metadata entries per log
    /// - Returns: A custom logging configuration
    public static func create(
        isEnabled: Bool = true,
        defaultPrivacyLevel: PrivacyLevel = .private,
        redactionBehavior: RedactionBehavior = LoggingConstants.redactionBehavior,
        includeSourceLocation: Bool = true,
        maxMetadataEntries: Int = LoggingConstants.maxMetadataEntries
    ) -> PrivacyAwareLoggingConfig {
        PrivacyAwareLoggingConfig(
            isEnabled: isEnabled,
            defaultPrivacyLevel: defaultPrivacyLevel,
            redactionBehavior: redactionBehavior,
            includeSourceLocation: includeSourceLocation,
            maxMetadataEntries: maxMetadataEntries
        )
    }
}
