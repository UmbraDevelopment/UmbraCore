import CryptoTypes
import DomainSecurityTypes
import Foundation
import LoggingInterfaces
import LoggingTypes
import SecurityCoreInterfaces

/**
 # Logging Crypto Service

 Provides logging capabilities for cryptographic operations by wrapping
 any CryptoServiceProtocol implementation and adding comprehensive logging.

 This implementation follows the Alpha Dot Five architecture principles:
 - Full actor isolation
 - Privacy-aware logging
 - Proper error handling
 */
public actor LoggingCryptoServiceImpl: CryptoServiceProtocol {
  /// The wrapped implementation
  private let wrapped: CryptoServiceProtocol
  
  /// The logger to use for recording operations
  private let logger: LoggingProtocol
  
  /// The secure storage used for handling sensitive data
  public nonisolated var secureStorage: SecureStorageProtocol {
    wrapped.secureStorage
  }
  
  /**
   Initialise with a wrapped implementation and a logger
   
   - Parameters:
     - wrapped: The implementation to delegate to
     - logger: The logger to use for recording operations
   */
  public init(
    wrapped: CryptoServiceProtocol,
    logger: LoggingProtocol
  ) {
    self.wrapped = wrapped
    self.logger = logger
  }
  
  /**
   Encrypts binary data using a key from secure storage.
   - Parameters:
     - dataIdentifier: Identifier of the data to encrypt in secure storage.
     - keyIdentifier: Identifier of the encryption key in secure storage.
     - options: Optional encryption configuration.
   - Returns: Identifier for the encrypted data in secure storage, or an error.
   */
  public func encrypt(
    dataIdentifier: String,
    keyIdentifier: String,
    options: SecurityCoreInterfaces.EncryptionOptions?
  ) async -> Result<String, SecurityStorageError> {
    // Create a context for logging
    let context = CryptoLogContext(
      domainName: "CryptoServices",
      source: "LoggingCryptoService",
      operation: "encrypt"
    )
    
    // Log the beginning of the operation
    await logger.debug("Starting encryption operation", context: context)
    
    // Delegate to the wrapped implementation
    let result = await wrapped.encrypt(
      dataIdentifier: dataIdentifier,
      keyIdentifier: keyIdentifier,
      options: options
    )
    
    // Log the result
    switch result {
    case .success(let identifier):
      await logger.info("Encryption completed successfully", context: context)
      return .success(identifier)
    case .failure(let error):
      await logger.error("Encryption failed: \(error.localizedDescription)", context: context)
      return .failure(error)
    }
  }
  
  /**
   Decrypts binary data using a key from secure storage.
   - Parameters:
     - encryptedDataIdentifier: Identifier of the encrypted data in secure storage.
     - keyIdentifier: Identifier of the decryption key in secure storage.
     - options: Optional decryption configuration.
   - Returns: Identifier for the decrypted data in secure storage, or an error.
   */
  public func decrypt(
    encryptedDataIdentifier: String,
    keyIdentifier: String,
    options: SecurityCoreInterfaces.DecryptionOptions?
  ) async -> Result<String, SecurityStorageError> {
    // Create a context for logging
    let context = CryptoLogContext(
      domainName: "CryptoServices",
      source: "LoggingCryptoService",
      operation: "decrypt"
    )
    
    // Log the beginning of the operation
    await logger.debug("Starting decryption operation", context: context)
    
    // Delegate to the wrapped implementation
    let result = await wrapped.decrypt(
      encryptedDataIdentifier: encryptedDataIdentifier,
      keyIdentifier: keyIdentifier,
      options: options
    )
    
    // Log the result
    switch result {
    case .success(let identifier):
      await logger.info("Decryption completed successfully", context: context)
      return .success(identifier)
    case .failure(let error):
      await logger.error("Decryption failed: \(error.localizedDescription)", context: context)
      return .failure(error)
    }
  }
  
  /**
   Computes a cryptographic hash of data in secure storage.
   - Parameter dataIdentifier: Identifier of the data to hash in secure storage.
   - Parameter options: Optional hashing configuration.
   - Returns: Identifier for the hash in secure storage, or an error.
   */
  public func hash(
    dataIdentifier: String,
    options: SecurityCoreInterfaces.HashingOptions?
  ) async -> Result<String, SecurityStorageError> {
    // Create a context for logging
    let context = CryptoLogContext(
      domainName: "CryptoServices",
      source: "LoggingCryptoService",
      operation: "hash"
    )
    
    // Log the beginning of the operation
    await logger.debug("Starting hash operation", context: context)
    
    // Delegate to the wrapped implementation
    let result = await wrapped.hash(
      dataIdentifier: dataIdentifier,
      options: options
    )
    
    // Log the result
    switch result {
    case .success(let identifier):
      await logger.info("Hash operation completed successfully", context: context)
      return .success(identifier)
    case .failure(let error):
      await logger.error("Hash operation failed: \(error.localizedDescription)", context: context)
      return .failure(error)
    }
  }
  
  /**
   Verifies a cryptographic hash against the expected value.
   - Parameters:
     - dataIdentifier: Identifier of the data to verify in secure storage.
     - hashIdentifier: Identifier of the expected hash in secure storage.
     - options: Optional hashing configuration.
   - Returns: `true` if the hash matches, `false` if not, or an error.
   */
  public func verifyHash(
    dataIdentifier: String,
    hashIdentifier: String,
    options: SecurityCoreInterfaces.HashingOptions?
  ) async -> Result<Bool, SecurityStorageError> {
    // Create a context for logging
    let context = CryptoLogContext(
      domainName: "CryptoServices",
      source: "LoggingCryptoService",
      operation: "verifyHash"
    )
    
    // Log the beginning of the operation
    await logger.debug("Starting hash verification", context: context)
    
    // Delegate to the wrapped implementation
    let result = await wrapped.verifyHash(
      dataIdentifier: dataIdentifier,
      hashIdentifier: hashIdentifier,
      options: options
    )
    
    // Log the result
    switch result {
    case .success(let verified):
      let status = verified ? "verified" : "failed verification"
      await logger.info("Hash verification completed: \(status)", context: context)
      return .success(verified)
    case .failure(let error):
      await logger.error("Hash verification failed: \(error.localizedDescription)", context: context)
      return .failure(error)
    }
  }
  
  /**
   Generates a cryptographic key and stores it securely.
   - Parameters:
     - length: The length of the key to generate in bytes.
     - options: Optional key generation configuration.
   - Returns: Identifier for the generated key in secure storage, or an error.
   */
  public func generateKey(
    length: Int,
    options: SecurityCoreInterfaces.KeyGenerationOptions?
  ) async -> Result<String, SecurityStorageError> {
    // Create a context for logging
    let context = CryptoLogContext(
      domainName: "CryptoServices",
      source: "LoggingCryptoService",
      operation: "generateKey"
    )
    
    // Log the beginning of the operation
    await logger.debug("Starting key generation", context: context)
    
    // Delegate to the wrapped implementation
    let result = await wrapped.generateKey(
      length: length,
      options: options
    )
    
    // Log the result
    switch result {
    case .success(let identifier):
      await logger.info("Key generation completed successfully", context: context)
      return .success(identifier)
    case .failure(let error):
      await logger.error("Key generation failed: \(error.localizedDescription)", context: context)
      return .failure(error)
    }
  }
  
  /**
   Imports data into secure storage for use with cryptographic operations.
   - Parameters:
     - data: The raw data to store securely.
     - customIdentifier: Optional custom identifier for the data. If nil, a random identifier is
   generated.
   - Returns: The identifier for the data in secure storage, or an error.
   */
  public func importData(
    _ data: [UInt8],
    customIdentifier: String?
  ) async -> Result<String, SecurityStorageError> {
    // Create a context for logging
    let context = CryptoLogContext(
      domainName: "CryptoServices",
      source: "LoggingCryptoService",
      operation: "importData"
    )
    
    // Log the beginning of the operation
    await logger.debug("Starting data import", context: context)
    
    // Delegate to the wrapped implementation
    let result = await wrapped.importData(
      data,
      customIdentifier: customIdentifier
    )
    
    // Log the result
    switch result {
    case .success(let identifier):
      await logger.info("Data import completed successfully", context: context)
      return .success(identifier)
    case .failure(let error):
      await logger.error("Data import failed: \(error.localizedDescription)", context: context)
      return .failure(error)
    }
  }
  
  /**
   Exports data from secure storage.
   - Parameter identifier: The identifier of the data to export.
   - Returns: The raw data, or an error.
   - Warning: Use with caution as this exposes sensitive data.
   */
  public func exportData(
    identifier: String
  ) async -> Result<[UInt8], SecurityStorageError> {
    // Create a context for logging
    let context = CryptoLogContext(
      domainName: "CryptoServices",
      source: "LoggingCryptoService",
      operation: "exportData"
    )
    
    // Log the beginning of the operation
    await logger.debug("Starting data export", context: context)
    
    // Delegate to the wrapped implementation
    let result = await wrapped.exportData(
      identifier: identifier
    )
    
    // Log the result
    switch result {
    case .success(let data):
      await logger.info("Data export completed successfully", context: context)
      return .success(data)
    case .failure(let error):
      await logger.error("Data export failed: \(error.localizedDescription)", context: context)
      return .failure(error)
    }
  }
}

/**
 Context for logging crypto operations 
 */
private struct CryptoLogContext: LogContext {
  var domainName: String
  var source: String?
  var correlationID: String?
  var metadata: LogMetadataDTOCollection = LogMetadataDTOCollection()
  var parameters: [String: Any] = [:]
  
  init(domainName: String, source: String? = nil, operation: String) {
    self.domainName = domainName
    self.source = source
    self.parameters["operation"] = operation
    
    // Create a correlation ID for tracing related operations
    self.correlationID = UUID().uuidString
  }
}
