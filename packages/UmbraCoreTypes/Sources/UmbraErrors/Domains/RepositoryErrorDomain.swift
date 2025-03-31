import Foundation

// Define the UmbraErrors namespace if it doesn't exist
public enum UmbraErrors {}

/// Repository domain errors
extension UmbraErrors {
  /// Repository-related errors
  public enum Repository: Error, Sendable {
    /// Repository is not accessible due to permissions or path issues
    case inaccessible(reason: String)

    /// Repository is locked and the operation cannot proceed
    case locked(reason: String)

    /// Repository is corrupted and needs repair
    case corrupted(reason: String)

    /// Repository needs to be initialised before use
    case uninitialised(reason: String)

    /// Repository validation failed
    case invalidRepository(reason: String)

    /// Invalid operation for the current repository state
    case invalidOperation(operation: String, reason: String)

    /// Repository with this identifier already exists
    case duplicateIdentifier(reason: String)

    /// Repository not found in the registry
    case notFound(reason: String)

    /// Internal error during repository operation
    case internalError(reason: String)

    /// IO error during repository operations
    case ioError(reason: String)

    /// Permission denied for repository operation
    case permissionDenied(operation: String, reason: String)

    /// Maintenance operation failed
    case maintenanceFailed(operation: String, reason: String)

    /// Network error during repository operation
    case networkError(reason: String)

    /// Invalid repository URL
    case invalidURL(reason: String)
  }
}
