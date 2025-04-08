import Foundation
import CoreSecurityTypes

// MARK: - CoreSecurityError Extensions
extension CoreSecurityError {
  /// Creates an invalid verification context error with the specified reason
  /// - Parameter reason: The reason for the error
  /// - Returns: A CoreSecurityError with the appropriate error code
  public static func invalidVerificationContext(reason: String) -> CoreSecurityError {
    return .invalidInput("Invalid verification context: \(reason)")
  }
  
  /// Creates an invalid verification method error with the specified reason
  /// - Parameter reason: The reason for the error
  /// - Returns: A CoreSecurityError with the appropriate error code
  public static func invalidVerificationMethod(reason: String) -> CoreSecurityError {
    return .invalidInput("Invalid verification method: \(reason)")
  }
  
  /// Creates a verification failed error with the specified reason
  /// - Parameter reason: The reason for the error
  /// - Returns: A CoreSecurityError with the appropriate error code
  public static func verificationFailed(reason: String) -> CoreSecurityError {
    return .authenticationFailed("Verification failed: \(reason)")
  }
  
  /// Creates a not implemented error with the specified reason
  /// - Parameter reason: The reason for the error
  /// - Returns: A CoreSecurityError with the appropriate error code
  public static func notImplemented(reason: String) -> CoreSecurityError {
    return .unsupportedOperation("Not implemented: \(reason)")
  }
  
  /// Creates a decryption failed error with the specified reason
  /// - Parameter reason: The reason for the error
  /// - Returns: A CoreSecurityError with the appropriate error code
  public static func decryptionFailed(reason: String) -> CoreSecurityError {
    return .cryptoError("Decryption failed: \(reason)")
  }
  
  /// Creates an invalid operation error with the specified reason
  /// - Parameter reason: The reason for the error
  /// - Returns: A CoreSecurityError with the appropriate error code
  public static func invalidOperation(reason: String) -> CoreSecurityError {
    return .unsupportedOperation("Invalid operation: \(reason)")
  }
  
  /// Creates a not initialised error
  /// - Returns: A CoreSecurityError with the appropriate error code
  public static func notInitialised() -> CoreSecurityError {
    return .configurationError("Security service not initialised")
  }
}
