import Foundation
import LoggingInterfaces
import SecurityCoreInterfaces

/**
 * A mock implementation of CryptoServiceProtocol for testing purposes.
 *
 * This implementation provides configurable success/failure behavior for all methods,
 * making it useful for unit testing components that depend on CryptoServiceProtocol.
 */
public actor MockCryptoServiceImpl: @preconcurrency CryptoServiceProtocol {
  /// Configuration options for the mock
  public struct Configuration: Sendable {
    /// Whether encryption operations should succeed
    public var encryptionSucceeds: Bool
    
    /// Whether decryption operations should succeed
    public var decryptionSucceeds: Bool
    
    /// Whether hashing operations should succeed
    public var hashingSucceeds: Bool
    
    /// Whether verification operations should succeed
    public var verificationSucceeds: Bool
    
    /// Whether key generation operations should succeed
    public var keyGenerationSucceeds: Bool
    
    /// Whether data storage operations should succeed
    public var storageSucceeds: Bool
    
    /// Whether a verified hash matches (if verification succeeds)
    public var hashMatches: Bool
    
    /// Whether export data operations should succeed
    public var exportDataSucceeds: Bool
    
    /// Creates a new configuration with specified options
    public init(
      encryptionSucceeds: Bool = true,
      decryptionSucceeds: Bool = true,
      hashingSucceeds: Bool = true,
      verificationSucceeds: Bool = true,
      keyGenerationSucceeds: Bool = true,
      storageSucceeds: Bool = true,
      hashMatches: Bool = true,
      exportDataSucceeds: Bool = true
    ) {
      self.encryptionSucceeds = encryptionSucceeds
      self.decryptionSucceeds = decryptionSucceeds
      self.hashingSucceeds = hashingSucceeds
      self.verificationSucceeds = verificationSucceeds
      self.keyGenerationSucceeds = keyGenerationSucceeds
      self.storageSucceeds = storageSucceeds
      self.hashMatches = hashMatches
      self.exportDataSucceeds = exportDataSucceeds
    }
  }
  
  /// The current configuration for this mock
  public var configuration: Configuration
  
  /// The secure storage used by this service
  public let secureStorage: SecureStorageProtocol
  
  /**
   Creates a new MockCryptoServiceImpl.
   
   - Parameters:
   - configuration: Configuration options for the mock implementation
   - secureStorage: The secure storage to use
   */
  public init(
    configuration: Configuration = Configuration(),
    secureStorage: SecureStorageProtocol
  ) {
    self.configuration = configuration
    self.secureStorage = secureStorage
  }
  
  /**
   Encrypts data with configurable success/failure behavior.
   
   - Parameters:
   - dataIdentifier: Identifier for the data to encrypt
   - keyIdentifier: Identifier for the encryption key
   - options: Optional encryption options (ignored in this implementation)
   - Returns: Identifier for the encrypted data or an error
   */
  public func encrypt(
    dataIdentifier: String,
    keyIdentifier: String,
    options: SecurityCoreInterfaces.EncryptionOptions?
  ) async -> Result<String, SecurityStorageError> {
    if configuration.encryptionSucceeds {
      let encryptedID = "encrypted_\(dataIdentifier)"
      
      // Mock data to store
      let mockData: [UInt8] = [0x01, 0x02, 0x03, 0x04]
      
      // Store encrypted data
      let _ = await secureStorage.storeData(mockData, withIdentifier: encryptedID)
      
      return .success(encryptedID)
    } else {
      return .failure(.operationFailed("Mock encryption failure"))
    }
  }
  
  /**
   Decrypts data with configurable success/failure behavior.
   
   - Parameters:
   - encryptedDataIdentifier: Identifier for the encrypted data
   - keyIdentifier: Identifier for the decryption key
   - options: Optional decryption options (ignored in this implementation)
   - Returns: Identifier for the decrypted data or an error
   */
  public func decrypt(
    encryptedDataIdentifier: String,
    keyIdentifier: String,
    options: SecurityCoreInterfaces.DecryptionOptions?
  ) async -> Result<String, SecurityStorageError> {
    if configuration.decryptionSucceeds {
      let decryptedID = "decrypted_\(encryptedDataIdentifier)"
      
      // Mock data to store
      let mockData: [UInt8] = [0x01, 0x02, 0x03, 0x04]
      
      let _ = await secureStorage.storeData(mockData, withIdentifier: decryptedID)
      return .success(decryptedID)
    } else {
      return .failure(.operationFailed("Mock decryption failure"))
    }
  }
  
  /**
   Hashes data with configurable success/failure behavior.
   
   - Parameters:
   - dataIdentifier: Identifier for the data to hash
   - options: Optional hashing options (ignored in this implementation)
   - Returns: Identifier for the hash or an error
   */
  public func hash(
    dataIdentifier: String,
    options: SecurityCoreInterfaces.HashingOptions?
  ) async -> Result<String, SecurityStorageError> {
    if configuration.hashingSucceeds {
      let identifier = "hash_\(dataIdentifier)"
      
      // Store a mock hash value
      let _ = await secureStorage.storeData([0x01, 0x02, 0x03, 0x04], withIdentifier: identifier)
      return .success(identifier)
    } else {
      return .failure(.operationFailed("Mock hashing failure"))
    }
  }
  
  /**
   Verifies a hash with configurable success/failure behavior.
   
   - Parameters:
   - dataIdentifier: Identifier for the data to verify
   - hashIdentifier: Identifier for the expected hash
   - options: Optional hashing options (ignored in this implementation)
   - Returns: Whether the hash matches or an error
   */
  public func verifyHash(
    dataIdentifier: String,
    hashIdentifier: String,
    options: SecurityCoreInterfaces.HashingOptions?
  ) async -> Result<Bool, SecurityStorageError> {
    if configuration.verificationSucceeds {
      return .success(configuration.hashMatches)
    } else {
      return .failure(.operationFailed("Mock hash verification failure"))
    }
  }
  
  /**
   Generates a cryptographic key with configurable success/failure behavior.
   
   - Parameters:
   - length: Length of the key in bytes
   - options: Optional key generation options (ignored in this implementation)
   - Returns: Identifier for the generated key or an error
   */
  public func generateKey(
    length: Int,
    options: SecurityCoreInterfaces.KeyGenerationOptions?
  ) async -> Result<String, SecurityStorageError> {
    if configuration.keyGenerationSucceeds {
      let keyID = "key_\(UUID().uuidString)"
      
      // Mock key data
      let keyData: [UInt8] = Array(repeating: 0x42, count: length)
      
      let _ = await secureStorage.storeData(keyData, withIdentifier: keyID)
      return .success(keyID)
    } else {
      return .failure(.operationFailed("Mock key generation failure"))
    }
  }
  
  /**
   Imports data with configurable success/failure behavior.
   
   - Parameters:
   - data: The data to import
   - customIdentifier: Optional custom identifier
   - Returns: Identifier for the imported data or an error
   */
  public func importData(
    _ data: [UInt8],
    customIdentifier: String?
  ) async -> Result<String, SecurityStorageError> {
    if configuration.storageSucceeds {
      let identifier = customIdentifier ?? "imported_\(UUID().uuidString)"
      
      let _ = await secureStorage.storeData(data, withIdentifier: identifier)
      return .success(identifier)
    } else {
      return .failure(.operationFailed("Mock data import failure"))
    }
  }
  
  /**
   Export data with configurable success/failure behavior.
   
   - Parameter identifier: Identifier for the data to export
   - Returns: Mock data or an error
   */
  public func exportData(
    identifier: String
  ) async -> Result<[UInt8], SecurityStorageError> {
    if configuration.exportDataSucceeds {
      let mockData: [UInt8] = [0x01, 0x02, 0x03, 0x04]
      return .success(mockData)
    } else {
      return .failure(.operationFailed("Mock data export failure"))
    }
  }
}
