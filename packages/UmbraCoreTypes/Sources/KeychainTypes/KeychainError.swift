import Foundation

/**
 # KeychainError

 Error type for keychain operations that follow the Alpha Dot Five
 domain-specific error pattern. This type encapsulates all potential
 error cases that may occur during keychain operations.

 ## Usage

 KeychainError is thrown by KeychainService implementations when operations fail.
 It provides specific error types with detailed messages to help diagnose
 the issue.

 ```swift
 do {
     try await keychainService.storePassword("securePassword", for: "userAccount")
 } catch let error as KeychainError {
     switch error {
     case .itemAlreadyExists:
         // Handle duplicate item
     case .accessDenied:
         // Handle access permission issues
     default:
         // Handle other errors
     }
 }
 ```
 */
public enum KeychainError: Error, Equatable, Sendable {
  /// The operation failed due to an invalid parameter
  case invalidParameter(String)

  /// The item already exists
  case itemAlreadyExists

  /// The item could not be found
  case itemNotFound

  /// Access to the keychain item was denied
  case accessDenied

  /// Authentication failed for the keychain operation
  case authenticationFailed

  /// The data format is invalid
  case invalidDataFormat(String)

  /// The keychain is locked
  case keychainLocked

  /// User interaction is required before the operation can proceed
  case userInteractionRequired

  /// A server communication error occurred
  case serverError(String)

  /// An unexpected error occurred
  case unexpectedError(String)

  /// A system error occurred with a specific error code
  case systemError(OSStatus, String)

  /// Maps an OSStatus error code to a KeychainError
  /// - Parameter status: The OSStatus error code
  /// - Returns: A KeychainError that best describes the error
  public static func fromOSStatus(_ status: OSStatus) -> KeychainError {
    switch status {
      case errSecDuplicateItem:
        .itemAlreadyExists
      case errSecItemNotFound:
        .itemNotFound
      case errSecAuthFailed:
        .authenticationFailed
      case errSecInteractionNotAllowed:
        .userInteractionRequired
      case errSecNotAvailable:
        .keychainLocked
      case errSecParam, errSecAllocate:
        .invalidParameter("Invalid parameter for keychain operation")
      default:
        .systemError(status, "Keychain operation failed with code: \(status)")
    }
  }
}
