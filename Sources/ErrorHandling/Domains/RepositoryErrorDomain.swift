import Foundation

// Local type declarations to replace imports
// These replace the removed ErrorHandling and ErrorHandlingDomains imports

/// Error domain namespace
public enum ErrorDomain {
  /// Security domain
  public static let security = "Security"
  /// Crypto domain
  public static let crypto = "Crypto"
  /// Application domain
  public static let application = "Application"
}

/// Error context protocol
public protocol ErrorContext {
  /// Domain of the error
  var domain: String { get }
  /// Code of the error
  var code: Int { get }
  /// Description of the error
  var description: String { get }
}

/// Base error context implementation
public struct BaseErrorContext: ErrorContext {
  /// Domain of the error
  public let domain: String
  /// Code of the error
  public let code: Int
  /// Description of the error
  public let description: String

  /// Initialise with domain, code and description
  public init(domain: String, code: Int, description: String) {
    self.domain = domain
    self.code = code
    self.description = description
  }
}

/// Domain for repository-related errors
public struct RepositoryErrorDomain: ErrorDomain {
  /// The domain identifier
  public static let identifier = "Repository"

  /// The domain name
  public static let name = "Repository Errors"

  /// The domain description
  public static let description = "Errors related to repository operations and data management"

  /// Common error categories in this domain
  public enum Category: String, ErrorCategory {
    /// Errors related to repository access
    case access = "Access"

    /// Errors related to repository data
    case data = "Data"

    /// Errors related to repository state
    case state = "State"

    /// Errors related to repository operations
    case operation = "Operation"

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
