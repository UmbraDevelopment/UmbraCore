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

extension UmbraErrors.Resource {
  /// Core resource errors related to resource acquisition and management
  public enum Core: Error, UmbraError, StandardErrorCapabilities, ResourceErrors {
    // Resource acquisition errors
    /// Failed to acquire resource
    case acquisitionFailed(resource: String, reason: String)

    /// Resource is in an invalid state for the requested operation
    case invalidState(resource: String, currentState: String, requiredState: String?)

    /// Resource pool is exhausted (no more resources available)
    case poolExhausted(poolName: String, limit: Int)

    /// Resource not found
    case resourceNotFound(resource: String)

    /// Resource already exists
    case resourceAlreadyExists(resource: String)

    // Resource operation errors
    /// Resource operation failed
    case operationFailed(resource: String, operation: String, reason: String)

    /// Resource is locked by another process or thread
    case resourceLocked(resource: String, owner: String?)

    /// Timeout occurred waiting for resource
    case timeout(resource: String, timeoutMs: Int)

    /// Resource is corrupt
    case resourceCorrupt(resource: String, reason: String)

    /// Access to resource denied
    case accessDenied(resource: String, reason: String)

    /// Internal resource error
    case internalError(reason: String)

    // MARK: - UmbraError Protocol

    /// Domain identifier for resource core errors
    public var domain: String {
      "Resource.Core"
    }

    /// Error code uniquely identifying the error type
    public var code: String {
      switch self {
        case .acquisitionFailed:
          "acquisition_failed"
        case .invalidState:
          "invalid_state"
        case .poolExhausted:
          "pool_exhausted"
        case .resourceNotFound:
          "resource_not_found"
        case .resourceAlreadyExists:
          "resource_already_exists"
        case .operationFailed:
          "operation_failed"
        case .resourceLocked:
          "resource_locked"
        case .timeout:
          "timeout"
        case .resourceCorrupt:
          "resource_corrupt"
        case .accessDenied:
          "access_denied"
        case .internalError:
          "internal_error"
      }
    }

    /// Human-readable description of the error
    public var errorDescription: String {
      switch self {
        case let .acquisitionFailed(resource, reason):
          "Failed to acquire resource '\(resource)': \(reason)"
        case let .invalidState(resource, currentState, requiredState):
          if let required=requiredState {
            "Resource '\(resource)' is in invalid state: current '\(currentState)', required '\(required)'"
          } else {
            "Resource '\(resource)' is in invalid state: '\(currentState)'"
          }
        case let .poolExhausted(poolName, limit):
          "Resource pool '\(poolName)' exhausted (limit: \(limit))"
        case let .resourceNotFound(resource):
          "Resource not found: '\(resource)'"
        case let .resourceAlreadyExists(resource):
          "Resource already exists: '\(resource)'"
        case let .operationFailed(resource, operation, reason):
          "Operation '\(operation)' failed for resource '\(resource)': \(reason)"
        case let .resourceLocked(resource, owner):
          if let owner {
            "Resource '\(resource)' is locked by: \(owner)"
          } else {
            "Resource '\(resource)' is locked by another process"
          }
        case let .timeout(resource, timeoutMs):
          "Timeout waiting for resource '\(resource)' after \(timeoutMs)ms"
        case let .resourceCorrupt(resource, reason):
          "Resource '\(resource)' is corrupt: \(reason)"
        case let .accessDenied(resource, reason):
          "Access denied to resource '\(resource)': \(reason)"
        case let .internalError(reason):
          "Internal resource error: \(reason)"
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
        operation: "resource_operation",
        details: errorDescription
      )
    }

    /// Creates a new instance of the error with additional context
    public func with(context _: ErrorHandlingInterfaces.ErrorContext) -> Self {
      // Since these are enum cases, we need to return a new instance with the same value
      switch self {
        case let .acquisitionFailed(resource, reason):
          .acquisitionFailed(resource: resource, reason: reason)
        case let .invalidState(resource, currentState, requiredState):
          .invalidState(
            resource: resource,
            currentState: currentState,
            requiredState: requiredState
          )
        case let .poolExhausted(poolName, limit):
          .poolExhausted(poolName: poolName, limit: limit)
        case let .resourceNotFound(resource):
          .resourceNotFound(resource: resource)
        case let .resourceAlreadyExists(resource):
          .resourceAlreadyExists(resource: resource)
        case let .operationFailed(resource, operation, reason):
          .operationFailed(resource: resource, operation: operation, reason: reason)
        case let .resourceLocked(resource, owner):
          .resourceLocked(resource: resource, owner: owner)
        case let .timeout(resource, timeoutMs):
          .timeout(resource: resource, timeoutMs: timeoutMs)
        case let .resourceCorrupt(resource, reason):
          .resourceCorrupt(resource: resource, reason: reason)
        case let .accessDenied(resource, reason):
          .accessDenied(resource: resource, reason: reason)
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

    // MARK: - ResourceErrors Protocol Conformance

    // The resourceNotFound and resourceAlreadyExists methods are already implemented
    // as enum cases with the same names

    /// Creates an error for a resource in an invalid format (required by ResourceErrors protocol)
    public static func resourceInvalidFormat(resource: String, reason: String) -> Self {
      .resourceCorrupt(resource: resource, reason: reason)
    }
  }
}

// MARK: - Factory Methods

extension UmbraErrors.Resource.Core {
  /// Create an error for a failed resource acquisition
  public static func makeAcquisitionFailedError(
    resource: String,
    reason: String,
    file _: String=#file,
    line _: Int=#line,
    function _: String=#function
  ) -> Self {
    .acquisitionFailed(resource: resource, reason: reason)
  }

  /// Create an error for an exhausted resource pool
  public static func makePoolExhaustedError(
    poolName: String,
    limit: Int=0,
    file _: String=#file,
    line _: Int=#line,
    function _: String=#function
  ) -> Self {
    .poolExhausted(poolName: poolName, limit: limit)
  }

  /// Create an error for a failed resource operation
  public static func makeOperationFailedError(
    resource: String,
    operation: String,
    reason: String,
    file _: String=#file,
    line _: Int=#line,
    function _: String=#function
  ) -> Self {
    .operationFailed(resource: resource, operation: operation, reason: reason)
  }

  /// Creates an error for a resource in an invalid format
  public static func makeResourceInvalidFormatError(
    resource: String,
    reason: String,
    file _: String=#file,
    line _: Int=#line,
    function _: String=#function
  ) -> Self {
    .resourceCorrupt(resource: resource, reason: reason)
  }

  /// Creates an error for a missing resource
  public static func makeResourceNotFoundError(
    resource: String,
    file _: String=#file,
    line _: Int=#line,
    function _: String=#function
  ) -> Self {
    .resourceNotFound(resource: resource)
  }

  /// Creates an error for a resource that already exists
  public static func makeResourceAlreadyExistsError(
    resource: String,
    file _: String=#file,
    line _: Int=#line,
    function _: String=#function
  ) -> Self {
    .resourceAlreadyExists(resource: resource)
  }
}
