import ErrorHandlingDomains
import Foundation
import SecurityProtocolsCore
import UmbraCoreTypes

/// In-memory implementation of KeyManagementProtocol
/// This is a basic implementation that stores keys in memory for demonstration purposes
/// In a real implementation, keys would be stored securely in a platform-specific secure storage
public actor KeyManagementImpl: KeyManagementProtocol {
  // MARK: - Properties

  /// Storage provider for secure key storage
  private let secureStorage: SecureStorageProtocol?

  /// In-memory storage of keys (used as fallback when secureStorage is nil)
  private var keyStore: [String: SecureBytes]=[:]

  // MARK: - Initialization

  /// Initialize with a specific secure storage implementation
  /// - Parameter secureStorage: Implementation of SecureStorageProtocol
  public init(secureStorage: SecureStorageProtocol?=nil) {
    self.secureStorage=secureStorage
  }

  // MARK: - KeyManagementProtocol Implementation

  public func retrieveKey(withIdentifier identifier: String) async
  -> Result<SecureBytes, UmbraErrors.Security.Protocols> {
    // If secure storage is available, use it
    if let secureStorage {
      let result=await secureStorage.retrieveSecurely(identifier: identifier)
      switch result {
        case let .success(data):
          return .success(data)
        case let .failure(error):
          switch error {
            case .keyNotFound:
              return .failure(.invalidInput("Key not found: \(identifier)"))
            default:
              return .failure(.storageOperationFailed("Storage error: \(error)"))
          }
        @unknown default:
          return .failure(.internalError("Unknown storage result"))
      }
    }

    // Fallback to in-memory storage
    guard let key=keyStore[identifier] else {
      return .failure(.invalidInput("Key not found: \(identifier)"))
    }
    return .success(key)
  }

  public func storeKey(
    _ key: SecureBytes,
    withIdentifier identifier: String
  ) async -> Result<Void, UmbraErrors.Security.Protocols> {
    // If secure storage is available, use it
    if let secureStorage {
      let result=await secureStorage.storeSecurely(data: key, identifier: identifier)
      switch result {
        case .success:
          return .success(())
        case let .failure(error):
          return .failure(.storageOperationFailed("Storage error: \(error)"))
        @unknown default:
          return .failure(.internalError("Unknown storage result"))
      }
    }

    // Fallback to in-memory storage
    keyStore[identifier]=key
    return .success(())
  }

  public func deleteKey(withIdentifier identifier: String) async
  -> Result<Void, UmbraErrors.Security.Protocols> {
    // If secure storage is available, use it
    if let secureStorage {
      let result=await secureStorage.deleteSecurely(identifier: identifier)
      switch result {
        case .success:
          return .success(())
        case let .failure(error):
          switch error {
            case .keyNotFound:
              return .failure(.invalidInput("Key not found: \(identifier)"))
            default:
              return .failure(.storageOperationFailed("Storage error: \(error)"))
          }
        @unknown default:
          return .failure(.internalError("Unknown deletion result"))
      }
    }

    // Fallback to in-memory storage
    guard keyStore[identifier] != nil else {
      return .failure(.invalidInput("Key not found: \(identifier)"))
    }

    keyStore.removeValue(forKey: identifier)
    return .success(())
  }

  /// Rotates a security key, creating a new key and optionally re-encrypting data.
  /// - Parameters:
  ///   - identifier: A string identifying the key to rotate.
  ///   - dataToReencrypt: Optional data to re-encrypt with the new key.
  /// - Returns: The new key and re-encrypted data (if provided) or an error.
  public func rotateKey(
    withIdentifier identifier: String,
    dataToReencrypt: SecureBytes?
  ) async -> Result<(
    newKey: SecureBytes,
    reencryptedData: SecureBytes?
  ), UmbraErrors.Security.Protocols> {
    // Retrieve the old key
    let oldKeyResult=await retrieveKey(withIdentifier: identifier)
    guard case let .success(oldKey)=oldKeyResult else {
      if case let .failure(error)=oldKeyResult {
        return .failure(error)
      }
      return .failure(.invalidInput("Failed to retrieve old key"))
    }

    do {
      // Generate a new key
      let keyResult=await KeyGenerator().generateKey(
        bits: 256,
        keyType: .symmetric,
        purpose: .encryption
      )
      guard case let .success(newKey)=keyResult else {
        if case let .failure(error)=keyResult {
          return .failure(error)
        }
        return .failure(.internalError("Unknown key generation error"))
      }

      // Re-encrypt data if provided
      var reencryptedData: SecureBytes?
      if let existingCiphertext=dataToReencrypt {
        // First decrypt with old key
        let cryptoService=CryptoServiceCore()
        let decryptResult=await cryptoService.decryptSymmetric(
          data: existingCiphertext,
          key: oldKey,
          config: SecurityConfigDTO(algorithm: "AES-GCM", keySizeInBits: 256)
        )
        guard case let .success(decryptedData)=decryptResult else {
          if case let .failure(error)=decryptResult {
            return .failure(error)
          }
          return .failure(.decryptionFailed("Failed to decrypt with old key"))
        }

        // Then encrypt with new key
        let encryptResult=await cryptoService.encryptSymmetric(
          data: decryptedData,
          key: newKey,
          config: SecurityConfigDTO(algorithm: "AES-GCM", keySizeInBits: 256)
        )
        guard case let .success(encryptedData)=encryptResult else {
          if case let .failure(error)=encryptResult {
            return .failure(error)
          }
          return .failure(.encryptionFailed("Failed to encrypt with new key"))
        }

        reencryptedData=encryptedData
      }

      // Store the new key
      let storeResult=await storeKey(newKey, withIdentifier: identifier)
      guard case .success=storeResult else {
        if case let .failure(error)=storeResult {
          return .failure(error)
        }
        return .failure(.storageOperationFailed("Failed to store new key"))
      }

      return .success((newKey: newKey, reencryptedData: reencryptedData))
    } catch {
      return .failure(.internalError("Key rotation failed: \(error)"))
    }
  }

  public func listKeyIdentifiers() async -> Result<[String], UmbraErrors.Security.Protocols> {
    // If secure storage is available, it should provide a way to list keys
    // For now, we'll just return the in-memory keys
    .success(Array(keyStore.keys))
  }
}
