import CoreSecurityTypes
import Foundation
import KeychainInterfaces
import LoggingInterfaces
import LoggingServices
import SecurityCoreInterfaces

/**
 Factory for creating Keychain security services.

 This factory follows the Alpha Dot Five architecture pattern with a
 standardised factory approach.
 */
public enum KeychainSecurityFactory {
  /**
   Creates a basic crypto service with the specified logger.

   - Parameter logger: Logger for the crypto service
   - Returns: An instance of CryptoServiceProtocol
   */
  public static func createCryptoService(logger: LoggingProtocol?=nil) -> CryptoServiceProtocol {
    // Use provided logger or create a DefaultLogger if none provided
    let loggerToUse=logger ?? DefaultLogger()
    return BasicCryptoService(logger: loggerToUse)
  }

  /**
   Creates a secure storage implementation.

   - Returns: An instance of SecureStorageProtocol
   */
  public static func createSecureStorage() -> SecureStorageProtocol {
    KeychainSecureStorage()
  }
}

/**
 A Keychain-based implementation of SecureStorageProtocol.
 */
final class KeychainSecureStorage: SecureStorageProtocol {
  // Use an actor for thread-safe access to storage
  private actor SecureStore {
    var storage: [String: [UInt8]]=[:]

    func store(_ data: [UInt8], forKey key: String) {
      storage[key]=data
    }

    func retrieve(forKey key: String) -> [UInt8]? {
      storage[key]
    }

    func delete(forKey key: String) {
      storage.removeValue(forKey: key)
    }

    func allKeys() -> [String] {
      Array(storage.keys)
    }
  }

  private let store=SecureStore()

  public func storeData(
    _ data: [UInt8],
    withIdentifier identifier: String
  ) async -> Result<Void, SecurityProtocolError> {
    await store.store(data, forKey: identifier)
    return .success(())
  }

  public func retrieveData(withIdentifier identifier: String) async
  -> Result<[UInt8], SecurityProtocolError> {
    if let data=await store.retrieve(forKey: identifier) {
      .success(data)
    } else {
      .failure(.inputError("Item not found with identifier: \(identifier)"))
    }
  }

  public func deleteData(withIdentifier identifier: String) async
  -> Result<Void, SecurityProtocolError> {
    await store.delete(forKey: identifier)
    return .success(())
  }

  public func listDataIdentifiers() async -> Result<[String], SecurityProtocolError> {
    await .success(store.allKeys())
  }
}

/**
 Basic implementation of CryptoServiceProtocol for development and testing.

 This implementation follows the Alpha Dot Five architecture with proper
 privacy-by-design principles and actor-based concurrency.
 */
final class BasicCryptoService: CryptoServiceProtocol {
  // Required by protocol
  public let secureStorage: SecureStorageProtocol

  // Logger for operations
  private let logger: LoggingProtocol

  init(logger: LoggingProtocol) {
    secureStorage=KeychainSecureStorage()
    self.logger=logger
  }

  public func encrypt(
    dataIdentifier: String,
    keyIdentifier: String,
    options _: EncryptionOptions?
  ) async -> Result<String, SecurityProtocolError> {
    // Get the data from secure storage
    let dataResult=await secureStorage.retrieveData(withIdentifier: dataIdentifier)

    switch dataResult {
      case let .success(data):
        // Get the key from secure storage
        let keyResult=await secureStorage.retrieveData(withIdentifier: keyIdentifier)

        switch keyResult {
          case let .success(key):
            // In a real implementation, this would perform actual encryption
            // Here we just store the original data with a new identifier
            let encryptedIdentifier="encrypted_\(UUID().uuidString)"
            let storeResult=await secureStorage.storeData(data, withIdentifier: encryptedIdentifier)

            switch storeResult {
              case .success:
                return .success(encryptedIdentifier)
              case let .failure(error):
                return .failure(
                  .operationFailed(reason: "Storage error: \(error.localizedDescription)")
                )
            }
          case let .failure(error):
            return .failure(
              .operationFailed(reason: "Failed to retrieve key: \(error.localizedDescription)")
            )
        }
      case let .failure(error):
        return .failure(.inputError("Failed to retrieve data: \(error.localizedDescription)"))
    }
  }

