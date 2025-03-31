import Foundation
import UmbraErrorsCore

/// Domain identifier for keychain-related errors
public enum KeychainErrorDomain: String, CaseIterable, Sendable {
  /// Domain identifier
  public static let domain="Keychain"

  // Access errors
  case accessDenied="ACCESS_DENIED"
  case itemNotFound="ITEM_NOT_FOUND"
  case duplicateItem="DUPLICATE_ITEM"

  // Input validation errors
  case invalidParameter="INVALID_PARAMETER"
  case missingParameter="MISSING_PARAMETER"
  case invalidData="INVALID_DATA"

  // Operation errors
  case storeFailed="STORE_FAILED"
  case retrieveFailed="RETRIEVE_FAILED"
  case updateFailed="UPDATE_FAILED"
  case deleteFailed="DELETE_FAILED"

  // Encoding/decoding errors
  case encodingFailed="ENCODING_FAILED"
  case decodingFailed="DECODING_FAILED"

  // Security errors
  case securityViolation="SECURITY_VIOLATION"
  case maxRetryExceeded="MAX_RETRY_EXCEEDED"

  // System errors
  case systemError="SYSTEM_ERROR"
  case serviceUnavailable="SERVICE_UNAVAILABLE"
  case interactionNotAllowed="INTERACTION_NOT_ALLOWED"
  case userCancelled="USER_CANCELLED"

  // Miscellaneous
  case unspecified="UNSPECIFIED"
}

/// Extension to add more functionality to the keychain error domain
extension KeychainErrorDomain {
  /// Map to a standard error severity
  public var defaultSeverity: ErrorSeverity {
    switch self {
      case .invalidParameter, .missingParameter, .invalidData, .userCancelled:
        .warning

      case .itemNotFound, .duplicateItem:
        .info

      case .storeFailed, .retrieveFailed, .updateFailed, .deleteFailed,
           .encodingFailed, .decodingFailed, .maxRetryExceeded:
        .error

      case .accessDenied, .securityViolation, .systemError, .serviceUnavailable:
        .critical

      default:
        .error
    }
  }

  /// Get a user-friendly description of the error
  /// All descriptions use British English spelling
  public var localizedDescription: String {
    switch self {
      case .accessDenied:
        "Access to the keychain was denied"

      case .itemNotFound:
        "The requested item was not found in the keychain"

      case .duplicateItem:
        "An item with this identifier already exists in the keychain"

      case .invalidParameter:
        "One or more parameters provided to the keychain are invalid"

      case .missingParameter:
        "A required parameter is missing for this keychain operation"

      case .invalidData:
        "The data provided for this keychain operation is invalid"

      case .storeFailed:
        "Failed to store the item in the keychain"

      case .retrieveFailed:
        "Failed to retrieve the item from the keychain"

      case .updateFailed:
        "Failed to update the item in the keychain"

      case .deleteFailed:
        "Failed to delete the item from the keychain"

      case .encodingFailed:
        "Failed to encode the data for keychain storage"

      case .decodingFailed:
        "Failed to decode the data retrieved from the keychain"

      case .securityViolation:
        "A security violation occurred during the keychain operation"

      case .maxRetryExceeded:
        "Maximum retry attempts exceeded for the keychain operation"

      case .systemError:
        "A system error occurred while accessing the keychain"

      case .serviceUnavailable:
        "The keychain service is currently unavailable"

      case .interactionNotAllowed:
        "User interaction is not allowed for this keychain operation"

      case .userCancelled:
        "The keychain operation was cancelled by the user"

      case .unspecified:
        "An unspecified keychain error occurred"
    }
  }

  /// Map from system keychain error codes to our domain errors
  /// - Parameter status: The OSStatus from a keychain operation
  /// - Returns: The appropriate KeychainErrorDomain case
  public static func fromOSStatus(_ status: OSStatus) -> KeychainErrorDomain {
    switch status {
      case errSecDuplicateItem:
        .duplicateItem
      case errSecItemNotFound:
        .itemNotFound
      case errSecAuthFailed:
        .accessDenied
      case errSecDecode:
        .decodingFailed
      case errSecParam:
        .invalidParameter
      case errSecAllocate:
        .systemError
      case errSecInteractionNotAllowed:
        .interactionNotAllowed
      case errSecUserCanceled:
        .userCancelled
      case errSecNotAvailable:
        .serviceUnavailable
      default:
        .unspecified
    }
  }
}
