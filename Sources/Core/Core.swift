/// Core Module
///
/// Provides fundamental types and utilities that form the foundation
/// of the UmbraCore framework. This module contains essential
/// functionality used across all other modules.
///
/// # Key Features
/// - Base types and protocols
/// - Common utilities
/// - Framework configuration
/// - System integration
///
/// # Module Organisation
///
/// ## Foundation Types
/// ```swift
/// Result
/// Optional
/// Sequence
/// ```
///
/// ## Configuration
/// ```swift
/// CoreConfig
/// Environment
/// BuildFlags
/// ```
///
/// ## System Integration
/// ```swift
/// SystemInfo
/// PlatformUtils
/// VersionInfo
/// ```
///
/// # Framework Configuration
///
/// ## Build Configuration
/// Supports multiple build configurations:
/// - Debug: Development builds
/// - Release: Production builds
/// - Profile: Performance analysis
///
/// ## Environment Settings
/// Environment-specific configuration:
/// - Development
/// - Staging
/// - Production
///
/// # System Integration
///
/// ## Platform Support
/// - macOS 14.0+
/// - Apple Silicon optimisation
/// - Intel compatibility
///
/// ## Version Management
/// - Semantic versioning
/// - Compatibility checking
/// - Update management
///
/// # Performance Considerations
///
/// ## Memory Management
/// - Resource pooling
/// - Cache management
/// - Memory limits
///
/// ## Optimisation
/// - Lazy loading
/// - Value semantics
/// - Copy-on-write
///
/// # Usage Example
/// ```swift
/// let config = CoreConfig.current
///
/// if config.isDebugBuild {
///     // Enable additional debugging
/// }
/// ```
///
/// # Thread Safety
/// Core types are designed for concurrent use:
/// - Thread-safe configuration
/// - Atomic operations
/// - Value types

import Foundation
import ObjCBridgingTypesFoundation

/// Core framework initialisation and management
public enum Core {
  /// Current version of the Core module
  public static let version="1.0.0"

  /// Flag indicating whether the Core framework has been initialised
  @MainActor
  private static var isInitialized=false

  /// Initialises the core framework and its essential services.
  /// - Throws: CoreError if framework is already initialised or if service initialisation fails
  @MainActor
  public static func initialize() async throws {
    // Ensure framework is in a valid state for initialisation
    guard !isInitialized else {
      throw CoreError.initialisationError("Core framework is already initialised")
    }

    // Mark framework as initialized
    isInitialized=true

    // Note: When ServiceContainer is implemented, add:
    // try await ServiceContainer.shared.initialize()
  }
}

/// Errors that can occur during Core operations
/// @deprecated This will be replaced by ErrorHandling.CoreError in a future version.
/// New code should use ErrorHandling.CoreError directly.
@available(
  *,
  deprecated,
  message: "This will be replaced by ErrorHandling.CoreError in a future version. Use ErrorHandling.CoreError instead."
)
public enum CoreError: Foundation.LocalizedError {
  /// Error during initialisation
  case initialisationError(String)

  public var errorDescription: String? {
    switch self {
      case let .initialisationError(message):
        "Initialisation error: \(message)"
    }
  }
}
