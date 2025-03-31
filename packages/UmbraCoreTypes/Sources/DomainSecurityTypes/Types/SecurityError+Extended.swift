import CoreSecurityTypes
import Foundation

/**
 Domain-specific extensions to CoreSecurityError for handling specialised security scenarios.

 This extension follows the architecture pattern for domain-specific error handling
 while maintaining the core error types.
 */
extension CoreSecurityError {
  /**
   Creates a domain-specific error with additional context for secure storage operations.

   - Parameters:
     - identifier: Storage identifier related to the error
     - message: Error message

   - Returns: A storage error with context
   */
  public static func secureStorageError(identifier: String, message: String) -> CoreSecurityError {
    .storageError("Storage operation failed for '\(identifier)': \(message)")
  }

  /**
   Creates a domain-specific error for key validation failures.

   - Parameters:
     - keyType: Type of key that failed validation
     - reason: Reason for validation failure

   - Returns: A key validation error with context
   */
  public static func keyValidationError(keyType: String, reason: String) -> CoreSecurityError {
    .invalidKey("Invalid \(keyType) key: \(reason)")
  }

  /**
   Creates a domain-specific error for authentication failures.

   - Parameters:
     - context: Authentication context
     - message: Error message

   - Returns: An authentication error with context
   */
  public static func authenticationError(context: String, message: String) -> CoreSecurityError {
    .permissionDenied("Authentication failed in \(context): \(message)")
  }

  /**
   Creates a domain-specific error for unsupported configurations.

   - Parameters:
     - configuration: Requested configuration
     - reason: Reason for being unsupported

   - Returns: A configuration error with context
   */
  public static func unsupportedConfiguration(
    configuration: String,
    reason: String
  ) -> CoreSecurityError {
    .configurationError("Unsupported configuration '\(configuration)': \(reason)")
  }
}
