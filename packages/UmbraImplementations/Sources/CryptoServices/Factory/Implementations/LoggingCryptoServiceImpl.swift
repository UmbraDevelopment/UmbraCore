import LoggingInterfaces
import LoggingTypes
import SecurityCoreInterfaces

/**
 An implementation of CryptoServiceProtocol that adds logging for
 all operations before delegating to the wrapped implementation.
 */
public actor LoggingCryptoServiceImpl: @preconcurrency CryptoServiceProtocol {
  /// The wrapped implementation
  private let wrapped: CryptoServiceProtocol
  
  /// The logger for this implementation
  private let logger: LoggingInterfaces.LoggingProtocol
  
  /// The secure storage used by this service
  public let secureStorage: SecureStorageProtocol
  
  /**
   Creates a new LoggingCryptoServiceImpl.
   
   - Parameters:
   - wrapped: The CryptoServiceProtocol implementation to wrap
   - logger: The logger to use
   */
  public init(
    wrapped: CryptoServiceProtocol,
    logger: LoggingInterfaces.LoggingProtocol
  ) {
    self.wrapped = wrapped
    self.logger = logger
    self.secureStorage = wrapped.secureStorage
  }
  
  /**
   Encrypts data with logging.
   
   - Parameters:
   - dataIdentifier: Identifier for the data to encrypt
   - keyIdentifier: Identifier for the encryption key
   - options: Optional encryption options
   - Returns: Identifier for the encrypted data or an error
   */
  public func encrypt(
    dataIdentifier: String,
    keyIdentifier: String,
    options: SecurityCoreInterfaces.EncryptionOptions?
  ) async -> Result<String, SecurityStorageError> {
    await logger.info(
      "Encrypting data with identifier \(dataIdentifier) using key \(keyIdentifier)",
      metadata: PrivacyMetadata(),
      source: "LoggingCryptoService"
    )
    
    let result = await wrapped.encrypt(
      dataIdentifier: dataIdentifier,
      keyIdentifier: keyIdentifier,
      options: options
    )
    
    switch result {
      case let .success(identifier):
      await logger.info(
        "Successfully encrypted data to identifier: \(identifier)",
        metadata: PrivacyMetadata(),
        source: "LoggingCryptoService"
      )
      case let .failure(error):
      await logger.error(
        "Failed to encrypt data: \(error)",
        metadata: PrivacyMetadata(),
        source: "LoggingCryptoService"
      )
    }
    
    return result
  }
  
  /**
   Decrypts data with logging.
   
   - Parameters:
   - encryptedDataIdentifier: Identifier for the encrypted data
   - keyIdentifier: Identifier for the decryption key
   - options: Optional decryption options
   - Returns: Identifier for the decrypted data or an error
   */
  public func decrypt(
    encryptedDataIdentifier: String,
    keyIdentifier: String,
    options: SecurityCoreInterfaces.DecryptionOptions?
  ) async -> Result<String, SecurityStorageError> {
    await logger.info(
      "Decrypting data with identifier \(encryptedDataIdentifier) using key \(keyIdentifier)",
      metadata: PrivacyMetadata(),
      source: "LoggingCryptoService"
    )
    
    let result = await wrapped.decrypt(
      encryptedDataIdentifier: encryptedDataIdentifier,
      keyIdentifier: keyIdentifier,
      options: options
    )
    
    switch result {
      case let .success(identifier):
      await logger.info(
        "Successfully decrypted data to identifier: \(identifier)",
        metadata: PrivacyMetadata(),
        source: "LoggingCryptoService"
      )
      case let .failure(error):
      await logger.error(
        "Failed to decrypt data: \(error)",
        metadata: PrivacyMetadata(),
        source: "LoggingCryptoService"
      )
    }
    
    return result
  }
  
  /**
   Computes a hash with logging.
   
   - Parameters:
   - dataIdentifier: Identifier for the data to hash
   - options: Optional hashing options
   - Returns: Identifier for the hash or an error
   */
  public func hash(
    dataIdentifier: String,
    options: SecurityCoreInterfaces.HashingOptions?
  ) async -> Result<String, SecurityStorageError> {
    await logger.info(
      "Hashing data with identifier \(dataIdentifier)",
      metadata: PrivacyMetadata(),
      source: "LoggingCryptoService"
    )
    
    let result = await wrapped.hash(
      dataIdentifier: dataIdentifier,
      options: options
    )
    
    switch result {
      case let .success(identifier):
      await logger.info(
        "Successfully hashed data to identifier: \(identifier)",
        metadata: PrivacyMetadata(),
        source: "LoggingCryptoService"
      )
      case let .failure(error):
      await logger.error(
        "Failed to hash data: \(error)",
        metadata: PrivacyMetadata(),
        source: "LoggingCryptoService"
      )
    }
    
    return result
  }
  
  /**
   Verifies a hash with logging.
   
   - Parameters:
   - dataIdentifier: Identifier for the data to verify
   - hashIdentifier: Identifier for the expected hash
   - options: Optional hashing options
   - Returns: Whether the hash is valid or an error
   */
  public func verifyHash(
    dataIdentifier: String,
    hashIdentifier: String,
    options: SecurityCoreInterfaces.HashingOptions?
  ) async -> Result<Bool, SecurityStorageError> {
    await logger.info(
      "Verifying hash for data with identifier \(dataIdentifier) against hash \(hashIdentifier)",
      metadata: PrivacyMetadata(),
      source: "LoggingCryptoService"
    )
    
    let result = await wrapped.verifyHash(
      dataIdentifier: dataIdentifier,
      hashIdentifier: hashIdentifier,
      options: options
    )
    
    switch result {
      case let .success(matches):
      await logger.info(
        "Hash verification result: \(matches ? "Match" : "No match")",
        metadata: PrivacyMetadata(),
        source: "LoggingCryptoService"
      )
      case let .failure(error):
      await logger.error(
        "Failed to verify hash: \(error)",
        metadata: PrivacyMetadata(),
        source: "LoggingCryptoService"
      )
    }
    
    return result
  }
  
  /**
   Generates a key with logging.
   
   - Parameters:
   - length: Length of the key to generate in bytes
   - options: Optional key generation options
   - Returns: Identifier for the generated key or an error
   */
  public func generateKey(
    length: Int,
    options: SecurityCoreInterfaces.KeyGenerationOptions?
  ) async -> Result<String, SecurityStorageError> {
    await logger.info(
      "Generating key with length \(length) bytes",
      metadata: PrivacyMetadata(),
      source: "LoggingCryptoService"
    )
    
    let result = await wrapped.generateKey(
      length: length,
      options: options
    )
    
    switch result {
      case let .success(identifier):
      await logger.info(
        "Successfully generated key with identifier: \(identifier)",
        metadata: PrivacyMetadata(),
        source: "LoggingCryptoService"
      )
      case let .failure(error):
      await logger.error(
        "Failed to generate key: \(error)",
        metadata: PrivacyMetadata(),
        source: "LoggingCryptoService"
      )
    }
    
    return result
  }
  
  /**
   Imports data with logging.
   
   - Parameters:
   - data: Raw data to import
   - customIdentifier: Optional custom identifier for the data
   - Returns: Identifier for the imported data or an error
   */
  public func importData(
    _ data: [UInt8],
    customIdentifier: String?
  ) async -> Result<String, SecurityStorageError> {
    await logger.info(
      "Importing data\(customIdentifier != nil ? " with custom identifier \(customIdentifier!)" : "")",
      metadata: PrivacyMetadata(),
      source: "LoggingCryptoService"
    )
    
    let result = await wrapped.importData(
      data,
      customIdentifier: customIdentifier
    )
    
    switch result {
      case let .success(identifier):
      await logger.info(
        "Successfully imported data with identifier: \(identifier)",
        metadata: PrivacyMetadata(),
        source: "LoggingCryptoService"
      )
      case let .failure(error):
      await logger.error(
        "Failed to import data: \(error)",
        metadata: PrivacyMetadata(),
        source: "LoggingCryptoService"
      )
    }
    
    return result
  }
  
  /**
   Exports data with logging.
   
   - Parameter identifier: Identifier for the data to export
   - Returns: Raw bytes or an error
   */
  public func exportData(identifier: String) async -> Result<[UInt8], SecurityStorageError> {
    await logger.info(
      "Exporting data with identifier: \(identifier)",
      metadata: PrivacyMetadata(),
      source: "LoggingCryptoService"
    )
    
    let result = await wrapped.exportData(identifier: identifier)
    
    switch result {
      case .success:
      await logger.info(
        "Successfully exported data with identifier: \(identifier)",
        metadata: PrivacyMetadata(),
        source: "LoggingCryptoService"
      )
      case let .failure(error):
      await logger.error(
        "Failed to export data: \(error)",
        metadata: PrivacyMetadata(),
        source: "LoggingCryptoService"
      )
    }
    
    return result
  }
}
