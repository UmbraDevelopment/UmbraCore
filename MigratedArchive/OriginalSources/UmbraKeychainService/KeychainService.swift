import Foundation
import Security
import UmbraLogging

/// A thread-safe service for managing secure keychain operations.
///
/// `KeychainService` provides a safe interface for storing and retrieving sensitive data
/// from the system keychain. It handles all common keychain operations and provides
/// detailed error information when operations fail.
///
/// Example:
/// ```swift
/// let service = KeychainService()
/// try await service.addItem(
///     account: "user@example.com",
///     service: "com.example.app",
///     accessGroup: nil,
///     data: "secret".data(using: .utf8)!
/// )
/// ```
public actor KeychainService: KeychainServiceProtocol {
  /// Logger instance for tracking operations.
  private let logger: LoggingProtocol

  /// Creates a new keychain service instance.
  public init(logger: LoggingProtocol) {
    self.logger=logger
  }

  // MARK: - KeychainServiceProtocol Implementation

  /// Add a new item to the keychain
  /// - Parameters:
  ///   - data: Data to store
  ///   - account: Account identifier
  ///   - service: Service identifier
  ///   - accessGroup: Optional access group
  ///   - accessibility: Keychain accessibility
  ///   - flags: Access control flags
  /// - Throws: KeychainError if operation fails
  public func addItem(
    _ data: Data,
    account: String,
    service: String,
    accessGroup: String?,
    accessibility: CFString,
    flags _: SecAccessControlCreateFlags
  ) async throws {
    var query: [String: Any]=[
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrAccount as String: account,
      kSecAttrService as String: service,
      kSecValueData as String: data,
      kSecAttrAccessible as String: accessibility
    ]

    if let accessGroup {
      query[kSecAttrAccessGroup as String]=accessGroup
    }

    let status=SecItemAdd(query as CFDictionary, nil)
    guard status == errSecSuccess else {
      let error=convertError(status)
      let metadata=LogMetadata([
        "error": String(describing: error),
        "status": String(status),
        "operation": "addItem",
        "account": account,
        "service": service,
        "accessGroup": accessGroup ?? "none"
      ])
      await logger.error("Failed to add keychain item", metadata: metadata)
      throw error
    }

    let metadata=LogMetadata([
      "operation": "addItem",
      "account": account,
      "service": service,
      "accessGroup": accessGroup ?? "none"
    ])
    await logger.info("Successfully added keychain item", metadata: metadata)
  }

  /// Update an existing keychain item
  /// - Parameters:
  ///   - data: New data to store
  ///   - account: Account identifier
  ///   - service: Service identifier
  ///   - accessGroup: Optional access group
  /// - Throws: KeychainError if operation fails
  public func updateItem(
    _ data: Data,
    account: String,
    service: String,
    accessGroup: String?
  ) async throws {
    var query: [String: Any]=[
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrAccount as String: account,
      kSecAttrService as String: service
    ]

    if let accessGroup {
      query[kSecAttrAccessGroup as String]=accessGroup
    }

    let attributes: [String: Any]=[
      kSecValueData as String: data
    ]

    let status=SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
    guard status == errSecSuccess else {
      let error=convertError(status)
      let metadata=LogMetadata([
        "error": String(describing: error),
        "status": String(status),
        "operation": "updateItem",
        "account": account,
        "service": service,
        "accessGroup": accessGroup ?? "none"
      ])
      await logger.error("Failed to update keychain item", metadata: metadata)
      throw error
    }

    let metadata=LogMetadata([
      "operation": "updateItem",
      "account": account,
      "service": service,
      "accessGroup": accessGroup ?? "none"
    ])
    await logger.info("Successfully updated keychain item", metadata: metadata)
  }

  /// Delete an item from the keychain
  /// - Parameters:
  ///   - account: Account identifier
  ///   - service: Service identifier
  ///   - accessGroup: Optional access group
  /// - Throws: KeychainError if operation fails
  public func deleteItem(
    account: String,
    service: String,
    accessGroup: String?
  ) async throws {
    var query: [String: Any]=[
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrAccount as String: account,
      kSecAttrService as String: service
    ]

    if let accessGroup {
      query[kSecAttrAccessGroup as String]=accessGroup
    }

    let status=SecItemDelete(query as CFDictionary)
    guard status == errSecSuccess else {
      let error=convertError(status)
      let metadata=LogMetadata([
        "error": String(describing: error),
        "status": String(status),
        "operation": "deleteItem",
        "account": account,
        "service": service,
        "accessGroup": accessGroup ?? "none"
      ])
      await logger.error("Failed to delete keychain item", metadata: metadata)
      throw error
    }

    let metadata=LogMetadata([
      "operation": "deleteItem",
      "account": account,
      "service": service,
      "accessGroup": accessGroup ?? "none"
    ])
    await logger.info("Successfully deleted keychain item", metadata: metadata)
  }

  /// Read an item from the keychain
  /// - Parameters:
  ///   - account: Account identifier
  ///   - service: Service identifier
  ///   - accessGroup: Optional access group
  /// - Returns: Stored data
  /// - Throws: KeychainError if operation fails
  public func readItem(
    account: String,
    service: String,
    accessGroup: String?
  ) async throws -> Data {
    var query: [String: Any]=[
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrAccount as String: account,
      kSecAttrService as String: service,
      kSecReturnData as String: true
    ]

    if let accessGroup {
      query[kSecAttrAccessGroup as String]=accessGroup
    }

    var result: AnyObject?
    let status=SecItemCopyMatching(query as CFDictionary, &result)
    guard status == errSecSuccess else {
      let error=convertError(status)
      let metadata=LogMetadata([
        "error": String(describing: error),
        "status": String(status),
        "operation": "readItem",
        "account": account,
        "service": service,
        "accessGroup": accessGroup ?? "none"
      ])
      await logger.error("Failed to read keychain item", metadata: metadata)
      throw error
    }

    guard let data=result as? Data else {
      let metadata=LogMetadata([
        "operation": "readItem",
        "account": account,
        "service": service,
        "accessGroup": accessGroup ?? "none",
        "resultType": String(describing: type(of: result))
      ])
      await logger.error("Read keychain item is not Data", metadata: metadata)
      throw KeychainError.unexpectedData
    }

    let metadata=LogMetadata([
      "operation": "readItem",
      "account": account,
      "service": service,
      "accessGroup": accessGroup ?? "none"
    ])
    await logger.info("Successfully read keychain item", metadata: metadata)
    return data
  }

  /// Check if an item exists in the keychain
  /// - Parameters:
  ///   - account: Account identifier
  ///   - service: Service identifier
  ///   - accessGroup: Optional access group
  /// - Returns: True if item exists
  public func containsItem(
    account: String,
    service: String,
    accessGroup: String?
  ) async -> Bool {
    var query: [String: Any]=[
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrAccount as String: account,
      kSecAttrService as String: service,
      kSecReturnData as String: false
    ]

    if let accessGroup {
      query[kSecAttrAccessGroup as String]=accessGroup
    }

    let status=SecItemCopyMatching(query as CFDictionary, nil)

    // Most important: don't throw, just return a boolean
    return status == errSecSuccess
  }

  /// Converts a `SecItemError` to a `KeychainError`.
  private func convertError(_ status: OSStatus) -> KeychainError {
    switch status {
      case errSecDuplicateItem:
        .duplicateItem
      case errSecItemNotFound:
        .itemNotFound
      case errSecAuthFailed:
        .authenticationFailed
      default:
        .unhandledError(status: status)
    }
  }
}
