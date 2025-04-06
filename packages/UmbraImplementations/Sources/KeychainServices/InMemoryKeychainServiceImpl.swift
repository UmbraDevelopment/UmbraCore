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
   Stores a password securely.

   - Parameters:
     - password: The password string to store
     - account: The account identifier
     - keychainOptions: Optional keychain configuration options

   - Throws: KeychainError if the operation fails
   */
  public func storePassword(
    _ password: String,
    for account: String,
    keychainOptions _: KeychainOptions?
  ) async throws {
    await logger.debug(
      "Storing password for account: \(account) in memory",
      context: KeychainLogContext(
        account: account,
        operation: "storePassword"
      )
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
        context: KeychainLogContext(
          account: account,
          operation: "storePassword"
        )
      )
      throw KeychainError.itemAlreadyExists
    }

    // Store the password
    passwordStorage[account]=password
    await logger.info(
      "Successfully stored password for account: \(account) in memory",
      context: KeychainLogContext(
        account: account,
        operation: "storePassword"
      )
    )
  }

  /**
   Retrieves a password.

   - Parameters:
     - account: The account identifier
     - keychainOptions: Optional keychain configuration options

   - Returns: The stored password
   - Throws: KeychainError if the password doesn't exist
   */
  public func retrievePassword(
    for account: String,
    keychainOptions _: KeychainOptions?
  ) async throws -> String {
    await logger.debug(
      "Retrieving password for account: \(account) from memory",
      context: KeychainLogContext(
        account: account,
        operation: "retrievePassword"
      )
    )

    guard !account.isEmpty else {
      throw KeychainError.invalidParameter("Account identifier cannot be empty")
    }

    // Retrieve the password
    guard let password=passwordStorage[account] else {
      await logger.warning(
        "No password found for account: \(account) in memory",
        context: KeychainLogContext(
          account: account,
          operation: "retrievePassword"
        )
      )
      throw KeychainError.itemNotFound
    }

    await logger.info(
      "Successfully retrieved password for account: \(account) from memory",
      context: KeychainLogContext(
        account: account,
        operation: "retrievePassword"
      )
    )
    return password
  }

  /**
   Deletes a password.

   - Parameters:
     - account: The account identifier
     - keychainOptions: Optional keychain configuration options

   - Throws: KeychainError if the operation fails
   */
  public func deletePassword(
    for account: String,
    keychainOptions _: KeychainOptions?
  ) async throws {
    await logger.debug(
      "Deleting password for account: \(account) from memory",
      context: KeychainLogContext(
        account: account,
        operation: "deletePassword"
      )
    )

    guard !account.isEmpty else {
      throw KeychainError.invalidParameter("Account identifier cannot be empty")
    }

    // Check if password exists
    if passwordStorage[account] != nil {
      passwordStorage.removeValue(forKey: account)
      await logger.info(
        "Successfully deleted password for account: \(account) from memory",
        context: KeychainLogContext(
          account: account,
          operation: "deletePassword"
        )
      )
    } else {
      await logger.warning(
        "No password found to delete for account: \(account) in memory",
        context: KeychainLogContext(
          account: account,
          operation: "deletePassword"
        )
      )
      throw KeychainError.itemNotFound
    }
  }

  /**
   Stores binary data securely.

   - Parameters:
     - data: The data to store
     - account: The account identifier
     - keychainOptions: Optional keychain configuration options

   - Throws: KeychainError if the operation fails
   */
  public func storeData(
    _ data: Data,
    for account: String,
    keychainOptions _: KeychainOptions?
  ) async throws {
    await logger.debug(
      "Storing data for account: \(account) in memory",
      context: KeychainLogContext(
        account: account,
        operation: "storeData"
      )
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
        context: KeychainLogContext(
          account: account,
          operation: "storeData"
        )
      )
      throw KeychainError.itemAlreadyExists
    }

    // Store the data
    dataStorage[account]=data
    await logger.info(
      "Successfully stored data for account: \(account) in memory",
      context: KeychainLogContext(
        account: account,
        operation: "storeData"
      )
    )
  }

  /**
   Retrieves binary data.

   - Parameters:
     - account: The account identifier
     - keychainOptions: Optional keychain configuration options

   - Returns: The stored data
   - Throws: KeychainError if the data doesn't exist
   */
  public func retrieveData(
    for account: String,
    keychainOptions _: KeychainOptions?
  ) async throws -> Data {
    await logger.debug(
      "Retrieving data for account: \(account) from memory",
      context: KeychainLogContext(
        account: account,
        operation: "retrieveData"
      )
    )

    guard !account.isEmpty else {
      throw KeychainError.invalidParameter("Account identifier cannot be empty")
    }

    // Retrieve the data
    guard let data=dataStorage[account] else {
      await logger.warning(
        "No data found for account: \(account) in memory",
        context: KeychainLogContext(
          account: account,
          operation: "retrieveData"
        )
      )
      throw KeychainError.itemNotFound
    }

    await logger.info(
      "Successfully retrieved data for account: \(account) from memory",
      context: KeychainLogContext(
        account: account,
        operation: "retrieveData"
      )
    )
    return data
  }

  /**
   Deletes binary data.

   - Parameters:
     - account: The account identifier
     - keychainOptions: Optional keychain configuration options

   - Throws: KeychainError if the operation fails
   */
  public func deleteData(
    for account: String,
    keychainOptions _: KeychainOptions?
  ) async throws {
    await logger.debug(
      "Deleting data for account: \(account) from memory",
      context: KeychainLogContext(
        account: account,
        operation: "deleteData"
      )
    )

    guard !account.isEmpty else {
      throw KeychainError.invalidParameter("Account identifier cannot be empty")
    }

    // Check if data exists
    if dataStorage[account] != nil {
      dataStorage.removeValue(forKey: account)
      await logger.info(
        "Successfully deleted data for account: \(account) from memory",
        context: KeychainLogContext(
          account: account,
          operation: "deleteData"
        )
      )
    } else {
      await logger.warning(
        "No data found to delete for account: \(account) in memory",
        context: KeychainLogContext(
          account: account,
          operation: "deleteData"
        )
      )
      throw KeychainError.itemNotFound
    }
  }

  /**
   Updates an existing password.

   - Parameters:
     - newPassword: The new password to store
     - account: The account identifier
     - keychainOptions: Optional keychain configuration options

   - Throws: KeychainError if the password doesn't exist
   */
  public func updatePassword(
    _ newPassword: String,
    for account: String,
    keychainOptions _: KeychainOptions?
  ) async throws {
    await logger.debug(
      "Updating password for account: \(account) in memory",
      context: KeychainLogContext(
        account: account,
        operation: "updatePassword"
      )
    )

    guard !newPassword.isEmpty else {
      throw KeychainError.invalidParameter("Password cannot be empty")
    }

    guard !account.isEmpty else {
      throw KeychainError.invalidParameter("Account identifier cannot be empty")
    }

    // Check if password exists
    guard passwordStorage[account] != nil else {
      await logger.warning(
        "No password found to update for account: \(account)",
        context: KeychainLogContext(
          account: account,
          operation: "updatePassword"
        )
      )
      throw KeychainError.itemNotFound
    }

    // Update the password
    passwordStorage[account]=newPassword
    await logger.info(
      "Successfully updated password for account: \(account)",
      context: KeychainLogContext(
        account: account,
        operation: "updatePassword"
      )
    )
  }

  /**
   Checks if a password exists.

   - Parameters:
     - account: The account identifier
     - keychainOptions: Optional keychain configuration options

   - Returns: `true` if the password exists, `false` otherwise
   */
  public func passwordExists(
    for account: String,
    keychainOptions _: KeychainOptions?
  ) async throws -> Bool {
    await logger.debug(
      "Checking if password exists for account: \(account) in memory",
      context: KeychainLogContext(
        account: account,
        operation: "passwordExists"
      )
    )

    guard !account.isEmpty else {
      throw KeychainError.invalidParameter("Account identifier cannot be empty")
    }

    return passwordStorage[account] != nil
  }

  /**
   Clears all stored data from memory.
   Useful for test setup/teardown.
   */
  public func clearAllData() async {
    await logger.info(
      "Clearing all stored data from memory",
      context: KeychainLogContext(
        account: "all_accounts",
        operation: "clearAllData"
      )
    )
    passwordStorage.removeAll()
    dataStorage.removeAll()
    await logger.info(
      "Successfully cleared all stored data from memory",
      context: KeychainLogContext(
        account: "all_accounts",
        operation: "clearAllData"
      )
    )
  }
}
