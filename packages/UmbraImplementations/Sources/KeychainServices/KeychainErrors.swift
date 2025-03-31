import Foundation
import UmbraErrors

/**
 # KeychainError

 Error types specific to keychain operations. This follows the Alpha Dot Five architecture's
 privacy-by-design principles by providing specific error types rather than generic errors
 to avoid leaking sensitive information in error messages.
 */
public enum KeychainError: Error, Equatable, Sendable {
  /// Error when a required parameter is missing or invalid
  case invalidParameter(String)

  /// Error when trying to add an item that already exists
  case itemAlreadyExists

  /// Error when an item is not found
  case itemNotFound

  /// Error when the user doesn't have permission to perform an operation
  case accessDenied

  /// Error when authentication fails (e.g., wrong password)
  case authenticationFailed

  /// Error when data cannot be decoded/encoded in the expected format
  case invalidDataFormat(String)

  /// Error when the keychain is locked
  case keychainLocked

  /// Error when user interaction is required but not available
  case userInteractionRequired

  /// Error when the keychain service fails to start
  case serviceStartFailed(String)

  /// Error when the keychain service is not running
  case serviceNotRunning(String)

  /// Error when connection to the keychain service fails
  case serviceConnectionFailed(String)

  /// Error when a keychain operation fails for an unknown reason
  case operationFailed(String)

  /// Error when data is corrupt or has been tampered with
  case dataCorruption(String)

  /// Error on the server side (for network-based keychains)
  case serverError(String)

  /// Error for unexpected situations not covered by other cases
  case unexpectedError(String)

  /// Error with the underlying system error code
  case systemError(OSStatus, String)

  /**
   Create a KeychainError from an OSStatus error code

   - Parameter status: The OSStatus error code
   - Returns: The corresponding KeychainError
   */
  public static func fromOSStatus(_ status: OSStatus) -> KeychainError {
    switch status {
      case errSecItemNotFound:
        .itemNotFound
      case errSecDuplicateItem:
        .itemAlreadyExists
      case errSecAuthFailed:
        .authenticationFailed
      case errSecInteractionNotAllowed:
        .userInteractionRequired
      case errSecUserCanceled:
        .operationFailed("User cancelled the operation")
      default:
        .systemError(status, "OSStatus error \(status)")
    }
  }
}
