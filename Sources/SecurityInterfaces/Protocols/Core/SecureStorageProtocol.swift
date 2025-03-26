import UmbraCoreTypes

/// Result type for key storage operations
public enum KeyStorageResult: Sendable {
  case success
  case failure(KeyStorageError)

  // Swift 6 forward compatibility: handle future enum cases
  @available(*, unavailable, message: "This case exists only for Swift 6+ forward compatibility")
  case _unspecified
}

/// Result type for key retrieval operations
public enum KeyRetrievalResult: Sendable {
  case success(SecureBytes)
  case failure(KeyStorageError)

  // Swift 6 forward compatibility: handle future enum cases
  @available(*, unavailable, message: "This case exists only for Swift 6+ forward compatibility")
  case _unspecified
}

/// Result type for key deletion operations
public enum KeyDeletionResult: Sendable {
  case success
  case failure(KeyStorageError)

  // Swift 6 forward compatibility: handle future enum cases
  @available(*, unavailable, message: "This case exists only for Swift 6+ forward compatibility")
  case _unspecified
}

/// Error type for secure storage operations
public enum KeyStorageError: Sendable {
  case keyNotFound
  case storageFailure
  case unknown

  // Swift 6 forward compatibility: handle future enum cases
  @available(*, unavailable, message: "This case exists only for Swift 6+ forward compatibility")
  case _unspecified
}

/// Protocol defining secure storage operations in a Foundation-independent manner.
/// This protocol is used for securely storing cryptographic keys and sensitive data.
///
/// - Note: This is the canonical implementation of SecureStorageProtocol in UmbraCore.
///         It has been unified to eliminate ambiguity and ensure consistent usage across the
/// codebase.
///         For migration guidance, see the SecureStorageProtocol Migration Guide in the
/// documentation.
public protocol SecureStorageProtocol: Sendable {
  /// Stores data securely with the given identifier
  /// - Parameters:
  ///   - data: The data to store as SecureBytes
  ///   - identifier: A unique identifier for later retrieval
  /// - Returns: Result of the storage operation
  func storeSecurely(data: SecureBytes, identifier: String) async -> KeyStorageResult

  /// Retrieves data securely by its identifier
  /// - Parameter identifier: The unique identifier for the data
  /// - Returns: The retrieved data or an error
  func retrieveSecurely(identifier: String) async -> KeyRetrievalResult

  /// Deletes data securely by its identifier
  /// - Parameter identifier: The unique identifier for the data to delete
  /// - Returns: Result of the deletion operation
  func deleteSecurely(identifier: String) async -> KeyDeletionResult
}
