import CoreSecurityTypes
import Foundation
import LoggingServices
import SecurityCoreInterfaces

/**
 An implementation of CryptoServiceProtocol that adds logging for
 all operations before delegating to the wrapped implementation.
 */
public actor LoggingCryptoServiceImpl: @preconcurrency CryptoServiceProtocol {
  /// The wrapped implementation
  private let wrapped: CryptoServiceProtocol
  
  /// Logger for operations
  private let logger: LoggingProtocol
  
  /// Provides access to the secure storage from the wrapped implementation
  public var secureStorage: SecureStorageProtocol {
    wrapped.secureStorage
  }
  
  /**
   Initialises a new logging crypto service.
   
   - Parameters:
     - wrapped: The underlying implementation to delegate to
     - logger: Logger for operations
   */
  public init(
    wrapped: CryptoServiceProtocol,
    logger: LoggingProtocol
  ) {
    self.wrapped = wrapped
    self.logger = logger
  }
  
  /**
   Encrypt data using the specified key with logging.
   
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
      "Encrypting data: \(dataIdentifier) with key: \(keyIdentifier)",
      metadata: nil,
      source: "LoggingCryptoService"
    )
    
    let result = await wrapped.encrypt(
      dataIdentifier: dataIdentifier,
      keyIdentifier: keyIdentifier,
      options: options
    )
    
    switch result {
      case .success(let identifier):
        await logger.debug(
          "Successfully encrypted data, new identifier: \(identifier)",
          metadata: nil,
          source: "LoggingCryptoService"
        )
      case .failure(let error):
        await logger.error(
          "Failed to encrypt data: \(error)",
          metadata: nil,
          source: "LoggingCryptoService"
        )
    }
    
    return result
  }
  
  /**
   Decrypt data using the specified key with logging.
   
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
      "Decrypting data: \(encryptedDataIdentifier) with key: \(keyIdentifier)",
      metadata: nil,
      source: "LoggingCryptoService"
    )
    
    let result = await wrapped.decrypt(
      encryptedDataIdentifier: encryptedDataIdentifier,
      keyIdentifier: keyIdentifier,
      options: options
    )
    
    switch result {
      case .success(let identifier):
        await logger.debug(
          "Successfully decrypted data, new identifier: \(identifier)",
          metadata: nil,
          source: "LoggingCryptoService"
        )
      case .failure(let error):
        await logger.error(
          "Failed to decrypt data: \(error)",
          metadata: nil,
          source: "LoggingCryptoService"
        )
    }
    
    return result
  }
  
  /**
   Create a hash of the specified data with logging.
   
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
      "Hashing data: \(dataIdentifier)",
      metadata: nil,
      source: "LoggingCryptoService"
    )
    
    let result = await wrapped.hash(
      dataIdentifier: dataIdentifier,
      options: options
    )
    
    switch result {
      case .success(let identifier):
        await logger.debug(
          "Successfully hashed data, hash identifier: \(identifier)",
          metadata: nil,
          source: "LoggingCryptoService"
        )
      case .failure(let error):
        await logger.error(
          "Failed to hash data: \(error)",
          metadata: nil,
          source: "LoggingCryptoService"
        )
    }
    
    return result
  }
  
  /**
   Verify that a hash matches the expected data with logging.
   
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
      "Verifying hash for data: \(dataIdentifier) against hash: \(hashIdentifier)",
      metadata: nil,
      source: "LoggingCryptoService"
    )
    
    let result = await wrapped.verifyHash(
      dataIdentifier: dataIdentifier,
      hashIdentifier: hashIdentifier,
      options: options
    )
    
    switch result {
      case .success(let matches):
        await logger.debug(
          "Hash verification result: \(matches ? "matched" : "did not match")",
          metadata: nil,
          source: "LoggingCryptoService"
        )
      case .failure(let error):
        await logger.error(
          "Failed to verify hash: \(error)",
          metadata: nil,
          source: "LoggingCryptoService"
        )
    }
    
    return result
  }
  
  /**
   Generate a new cryptographic key with logging.
   
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
      "Generating key with length: \(length)",
      metadata: nil,
      source: "LoggingCryptoService"
    )
    
    let result = await wrapped.generateKey(
      length: length,
      options: options
    )
    
    switch result {
      case .success(let identifier):
        await logger.debug(
          "Successfully generated key, identifier: \(identifier)",
          metadata: nil,
          source: "LoggingCryptoService"
        )
      case .failure(let error):
        await logger.error(
          "Failed to generate key: \(error)",
          metadata: nil,
          source: "LoggingCryptoService"
        )
    }
    
    return result
  }
  
  /**
   Import data into secure storage with logging.
   
   - Parameters:
     - data: The data to import
     - customIdentifier: Optional custom identifier to use
   - Returns: Identifier for the imported data or an error
   */
  public func importData(
    _ data: [UInt8],
    customIdentifier: String?
  ) async -> Result<String, SecurityStorageError> {
    await logger.debug(
      "Importing data" + (customIdentifier != nil ? " with custom identifier: \(customIdentifier!)" : ""),
      metadata: nil,
      source: "LoggingCryptoService"
    )
    
    let result = await wrapped.importData(
      data,
      customIdentifier: customIdentifier
    )
    
    switch result {
      case .success(let identifier):
        await logger.debug(
          "Successfully imported data, identifier: \(identifier)",
          metadata: nil,
          source: "LoggingCryptoService"
        )
      case .failure(let error):
        await logger.error(
          "Failed to import data: \(error)",
          metadata: nil,
          source: "LoggingCryptoService"
        )
    }
    
    return result
  }
  
  /**
   Export data from secure storage with logging.
   
   - Parameter identifier: Identifier for the data to export
   - Returns: The raw data or an error
   */
  public func exportData(
    identifier: String
  ) async -> Result<[UInt8], SecurityStorageError> {
    await logger.info(
      "Exporting data with identifier: \(identifier)",
      metadata: nil,
      source: "LoggingCryptoService"
    )
    
    let result = await wrapped.exportData(identifier: identifier)
    
    switch result {
    case .success:
      await logger.info(
        "Successfully exported data with identifier: \(identifier)",
        metadata: nil,
        source: "LoggingCryptoService"
      )
    case .failure(let error):
      await logger.error(
        "Failed to export data: \(error)",
        metadata: nil,
        source: "LoggingCryptoService"
      )
    }
    
    return result
  }
}
