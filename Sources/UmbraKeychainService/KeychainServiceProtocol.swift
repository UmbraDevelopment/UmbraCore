import Foundation

/// Access control options for keychain items
public struct KeychainAccessOptions: OptionSet, Sendable {
  public let rawValue: UInt

  public init(rawValue: UInt) {
    self.rawValue=rawValue
  }

  /// Item data can only be accessed while the device is unlocked
  public static let whenUnlocked=KeychainAccessOptions(rawValue: 1 << 0)

  /// Item data can only be accessed once per unlock
  public static let whenPasscodeSetThisDeviceOnly=KeychainAccessOptions(rawValue: 1 << 1)

  /// Item data can only be accessed while the application is in the foreground
  public static let accessibleWhenUnlockedThisDeviceOnly=KeychainAccessOptions(rawValue: 1 << 2)

  /// Item data cannot be synchronized to other devices
  public static let thisDeviceOnly=KeychainAccessOptions(rawValue: 1 << 3)
}

/// Protocol defining operations for secure keychain access
@objc
public protocol KeychainServiceXPCProtocol {
  /// Add a new item to the keychain
  /// - Parameters:
  ///   - data: Data to store
  ///   - account: Account identifier
  ///   - service: Service identifier
  ///   - accessGroup: Optional access group
  ///   - accessibility: Keychain accessibility
  ///   - flags: Access control flags
  /// - Throws: KeychainError if operation fails
  func addItem(
    _ data: Data,
    account: String,
    service: String,
    accessGroup: String?,
    accessibility: String,
    flags: UInt
  ) async throws

  /// Update an existing keychain item
  /// - Parameters:
  ///   - data: New data to store
  ///   - account: Account identifier
  ///   - service: Service identifier
  ///   - accessGroup: Optional access group
  /// - Throws: KeychainError if operation fails
  func updateItem(
    _ data: Data,
    account: String,
    service: String,
    accessGroup: String?
  ) async throws

  /// Delete an item from the keychain
  /// - Parameters:
  ///   - account: Account identifier
  ///   - service: Service identifier
  ///   - accessGroup: Optional access group
  /// - Throws: KeychainError if operation fails
  func deleteItem(
    account: String,
    service: String,
    accessGroup: String?
  ) async throws

  /// Read an item from the keychain
  /// - Parameters:
  ///   - account: Account identifier
  ///   - service: Service identifier
  ///   - accessGroup: Optional access group
  /// - Returns: Stored data
  /// - Throws: KeychainError if operation fails
  func readItem(
    account: String,
    service: String,
    accessGroup: String?
  ) async throws -> Data

  /// Check if an item exists in the keychain
  /// - Parameters:
  ///   - account: Account identifier
  ///   - service: Service identifier
  ///   - accessGroup: Optional access group
  /// - Returns: True if item exists
  func containsItem(
    account: String,
    service: String,
    accessGroup: String?
  ) async -> Bool
}

/// Protocol for actor-based keychain service
public protocol KeychainServiceProtocol: Actor {
  /// Add a new item to the keychain
  /// - Parameters:
  ///   - data: Data to store
  ///   - account: Account identifier
  ///   - service: Service identifier
  ///   - accessGroup: Optional access group
  ///   - accessibility: Keychain accessibility
  ///   - flags: Access control flags
  /// - Throws: KeychainError if operation fails
  func addItem(
    _ data: Data,
    account: String,
    service: String,
    accessGroup: String?,
    accessibility: CFString,
    flags: SecAccessControlCreateFlags
  ) async throws

  /// Update an existing keychain item
  /// - Parameters:
  ///   - data: New data to store
  ///   - account: Account identifier
  ///   - service: Service identifier
  ///   - accessGroup: Optional access group
  /// - Throws: KeychainError if operation fails
  func updateItem(
    _ data: Data,
    account: String,
    service: String,
    accessGroup: String?
  ) async throws

  /// Delete an item from the keychain
  /// - Parameters:
  ///   - account: Account identifier
  ///   - service: Service identifier
  ///   - accessGroup: Optional access group
  /// - Throws: KeychainError if operation fails
  func deleteItem(
    account: String,
    service: String,
    accessGroup: String?
  ) async throws

  /// Read an item from the keychain
  /// - Parameters:
  ///   - account: Account identifier
  ///   - service: Service identifier
  ///   - accessGroup: Optional access group
  /// - Returns: Stored data
  /// - Throws: KeychainError if operation fails
  func readItem(
    account: String,
    service: String,
    accessGroup: String?
  ) async throws -> Data

  /// Check if an item exists in the keychain
  /// - Parameters:
  ///   - account: Account identifier
  ///   - service: Service identifier
  ///   - accessGroup: Optional access group
  /// - Returns: True if item exists
  func containsItem(
    account: String,
    service: String,
    accessGroup: String?
  ) async -> Bool
}
