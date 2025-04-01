import Foundation

/**
 # KeychainServiceProtocol

 Defines the interface for keychain services in the Umbra system.
 This protocol provides secure storage and retrieval of sensitive data like
 passwords, certificates, and keys using the system keychain.

 ## Actor-Based Implementation

 Implementations of this protocol MUST use Swift actors to ensure proper
 state isolation and thread safety for credential operations:

 ```swift
 actor KeychainServiceActor: KeychainServiceProtocol {
     // Private state should be isolated within the actor
     private let serviceIdentifier: String
     private let logger: PrivacyAwareLoggingProtocol

     // All function implementations must use 'await' appropriately when
     // accessing actor-isolated state or calling other actor methods
 }
 ```

 ## Protocol Forwarding

 To support proper protocol conformance while maintaining actor isolation,
 implementations should consider using the protocol forwarding pattern:

 ```swift
 // Public non-actor class that conforms to protocol
 public final class KeychainService: KeychainServiceProtocol {
     private let actor: KeychainServiceActor

     // Forward all protocol methods to the actor
     public func storePassword(...) async throws {
         try await actor.storePassword(...)
     }
 }
 ```

 ## Privacy Considerations

 Keychain operations involve highly sensitive data. Implementations must:
 - Never log passwords or other sensitive credential material
 - Use privacy-aware logging for operation contexts
 - Properly handle keychain access errors without revealing sensitive information
 - Implement appropriate access controls based on security requirements

 ## Usage Example

 ```swift
 let keychainService = await KeychainServices.createService()

 // Store a password
 try await keychainService.storePassword("securePassword123",
                                       for: "userAccount",
                                       keychainOptions: .standard)

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
      - keychainOptions: Options for configuring keychain storage and access

   - Throws: KeychainError if the operation fails
   */
  func storePassword(
    _ password: String,
    for account: String,
    keychainOptions: KeychainOptions?
  ) async throws

  /**
   Retrieves a password from the keychain.

   - Parameters:
      - account: The account identifier for the password
      - keychainOptions: Options for configuring keychain access

   - Returns: The stored password as a string
   - Throws: KeychainError if the password doesn't exist or retrieval fails
   */
  func retrievePassword(
    for account: String,
    keychainOptions: KeychainOptions?
  ) async throws -> String

  /**
   Deletes a password from the keychain.

   - Parameters:
      - account: The account identifier for the password to delete
      - keychainOptions: Options for configuring keychain access

   - Throws: KeychainError if the deletion fails
   */
  func deletePassword(
    for account: String,
    keychainOptions: KeychainOptions?
  ) async throws

  /**
   Stores binary data securely in the keychain.

   - Parameters:
      - data: The binary data to store
      - account: The account identifier for the data
      - keychainOptions: Options for configuring keychain storage and access

   - Throws: KeychainError if the operation fails
   */
  func storeData(
    _ data: Data,
    for account: String,
    keychainOptions: KeychainOptions?
  ) async throws

  /**
   Retrieves binary data from the keychain.

   - Parameters:
      - account: The account identifier for the data
      - keychainOptions: Options for configuring keychain access

   - Returns: The stored data
   - Throws: KeychainError if the data doesn't exist or retrieval fails
   */
  func retrieveData(
    for account: String,
    keychainOptions: KeychainOptions?
  ) async throws -> Data

  /**
   Deletes binary data from the keychain.

   - Parameters:
      - account: The account identifier for the data to delete
      - keychainOptions: Options for configuring keychain access

   - Throws: KeychainError if the deletion fails
   */
  func deleteData(
    for account: String,
    keychainOptions: KeychainOptions?
  ) async throws

  /**
   Updates an existing password in the keychain.

   - Parameters:
      - newPassword: The new password to store
      - account: The account identifier for the password
      - keychainOptions: Options for configuring keychain access

   - Throws: KeychainError if the password doesn't exist or the update fails
   */
  func updatePassword(
    _ newPassword: String,
    for account: String,
    keychainOptions: KeychainOptions?
  ) async throws

  /**
   Checks if a password exists in the keychain.

   - Parameters:
      - account: The account identifier for the password
      - keychainOptions: Options for configuring keychain access

   - Returns: True if the password exists, false otherwise
   - Throws: KeychainError if the operation fails
   */
  func passwordExists(
    for account: String,
    keychainOptions: KeychainOptions?
  ) async throws -> Bool
}

/**
 Configuration options for keychain operations.

 These options allow customisation of how items are stored in and retrieved
 from the keychain, including access controls, synchronisation behaviour,
 and item attributes.
 */
public struct KeychainOptions: Sendable, Equatable {
  /// Standard options for most operations
  public static let standard=KeychainOptions()

  /// Secure options with higher security requirements
  public static let secure=KeychainOptions(
    accessLevel: .whenUnlockedThisDeviceOnly,
    authenticationType: .biometryAny,
    synchronisable: false
  )

  /// Access level for the keychain item
  public enum AccessLevel: String, Sendable, Equatable {
    /// Item data can be accessed only while the device is unlocked
    case whenUnlocked
    /// Item data can be accessed only while the device is unlocked by this device only
    case whenUnlockedThisDeviceOnly
    /// Item data can always be accessed regardless of lock state
    case always
    /// Item data can always be accessed regardless of lock state by this device only
    case alwaysThisDeviceOnly
    /// Item data can be accessed only when the device is unlocked or when using biometrics
    case whenPasscodeSetThisDeviceOnly
  }

  /// Authentication type required to access the item
  public enum AuthenticationType: String, Sendable, Equatable {
    /// No authentication required
    case none
    /// Any biometry authentication (Face ID or Touch ID)
    case biometryAny
    /// Face ID authentication
    case biometryFaceID
    /// Touch ID authentication
    case biometryTouchID
    /// Device passcode authentication
    case devicePasscode
  }

  /// Access level for the keychain item
  public let accessLevel: AccessLevel

  /// Authentication type required to access the item
  public let authenticationType: AuthenticationType

  /// Whether the item should be synchronised across devices
  public let synchronisable: Bool

  /// Application tag for cryptographic keys
  public let applicationTag: Data?

  /// Whether to use a case-sensitive account when searching
  public let caseSensitiveAccount: Bool

  /// Creates new keychain options
  public init(
    accessLevel: AccessLevel = .whenUnlocked,
    authenticationType: AuthenticationType = .none,
    synchronisable: Bool=true,
    applicationTag: Data?=nil,
    caseSensitiveAccount: Bool=true
  ) {
    self.accessLevel=accessLevel
    self.authenticationType=authenticationType
    self.synchronisable=synchronisable
    self.applicationTag=applicationTag
    self.caseSensitiveAccount=caseSensitiveAccount
  }
}
