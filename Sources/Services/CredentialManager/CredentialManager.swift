import Foundation
import Security

/// Service for managing credentials in the keychain
public actor CredentialManager {
  /// Shared instance of the credential manager
  public static let shared = CredentialManager()

  private init() {}

  /// Store a credential in the keychain
  /// - Parameters:
  ///   - credential: The credential to store
  ///   - service: The service identifier
  ///   - account: The account identifier
  public func store(_ credential: Data, service: String, account: String) throws {
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service,
      kSecAttrAccount as String: account,
      kSecValueData as String: credential
    ]

    let status = SecItemAdd(query as CFDictionary, nil)
    guard status == errSecSuccess else {
      throw CredentialError.storeFailed(status)
    }
  }

  /// Retrieve a credential from the keychain
  /// - Parameters:
  ///   - service: The service identifier
  ///   - account: The account identifier
  /// - Returns: The stored credential
  public func retrieve(service: String, account: String) throws -> Data {
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service,
      kSecAttrAccount as String: account,
      kSecReturnData as String: true
    ]

    var result: AnyObject?
    let status = SecItemCopyMatching(query as CFDictionary, &result)

    guard status == errSecSuccess else {
      throw CredentialError.retrieveFailed(status)
    }

    guard let data = result as? Data else {
      throw CredentialError.invalidData
    }

    return data
  }

  /// Delete a credential from the keychain
  /// - Parameters:
  ///   - service: The service identifier
  ///   - account: The account identifier
  public func delete(service: String, account: String) throws {
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service,
      kSecAttrAccount as String: account
    ]

    let status = SecItemDelete(query as CFDictionary)
    guard status == errSecSuccess else {
      throw CredentialError.deleteFailed(status)
    }
  }
}

/// Errors that can occur during credential operations
public enum CredentialError: LocalizedError {
  /// Failed to store the credential
  case storeFailed(OSStatus)
  /// Failed to retrieve the credential
  case retrieveFailed(OSStatus)
  /// Failed to delete the credential
  case deleteFailed(OSStatus)
  /// The credential data is invalid
  case invalidData

  public var errorDescription: String? {
    switch self {
      case let .storeFailed(status):
        "Failed to store credential: \(status)"
      case let .retrieveFailed(status):
        "Failed to retrieve credential: \(status)"
      case let .deleteFailed(status):
        "Failed to delete credential: \(status)"
      case .invalidData:
        "Invalid credential data"
    }
  }
}
