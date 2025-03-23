import Foundation

// Local type declarations to replace imports
// These replace the removed ErrorHandling and ErrorHandlingDomains imports

/// Error domain namespace
public enum ErrorDomain {
  /// Security domain
  public static let security="Security"
  /// Crypto domain
  public static let crypto="Crypto"
  /// Application domain
  public static let application="Application"
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
    self.domain=domain
    self.code=code
    self.description=description
  }
}

extension UmbraErrors.Repository {
  /// Core repository errors relating to repository access and management
  public enum Core: Error, UmbraError, StandardErrorCapabilities, ResourceErrors {
    // Repository access errors
    /// The repository could not be found
    case repositoryNotFound(resource: String)

    /// The repository could not be opened
    case repositoryOpenFailed(reason: String)

    /// The repository is corrupt
    case repositoryCorrupt(reason: String)

    /// The repository is locked by another process
    case repositoryLocked(owner: String?)

    /// The repository is in an invalid state
    case invalidState(state: String, expectedState: String)

    /// Permission denied for repository operation
    case permissionDenied(operation: String, reason: String)

    // Object errors
    /// The object could not be found in the repository
    case objectNotFound(objectID: String, objectType: String?)

    /// The object already exists in the repository
    case objectAlreadyExists(objectID: String, objectType: String?)

    /// The object is corrupt
    case objectCorrupt(objectID: String, reason: String)

    /// The object type is invalid
    case invalidObjectType(providedType: String, expectedType: String)

    /// The object data is invalid
    case invalidObjectData(objectID: String, reason: String)

    // Operation errors
    /// Failed to save the object
    case saveFailed(objectID: String, reason: String)

    /// Failed to delete the object
    case deleteFailed(objectID: String, reason: String)

    /// Failed to update the object
    case updateFailed(objectID: String, reason: String)

    /// Operation timed out
    case timeout(operation: String, timeoutMs: Int)

    /// Internal repository error
    case internalError(reason: String)

    // MARK: - UmbraError Protocol

    /// Domain identifier for repository core errors
    public var domain: String {
      "Repository.Core"
    }

    /// Error code uniquely identifying the error type
    public var code: String {
      switch self {
        case .repositoryNotFound:
          "repository_not_found"
        case .repositoryOpenFailed:
          "repository_open_failed"
        case .repositoryCorrupt:
          "repository_corrupt"
        case .repositoryLocked:
          "repository_locked"
        case .invalidState:
          "invalid_state"
        case .permissionDenied:
          "permission_denied"
        case .objectNotFound:
          "object_not_found"
        case .objectAlreadyExists:
          "object_already_exists"
        case .objectCorrupt:
          "object_corrupt"
        case .invalidObjectType:
          "invalid_object_type"
        case .invalidObjectData:
          "invalid_object_data"
        case .saveFailed:
          "save_failed"
        case .deleteFailed:
          "delete_failed"
        case .updateFailed:
          "update_failed"
        case .timeout:
          "timeout"
        case .internalError:
          "internal_error"
      }
    }

    /// Human-readable description of the error
    public var errorDescription: String {
      switch self {
        case let .repositoryNotFound(resource):
          "Repository not found: \(resource)"
        case let .repositoryOpenFailed(reason):
          "Failed to open repository: \(reason)"
        case let .repositoryCorrupt(reason):
          "Repository is corrupt: \(reason)"
        case let .repositoryLocked(owner):
          if let owner {
            "Repository is locked by: \(owner)"
          } else {
            "Repository is locked by another process"
          }
        case let .invalidState(state, expectedState):
          "Repository is in invalid state: current '\(state)', expected '\(expectedState)'"
        case let .permissionDenied(operation, reason):
          "Permission denied for operation '\(operation)': \(reason)"
        case let .objectNotFound(objectID, objectType):
          if let type=objectType {
            "Object not found: \(type) with ID \(objectID)"
          } else {
            "Object not found: \(objectID)"
          }
        case let .objectAlreadyExists(objectID, objectType):
          if let type=objectType {
            "Object already exists: \(type) with ID \(objectID)"
          } else {
            "Object already exists: \(objectID)"
          }
        case let .objectCorrupt(objectID, reason):
          "Object is corrupt (ID: \(objectID)): \(reason)"
        case let .invalidObjectType(providedType, expectedType):
          "Invalid object type: provided '\(providedType)', expected '\(expectedType)'"
        case let .invalidObjectData(objectID, reason):
          "Invalid object data (ID: \(objectID)): \(reason)"
        case let .saveFailed(objectID, reason):
          "Failed to save object (ID: \(objectID)): \(reason)"
        case let .deleteFailed(objectID, reason):
          "Failed to delete object (ID: \(objectID)): \(reason)"
        case let .updateFailed(objectID, reason):
          "Failed to update object (ID: \(objectID)): \(reason)"
        case let .timeout(operation, timeoutMs):
          "Operation '\(operation)' timed out after \(timeoutMs)ms"
        case let .internalError(reason):
          "Internal repository error: \(reason)"
      }
    }

