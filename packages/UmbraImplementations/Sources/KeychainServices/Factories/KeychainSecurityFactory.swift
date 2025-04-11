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
actor KeychainSecureStorage: SecureStorageProtocol {
  // Dictionary for storing data, simulating keychain storage
  private var storage: [String: [UInt8]]=[:]

  public func storeData(
    _ data: [UInt8],
    withIdentifier identifier: String
  ) async -> Result<Void, SecurityStorageError> {
    storage[identifier]=data
    return .success(())
  }

  public func retrieveData(withIdentifier identifier: String) async
  -> Result<[UInt8], SecurityStorageError> {
    if let data=storage[identifier] {
      .success(data)
    } else {
      .failure(.dataNotFound)
    }
  }

  public func deleteData(withIdentifier identifier: String) async
  -> Result<Void, SecurityStorageError> {
    storage.removeValue(forKey: identifier)
    return .success(())
  }

  public func listDataIdentifiers() async -> Result<[String], SecurityStorageError> {
    .success(Array(storage.keys))
  }
}

/**
 Basic implementation of CryptoServiceProtocol for development and testing.

 This implementation follows the Alpha Dot Five architecture with proper
 privacy-by-design principles and actor-based concurrency.
 */
actor BasicCryptoService: CryptoServiceProtocol {
  // Required by protocol
  public nonisolated let secureStorage: SecureStorageProtocol

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
  ) async -> Result<String, SecurityStorageError> {
    // Get the data from secure storage
    let dataResult=await secureStorage.retrieveData(withIdentifier: dataIdentifier)

    switch dataResult {
      case let .success(data):
        // Attempt to retrieve the key
        let keyResult=await secureStorage.retrieveData(withIdentifier: keyIdentifier)

        switch keyResult {
          case .success:
            // In a real implementation, this would perform actual encryption
            // Here we just store the original data with a new identifier
            let encryptedIdentifier="encrypted-\(dataIdentifier)"
            // Store the "encrypted" data back
            _=await secureStorage.storeData(data, withIdentifier: encryptedIdentifier)
            return .success(encryptedIdentifier)

          case .failure:
            await logger.warning(
              "Key not found for encryption: \(keyIdentifier)",
              context: KeychainLogContext(
                account: dataIdentifier,
                operation: "encrypt"
              )
            )
            return .failure(.keyNotFound)
        }

      case .failure:
        await logger.warning(
          "Data not found for encryption: \(dataIdentifier)",
          context: KeychainLogContext(
            account: dataIdentifier,
            operation: "encrypt"
          )
        )
        return .failure(.dataNotFound)
    }
  }

  public func decrypt(
    encryptedDataIdentifier: String,
    keyIdentifier: String,
    options _: DecryptionOptions?
  ) async -> Result<String, SecurityStorageError> {
    // Get the data from secure storage
    let dataResult=await secureStorage.retrieveData(withIdentifier: encryptedDataIdentifier)

    switch dataResult {
      case let .success(data):
        // Attempt to retrieve the key
        let keyResult=await secureStorage.retrieveData(withIdentifier: keyIdentifier)

        switch keyResult {
          case .success:
            // In a real implementation, this would perform actual decryption
            // Here we just store the original data with a new identifier
            let decryptedIdentifier="decrypted-\(encryptedDataIdentifier)"
            // Store the "decrypted" data back
            _=await secureStorage.storeData(data, withIdentifier: decryptedIdentifier)
            return .success(decryptedIdentifier)

          case .failure:
            await logger.warning(
              "Key not found for decryption: \(keyIdentifier)",
              context: KeychainLogContext(
                account: encryptedDataIdentifier,
                operation: "decrypt"
              )
            )
            return .failure(.keyNotFound)
        }

      case .failure:
        await logger.warning(
          "Data not found for decryption: \(encryptedDataIdentifier)",
          context: KeychainLogContext(
            account: encryptedDataIdentifier,
            operation: "decrypt"
          )
        )
        return .failure(.dataNotFound)
    }
  }

  public func hash(
    dataIdentifier: String,
    options _: CoreSecurityTypes.HashingOptions?
  ) async -> Result<String, SecurityStorageError> {
    // Get the data from secure storage
    let dataResult=await secureStorage.retrieveData(withIdentifier: dataIdentifier)

    switch dataResult {
      case .success:
        // In a real implementation, this would perform actual hashing
        // Here we just store a placeholder "hash" value
        let hashedIdentifier="hashed-\(dataIdentifier)"
        let hashValue: [UInt8]=Array(repeating: 0, count: 32) // Mock 32-byte hash
        _=await secureStorage.storeData(hashValue, withIdentifier: hashedIdentifier)
        return .success(hashedIdentifier)

      case .failure:
        await logger.warning(
          "Data not found for hashing: \(dataIdentifier)",
          context: KeychainLogContext(
            account: dataIdentifier,
            operation: "hash"
          )
        )
        return .failure(.dataNotFound)
    }
  }

  public func verifyHash(
    dataIdentifier: String,
    hashIdentifier: String,
    options _: CoreSecurityTypes.HashingOptions?
  ) async -> Result<Bool, SecurityStorageError> {
    // Get the data from secure storage
    let dataResult=await secureStorage.retrieveData(withIdentifier: dataIdentifier)

    switch dataResult {
      case .success:
        // Get the hash from secure storage
        let hashResult=await secureStorage.retrieveData(withIdentifier: hashIdentifier)

        switch hashResult {
          case .success:
            // In a real implementation, this would perform actual hash verification
            // Here we just return true as a simple mock
            return .success(true)

          case .failure:
            await logger.warning(
              "Hash not found for verification: \(hashIdentifier)",
              context: KeychainLogContext(
                account: dataIdentifier,
                operation: "verifyHash"
              )
            )
            return .failure(.hashNotFound)
        }

      case .failure:
        await logger.warning(
          "Data not found for hash verification: \(dataIdentifier)",
          context: KeychainLogContext(
            account: dataIdentifier,
            operation: "verifyHash"
          )
        )
        return .failure(.dataNotFound)
    }
  }

  public func generateKey(
    length: Int,
    options _: CoreSecurityTypes.KeyGenerationOptions?
  ) async -> Result<String, SecurityStorageError> {
    // In a real implementation, this would generate a secure random key
    // Here we just create a placeholder key
    let keyData: [UInt8]=Array(repeating: 0, count: length)
    let keyIdentifier="key-\(UUID().uuidString)"
    let storeResult=await secureStorage.storeData(keyData, withIdentifier: keyIdentifier)

    switch storeResult {
      case .success:
        return .success(keyIdentifier)
      case let .failure(error):
        await logger.warning(
          "Failed to generate key: \(error)",
          context: KeychainLogContext(
            account: keyIdentifier,
            operation: "generateKey"
          )
        )
        return .failure(error)
    }
  }

  public func importData(
    _ data: [UInt8],
    customIdentifier: String?
  ) async -> Result<String, SecurityStorageError> {
    let identifier=customIdentifier ?? "imported-\(UUID().uuidString)"
    let storeResult=await secureStorage.storeData(data, withIdentifier: identifier)

    switch storeResult {
      case .success:
        return .success(identifier)
      case let .failure(error):
        await logger.warning(
          "Failed to import data: \(error)",
          context: KeychainLogContext(
            account: identifier,
            operation: "importData"
          )
        )
        return .failure(error)
    }
  }

  public func exportData(
    identifier: String
  ) async -> Result<[UInt8], SecurityStorageError> {
    await secureStorage.retrieveData(withIdentifier: identifier)
  }

  // MARK: - CryptoServiceProtocol Implementation (Data-based methods)

  /// Required by CryptoServiceProtocol - Generate hash from data identifier
  public func generateHash(
    dataIdentifier: String,
    options _: CoreSecurityTypes.HashingOptions?
  ) async -> Result<String, SecurityStorageError> {
    // This is a simplified implementation that just prefixes the identifier
    let hashIdentifier="hash-\(dataIdentifier)"

    await logger.debug(
      "Generated hash identifier: \(hashIdentifier)",
      context: KeychainLogContext(
        account: dataIdentifier,
        operation: "generateHash"
      )
    )

    return .success(hashIdentifier)
  }

  /// Required by CryptoServiceProtocol - Store Data
  public func storeData(
    data: Data,
    identifier: String
  ) async -> Result<Void, SecurityStorageError> {
    // Convert Data to [UInt8] for internal storage
    let bytes=[UInt8](data)
    return await secureStorage.storeData(bytes, withIdentifier: identifier)
  }

  /// Required by CryptoServiceProtocol - Retrieve Data
  public func retrieveData(
    identifier: String
  ) async -> Result<Data, SecurityStorageError> {
    // Retrieve as [UInt8] and convert to Data
    let result=await secureStorage.retrieveData(withIdentifier: identifier)

    switch result {
      case let .success(bytes):
        return .success(Data(bytes))
      case let .failure(error):
        return .failure(error)
    }
  }

  /// Required by CryptoServiceProtocol - Delete Data
  public func deleteData(
    identifier: String
  ) async -> Result<Void, SecurityStorageError> {
    await secureStorage.deleteData(withIdentifier: identifier)
  }

  /// Required by CryptoServiceProtocol - Import Data
  public func importData(
    _ data: Data,
    customIdentifier: String
  ) async -> Result<String, SecurityStorageError> {
    // Convert Data to [UInt8] for internal storage
    let bytes=[UInt8](data)
    let identifier=customIdentifier
    let storeResult=await secureStorage.storeData(bytes, withIdentifier: identifier)

    switch storeResult {
      case .success:
        return .success(identifier)
      case let .failure(error):
        await logger.warning(
          "Failed to import data: \(error)",
          context: KeychainLogContext(
            account: identifier,
            operation: "importData_data"
          )
        )
        return .failure(error)
    }
  }
}
