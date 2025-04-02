import Foundation
import KeychainInterfaces
import LoggingInterfaces
import LoggingTypes

/**
 # KeychainServiceImpl

 Actor-based implementation of KeychainServiceProtocol that provides secure
 storage and retrieval of sensitive data using the system keychain.

 This implementation follows the Alpha Dot Five architecture pattern with:
 - Thread safety through Swift actors
 - Domain-specific error handling
 - Proper British spelling in documentation
 - Comprehensive logging

 ## Thread Safety

 As an actor, KeychainServiceImpl serialises access to keychain operations,
 preventing race conditions when multiple parts of the system attempt to
 access the keychain simultaneously.
 */
public actor KeychainServiceImpl: KeychainServiceProtocol {
  /// Service identifier used for categorising keychain items
  public let serviceIdentifier: String

  /// Logger for recording operations and errors
  private let logger: LoggingProtocol

  /**
   Initialises a new KeychainServiceImpl.

   - Parameters:
      - serviceIdentifier: The service identifier for keychain entries
      - logger: Logger for recording operations
   */
  public init(serviceIdentifier: String, logger: LoggingProtocol) {
    self.serviceIdentifier=serviceIdentifier
    self.logger=logger
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
    await logger.debug(
      "Storing password for account: \(account)",
      metadata: nil,
      source: "KeychainService"
    )

    guard !password.isEmpty else {
      throw KeychainError.invalidParameter("Password cannot be empty")
    }

    guard !account.isEmpty else {
      throw KeychainError.invalidParameter("Account identifier cannot be empty")
    }

    // Convert password to data
    guard let passwordData=password.data(using: .utf8) else {
      throw KeychainError.invalidDataFormat("Unable to convert password to data")
    }

    // Determine access options
    var securityAccessibility: CFString=kSecAttrAccessibleWhenUnlocked
    if let accessLevel=keychainOptions?.accessLevel {
      switch accessLevel {
        case .whenUnlocked:
          securityAccessibility=kSecAttrAccessibleWhenUnlocked
        case .whenUnlockedThisDeviceOnly:
          securityAccessibility=kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        case .always:
          securityAccessibility=kSecAttrAccessibleAfterFirstUnlock
        case .alwaysThisDeviceOnly:
          securityAccessibility=kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        case .whenPasscodeSetThisDeviceOnly:
          securityAccessibility=kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly
      }
    }

    // Create the keychain query
    let query: [String: Any]=[
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: serviceIdentifier,
      kSecAttrAccount as String: account,
      kSecValueData as String: passwordData,
      kSecAttrAccessible as String: securityAccessibility
    ]

    // Add authentication options if specified
    if let authType=keychainOptions?.authenticationType {
      switch authType {
        case .none:
          // No additional authentication required
          break
        case .biometryAny, .biometryFaceID, .biometryTouchID:
          // These would require additional setup, but for now we'll just acknowledge them
          break
        case .devicePasscode:
          // This would require additional security setup
          break
      }
    }

    // Add the item to the keychain
    let status=SecItemAdd(query as CFDictionary, nil)

    if status == errSecSuccess {
      await logger.info(
        "Successfully stored password for account: \(account)",
        metadata: nil,
        source: "KeychainService"
      )
    } else if status == errSecDuplicateItem {
      await logger.warning(
        "Password already exists for account: \(account). Use updatePassword instead.",
        metadata: nil,
        source: "KeychainService"
      )
      throw KeychainError.itemAlreadyExists
    } else {
      let error=KeychainError.fromOSStatus(status)
      await logger.error(
        "Failed to store password: \(error)",
        metadata: nil,
        source: "KeychainService"
      )
      throw error
    }
  }

  /**
   Retrieves a password from the keychain.

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
    await logger.debug(
      "Retrieving password for account: \(account)",
      metadata: nil,
      source: "KeychainService"
    )

    guard !account.isEmpty else {
      throw KeychainError.invalidParameter("Account identifier cannot be empty")
    }

    // Create the query
    let query: [String: Any]=[
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: serviceIdentifier,
      kSecAttrAccount as String: account,
      kSecReturnData as String: true,
      kSecMatchLimit as String: kSecMatchLimitOne
    ]

    // Add authentication options if specified
    if let authType=keychainOptions?.authenticationType {
      switch authType {
        case .none:
          // No additional authentication required
          break
        case .biometryAny, .biometryFaceID, .biometryTouchID:
          // These would require additional setup, but for now we'll just acknowledge them
          break
        case .devicePasscode:
          // This would require additional security setup
          break
      }
    }

    // Execute the query
    var result: AnyObject?
    let status=SecItemCopyMatching(query as CFDictionary, &result)

    if status == errSecSuccess, let passwordData=result as? Data {
      // Convert data to string
      guard let password=String(data: passwordData, encoding: .utf8) else {
        await logger.error(
          "Retrieved data couldn't be converted to a string",
          metadata: nil,
          source: "KeychainService"
        )
        throw KeychainError.invalidDataFormat("Retrieved data is not a valid UTF-8 string")
      }

      await logger.info(
        "Successfully retrieved password for account: \(account)",
        metadata: nil,
        source: "KeychainService"
      )
      return password
    } else {
      if status == errSecItemNotFound {
        await logger.warning(
          "No password found for account: \(account)",
          metadata: nil,
          source: "KeychainService"
        )
        throw KeychainError.itemNotFound
      } else {
        let error=KeychainError.fromOSStatus(status)
        await logger.error(
          "Failed to retrieve password: \(error)",
          metadata: nil,
          source: "KeychainService"
        )
        throw error
      }
    }
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
    await logger.debug(
      "Updating password for account: \(account)",
      metadata: nil,
      source: "KeychainService"
    )

    guard !newPassword.isEmpty else {
      throw KeychainError.invalidParameter("New password cannot be empty")
    }

    guard !account.isEmpty else {
      throw KeychainError.invalidParameter("Account identifier cannot be empty")
    }

    // First check if the password exists
    if try await !(passwordExists(for: account, keychainOptions: keychainOptions)) {
      throw KeychainError.itemNotFound
    }

    // Convert password to data
    guard let passwordData=newPassword.data(using: .utf8) else {
      throw KeychainError.invalidDataFormat("Unable to convert password to data")
    }

    // Create the query to find the item
    let query: [String: Any]=[
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: serviceIdentifier,
      kSecAttrAccount as String: account
    ]

    // Attributes to update
    let attributes: [String: Any]=[
      kSecValueData as String: passwordData
    ]

    // Update the item
    let status=SecItemUpdate(query as CFDictionary, attributes as CFDictionary)

    if status == errSecSuccess {
      await logger.info(
        "Successfully updated password for account: \(account)",
        metadata: nil,
        source: "KeychainService"
      )
    } else {
      let error=KeychainError.fromOSStatus(status)
      await logger.error(
        "Failed to update password: \(error)",
        metadata: nil,
        source: "KeychainService"
      )
      throw error
    }
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
    keychainOptions _: KeychainOptions?=nil
  ) async throws -> Bool {
    await logger.debug(
      "Checking if password exists for account: \(account)",
      metadata: nil,
      source: "KeychainService"
    )

    guard !account.isEmpty else {
      throw KeychainError.invalidParameter("Account identifier cannot be empty")
    }

    // Create the query
    let query: [String: Any]=[
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: serviceIdentifier,
      kSecAttrAccount as String: account,
      kSecReturnData as String: false,
      kSecMatchLimit as String: kSecMatchLimitOne
    ]

    // Execute the query
    let status=SecItemCopyMatching(query as CFDictionary, nil)

    if status == errSecSuccess {
      await logger.debug(
        "Password exists for account: \(account)",
        metadata: nil,
        source: "KeychainService"
      )
      return true
    } else if status == errSecItemNotFound {
      await logger.debug(
        "Password does not exist for account: \(account)",
        metadata: nil,
        source: "KeychainService"
      )
      return false
    } else {
      let error=KeychainError.fromOSStatus(status)
      await logger.error(
        "Failed to check if password exists: \(error)",
        metadata: nil,
        source: "KeychainService"
      )
      throw error
    }
  }

  /**
   Deletes a password from the keychain.

   - Parameters:
      - account: The account identifier for the password to delete
      - keychainOptions: Options for configuring keychain access

   - Throws: KeychainError if the deletion fails
   */
  public func deletePassword(
    for account: String,
    keychainOptions _: KeychainOptions?=nil
  ) async throws {
    await logger.debug(
      "Deleting password for account: \(account)",
      metadata: nil,
      source: "KeychainService"
    )

    guard !account.isEmpty else {
      throw KeychainError.invalidParameter("Account identifier cannot be empty")
    }

    // Create the query
    let query: [String: Any]=[
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: serviceIdentifier,
      kSecAttrAccount as String: account
    ]

    // Delete the item
    let status=SecItemDelete(query as CFDictionary)

    if status == errSecSuccess {
      await logger.info(
        "Successfully deleted password for account: \(account)",
        metadata: nil,
        source: "KeychainService"
      )
    } else if status == errSecItemNotFound {
      await logger.warning(
        "No password found to delete for account: \(account)",
        metadata: nil,
        source: "KeychainService"
      )
      throw KeychainError.itemNotFound
    } else {
      let error=KeychainError.fromOSStatus(status)
      await logger.error(
        "Failed to delete password: \(error)",
        metadata: nil,
        source: "KeychainService"
      )
      throw error
    }
  }

  /**
   Stores binary data securely in the keychain.

   - Parameters:
      - data: The binary data to store
      - account: The account identifier for the data
      - keychainOptions: Options for configuring keychain storage and access

   - Throws: KeychainError if the operation fails
   */
  public func storeData(
    _ data: Data,
    for account: String,
    keychainOptions: KeychainOptions?=nil
  ) async throws {
    await logger.debug(
      "Storing data for account: \(account)",
      metadata: nil,
      source: "KeychainService"
    )

    guard !data.isEmpty else {
      throw KeychainError.invalidParameter("Data cannot be empty")
    }

    guard !account.isEmpty else {
      throw KeychainError.invalidParameter("Account identifier cannot be empty")
    }

    // Determine access options
    var securityAccessibility: CFString=kSecAttrAccessibleWhenUnlocked
    if let accessLevel=keychainOptions?.accessLevel {
      switch accessLevel {
        case .whenUnlocked:
          securityAccessibility=kSecAttrAccessibleWhenUnlocked
        case .whenUnlockedThisDeviceOnly:
          securityAccessibility=kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        case .always:
          securityAccessibility=kSecAttrAccessibleAfterFirstUnlock
        case .alwaysThisDeviceOnly:
          securityAccessibility=kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        case .whenPasscodeSetThisDeviceOnly:
          securityAccessibility=kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly
      }
    }

    // Create the keychain query
    let query: [String: Any]=[
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: serviceIdentifier,
      kSecAttrAccount as String: account,
      kSecValueData as String: data,
      kSecAttrAccessible as String: securityAccessibility
    ]

    // Add the item to the keychain
    let status=SecItemAdd(query as CFDictionary, nil)

    if status == errSecSuccess {
      await logger.info(
        "Successfully stored data for account: \(account)",
        metadata: nil,
        source: "KeychainService"
      )
    } else if status == errSecDuplicateItem {
      await logger.warning(
        "Data already exists for account: \(account)",
        metadata: nil,
        source: "KeychainService"
      )
      throw KeychainError.itemAlreadyExists
    } else {
      let error=KeychainError.fromOSStatus(status)
      await logger.error(
        "Failed to store data: \(error)",
        metadata: nil,
        source: "KeychainService"
      )
      throw error
    }
  }

  /**
   Retrieves binary data from the keychain.

   - Parameters:
      - account: The account identifier for the data
      - keychainOptions: Options for configuring keychain access

   - Returns: The stored data
   - Throws: KeychainError if the data doesn't exist or retrieval fails
   */
  public func retrieveData(
    for account: String,
    keychainOptions: KeychainOptions?=nil
  ) async throws -> Data {
    await logger.debug(
      "Retrieving data for account: \(account)",
      metadata: nil,
      source: "KeychainService"
    )

    guard !account.isEmpty else {
      throw KeychainError.invalidParameter("Account identifier cannot be empty")
    }

    // Create the query
    let query: [String: Any]=[
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: serviceIdentifier,
      kSecAttrAccount as String: account,
      kSecReturnData as String: true,
      kSecMatchLimit as String: kSecMatchLimitOne
    ]

    // Add authentication options if specified
    if let authType=keychainOptions?.authenticationType {
      switch authType {
        case .none:
          // No additional authentication required
          break
        case .biometryAny, .biometryFaceID, .biometryTouchID:
          // These would require additional setup, but for now we'll just acknowledge them
          break
        case .devicePasscode:
          // This would require additional security setup
          break
      }
    }

    // Execute the query
    var result: AnyObject?
    let status=SecItemCopyMatching(query as CFDictionary, &result)

    if status == errSecSuccess, let data=result as? Data {
      await logger.info(
        "Successfully retrieved data for account: \(account)",
        metadata: nil,
        source: "KeychainService"
      )
      return data
    } else {
      if status == errSecItemNotFound {
        await logger.warning(
          "No data found for account: \(account)",
          metadata: nil,
          source: "KeychainService"
        )
        throw KeychainError.itemNotFound
      } else {
        let error=KeychainError.fromOSStatus(status)
        await logger.error(
          "Failed to retrieve data: \(error)",
          metadata: nil,
          source: "KeychainService"
        )
        throw error
      }
    }
  }

  /**
   Deletes binary data from the keychain.

   - Parameters:
      - account: The account identifier for the data to delete
      - keychainOptions: Options for configuring keychain access

   - Throws: KeychainError if the deletion fails
   */
  public func deleteData(
    for account: String,
    keychainOptions _: KeychainOptions?=nil
  ) async throws {
    await logger.debug(
      "Deleting data for account: \(account)",
      metadata: nil,
      source: "KeychainService"
    )

    guard !account.isEmpty else {
      throw KeychainError.invalidParameter("Account identifier cannot be empty")
    }

    // Create the query
    let query: [String: Any]=[
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: serviceIdentifier,
      kSecAttrAccount as String: account
    ]

    // Delete the item
    let status=SecItemDelete(query as CFDictionary)

    if status == errSecSuccess {
      await logger.info(
        "Successfully deleted data for account: \(account)",
        metadata: nil,
        source: "KeychainService"
      )
    } else if status == errSecItemNotFound {
      await logger.warning(
        "No data found to delete for account: \(account)",
        metadata: nil,
        source: "KeychainService"
      )
      throw KeychainError.itemNotFound
    } else {
      let error=KeychainError.fromOSStatus(status)
      await logger.error(
        "Failed to delete data: \(error)",
        metadata: nil,
        source: "KeychainService"
      )
      throw error
    }
  }

  /**
   Checks if a password exists in the keychain.

   - Parameter account: The account identifier to check

   - Returns: True if a password exists for the account, false otherwise
   */
  public func passwordExists(for account: String) async -> Bool {
    await logger.debug(
      "Checking if password exists for account: \(account)",
      metadata: nil,
      source: "KeychainService"
    )

    guard !account.isEmpty else {
      return false
    }

    // Create the query
    let query: [String: Any]=[
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: serviceIdentifier,
      kSecAttrAccount as String: account,
      kSecReturnData as String: false,
      kSecMatchLimit as String: kSecMatchLimitOne
    ]

    // Execute the query
    let status=SecItemCopyMatching(query as CFDictionary, nil)
    return status == errSecSuccess
  }

  /**
   Updates an existing password in the keychain.

   - Parameters:
      - newPassword: The new password to store
      - account: The account identifier for the password

   - Throws: KeychainError if the operation fails or the password doesn't exist
   */
  public func updatePassword(_ newPassword: String, for account: String) async throws {
    await logger.debug(
      "Updating password for account: \(account)",
      metadata: nil,
      source: "KeychainService"
    )

    guard !newPassword.isEmpty else {
      throw KeychainError.invalidParameter("New password cannot be empty")
    }

    guard !account.isEmpty else {
      throw KeychainError.invalidParameter("Account identifier cannot be empty")
    }

    // Check if the password exists
    guard await passwordExists(for: account) else {
      await logger.warning(
        "Cannot update - no password exists for account: \(account)",
        metadata: nil,
        source: "KeychainService"
      )
      throw KeychainError.itemNotFound
    }

    // Convert password to data
    guard let passwordData=newPassword.data(using: .utf8) else {
      throw KeychainError.invalidDataFormat("Unable to convert password to data")
    }

    // Create the search query
    let query: [String: Any]=[
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: serviceIdentifier,
      kSecAttrAccount as String: account
    ]

    // Create the update attributes
    let attributes: [String: Any]=[
      kSecValueData as String: passwordData
    ]

    // Update the item
    let status=SecItemUpdate(query as CFDictionary, attributes as CFDictionary)

    if status == errSecSuccess {
      await logger.info(
        "Successfully updated password for account: \(account)",
        metadata: nil,
        source: "KeychainService"
      )
    } else {
      let error=KeychainError.fromOSStatus(status)
      await logger.error(
        "Failed to update password: \(error)",
        metadata: nil,
        source: "KeychainService"
      )
      throw error
    }
  }
}

// MARK: - Security Accessibility Helper

extension KeychainAccessOptions {
  /// Converts KeychainAccessOptions to the corresponding CFString constant for Security framework
  /// - Returns: The CFString accessibility constant
  func toSecurityAccessibility() -> CFString {
    if contains(.whenPasscodeSetThisDeviceOnly) {
      kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly
    } else if contains(.accessibleWhenUnlockedThisDeviceOnly) {
      kSecAttrAccessibleWhenUnlockedThisDeviceOnly
    } else if contains([.whenUnlocked, .thisDeviceOnly]) {
      kSecAttrAccessibleWhenUnlockedThisDeviceOnly
    } else if contains(.whenUnlocked) {
      kSecAttrAccessibleWhenUnlocked
    } else {
      // Default to most secure option if nothing specific is selected
      kSecAttrAccessibleWhenUnlockedThisDeviceOnly
    }
  }
}
