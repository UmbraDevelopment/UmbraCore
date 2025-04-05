import CryptoInterfaces
import SecurityCoreInterfaces
import CryptoTypes
import CoreSecurityTypes
import DomainSecurityTypes
import Foundation
import LoggingInterfaces
import UmbraErrors

/**
 Mock implementation of CryptoServiceProtocol for testing.
 
 This implementation provides configurable success/failure responses for operations,
 making it useful for unit testing components that depend on CryptoServiceProtocol.
 */
public actor MockCryptoServiceImpl: CryptoServiceProtocol {
  /// Configuration options for the mock
  public struct Configuration: Sendable {
    /// Whether encryption operations should succeed
    public let encryptionSucceeds: Bool
    
    /// Whether decryption operations should succeed
    public let decryptionSucceeds: Bool
    
    /// Whether hashing operations should succeed
    public let hashingSucceeds: Bool
    
    /// Whether hash verification operations should succeed
    public let verificationSucceeds: Bool
    
    /// Result to return for hash verification
    public let hashVerificationResult: Bool
    
    /// Whether key generation operations should succeed
    public let keyGenerationSucceeds: Bool
    
    /// Whether storage operations should succeed
    public let storageSucceeds: Bool
    
    /// Whether retrieval operations should succeed
    public let retrievalSucceeds: Bool
    
    /// Whether deletion operations should succeed
    public let deletionSucceeds: Bool
    
    /// Creates a new configuration with the specified options
    public init(
      encryptionSucceeds: Bool = true,
      decryptionSucceeds: Bool = true,
      hashingSucceeds: Bool = true,
      verificationSucceeds: Bool = true,
      hashVerificationResult: Bool = true,
      keyGenerationSucceeds: Bool = true,
      storageSucceeds: Bool = true,
      retrievalSucceeds: Bool = true,
      deletionSucceeds: Bool = true
    ) {
      self.encryptionSucceeds = encryptionSucceeds
      self.decryptionSucceeds = decryptionSucceeds
      self.hashingSucceeds = hashingSucceeds
      self.verificationSucceeds = verificationSucceeds
      self.hashVerificationResult = hashVerificationResult
      self.keyGenerationSucceeds = keyGenerationSucceeds
      self.storageSucceeds = storageSucceeds
      self.retrievalSucceeds = retrievalSucceeds
      self.deletionSucceeds = deletionSucceeds
    }
  }
  
  /// The mock configuration
  private let configuration: Configuration
  
  /// The logger to use
  private let logger: LoggingProtocol
  
  /// In-memory storage for mock operations
  private var storage: [String: [UInt8]] = [:]
  
  /// Required by the CryptoServiceProtocol
  public nonisolated let secureStorage: SecureStorageProtocol
  
  /**
   Initialises a new mock crypto service.
   
   - Parameters:
     - configuration: The configuration to use
     - logger: The logger to use
   */
  public init(
    configuration: Configuration = Configuration(),
    logger: LoggingProtocol,
    secureStorage: SecureStorageProtocol = InMemorySecureStorage()
  ) {
    self.configuration = configuration
    self.logger = logger
    self.secureStorage = secureStorage
  }
  
  // MARK: - CryptoServiceProtocol Methods
  
  public func encrypt(
    dataIdentifier: String,
    keyIdentifier: String,
    options: SecurityCoreInterfaces.EncryptionOptions?
  ) async -> Result<String, SecurityStorageError> {
    await logger.debug(
      "Mock encrypt operation with dataIdentifier: \(dataIdentifier), keyIdentifier: \(keyIdentifier)",
      metadata: LogMetadataDTOCollection().toPrivacyMetadata(),
      source: "MockCryptoService"
    )
    
    // Retrieve data
    let dataResult = await secureStorage.retrieveData(withIdentifier: dataIdentifier)
    
    guard case let .success(data) = dataResult else {
      return .failure(.keyNotFound)
    }
    
    if configuration.encryptionSucceeds {
      let identifier = "encrypted_\(UUID().uuidString)"
      await secureStorage.storeData(data, withIdentifier: identifier)
      return .success(identifier)
    } else {
      return .failure(.operationFailed("Mock encryption failure"))
    }
  }
  
  // Special version for the data-based API
  public func encrypt(
    data: [UInt8],
    keyIdentifier: String,
    options: UEncryptionOptions?
  ) async -> Result<String, SecurityStorageError> {
    await logger.debug(
      "Mock encrypt operation with data, keyIdentifier: \(keyIdentifier)",
      metadata: LogMetadataDTOCollection().toPrivacyMetadata(),
      source: "MockCryptoService"
    )
    
    if configuration.encryptionSucceeds {
      let identifier = "encrypted_\(UUID().uuidString)"
      storage[identifier] = data
      return .success(identifier)
    } else {
      return .failure(.operationFailed("Mock encryption failure"))
    }
  }
  
  public func decrypt(
    encryptedDataIdentifier: String,
    keyIdentifier: String,
    options: SecurityCoreInterfaces.DecryptionOptions?
  ) async -> Result<String, SecurityStorageError> {
    await logger.debug(
      "Mock decrypt operation with encryptedDataIdentifier: \(encryptedDataIdentifier), keyIdentifier: \(keyIdentifier)",
      metadata: LogMetadataDTOCollection().toPrivacyMetadata(),
      source: "MockCryptoService"
    )
    
    if configuration.decryptionSucceeds {
      let decryptedId = "decrypted_\(UUID().uuidString)"
      let mockData: [UInt8] = [0x01, 0x02, 0x03, 0x04]
      await secureStorage.storeData(mockData, withIdentifier: decryptedId)
      return .success(decryptedId)
    } else {
      return .failure(.operationFailed("Mock decryption failure"))
    }
  }
  
  // Special version for the data-based API
  public func decrypt(
    encryptedDataIdentifier: String,
    keyIdentifier: String,
    options: UDecryptionOptions?
  ) async -> Result<[UInt8], SecurityStorageError> {
    await logger.debug(
      "Mock decrypt operation with encryptedDataIdentifier: \(encryptedDataIdentifier), keyIdentifier: \(keyIdentifier)",
      metadata: LogMetadataDTOCollection().toPrivacyMetadata(),
      source: "MockCryptoService"
    )
    
    if configuration.decryptionSucceeds {
      if let data = storage[encryptedDataIdentifier] {
        return .success(data)
      } else {
        return .failure(.keyNotFound)
      }
    } else {
      return .failure(.operationFailed("Mock decryption failure"))
    }
  }
  
  public func hash(
    dataIdentifier: String,
    options: SecurityCoreInterfaces.HashingOptions?
  ) async -> Result<String, SecurityStorageError> {
    await logger.debug(
      "Mock hash operation with dataIdentifier: \(dataIdentifier)",
      metadata: LogMetadataDTOCollection().toPrivacyMetadata(),
      source: "MockCryptoService"
    )
    
    if configuration.hashingSucceeds {
      let identifier = "hash_\(UUID().uuidString)"
      await secureStorage.storeData([0x01, 0x02, 0x03, 0x04], withIdentifier: identifier)
      return .success(identifier)
    } else {
      return .failure(.operationFailed("Mock hash generation failure"))
    }
  }
  
  // Special version for the data-based API
  public func hash(
    data: [UInt8],
    options: CoreSecurityTypes.HashAlgorithm = .sha256
  ) async -> Result<String, SecurityStorageError> {
    await logger.debug(
      "Mock hash operation with data",
      metadata: LogMetadataDTOCollection().toPrivacyMetadata(),
      source: "MockCryptoService"
    )
    
    if configuration.hashingSucceeds {
      let identifier = "hash_\(UUID().uuidString)"
      storage[identifier] = data
      return .success(identifier)
    } else {
      return .failure(.operationFailed("Mock hash generation failure"))
    }
  }
  
  public func verifyHash(
    dataIdentifier: String, 
    hashIdentifier: String,
    options: SecurityCoreInterfaces.HashingOptions?
  ) async -> Result<Bool, SecurityStorageError> {
    await logger.debug(
      "Mock verifyHash operation with dataIdentifier: \(dataIdentifier), hashIdentifier: \(hashIdentifier)",
      metadata: LogMetadataDTOCollection().toPrivacyMetadata(),
      source: "MockCryptoService"
    )
    
    if configuration.verificationSucceeds {
      return .success(configuration.hashVerificationResult)
    } else {
      return .failure(.operationFailed("Mock hash verification failure"))
    }
  }
  
  // Special version for the data-based API
  public func verifyHash(
    data: [UInt8], 
    againstHash: [UInt8],
    options: CoreSecurityTypes.HashAlgorithm = .sha256
  ) async -> Result<Bool, SecurityStorageError> {
    await logger.debug(
      "Mock verifyHash operation with data and hash",
      metadata: LogMetadataDTOCollection().toPrivacyMetadata(),
      source: "MockCryptoService"
    )
    
    if configuration.verificationSucceeds {
      return .success(configuration.hashVerificationResult)
    } else {
      return .failure(.operationFailed("Mock hash verification failure"))
    }
  }
  
  public func generateKey(
    length: Int,
    options: SecurityCoreInterfaces.KeyGenerationOptions?
  ) async -> Result<String, SecurityStorageError> {
    await logger.debug(
      "Mock generateKey operation with length: \(length)",
      metadata: LogMetadataDTOCollection().toPrivacyMetadata(),
      source: "MockCryptoService"
    )
    
    if configuration.keyGenerationSucceeds {
      let keyData: [UInt8] = Array(repeating: 0x42, count: length)
      let keyId = "key_\(UUID().uuidString)"
      await secureStorage.storeData(keyData, withIdentifier: keyId)
      return .success(keyId)
    } else {
      return .failure(.operationFailed("Mock key generation failure"))
    }
  }
  
  public func importData(
    _ data: [UInt8], 
    identifier: String
  ) async -> Result<String, SecurityStorageError> {
    await logger.debug(
      "Mock importData operation with identifier: \(identifier)",
      metadata: LogMetadataDTOCollection().toPrivacyMetadata(),
      source: "MockCryptoService"
    )
    
    if configuration.storageSucceeds {
      await secureStorage.storeData(data, withIdentifier: identifier)
      return .success(identifier)
    } else {
      return .failure(.operationFailed("Mock import failure"))
    }
  }
  
  public func storeData(
    _ data: [UInt8], 
    withIdentifier identifier: String
  ) async -> Result<Bool, SecurityStorageError> {
    await logger.debug(
      "Mock storeData operation with identifier: \(identifier)",
      metadata: LogMetadataDTOCollection().toPrivacyMetadata(),
      source: "MockCryptoService"
    )
    
    if configuration.storageSucceeds {
      await secureStorage.storeData(data, withIdentifier: identifier)
      return .success(true)
    } else {
      return .failure(.operationFailed("Mock storage failure"))
    }
  }
  
  public func retrieveData(
    withIdentifier identifier: String
  ) async -> Result<[UInt8], SecurityStorageError> {
    await logger.debug(
      "Mock retrieveData operation with identifier: \(identifier)",
      metadata: LogMetadataDTOCollection().toPrivacyMetadata(),
      source: "MockCryptoService"
    )
    
    if configuration.retrievalSucceeds {
      if let data = storage[identifier] {
        return .success(data)
      } else {
        return await secureStorage.retrieveData(withIdentifier: identifier)
      }
    } else {
      return .failure(.operationFailed("Mock retrieval failure"))
    }
  }
  
  public func exportData(
    identifier: String
  ) async -> Result<[UInt8], SecurityStorageError> {
    await retrieveData(withIdentifier: identifier)
  }
  
  public func deleteData(
    withIdentifier identifier: String
  ) async -> Result<Bool, SecurityStorageError> {
    await logger.debug(
      "Mock deleteData operation with identifier: \(identifier)",
      metadata: LogMetadataDTOCollection().toPrivacyMetadata(),
      source: "MockCryptoService"
    )
    
    if configuration.deletionSucceeds {
      storage.removeValue(forKey: identifier)
      
      if storage[identifier] == nil {
        return .success(true)
      } else {
        return .failure(.operationFailed("Failed to delete data"))
      }
    } else {
      return .failure(.operationFailed("Mock deletion failure"))
    }
  }
}

/**
 A simple in-memory implementation of SecureStorageProtocol for testing.
 */
private actor InMemorySecureStorage: SecureStorageProtocol {
  private var storage: [String: [UInt8]] = [:]
  
  public init() {}
  
  public func storeData(_ data: [UInt8], withIdentifier identifier: String) async -> Result<Bool, SecurityStorageError> {
    storage[identifier] = data
    return .success(true)
  }
  
  public func retrieveData(withIdentifier identifier: String) async -> Result<[UInt8], SecurityStorageError> {
    if let data = storage[identifier] {
      return .success(data)
    } else {
      return .failure(.keyNotFound)
    }
  }
  
  public func deleteData(withIdentifier identifier: String) async -> Result<Bool, SecurityStorageError> {
    storage.removeValue(forKey: identifier)
    return .success(true)
  }
}
