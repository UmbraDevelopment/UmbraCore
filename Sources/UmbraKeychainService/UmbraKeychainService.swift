/// UmbraKeychainService Module
///
/// Provides secure keychain access and management for UmbraCore.
/// This module handles all interactions with the macOS Keychain,
/// ensuring secure credential storage and retrieval.
///
/// # Key Features
/// - Secure credential storage
/// - Access control
/// - Keychain management
/// - Migration support
///
/// # Module Organisation
///
/// ## Core Types
/// ```swift
/// KeychainService
/// KeychainItem
/// AccessControl
/// ```
///
/// ## Operations
/// ```swift
/// ItemStorage
/// ItemRetrieval
/// ItemUpdate
/// ```
///
/// ## Security
/// ```swift
/// AccessPolicy
/// SecurityLevel
/// AuthContext
/// ```
///
/// # Keychain Operations
///
/// ## Storage
/// Secure item storage:
/// - Password storage
/// - Certificate storage
/// - Key storage
///
/// ## Retrieval
/// Secure item retrieval:
/// - Credential fetch
/// - Certificate fetch
/// - Key access
///
/// # Access Control
///
/// Access control provides:
/// - User prompt management
/// - Privilege escalation
/// - Permissions handling
///
/// # Integration
///
/// Integration with other modules:
/// - Core integration
/// - Security interface implementation
/// - Credential management
///
/// # Error Handling
///
/// Error handling strategy:
/// - Specific error types
/// - Recovery suggestions
/// - User-facing messages
///
/// # Usage
///
/// ```swift
/// let service = UmbraKeychainService(identifier: "com.umbra.app")
///
/// // Store a password
/// try service.storePassword("SecurePassword123", for: "user@example.com")
///
/// // Retrieve a password
/// let password = try service.retrievePassword(for: "user@example.com")
///
/// // Delete a password
/// try service.deletePassword(for: "user@example.com")
/// ```
///
/// # Security Best Practices
///
/// Follow these best practices:
/// - Use strong, unique identifiers
/// - Handle errors appropriately
/// - Clean up keychain items when no longer needed
/// - Use appropriate access control
///
import Foundation
import SecurityTypes
import SecurityUtils
import UmbraLogging

/// UmbraKeychainService provides a simplified interface for storing and retrieving
/// secure credentials in the system keychain.
public final class UmbraKeychainService: @unchecked Sendable {
  /// Current version of the UmbraKeychainService module
  public static let version="1.0.0"

  /// Service identifier used for keychain items
  public let identifier: String

  /// Logger instance for capturing keychain operations (without sensitive data)
  private let logger: LoggingProtocol

  /// Initialize a keychain service with the given identifier
  /// - Parameter identifier: Service identifier used for keychain items
  public init(identifier: String) {
    self.identifier=identifier
    logger=UmbraLogging.createLogger()
    Task {
      await logger.debug(
        "Initialized UmbraKeychainService with identifier: \(identifier)",
        metadata: nil
      )
    }
  }

  /// Store a password in the keychain
  /// - Parameters:
  ///   - password: Password to store
  ///   - account: Account identifier
  /// - Throws: KeychainError if storage fails
  public func storePassword(_ password: String, for account: String) throws {
    guard let passwordData=password.data(using: .utf8) else {
      Task {
        await logger.error("Failed to convert password to data", metadata: nil)
      }
      throw KeychainError.itemEncodingFailed
    }

    Task {
      await logger.debug("Storing password for account: \(account)", metadata: nil)
    }

    let query: [String: Any]=[
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: identifier,
      kSecAttrAccount as String: account,
      kSecValueData as String: passwordData
    ]

    // Check if item already exists
    var existingItem: CFTypeRef?
    let checkStatus=SecItemCopyMatching([
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: identifier,
      kSecAttrAccount as String: account,
      kSecReturnData as String: false
    ] as CFDictionary, &existingItem)

    if checkStatus == errSecSuccess {
      // Item exists, update it
      let updateStatus=SecItemUpdate([
        kSecClass as String: kSecClassGenericPassword,
        kSecAttrService as String: identifier,
        kSecAttrAccount as String: account
      ] as CFDictionary, [
        kSecValueData as String: passwordData
      ] as CFDictionary)

      guard updateStatus == errSecSuccess else {
        Task {
          await logger.error("Failed to update existing password: \(updateStatus)", metadata: nil)
        }
        throw KeychainError.storeFailed(
          "Failed to update password: \(updateStatus)"
        )
      }

      Task {
        await logger.debug("Updated existing password for account: \(account)", metadata: nil)
      }
      return
    } else if checkStatus != errSecItemNotFound {
      Task {
        await logger.error(
          "Unexpected error checking for existing item: \(checkStatus)",
          metadata: nil
        )
      }
    }

    let status=SecItemAdd(query as CFDictionary, nil)
    guard status == errSecSuccess else {
      Task {
        await logger.error("Failed to store password: \(status)", metadata: nil)
      }
      throw KeychainError.storeFailed(
        "Failed to store password: \(status)"
      )
    }

    Task {
      await logger.debug("Stored new password for account: \(account)", metadata: nil)
    }
  }

  /// Retrieve a password from the keychain
  /// - Parameter account: Account identifier
  /// - Returns: Retrieved password
  /// - Throws: KeychainError if retrieval fails
  public func retrievePassword(for account: String) throws -> String {
    let query: [String: Any]=[
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: identifier,
      kSecAttrAccount as String: account,
      kSecReturnData as String: true
    ]

    var item: CFTypeRef?
    let status=SecItemCopyMatching(query as CFDictionary, &item)

    guard
      status == errSecSuccess,
      let data=item as? Data,
      let password=String(data: data, encoding: .utf8)
    else {
      Task {
        await logger.error("Failed to retrieve password: \(status)", metadata: nil)
      }
      throw KeychainError.retrieveFailed(
        "Failed to retrieve password: \(status)"
      )
    }

    Task {
      await logger.debug("Retrieved password for account: \(account)", metadata: nil)
    }
    return password
  }

  /// Delete a password from the keychain
  /// - Parameter account: Account identifier
  /// - Throws: KeychainError if deletion fails
  public func deletePassword(for account: String) throws {
    let query: [String: Any]=[
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: identifier,
      kSecAttrAccount as String: account
    ]

    let status=SecItemDelete(query as CFDictionary)
    guard status == errSecSuccess else {
      Task {
        await logger.error("Failed to delete password: \(status)", metadata: nil)
      }
      throw KeychainError.deleteFailed(
        "Failed to delete password: \(status)"
      )
    }

    Task {
      await logger.debug("Deleted password for account: \(account)", metadata: nil)
    }
  }
}
