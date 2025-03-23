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

extension UmbraErrors.Resource {
  /// Resource pool management errors
  public enum Pool: Error, UmbraError, StandardErrorCapabilities {
    // Pool creation and management errors
    /// Failed to create resource pool
    case poolCreationFailed(poolName: String, reason: String)

    /// Failed to initialise resource pool
    case poolInitialisationFailed(poolName: String, reason: String)

    /// Resource pool is exhausted
    case poolExhausted(poolName: String, currentSize: Int, maxSize: Int)

    /// Resource pool is in an invalid state
    case invalidPoolState(poolName: String, state: String, expectedState: String?)

    /// Pool already exists
    case poolAlreadyExists(poolName: String)

    // Resource acquisition errors
    /// Failed to acquire resource from pool
    case resourceAcquisitionFailed(poolName: String, resourceID: String?, reason: String)

    /// Failed to release resource back to pool
    case resourceReleaseFailed(poolName: String, resourceID: String, reason: String)

    /// Resource not found in pool
    case resourceNotFound(poolName: String, resourceID: String)

    /// Resource is already in use
    case resourceAlreadyInUse(poolName: String, resourceID: String, owner: String?)

    /// Resource is invalid for the pool
    case invalidResource(poolName: String, resourceID: String, reason: String)

    /// Wait timeout for resource acquisition
    case acquisitionTimeout(poolName: String, timeoutMs: Int)

    /// Pool operation failed
    case operationFailed(poolName: String, operation: String, reason: String)

    // MARK: - UmbraError Protocol

    /// Domain identifier for pool errors
    public var domain: String {
      "Resource.Pool"
    }

    /// Error code uniquely identifying the error type
    public var code: String {
      switch self {
        case .poolCreationFailed:
          "pool_creation_failed"
        case .poolInitialisationFailed:
          "pool_initialisation_failed"
        case .poolExhausted:
          "pool_exhausted"
        case .invalidPoolState:
          "invalid_pool_state"
        case .poolAlreadyExists:
          "pool_already_exists"
        case .resourceAcquisitionFailed:
          "resource_acquisition_failed"
        case .resourceReleaseFailed:
          "resource_release_failed"
        case .resourceNotFound:
          "resource_not_found"
        case .resourceAlreadyInUse:
          "resource_already_in_use"
        case .invalidResource:
          "invalid_resource"
        case .acquisitionTimeout:
          "acquisition_timeout"
        case .operationFailed:
          "operation_failed"
      }
    }

    /// Human-readable description of the error
    public var errorDescription: String {
      switch self {
        case let .poolCreationFailed(poolName, reason):
          "Failed to create resource pool '\(poolName)': \(reason)"
        case let .poolInitialisationFailed(poolName, reason):
          "Failed to initialise resource pool '\(poolName)': \(reason)"
        case let .poolExhausted(poolName, currentSize, maxSize):
          "Resource pool '\(poolName)' exhausted (current: \(currentSize), maximum: \(maxSize))"
        case let .invalidPoolState(poolName, state, expectedState):
          if let expected = expectedState {
            "Resource pool '\(poolName)' is in invalid state: current '\(state)', expected '\(expected)'"
          } else {
            "Resource pool '\(poolName)' is in invalid state: '\(state)'"
          }
        case let .poolAlreadyExists(poolName):
          "Resource pool '\(poolName)' already exists"
        case let .resourceAcquisitionFailed(poolName, resourceID, reason):
          if let id = resourceID {
            "Failed to acquire resource '\(id)' from pool '\(poolName)': \(reason)"
          } else {
            "Failed to acquire resource from pool '\(poolName)': \(reason)"
          }
        case let .resourceReleaseFailed(poolName, resourceID, reason):
          "Failed to release resource '\(resourceID)' back to pool '\(poolName)': \(reason)"
        case let .resourceNotFound(poolName, resourceID):
          "Resource '\(resourceID)' not found in pool '\(poolName)'"
        case let .resourceAlreadyInUse(poolName, resourceID, owner):
          if let owner {
            "Resource '\(resourceID)' in pool '\(poolName)' is already in use by: \(owner)"
          } else {
            "Resource '\(resourceID)' in pool '\(poolName)' is already in use"
          }
        case let .invalidResource(poolName, resourceID, reason):
          "Resource '\(resourceID)' is invalid for pool '\(poolName)': \(reason)"
        case let .acquisitionTimeout(poolName, timeoutMs):
          "Timeout waiting for resource from pool '\(poolName)' after \(timeoutMs)ms"
        case let .operationFailed(poolName, operation, reason):
          "Operation '\(operation)' failed for pool '\(poolName)': \(reason)"
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
        operation: "pool_operation",
        details: errorDescription
      )
    }

