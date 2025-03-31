import Foundation

/// Errors that can occur during keychain operations
public enum KeychainError: LocalizedError, Equatable {
  /// Item not found in the keychain
  case itemNotFound
  /// Item already exists in the keychain
  case duplicateItem
  /// Authentication failed for the keychain operation
  case authenticationFailed
  /// Unexpected data type returned from keychain
  case unexpectedData
  /// Failed to encode item for keychain storage
  case itemEncodingFailed
  /// Failed to store item in keychain
  case storeFailed(String)
  /// Failed to retrieve item from keychain
  case retrieveFailed(String)
  /// Failed to delete item from keychain
  case deleteFailed(String)
  /// Unhandled error with status code
  case unhandledError(status: OSStatus)
  /// XPC connection failed
  case xpcConnectionFailed
  /// XPC connection was interrupted
  case xpcConnectionInterrupted
  /// XPC connection was invalidated
  case xpcConnectionInvalidated

  public var errorDescription: String? {
    switch self {
      case .itemNotFound:
        "The requested item was not found in the keychain"
      case .duplicateItem:
        "An item with the specified attributes already exists in the keychain"
      case .authenticationFailed:
        "Authentication failed for the keychain operation"
      case .unexpectedData:
        "The keychain returned data in an unexpected format"
      case .itemEncodingFailed:
        "Failed to encode item for keychain storage"
      case let .storeFailed(message):
        "Failed to store item in keychain: \(message)"
      case let .retrieveFailed(message):
        "Failed to retrieve item from keychain: \(message)"
      case let .deleteFailed(message):
        "Failed to delete item from keychain: \(message)"
      case let .unhandledError(status):
        "An unhandled keychain error occurred (status: \(status))"
      case .xpcConnectionFailed:
        "Failed to establish XPC connection"
      case .xpcConnectionInterrupted:
        "XPC connection was interrupted"
      case .xpcConnectionInvalidated:
        "XPC connection was invalidated"
    }
  }

  public var recoverySuggestion: String? {
    switch self {
      case .itemNotFound:
        "Check that the item exists and you have the correct credentials"
      case .duplicateItem:
        "Update the existing item instead of creating a new one"
      case .authenticationFailed:
        "Verify that you have the necessary permissions to access this item"
      case .unexpectedData:
        "Contact support if this issue persists"
      case .itemEncodingFailed:
        "Check the data format and try again"
      case .storeFailed:
        "Check that you have write permissions and try again"
      case .retrieveFailed:
        "Check that you have read permissions and try again"
      case .deleteFailed:
        "Check that you have delete permissions and try again"
      case .unhandledError:
        "Contact support if this issue persists"
      case .xpcConnectionFailed:
        "Check that the XPC service is running and try again"
      case .xpcConnectionInterrupted:
        "Try reconnecting to the XPC service"
      case .xpcConnectionInvalidated:
        "Try restarting the application"
    }
  }

  public static func == (lhs: KeychainError, rhs: KeychainError) -> Bool {
    switch (lhs, rhs) {
      case (.itemNotFound, .itemNotFound),
           (.duplicateItem, .duplicateItem),
           (.authenticationFailed, .authenticationFailed),
           (.unexpectedData, .unexpectedData),
           (.itemEncodingFailed, .itemEncodingFailed),
           (.xpcConnectionFailed, .xpcConnectionFailed),
           (.xpcConnectionInterrupted, .xpcConnectionInterrupted),
           (.xpcConnectionInvalidated, .xpcConnectionInvalidated):
        true
      case let (.unhandledError(lhsStatus), .unhandledError(rhsStatus)):
        lhsStatus == rhsStatus
      case (.storeFailed, .storeFailed),
           (.retrieveFailed, .retrieveFailed),
           (.deleteFailed, .deleteFailed):
        true
      default:
        false
    }
  }
}
