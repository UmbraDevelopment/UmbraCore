import Foundation

// Use the shared declarations instead of local ones
import Interfaces
import UmbraErrorsCore

/// Error domain namespace

/// Error context protocol

/// Base error context implementation

/// Enum representing the specific repository error types
public enum RepositoryErrorType: Error {
  /// The repository could not be found
  case repositoryNotFound(String)

  /// The repository could not be opened
  case repositoryOpenFailed(String)

  /// The repository is corrupt
  case repositoryCorrupt(String)

  /// The repository is locked by another process
  case repositoryLocked(String)

  /// The repository is in an invalid state
  case invalidState(String)

  /// Permission denied for repository operation
  case permissionDenied(String)

  /// The object could not be found in the repository
  case objectNotFound(String)

  /// The object already exists in the repository
  case objectAlreadyExists(String)

  /// The object is corrupt
  case objectCorrupt(String)

  /// The object type is invalid
  case invalidObjectType(String)

  /// The object data is invalid
  case invalidObjectData(String)

  /// Failed to save the object
  case saveFailed(String)

  /// Failed to load the object
  case loadFailed(String)

  /// Failed to delete the object
  case deleteFailed(String)

  /// Operation timed out
  case timeout(String)

  /// General repository error
  case general(String)

  /// Get a descriptive message for this error type
  var message: String {
    switch self {
      case let .repositoryNotFound(message): "Repository not found: \(message)"
      case let .repositoryOpenFailed(message): "Failed to open repository: \(message)"
      case let .repositoryCorrupt(message): "Repository is corrupt: \(message)"
      case let .repositoryLocked(message): "Repository is locked: \(message)"
      case let .invalidState(message): "Invalid repository state: \(message)"
      case let .permissionDenied(message): "Permission denied: \(message)"
      case let .objectNotFound(message): "Object not found: \(message)"
      case let .objectAlreadyExists(message): "Object already exists: \(message)"
      case let .objectCorrupt(message): "Object is corrupt: \(message)"
      case let .invalidObjectType(message): "Invalid object type: \(message)"
      case let .invalidObjectData(message): "Invalid object data: \(message)"
      case let .saveFailed(message): "Failed to save object: \(message)"
      case let .loadFailed(message): "Failed to load object: \(message)"
      case let .deleteFailed(message): "Failed to delete object: \(message)"
      case let .timeout(message): "Operation timed out: \(message)"
      case let .general(message): "Repository error: \(message)"
    }
  }

  /// Get a short code for this error type
  var code: String {
    switch self {
      case .repositoryNotFound: "repo_not_found"
      case .repositoryOpenFailed: "repo_open_failed"
      case .repositoryCorrupt: "repo_corrupt"
      case .repositoryLocked: "repo_locked"
      case .invalidState: "invalid_state"
      case .permissionDenied: "permission_denied"
      case .objectNotFound: "object_not_found"
      case .objectAlreadyExists: "object_already_exists"
      case .objectCorrupt: "object_corrupt"
      case .invalidObjectType: "invalid_object_type"
      case .invalidObjectData: "invalid_object_data"
      case .saveFailed: "save_failed"
      case .loadFailed: "load_failed"
      case .deleteFailed: "delete_failed"
      case .timeout: "timeout"
      case .general: "general_error"
    }
  }
}

/// Struct wrapper for repository errors that conforms to UmbraError
public struct RepositoryError: Error, UmbraErrorsCore.UmbraError, Sendable,
CustomStringConvertible {
  /// The specific repository error type
  public let errorType: RepositoryErrorType

  /// The domain for repository errors
  public let domain: String="Repository"

  /// The error code
  public var code: String {
    errorType.code
  }

  /// Human-readable description of the error
  public var errorDescription: String {
    errorType.message
  }

  /// A user-readable description of the error
  public var description: String {
    "[\(domain).\(code)] \(errorDescription)"
  }

  /// Source information about where the error occurred
  public let source: UmbraErrorsCore.ErrorSource?

  /// The underlying error, if any
  public let underlyingError: Error?

  /// Additional context for the error
  public let context: UmbraErrorsCore.ErrorContext

  /// Initialize a new repository error
  public init(
    errorType: RepositoryErrorType,
    source: UmbraErrorsCore.ErrorSource?=nil,
    underlyingError: Error?=nil,
    context: UmbraErrorsCore.ErrorContext?=nil
  ) {
    self.errorType=errorType
    self.source=source
    self.underlyingError=underlyingError
    self.context=context ?? UmbraErrorsCore.ErrorContext(
      source: "Repository",
      operation: "repository_operation",
      details: errorType.message
    )
  }

  /// Creates a new instance of the error with additional context
  public func with(context: UmbraErrorsCore.ErrorContext) -> Self {
    RepositoryError(
      errorType: errorType,
      source: source,
      underlyingError: underlyingError,
      context: context
    )
  }

  /// Creates a new instance of the error with a specified underlying error
  public func with(underlyingError: Error) -> Self {
    RepositoryError(
      errorType: errorType,
      source: source,
      underlyingError: underlyingError,
      context: context
    )
  }

  /// Creates a new instance of the error with source information
  public func with(source: UmbraErrorsCore.ErrorSource) -> Self {
    RepositoryError(
      errorType: errorType,
      source: source,
      underlyingError: underlyingError,
      context: context
    )
  }

  /// Create a repository error with the specified type and message
  public static func create(
    _ type: RepositoryErrorType,
    file: String=#file,
    function: String=#function,
    line: Int=#line
  ) -> RepositoryError {
    RepositoryError(
      errorType: type,
      source: UmbraErrorsCore.ErrorSource(
        file: file,
        line: line,
        function: function
      )
    )
  }

  /// Convenience initializers for specific error types
  public static func notFound(
    _ message: String,
    file: String=#file,
    function: String=#function,
    line: Int=#line
  ) -> RepositoryError {
    create(.repositoryNotFound(message), file: file, function: function, line: line)
  }

  public static func openFailed(
    _ message: String,
    file: String=#file,
    function: String=#function,
    line: Int=#line
  ) -> RepositoryError {
    create(.repositoryOpenFailed(message), file: file, function: function, line: line)
  }

  // Add other convenience methods as needed
}

// MARK: - Mapping Extension

extension RepositoryError {
  /// Create a RepositoryError from a CoreErrors.RepositoryError
  ///
  /// This allows for easier migration from the legacy error system
  ///
  /// - Parameter legacyError: The legacy CoreErrors.RepositoryError
  /// - Returns: The equivalent RepositoryError
  public static func from(legacyError _: Any) -> RepositoryError {
    // We need to refactor this mapping once we have access to the actual CoreErrors type
    // For now just return a generic error to fix the build
    RepositoryError(errorType: .general("Converted from legacy error"))
  }
}
