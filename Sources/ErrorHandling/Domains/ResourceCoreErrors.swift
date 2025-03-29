import Foundation
import Interfaces
import UmbraErrorsCore

/// Error domain namespace

/// Error context protocol

/// Base error context implementation

extension UmbraErrors.Resource {
  /// Core resource errors related to resource acquisition and management
  public enum Core: Error, StandardErrorCapabilitiesProtocol /* ResourceErrors */ {
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
      ErrorDomain.resource
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

    /// String description for CustomStringConvertible conformance
    public var description: String {
      errorDescription
    }

    /// Source information about where the error occurred
    public var source: ErrorSource? {
      nil // Source is typically set when the error is created with context
    }

    /// The underlying error, if any
    public var underlyingError: Error? {
      nil // Underlying error is typically set when the error is created with context
    }

    /// Additional context for the error
    public var context: ErrorContext {
      ErrorContext(
        source: domain,
        operation: "resource_operation",
        details: errorDescription,
        file: "",
        line: 0,
        function: ""
      )
    }

    /// Creates a new instance of the error with additional context
    public func with(context _: ErrorContext) -> Self {
      // Since these are enum cases, we need to return a new instance with the same value
      self
    }

    /// Creates a new instance of the error with a specified underlying error
    public func with(underlyingError _: Error) -> Self {
      // Since these are enum cases, we need to return a new instance with the same value
      self
    }

    /// Creates a new instance of the error with source information
    public func with(source _: ErrorSource) -> Self {
      // Return self for now - in a real implementation we would attach the source
      self
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