    /// Source information about where the error occurred
    public var source: ErrorHandlingInterfaces.ErrorSource? {
      nil // Source is typically set when the error is created with context
    }

    /// The underlying error, if any
    public var underlyingError: Error? {
      nil // Underlying error is typically set when the error is created with context
    }

    /// Additional context for the error
    public var context: ErrorHandlingInterfaces.ErrorContext {
      ErrorHandlingInterfaces.ErrorContext(
        source: domain,
        operation: "repository_operation",
        details: errorDescription
      )
    }

    /// Creates a new instance of the error with additional context
    public func with(context _: ErrorHandlingInterfaces.ErrorContext) -> Self {
      // Since these are enum cases, we need to return a new instance with the same value
      switch self {
        case let .repositoryNotFound(resource):
          .repositoryNotFound(resource: resource)
        case let .repositoryOpenFailed(reason):
          .repositoryOpenFailed(reason: reason)
        case let .repositoryCorrupt(reason):
          .repositoryCorrupt(reason: reason)
        case let .repositoryLocked(owner):
          .repositoryLocked(owner: owner)
        case let .invalidState(state, expectedState):
          .invalidState(state: state, expectedState: expectedState)
        case let .permissionDenied(operation, reason):
          .permissionDenied(operation: operation, reason: reason)
        case let .objectNotFound(objectID, objectType):
          .objectNotFound(objectID: objectID, objectType: objectType)
        case let .objectAlreadyExists(objectID, objectType):
          .objectAlreadyExists(objectID: objectID, objectType: objectType)
        case let .objectCorrupt(objectID, reason):
          .objectCorrupt(objectID: objectID, reason: reason)
        case let .invalidObjectType(providedType, expectedType):
          .invalidObjectType(providedType: providedType, expectedType: expectedType)
        case let .invalidObjectData(objectID, reason):
          .invalidObjectData(objectID: objectID, reason: reason)
        case let .saveFailed(objectID, reason):
          .saveFailed(objectID: objectID, reason: reason)
        case let .deleteFailed(objectID, reason):
          .deleteFailed(objectID: objectID, reason: reason)
        case let .updateFailed(objectID, reason):
          .updateFailed(objectID: objectID, reason: reason)
        case let .timeout(operation, timeoutMs):
          .timeout(operation: operation, timeoutMs: timeoutMs)
        case let .internalError(reason):
          .internalError(reason: reason)
      }
      // In a real implementation, we would attach the context
    }

    /// Creates a new instance of the error with a specified underlying error
    public func with(underlyingError _: Error) -> Self {
      // Similar to above, return a new instance with the same value
      self // In a real implementation, we would attach the underlying error
    }

    /// Creates a new instance of the error with source information
    public func with(source _: ErrorHandlingInterfaces.ErrorSource) -> Self {
      // Similar to above, return a new instance with the same value
      self // In a real implementation, we would attach the source information
    }

    // MARK: - ResourceErrors Protocol

    /// Creates an error for a missing resource
    public static func resourceNotFound(resource: String) -> Self {
      .repositoryNotFound(resource: resource)
    }

    /// Creates an error for a resource that already exists
    public static func resourceAlreadyExists(resource: String) -> Self {
      .objectAlreadyExists(objectID: resource, objectType: nil)
    }

    /// Creates an error for a resource in an invalid format
    public static func resourceInvalidFormat(resource: String, reason: String) -> Self {
      .invalidObjectData(objectID: resource, reason: reason)
    }
  }
}

// MARK: - Factory Methods

extension UmbraErrors.Repository.Core {
  /// Create an error for a repository that could not be found
  public static func makeNotFound(
    repository: String,
    file _: String=#file,
    line _: Int=#line,
    function _: String=#function
  ) -> Self {
    .repositoryNotFound(resource: repository)
  }

  /// Create an error for an object that could not be found
  public static func makeObjectNotFound(
    id: String,
    type: String?=nil,
    file _: String=#file,
    line _: Int=#line,
    function _: String=#function
  ) -> Self {
    .objectNotFound(objectID: id, objectType: type)
  }

  /// Create an error for a repository operation that failed due to permissions
  public static func makePermissionDenied(
    operation: String,
    reason: String,
    file _: String=#file,
    line _: Int=#line,
    function _: String=#function
  ) -> Self {
    .permissionDenied(operation: operation, reason: reason)
  }

  /// Create an error for a failed resource operation
  public static func makeOperationFailed(
    resource: String,
    operation: String,
    reason: String,
    file _: String=#file,
    line _: Int=#line,
    function _: String=#function
  ) -> Self {
    .internalError(reason: "Failed to \(operation) \(resource): \(reason)")
  }
}
