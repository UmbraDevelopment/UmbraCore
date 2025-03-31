import Foundation

/// Protocol for errors related to authentication and authorization
public protocol AuthenticationErrors: UmbraError {
  /// Creates an authentication failure error
  static func authenticationFailed(reason: String) -> Self

  /// Creates an authorization failure error
  static func authorizationFailed(reason: String) -> Self

  /// Creates an error for insufficient permissions
  static func insufficientPermissions(resource: String, requiredPermission: String) -> Self
}

/// Protocol for errors related to resource handling
public protocol ResourceErrors: UmbraError {
  /// Creates an error for a missing resource
  static func resourceNotFound(resource: String) -> Self

  /// Creates an error for a resource that already exists
  static func resourceAlreadyExists(resource: String) -> Self

  /// Creates an error for a resource in an invalid format
  static func resourceInvalidFormat(resource: String, reason: String) -> Self
}

/// Protocol for errors related to operations
public protocol OperationErrors: UmbraError {
  /// Creates an error for an operation that failed
  static func operationFailed(operation: String, reason: String) -> Self

  /// Creates an error for an operation that timed out
  static func operationTimeout(operation: String, timeoutMs: Int) -> Self

  /// Creates an error for an operation that was cancelled
  static func operationCancelled(operation: String) -> Self
}

/// Protocol for errors related to configuration
public protocol ConfigurationErrors: UmbraError {
  /// Creates an error for an invalid configuration
  static func invalidConfiguration(reason: String) -> Self

  /// Creates an error for a missing configuration
  static func missingConfiguration(key: String) -> Self

  /// Creates an error for an incompatible configuration
  static func incompatibleConfiguration(reason: String) -> Self
}

/// Protocol for errors related to state management
public protocol StateErrors: UmbraError {
  /// Creates an error for an invalid state
  static func invalidState(state: String, expectedState: String) -> Self

  /// Creates an error for a component that is not initialised
  static func notInitialised(component: String) -> Self

  /// Creates an error for a component that is already initialised
  static func alreadyInitialised(component: String) -> Self
}

/// Protocol for errors related to security operations
public protocol SecurityOperationErrors: UmbraError {
  /// Creates an error for encryption failure
  static func encryptionFailed(reason: String) -> Self

  /// Creates an error for decryption failure
  static func decryptionFailed(reason: String) -> Self

  /// Creates an error for signature verification failure
  static func signatureInvalid(reason: String) -> Self

  /// Creates an error for hashing failure
  static func hashingFailed(reason: String) -> Self
}

/// Protocol for errors related to network operations
public protocol NetworkErrors: UmbraError {
  /// Creates an error for a connection failure
  static func connectionFailed(reason: String) -> Self

  /// Creates an error for an unreachable host
  static func hostUnreachable(host: String) -> Self

  /// Creates an error for a failed request
  static func requestFailed(statusCode: Int, reason: String) -> Self

  /// Creates an error for an invalid response
  static func responseInvalid(reason: String) -> Self
}
