import CoreSecurityTypes
import Foundation

// MARK: - CoreSecurityError Extensions

extension CoreSecurityError {
  /// Creates an invalid verification context error with the specified reason
  /// - Parameter reason: The reason for the error
  /// - Returns: A CoreSecurityError with the appropriate error code
  public static func invalidVerificationContext(reason: String) -> CoreSecurityError {
    .invalidInput("Invalid verification context: \(reason)")
  }

  // Note: The following methods have been moved to SecurityProvider+Validation.swift:
  // - invalidVerificationMethod(reason:)
  // - verificationFailed(reason:)
  // - notImplemented(reason:)

  /// Creates a decryption failed error with the specified reason
  /// - Parameter reason: The reason for the error
  /// - Returns: A CoreSecurityError with the appropriate error code
  public static func decryptionFailed(reason: String) -> CoreSecurityError {
    .cryptoError("Decryption failed: \(reason)")
  }
  
  /// Creates an encryption failed error with the specified reason
  /// - Parameter reason: The reason for the error
  /// - Returns: A CoreSecurityError with the appropriate error code
  public static func encryptionFailed(reason: String) -> CoreSecurityError {
    .cryptoError("Encryption failed: \(reason)")
  }

  /// Creates an invalid operation error with the specified reason
  /// - Parameter reason: The reason for the error
  /// - Returns: A CoreSecurityError with the appropriate error code
  public static func invalidOperation(reason: String) -> CoreSecurityError {
    .unsupportedOperation("Invalid operation: \(reason)")
  }

  /// Creates a not initialised error
  /// - Returns: A CoreSecurityError with the appropriate error code
  public static func notInitialised() -> CoreSecurityError {
    .configurationError("Security service not initialised")
  }
}
