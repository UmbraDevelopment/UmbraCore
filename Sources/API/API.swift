/// API Module
///
/// Provides the public API surface for UmbraCore, defining the primary
/// interfaces and types that external clients use to interact with
/// the framework.
///
/// # Key Features
/// - Public interfaces
/// - API versioning
/// - Stability guarantees
/// - Documentation
///
/// # Module Organisation
///
/// ## Core Interfaces
/// ```swift
/// UmbraClient
/// BackupManager
/// SecurityProvider
/// ```
///
/// ## Data Types
/// ```swift
/// BackupConfig
/// SecurityContext
/// RepositoryInfo
/// ```
///
/// ## Results
/// ```swift
/// BackupResult
/// RestoreResult
/// OperationStatus
/// ```
///
/// # API Design
///
/// ## Versioning
/// Semantic versioning strategy:
/// - Major: Breaking changes
/// - Minor: New features
/// - Patch: Bug fixes
///
/// ## Stability
/// API stability guarantees:
/// - Stable interfaces
/// - Deprecated warnings
/// - Migration paths
///
/// # Client Integration
///
/// ## Getting Started
/// ```swift
/// let client = UmbraClient()
/// try await client.initialize()
/// ```
///
/// ## Basic Operations
/// ```swift
/// let backup = try await client.createBackup(
///     path: path,
///     config: config
/// )
/// ```
///
/// # Error Handling
///
/// ## Error Types
/// Comprehensive error handling:
/// - Operation errors
/// - Validation errors
/// - System errors
///
/// ## Recovery
/// Error recovery options:
/// - Automatic retry
/// - Alternative paths
/// - Manual intervention
///
/// # Thread Safety
/// API is designed for concurrent use:
/// - Thread-safe operations
/// - Async/await support
/// - Actor isolation
///
/// # Documentation
///
/// ## API Reference
/// - Method documentation
/// - Type specifications
/// - Usage examples
///
/// ## Guides
/// - Getting started
/// - Best practices
/// - Migration guides
public enum API {
  /// Current version of the API module
  public static let version = "1.0.0"

  /// Initialise API with default configuration
  public static func initialize() {
    // Configure API system
  }
}
