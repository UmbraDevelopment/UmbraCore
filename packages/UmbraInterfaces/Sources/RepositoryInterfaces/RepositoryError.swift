import Foundation

/// Repository domain-specific errors
public enum RepositoryError: Int, Error, Sendable {
  /// Repository is not accessible due to permissions or path issues
  case inaccessible=1001

  /// Repository is locked and the operation cannot proceed
  case locked=1002

  /// Repository is corrupted and needs repair
  case corrupted=1003

  /// Repository needs to be initialised before use
  case uninitialised=1004

  /// Repository validation failed
  case invalidRepository=1005

  /// Invalid operation for the current repository state
  case invalidOperation=1006

  /// Repository with this identifier already exists
  case duplicateIdentifier=1007

  /// Repository not found in the registry
  case notFound=1008

  /// Internal error during repository operation
  case internalError=1009

  /// IO error during repository operations
  case ioError=1010

  /// Permission denied for repository operation
  case permissionDenied=1011

  /// Maintenance operation failed
  case maintenanceFailed=1012

  /// Network error during repository operation
  case networkError=1013

  /// Invalid repository URL
  case invalidURL=1014

  /// A textual description of the error
  public var description: String {
    switch self {
      case .inaccessible:
        "Repository is not accessible"
      case .locked:
        "Repository is locked"
      case .corrupted:
        "Repository is corrupted and needs repair"
      case .uninitialised:
        "Repository needs to be initialised before use"
      case .invalidRepository:
        "Repository validation failed"
      case .invalidOperation:
        "Invalid operation for the current repository state"
      case .duplicateIdentifier:
        "Repository with this identifier already exists"
      case .notFound:
        "Repository not found in the registry"
      case .internalError:
        "Internal error during repository operation"
      case .ioError:
        "IO error during repository operations"
      case .permissionDenied:
        "Permission denied for repository operation"
      case .maintenanceFailed:
        "Maintenance operation failed"
      case .networkError:
        "Network error during repository operation"
      case .invalidURL:
        "Invalid repository URL"
    }
  }
}
