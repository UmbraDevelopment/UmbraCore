import Foundation

/**
 # KeychainServiceProtocol

 Defines the interface for keychain services in the Umbra system.
 This protocol provides secure storage and retrieval of sensitive data like
 passwords, certificates, and keys using the system keychain.

 ## Thread Safety

 Implementations of this protocol should ensure thread safety and proper
 error handling for all operations.

 ## Usage Example

 ```swift
 let keychainService = await KeychainServices.createService()

 // Store a password
 try await keychainService.storePassword("securePassword123", for: "userAccount")

 // Retrieve a password
 let password = try await keychainService.retrievePassword(for: "userAccount")

 // Delete a password
 try await keychainService.deletePassword(for: "userAccount")
 ```
 */
public protocol KeychainServiceProtocol: Sendable {
  /**
   The service identifier used for categorising keychain items.
   */
  var serviceIdentifier: String { get }

  /**
   Stores a password securely in the keychain.

   - Parameters:
      - password: The password string to store
      - account: The account identifier for the password
      - accessOptions: Optional access control options

   - Throws: KeychainError if the operation fails
   */
  func storePassword(
    _ password: String,
    for account: String,
    accessOptions: KeychainAccessOptions?
  ) async throws

  /**
   Retrieves a password from the keychain.

   - Parameter account: The account identifier for the password

   - Returns: The stored password as a string
   - Throws: KeychainError if the password doesn't exist or retrieval fails
   */
  func retrievePassword(for account: String) async throws -> String

  /**
   Deletes a password from the keychain.

   - Parameter account: The account identifier for the password to delete

   - Throws: KeychainError if the deletion fails
   */
  func deletePassword(for account: String) async throws

  /**
   Stores binary data securely in the keychain.

   - Parameters:
      - data: The binary data to store
      - account: The account identifier for the data
      - accessOptions: Optional access control options

   - Throws: KeychainError if the operation fails
   */
  func storeData(
    _ data: Data,
    for account: String,
    accessOptions: KeychainAccessOptions?
  ) async throws

  /**
   Retrieves binary data from the keychain.

   - Parameter account: The account identifier for the data

   - Returns: The stored data
   - Throws: KeychainError if the data doesn't exist or retrieval fails
   */
  func retrieveData(for account: String) async throws -> Data

  /**
   Deletes binary data from the keychain.

   - Parameter account: The account identifier for the data to delete

   - Throws: KeychainError if the deletion fails
   */
  func deleteData(for account: String) async throws

  /**
   Checks if a password exists in the keychain.

   - Parameter account: The account identifier to check

   - Returns: True if a password exists for the account, false otherwise
   */
  func passwordExists(for account: String) async -> Bool

  /**
   Updates an existing password in the keychain.

   - Parameters:
      - newPassword: The new password to store
      - account: The account identifier for the password

   - Throws: KeychainError if the operation fails or the password doesn't exist
   */
  func updatePassword(_ newPassword: String, for account: String) async throws
}

/**
 # KeychainAccessOptions

 Access control options for keychain items.
 */
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

  /// Item data cannot be synchronised to other devices
  public static let thisDeviceOnly=KeychainAccessOptions(rawValue: 1 << 3)

  /// Default access options (when unlocked, this device only)
  public static let `default`: KeychainAccessOptions=[.whenUnlocked, .thisDeviceOnly]
}
