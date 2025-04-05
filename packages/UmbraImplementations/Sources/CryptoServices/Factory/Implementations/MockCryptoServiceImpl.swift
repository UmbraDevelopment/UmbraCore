import CoreSecurityTypes
import Foundation
import LoggingServices
import SecurityCoreInterfaces

/**
 A mock implementation of CryptoServiceProtocol for testing purposes.
 
 This implementation provides configurable success/failure behavior for all methods,
 making it useful for unit testing components that depend on CryptoServiceProtocol.
 */
public actor MockCryptoServiceImpl: CryptoServiceProtocol {
  /// Configuration options for the mock
  public struct Configuration: Sendable {
    /// Whether encryption operations should succeed
    public var encryptionSucceeds: Bool
    
    /// Whether decryption operations should succeed
    public var decryptionSucceeds: Bool
    
    /// Whether hashing operations should succeed
    public var hashingSucceeds: Bool
    
    /// Whether hash verification operations should succeed
    public var verificationSucceeds: Bool
    
    /// Whether key generation operations should succeed
    public var keyGenerationSucceeds: Bool
    
    /// Whether storage operations should succeed
    public var storageSucceeds: Bool
    
    /// Whether a verified hash matches (if verification succeeds)
    public var hashMatches: Bool
    
    /// Creates a new configuration with specified options
    public init(
      encryptionSucceeds: Bool = true,
      decryptionSucceeds: Bool = true,
      hashingSucceeds: Bool = true,
      verificationSucceeds: Bool = true,
      keyGenerationSucceeds: Bool = true,
      storageSucceeds: Bool = true,
      hashMatches: Bool = true
    ) {
      self.encryptionSucceeds = encryptionSucceeds
      self.decryptionSucceeds = decryptionSucceeds
      self.hashingSucceeds = hashingSucceeds
      self.verificationSucceeds = verificationSucceeds
      self.keyGenerationSucceeds = keyGenerationSucceeds
      self.storageSucceeds = storageSucceeds
      self.hashMatches = hashMatches
    }
  }
  
  /// Current configuration
  private let configuration: Configuration
  
  /// Logger for operations
  private let logger: LoggingProtocol
  
  /// Secure storage for mock data
  public let secureStorage: SecureStorageProtocol
  
  /// Creates a new mock crypto service with specified configuration
  public init(
    configuration: Configuration = Configuration(),
    logger: LoggingProtocol,
    secureStorage: SecureStorageProtocol
  ) {
    self.configuration = configuration
    self.logger = logger
    self.secureStorage = secureStorage
  }
  
  /**
   Encrypt data using the specified key.
   
   If configuration.encryptionSucceeds is true, returns a mock success result.
   Otherwise, returns a mock error.
   
   - Parameters:
     - dataIdentifier: Identifier for the data to encrypt
     - keyIdentifier: Identifier for the key to use
     - options: Optional encryption options
   - Returns: Identifier for the encrypted data or an error
   */
  public func encrypt(
    dataIdentifier: String,
    keyIdentifier: String,
    options: EncryptionOptions?
  ) async -> Result<String, SecurityStorageError> {
    await logger.debug(
      "Mock encrypting data: \(dataIdentifier) with key: \(keyIdentifier)",
      metadata: nil,
      source: "MockCryptoService"
    )
    
    if configuration.encryptionSucceeds {
      let identifier = "encrypted_\(UUID().uuidString)"
      
      // Store some mock encrypted data
      let mockEncryptedData: [UInt8] = [0xAA, 0x55, 0x01, 0x02, 0x03, 0x04]
      let _ = await secureStorage.storeData(mockEncryptedData, withIdentifier: identifier)
      
      return .success(identifier)
    } else {
      return .failure(.operationFailed)
    }
  }
  
  /**
   Decrypt data using the specified key.
   
   If configuration.decryptionSucceeds is true, returns a mock success result.
   Otherwise, returns a mock error.
   
   - Parameters:
     - encryptedDataIdentifier: Identifier for the encrypted data
     - keyIdentifier: Identifier for the key to use
     - options: Optional decryption options
   - Returns: Identifier for the decrypted data or an error
   */
  public func decrypt(
    encryptedDataIdentifier: String,
    keyIdentifier: String,
    options: DecryptionOptions?
  ) async -> Result<String, SecurityStorageError> {
    await logger.debug(
      "Mock decrypting data: \(encryptedDataIdentifier) with key: \(keyIdentifier)",
      metadata: nil,
      source: "MockCryptoService"
    )
    
    if configuration.decryptionSucceeds {
      let decryptedID = "decrypted_\(UUID().uuidString)"
      let mockData: [UInt8] = [0x01, 0x02, 0x03, 0x04]
      let _ = await secureStorage.storeData(mockData, withIdentifier: decryptedID)
      return .success(decryptedID)
    } else {
      return .failure(.operationFailed)
    }
  }
  
  /**
   Create a hash of the specified data.
   
   If configuration.hashingSucceeds is true, returns a mock success result.
   Otherwise, returns a mock error.
   
   - Parameters:
     - dataIdentifier: Identifier for the data to hash
     - options: Optional hashing options
   - Returns: Identifier for the hash or an error
   */
  public func hash(
    dataIdentifier: String,
    options: HashingOptions?
  ) async -> Result<String, SecurityStorageError> {
    await logger.debug(
      "Mock hashing data: \(dataIdentifier)",
      metadata: nil,
      source: "MockCryptoService"
    )
    
    if configuration.hashingSucceeds {
      let identifier = "hash_\(UUID().uuidString)"
      let _ = await secureStorage.storeData([0x01, 0x02, 0x03, 0x04], withIdentifier: identifier)
      return .success(identifier)
    } else {
      return .failure(.operationFailed)
    }
  }
  
  /**
   Verify that a hash matches the expected data.
   
   If configuration.verificationSucceeds is true, returns configuration.hashMatches.
   Otherwise, returns a mock error.
   
   - Parameters:
     - dataIdentifier: Identifier for the data to verify
     - hashIdentifier: Identifier for the expected hash
     - options: Optional hashing options used for verification
   - Returns: Whether the hash matches or an error
   */
  public func verifyHash(
    dataIdentifier: String,
    hashIdentifier: String,
    options: HashingOptions?
  ) async -> Result<Bool, SecurityStorageError> {
    await logger.debug(
      "Mock verifying hash for data: \(dataIdentifier) against hash: \(hashIdentifier)",
      metadata: nil,
      source: "MockCryptoService"
    )
    
    if configuration.verificationSucceeds {
      return .success(configuration.hashMatches)
    } else {
      return .failure(.operationFailed)
    }
  }
  
  /**
   Generate a new cryptographic key.
   
   If configuration.keyGenerationSucceeds is true, returns a mock success result.
   Otherwise, returns a mock error.
   
   - Parameters:
     - length: Length of the key in bits
     - options: Optional key generation options
   - Returns: Identifier for the generated key or an error
   */
  public func generateKey(
    length: Int,
    options: UnifiedCryptoTypes.KeyGenerationOptions?
  ) async -> Result<String, SecurityStorageError> {
    await logger.debug(
      "Mock generating key with length: \(length)",
      metadata: nil,
      source: "MockCryptoService"
    )
    
    if configuration.keyGenerationSucceeds {
      let keyData: [UInt8] = Array(repeating: 0x42, count: length / 8)
      let keyID = "key_\(UUID().uuidString)"
      let _ = await secureStorage.storeData(keyData, withIdentifier: keyID)
      return .success(keyID)
    } else {
      return .failure(.operationFailed)
    }
  }
  
  /**
   Import data into secure storage.
   
   If configuration.storageSucceeds is true, returns a mock success result.
   Otherwise, returns a mock error.
   
   - Parameters:
     - data: The data to import
     - customIdentifier: Optional custom identifier to use
   - Returns: Identifier for the imported data or an error
   */
  public func importData(
    _ data: [UInt8],
    customIdentifier: String?
  ) async -> Result<String, SecurityStorageError> {
    let identifier = customIdentifier ?? "import_\(UUID().uuidString)"
    
    await logger.debug(
      "Mock importing data with identifier: \(identifier)",
      metadata: nil,
      source: "MockCryptoService"
    )
    
    if configuration.storageSucceeds {
      let _ = await secureStorage.storeData(data, withIdentifier: identifier)
      return .success(identifier)
    } else {
      return .failure(.operationFailed)
    }
  }
}
