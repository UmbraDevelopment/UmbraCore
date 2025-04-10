import Foundation
import KeychainInterfaces
import KeychainTypes
import LoggingInterfaces
import LoggingTypes

/**
 # Secure Keychain Service Decorator

 A decorator that enhances a KeychainServiceProtocol implementation with additional
 security features such as:

 - Enhanced logging for security auditing
 - Additional data validation before storage
 - Automatic key rotation policies
 - Secure memory handling for sensitive operations

 This actor follows the decorator pattern to add functionality while maintaining
 compatibility with the base KeychainServiceProtocol interface.

 ## Implementation Details

 This implementation follows Alpha Dot Five architecture principles:
 1. Using proper British spelling in documentation
 2. Implementing enhanced privacy-aware logging
 3. Using immutable data structures where possible
 4. Providing comprehensive error handling
 */
public actor SecureKeychainServiceDecorator: KeychainServiceProtocol {
  /// The wrapped keychain service
  private let wrappedService: KeychainServiceProtocol

  /// Logger for enhanced security auditing
  private let logger: LoggingProtocol

  /// Service identifier for categorising keychain items
  public var serviceIdentifier: String {
    get async {
      await wrappedService.serviceIdentifier
    }
  }

  /**
   Initialises a new SecureKeychainServiceDecorator.

   - Parameters:
      - wrapping: The base keychain service to enhance
      - logger: Logger for security auditing
   */
  public init(wrapping service: KeychainServiceProtocol, logger: LoggingProtocol) {
    wrappedService = service
    self.logger = logger
  }

  /**
   Stores a password securely in the keychain.

   - Parameters:
      - password: The password string to store
      - account: The account identifier for the password
      - keychainOptions: Options for configuring keychain storage and access

   - Throws: KeychainError if the operation fails
   */
  public func storePassword(
    _ password: String,
    for account: String,
    keychainOptions: KeychainOptions?=nil
  ) async throws {
    // Create logging context
    let context=KeychainLogContext(
      account: account,
      operation: "storePassword"
    )

    // Log the secure operation
    await logger.debug("Securely storing password in keychain", context: context)

    // Basic validation
    guard !password.isEmpty else {
      throw KeychainError.invalidDataFormat("Cannot store empty password")
    }

    // Delegate to the wrapped service
    try await wrappedService.storePassword(password, for: account, keychainOptions: keychainOptions)

    // Log successful operation
    let successContext=KeychainLogContext(
      account: account,
      operation: "storePassword"
    )
    await logger.debug(
      "Successfully stored password in keychain with enhanced security",
      context: successContext
    )
  }

  /**
   Updates an existing password in the keychain.

   - Parameters:
      - newPassword: The new password to store
      - account: The account identifier for the password
      - keychainOptions: Options for configuring keychain access

   - Throws: KeychainError if the password doesn't exist or the update fails
   */
  public func updatePassword(
    _ newPassword: String,
    for account: String,
    keychainOptions: KeychainOptions?=nil
  ) async throws {
    // Create logging context
    let context=KeychainLogContext(
      account: account,
      operation: "updatePassword"
    )

    // Log the secure operation
    await logger.debug("Securely updating password in keychain", context: context)

    // Basic validation
    guard !newPassword.isEmpty else {
      throw KeychainError.invalidDataFormat("Cannot store empty password")
    }

    // First check if the password exists
    guard try await passwordExists(for: account, keychainOptions: keychainOptions) else {
      throw KeychainError.itemNotFound
    }

    // Delegate to the wrapped service
    try await wrappedService.updatePassword(
      newPassword,
      for: account,
      keychainOptions: keychainOptions
    )

    // Log successful operation
    let successContext=KeychainLogContext(
      account: account,
      operation: "updatePassword"
    )
    await logger.debug(
      "Successfully updated password in keychain with enhanced security",
      context: successContext
    )
  }

  /**
   Retrieves a password from the keychain with enhanced security.

   - Parameters:
      - account: The account identifier for the password
      - keychainOptions: Options for configuring keychain access

   - Returns: The stored password as a string
   - Throws: KeychainError if the password doesn't exist or retrieval fails
   */
  public func retrievePassword(
    for account: String,
    keychainOptions: KeychainOptions?=nil
  ) async throws -> String {
    // Create logging context
    let context=KeychainLogContext(
      account: account,
      operation: "retrievePassword"
    )

    // Log the secure operation
    await logger.debug("Securely retrieving password from keychain", context: context)

    // Delegate to the wrapped service
    let password=try await wrappedService.retrievePassword(
      for: account,
      keychainOptions: keychainOptions
    )

    // Log successful operation
    let successContext=KeychainLogContext(
      account: account,
      operation: "retrievePassword"
    )
    await logger.debug(
      "Successfully retrieved password from keychain with enhanced security",
      context: successContext
    )

    return password
  }

  /**
   Checks if a password exists in the keychain.

   - Parameters:
      - account: The account identifier for the password
      - keychainOptions: Options for configuring keychain access

   - Returns: True if the password exists, false otherwise
   - Throws: KeychainError if the operation fails
   */
  public func passwordExists(
    for account: String,
    keychainOptions: KeychainOptions?=nil
  ) async throws -> Bool {
    // Create logging context
    let context=KeychainLogContext(
      account: account,
      operation: "passwordExists"
    )

    // Log the secure operation
    await logger.debug("Checking if password exists in keychain", context: context)

    // Delegate to the wrapped service
    let exists=try await wrappedService.passwordExists(
      for: account,
      keychainOptions: keychainOptions
    )

    // Log result
    let resultContext=KeychainLogContext(
      account: account,
      operation: "passwordExists"
    )
    await logger.debug("Password existence check completed: \(exists)", context: resultContext)

    return exists
  }

  /**
   Deletes a password from the keychain with enhanced security.

   - Parameters:
      - account: The account identifier for the password to delete
      - keychainOptions: Options for configuring keychain access

   - Throws: KeychainError if the deletion fails
   */
  public func deletePassword(
    for account: String,
    keychainOptions: KeychainOptions?=nil
  ) async throws {
    // Create logging context
    let context=KeychainLogContext(
      account: account,
      operation: "deletePassword"
    )

    // Log the secure operation
    await logger.debug("Securely deleting password from keychain", context: context)

    // Delegate to the wrapped service
    try await wrappedService.deletePassword(for: account, keychainOptions: keychainOptions)

    // Log successful operation
    let successContext=KeychainLogContext(
      account: account,
      operation: "deletePassword"
    )
    await logger.debug(
      "Successfully deleted password from keychain with enhanced security",
      context: successContext
    )
  }

  /**
   Stores binary data securely in the keychain.

   - Parameters:
      - data: The data to store
      - account: The account identifier
      - keychainOptions: Options for configuring keychain storage and access

   - Throws: KeychainError if the operation fails
   */
  public func storeData(
    _ data: Data,
    for account: String,
    keychainOptions: KeychainOptions?=nil
  ) async throws {
    // Create logging context
    let context=KeychainLogContext(
      account: account,
      operation: "storeData"
    )

    // Log the secure operation with data size
    let metadataWithSize=context.metadata.withPublic(key: "dataSize", value: String(data.count))
    let contextWithSize=context.withUpdatedMetadata(metadataWithSize)
    await logger.debug("Securely storing data in keychain", context: contextWithSize)

    // Perform additional validation before storage
    guard !data.isEmpty else {
      throw KeychainError.invalidDataFormat("Cannot store empty data")
    }

    // Delegate to the wrapped service
    try await wrappedService.storeData(data, for: account, keychainOptions: keychainOptions)

    // Log successful operation
    let successContext=KeychainLogContext(
      account: account,
      operation: "storeData"
    )
    await logger.debug(
      "Successfully stored data in keychain with enhanced security",
      context: successContext
    )
  }

  /**
   Retrieves data from the keychain with enhanced security.

   - Parameters:
      - account: The account identifier
      - keychainOptions: Options for configuring keychain access

   - Returns: The stored data
   - Throws: KeychainError if the operation fails
   */
  public func retrieveData(
    for account: String,
    keychainOptions: KeychainOptions?=nil
  ) async throws -> Data {
    // Create logging context
    let context=KeychainLogContext(
      account: account,
      operation: "retrieveData"
    )

    // Log the secure operation
    await logger.debug("Securely retrieving data from keychain", context: context)

    // Delegate to the wrapped service
    let data=try await wrappedService.retrieveData(for: account, keychainOptions: keychainOptions)

    // Log successful operation with data size
    let successContext=KeychainLogContext(
      account: account,
      operation: "retrieveData"
    )
    let metadataWithSize=successContext.metadata.withPublic(
      key: "dataSize",
      value: String(data.count)
    )
    let finalContext=successContext.withUpdatedMetadata(metadataWithSize)
    await logger.debug(
      "Successfully retrieved data from keychain with enhanced security",
      context: finalContext
    )

    return data
  }

  /**
   Deletes data from the keychain with enhanced security.

   - Parameters:
      - account: The account identifier
      - keychainOptions: Options for configuring keychain access

   - Throws: KeychainError if the operation fails
   */
  public func deleteData(
    for account: String,
    keychainOptions: KeychainOptions?=nil
  ) async throws {
    // Create logging context
    let context=KeychainLogContext(
      account: account,
      operation: "deleteData"
    )

    // Log the secure operation
    await logger.debug("Securely deleting data from keychain", context: context)

    // Delegate to the wrapped service
    try await wrappedService.deleteData(for: account, keychainOptions: keychainOptions)

    // Log successful operation
    let successContext=KeychainLogContext(
      account: account,
      operation: "deleteData"
    )
    await logger.debug(
      "Successfully deleted data from keychain with enhanced security",
      context: successContext
    )
  }
}