    /// Creates a new instance of the error with additional context
    public func with(context _: ErrorHandlingInterfaces.ErrorContext) -> Self {
      // Since these are enum cases, we need to return a new instance with the same value
      switch self {
        case let .poolCreationFailed(poolName, reason):
          .poolCreationFailed(poolName: poolName, reason: reason)
        case let .poolInitialisationFailed(poolName, reason):
          .poolInitialisationFailed(poolName: poolName, reason: reason)
        case let .poolExhausted(poolName, currentSize, maxSize):
          .poolExhausted(poolName: poolName, currentSize: currentSize, maxSize: maxSize)
        case let .invalidPoolState(poolName, state, expectedState):
          .invalidPoolState(poolName: poolName, state: state, expectedState: expectedState)
        case let .poolAlreadyExists(poolName):
          .poolAlreadyExists(poolName: poolName)
        case let .resourceAcquisitionFailed(poolName, resourceID, reason):
          .resourceAcquisitionFailed(poolName: poolName, resourceID: resourceID, reason: reason)
        case let .resourceReleaseFailed(poolName, resourceID, reason):
          .resourceReleaseFailed(poolName: poolName, resourceID: resourceID, reason: reason)
        case let .resourceNotFound(poolName, resourceID):
          .resourceNotFound(poolName: poolName, resourceID: resourceID)
        case let .resourceAlreadyInUse(poolName, resourceID, owner):
          .resourceAlreadyInUse(poolName: poolName, resourceID: resourceID, owner: owner)
        case let .invalidResource(poolName, resourceID, reason):
          .invalidResource(poolName: poolName, resourceID: resourceID, reason: reason)
        case let .acquisitionTimeout(poolName, timeoutMs):
          .acquisitionTimeout(poolName: poolName, timeoutMs: timeoutMs)
        case let .operationFailed(poolName, operation, reason):
          .operationFailed(poolName: poolName, operation: operation, reason: reason)
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
  }
}

// MARK: - Factory Methods

extension UmbraErrors.Resource.Pool {
  /// Create an error for a failed pool creation
  public static func makeCreationFailed(
    poolName: String,
    reason: String,
    file _: String = #file,
    line _: Int = #line,
    function _: String = #function
  ) -> Self {
    .poolCreationFailed(poolName: poolName, reason: reason)
  }

  /// Create an error for a failed resource acquisition
  public static func makeAcquisitionFailed(
    poolName: String,
    resourceID: String? = nil,
    reason: String,
    file _: String = #file,
    line _: Int = #line,
    function _: String = #function
  ) -> Self {
    .resourceAcquisitionFailed(poolName: poolName, resourceID: resourceID, reason: reason)
  }

  /// Create an error for a resource not found in pool
  public static func makeResourceNotFound(
    poolName: String,
    resourceID: String,
    file _: String = #file,
    line _: Int = #line,
    function _: String = #function
  ) -> Self {
    .resourceNotFound(poolName: poolName, resourceID: resourceID)
  }

  /// Create an error for an exhausted resource pool
  public static func makeExhausted(
    poolName: String,
    currentSize: Int,
    maxSize: Int,
    file _: String = #file,
    line _: Int = #line,
    function _: String = #function
  ) -> Self {
    .poolExhausted(poolName: poolName, currentSize: currentSize, maxSize: maxSize)
  }
}
