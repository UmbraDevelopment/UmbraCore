import Foundation
import KeychainInterfaces
import LoggingInterfaces
import LoggingTypes

/**
 # InMemoryKeychainServiceImpl

 An in-memory implementation of KeychainServiceProtocol for testing purposes.
 This implementation stores all data in memory rather than in the system keychain,
 making it suitable for unit tests and isolated environments.

 ## Thread Safety

 As an actor, InMemoryKeychainServiceImpl serialises access to all operations,
 preventing race conditions when multiple parts of the system attempt to
 access the storage simultaneously.
 */
public actor InMemoryKeychainServiceImpl: KeychainServiceProtocol {
  /// Service identifier used for categorising keychain items
  public let serviceIdentifier: String

  /// Logger for recording operations and errors
  private let logger: LoggingProtocol

  /// In-memory storage for passwords
  private var passwordStorage: [String: String]=[:]

  /// In-memory storage for binary data
  private var dataStorage: [String: Data]=[:]

  /**
   Initialises a new InMemoryKeychainServiceImpl.

   - Parameters:
      - serviceIdentifier: The service identifier for storage entries
      - logger: Logger for recording operations
   */
  public init(serviceIdentifier: String, logger: LoggingProtocol) {
    self.serviceIdentifier=serviceIdentifier
    self.logger=logger
  }

  /**
   Stores a password in memory.

   - Parameters:
      - password: The password string to store
      - account: The account identifier for the password
      - accessOptions: Ignored in the in-memory implementation

   - Throws: KeychainError if the operation fails
   */
  public func storePassword(
    _ password: String,
    for account: String,
    accessOptions _: KeychainAccessOptions?=nil
  ) async throws {
    await logger.debug(
      "Storing password for account: \(account) in memory",
      metadata: nil,
      source: "InMemoryKeychainService"
    )

    guard !password.isEmpty else {
      throw KeychainError.invalidParameter("Password cannot be empty")
    }

    guard !account.isEmpty else {
      throw KeychainError.invalidParameter("Account identifier cannot be empty")
    }

    // Check if password already exists
    if passwordStorage[account] != nil {
      await logger.warning(
        "Password already exists for account: \(account)",
        metadata: nil,
        source: "InMemoryKeychainService"
      )
      throw KeychainError.itemAlreadyExists
    }

    // Store the password
    passwordStorage[account]=password
    await logger.info(
      "Successfully stored password for account: \(account) in memory",
      metadata: nil,
      source: "InMemoryKeychainService"
    )
  }

  /**
   Retrieves a password from memory.

   - Parameter account: The account identifier for the password

   - Returns: The stored password as a string
   - Throws: KeychainError if the password doesn't exist
   */
  public func retrievePassword(for account: String) async throws -> String {
    await logger.debug(
      "Retrieving password for account: \(account) from memory",
      metadata: nil,
      source: "InMemoryKeychainService"
    )

    guard !account.isEmpty else {
      throw KeychainError.invalidParameter("Account identifier cannot be empty")
    }

    // Retrieve the password
    if let password=passwordStorage[account] {
      await logger.info(
        "Successfully retrieved password for account: \(account) from memory",
        metadata: nil,
        source: "InMemoryKeychainService"
      )
      return password
    } else {
      await logger.warning(
        "No password found for account: \(account) in memory",
        metadata: nil,
        source: "InMemoryKeychainService"
      )
      throw KeychainError.itemNotFound
    }
  }

  /**
   Deletes a password from memory.

   - Parameter account: The account identifier for the password to delete

   - Throws: KeychainError if the password doesn't exist
   */
  public func deletePassword(for account: String) async throws {
    await logger.debug(
      "Deleting password for account: \(account) from memory",
      metadata: nil,
      source: "InMemoryKeychainService"
    )

    guard !account.isEmpty else {
      throw KeychainError.invalidParameter("Account identifier cannot be empty")
    }

    // Check if password exists
    if passwordStorage[account] != nil {
      passwordStorage.removeValue(forKey: account)
      await logger.info(
        "Successfully deleted password for account: \(account) from memory",
        metadata: nil,
        source: "InMemoryKeychainService"
      )
    } else {
      await logger.warning(
        "No password found to delete for account: \(account) in memory",
        metadata: nil,
        source: "InMemoryKeychainService"
      )
      throw KeychainError.itemNotFound
    }
  }

  /**
   Stores binary data in memory.

   - Parameters:
      - data: The binary data to store
      - account: The account identifier for the data
      - accessOptions: Ignored in the in-memory implementation

   - Throws: KeychainError if the operation fails
   */
  public func storeData(
    _ data: Data,
    for account: String,
    accessOptions _: KeychainAccessOptions?=nil
  ) async throws {
    await logger.debug(
      "Storing data for account: \(account) in memory",
      metadata: nil,
      source: "InMemoryKeychainService"
    )

    guard !data.isEmpty else {
      throw KeychainError.invalidParameter("Data cannot be empty")
    }

    guard !account.isEmpty else {
      throw KeychainError.invalidParameter("Account identifier cannot be empty")
    }

    // Check if data already exists
    if dataStorage[account] != nil {
      await logger.warning(
        "Data already exists for account: \(account)",
        metadata: nil,
        source: "InMemoryKeychainService"
      )
      throw KeychainError.itemAlreadyExists
    }

    // Store the data
    dataStorage[account]=data
    await logger.info(
      "Successfully stored data for account: \(account) in memory",
      metadata: nil,
      source: "InMemoryKeychainService"
    )
  }

  /**
   Retrieves binary data from memory.

   - Parameter account: The account identifier for the data

   - Returns: The stored data
   - Throws: KeychainError if the data doesn't exist
   */
  public func retrieveData(for account: String) async throws -> Data {
    await logger.debug(
      "Retrieving data for account: \(account) from memory",
      metadata: nil,
      source: "InMemoryKeychainService"
    )

    guard !account.isEmpty else {
      throw KeychainError.invalidParameter("Account identifier cannot be empty")
    }

    // Retrieve the data
    if let data=dataStorage[account] {
      await logger.info(
        "Successfully retrieved data for account: \(account) from memory",
        metadata: nil,
        source: "InMemoryKeychainService"
      )
      return data
    } else {
      await logger.warning(
        "No data found for account: \(account) in memory",
        metadata: nil,
        source: "InMemoryKeychainService"
      )
      throw KeychainError.itemNotFound
    }
  }

  /**
   Deletes binary data from memory.

   - Parameter account: The account identifier for the data to delete

   - Throws: KeychainError if the data doesn't exist
   */
  public func deleteData(for account: String) async throws {
    await logger.debug(
      "Deleting data for account: \(account) from memory",
      metadata: nil,
      source: "InMemoryKeychainService"
    )

    guard !account.isEmpty else {
      throw KeychainError.invalidParameter("Account identifier cannot be empty")
    }

    // Check if data exists
    if dataStorage[account] != nil {
      dataStorage.removeValue(forKey: account)
      await logger.info(
        "Successfully deleted data for account: \(account) from memory",
        metadata: nil,
        source: "InMemoryKeychainService"
      )
    } else {
      await logger.warning(
        "No data found to delete for account: \(account) in memory",
        metadata: nil,
        source: "InMemoryKeychainService"
      )
      throw KeychainError.itemNotFound
    }
  }

  /**
   Checks if a password exists in memory.

   - Parameter account: The account identifier to check

   - Returns: True if a password exists for the account, false otherwise
   */
  public func passwordExists(for account: String) async -> Bool {
    await logger.debug(
      "Checking if password exists for account: \(account) in memory",
      metadata: nil,
      source: "InMemoryKeychainService"
    )

    guard !account.isEmpty else {
      return false
    }

    return passwordStorage[account] != nil
  }

  /**
   Updates an existing password in memory.

   - Parameters:
      - newPassword: The new password to store
      - account: The account identifier for the password

   - Throws: KeychainError if the password doesn't exist
   */
  public func updatePassword(_ newPassword: String, for account: String) async throws {
    await logger.debug(
      "Updating password for account: \(account) in memory",
      metadata: nil,
      source: "InMemoryKeychainService"
    )

    guard !newPassword.isEmpty else {
      throw KeychainError.invalidParameter("New password cannot be empty")
    }

    guard !account.isEmpty else {
      throw KeychainError.invalidParameter("Account identifier cannot be empty")
    }

    // Check if the password exists
    if passwordStorage[account] != nil {
      passwordStorage[account]=newPassword
      await logger.info(
        "Successfully updated password for account: \(account) in memory",
        metadata: nil,
        source: "InMemoryKeychainService"
      )
    } else {
      await logger.warning(
        "Cannot update - no password exists for account: \(account) in memory",
        metadata: nil,
        source: "InMemoryKeychainService"
      )
      throw KeychainError.itemNotFound
    }
  }

  /**
   Clears all stored data from memory.
   Useful for test setup/teardown.
   */
  public func clearAllData() async {
    await logger.info(
      "Clearing all stored data from memory",
      metadata: nil,
      source: "InMemoryKeychainService"
    )
    passwordStorage.removeAll()
    dataStorage.removeAll()
  }
}