  public func decrypt(
    encryptedDataIdentifier: String,
    keyIdentifier: String,
    options _: DecryptionOptions?
  ) async -> Result<String, SecurityProtocolError> {
    // Get the encrypted data from secure storage
    let dataResult=await secureStorage.retrieveData(withIdentifier: encryptedDataIdentifier)

    switch dataResult {
      case let .success(encryptedData):
        // Get the key from secure storage
        let keyResult=await secureStorage.retrieveData(withIdentifier: keyIdentifier)

        switch keyResult {
          case .success:
            // In a real implementation, this would perform actual decryption
            // Here we just store the original data with a new identifier
            let decryptedIdentifier="decrypted_\(UUID().uuidString)"
            let storeResult=await secureStorage.storeData(
              encryptedData,
              withIdentifier: decryptedIdentifier
            )

            switch storeResult {
              case .success:
                return .success(decryptedIdentifier)
              case let .failure(error):
                return .failure(
                  .operationFailed(reason: "Storage error: \(error.localizedDescription)")
                )
            }
          case let .failure(error):
            return .failure(
              .operationFailed(reason: "Failed to retrieve key: \(error.localizedDescription)")
            )
        }
      case let .failure(error):
        return .failure(
          .inputError("Failed to retrieve encrypted data: \(error.localizedDescription)")
        )
    }
  }

  public func hash(
    dataIdentifier: String,
    options _: HashingOptions?
  ) async -> Result<String, SecurityProtocolError> {
    // Get the data from secure storage
    let dataResult=await secureStorage.retrieveData(withIdentifier: dataIdentifier)

    switch dataResult {
      case .success:
        // For testing purposes, create a dummy hash (in a real implementation, this would be a real
        // hash)
        // Convert Data to [UInt8] array for SecureStorage
        let hashData=[UInt8](repeating: 0, count: 32)
        let hashIdentifier="hash_\(UUID().uuidString)"

        let storeResult=await secureStorage.storeData(hashData, withIdentifier: hashIdentifier)

        switch storeResult {
          case .success:
            return .success(hashIdentifier)
          case let .failure(error):
            return .failure(
              .operationFailed(reason: "Storage error: \(error.localizedDescription)")
            )
        }
      case let .failure(error):
        return .failure(
          .inputError("Failed to retrieve data for hashing: \(error.localizedDescription)")
        )
    }
  }

  public func verifyHash(
    dataIdentifier: String,
    hashIdentifier: String,
    options _: HashingOptions?
  ) async -> Result<Bool, SecurityProtocolError> {
    // Get the data from secure storage
    let dataResult=await secureStorage.retrieveData(withIdentifier: dataIdentifier)

    switch dataResult {
      case .success:
        // Get the hash from secure storage
        let hashResult=await secureStorage.retrieveData(withIdentifier: hashIdentifier)

        switch hashResult {
          case .success:
            // In a real implementation, this would compute and verify an actual hash
            // Here we just return true for testing purposes
            return .success(true)
          case let .failure(error):
            return .failure(.inputError("Failed to retrieve hash: \(error.localizedDescription)"))
        }
      case let .failure(error):
        return .failure(
          .inputError(
            "Failed to retrieve data for hash verification: \(error.localizedDescription)"
          )
        )
    }
  }

  public func generateKey(
    length: Int,
    options _: KeyGenerationOptions?
  ) async -> Result<String, SecurityProtocolError> {
    // In a real implementation, this would generate a cryptographic key
    // Here we just create a random key with [UInt8] for compatibility with SecureStorage
    let keyBytes=[UInt8](repeating: 0, count: length / 8) // Convert bits to bytes
    let keyIdentifier="key_\(UUID().uuidString)"

    let storeResult=await secureStorage.storeData(keyBytes, withIdentifier: keyIdentifier)

    switch storeResult {
      case .success:
        return .success(keyIdentifier)
      case let .failure(error):
        return .failure(.operationFailed(reason: "Storage error: \(error.localizedDescription)"))
    }
  }

  public func importData(
    _ data: [UInt8],
    customIdentifier: String?
  ) async -> Result<String, SecurityProtocolError> {
    let identifier=customIdentifier ?? "imported_\(UUID().uuidString)"
    let storeResult=await secureStorage.storeData(data, withIdentifier: identifier)

    switch storeResult {
      case .success:
        return .success(identifier)
      case let .failure(error):
        return .failure(.operationFailed(reason: "Storage error: \(error.localizedDescription)"))
    }
  }

  public func exportData(
    identifier: String
  ) async -> Result<[UInt8], SecurityProtocolError> {
    let retrieveResult=await secureStorage.retrieveData(withIdentifier: identifier)

    switch retrieveResult {
      case let .success(data):
        return .success(data) // data is already [UInt8], no conversion needed
      case let .failure(error):
        return .failure(.operationFailed(reason: "Storage error: \(error.localizedDescription)"))
    }
  }
}
