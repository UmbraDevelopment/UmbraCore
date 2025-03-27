import Foundation
import UmbraErrorsCore
// Use the shared declarations instead of local ones
import Interfaces

// This file is temporarily commented out to break circular dependencies
// It should be restored after the module structure is refactored to avoid circular references.

/*
/// Error domain namespace

/// Error context protocol

/// Base error context implementation

/// Domain for repository-related errors
public struct RepositoryErrorDomain: ErrorDomain {
  /// The domain identifier
  public static let identifier="Repository"

  /// The domain name
  public static let name="Repository Errors"

  /// The domain description
  public static let description="Errors related to repository operations and data management"

  /// Common error categories in this domain
  public enum Category: String, ErrorCategory {
    /// Errors related to repository access
    case access="Access"

    /// Errors related to repository data
    case data="Data"

    /// Errors related to repository state
    case state="State"

    /// Errors related to repository operations
    case operation="Operation"

    /// The category description
    public var description: String {
      switch self {
        case .access:
          "Errors occurring when accessing or opening repositories"
        case .data:
          "Errors related to repository data integrity and operations"
        case .state:
          "Errors related to the repository state and lifecycle"
        case .operation:
          "Errors occurring during repository operations"
      }
    }
  }

  /// Map a RepositoryError to its category
  ///
  /// - Parameter error: The repository error
  /// - Returns: The error category
  public static func category(for error: RepositoryError) -> Category {
    switch error.errorType {
      case .repositoryNotFound, .repositoryOpenFailed, .repositoryLocked, .permissionDenied:
        .access
      case .objectNotFound, .objectAlreadyExists, .objectCorrupt, .invalidObjectType,
           .invalidObjectData:
        .data
      case .repositoryCorrupt, .invalidState:
        .state
      case .saveFailed, .loadFailed, .deleteFailed, .timeout, .general:
        .operation
    }
  }
}
*/
