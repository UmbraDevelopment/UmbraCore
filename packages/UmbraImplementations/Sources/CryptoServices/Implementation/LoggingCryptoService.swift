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
    
    // Extract metadata and source from context
    let metadata = context.metadata
    let source = context.source ?? "LoggingCryptoService"
    
    // Log the beginning of the operation
    await logger.debug("Starting encryption operation", metadata: metadata, source: source)
    
    // Delegate to the wrapped implementation
    let result = await wrapped.encrypt(
      dataIdentifier: dataIdentifier,
      keyIdentifier: keyIdentifier,
      options: options
    )
    
    // Log the result
    switch result {
    case .success(let identifier):
      await logger.info("Encryption completed successfully", metadata: metadata, source: source)
      return .success(identifier)
    case .failure(let error):
      await logger.error("Encryption failed: \(error.localizedDescription)", metadata: metadata, source: source)
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
    
    // Extract metadata and source from context
    let metadata = context.metadata
    let source = context.source ?? "LoggingCryptoService"
    
    // Log the beginning of the operation
    await logger.debug("Starting decryption operation", metadata: metadata, source: source)
    
    // Delegate to the wrapped implementation
    let result = await wrapped.decrypt(
      encryptedDataIdentifier: encryptedDataIdentifier,
      keyIdentifier: keyIdentifier,
      options: options
    )
    
    // Log the result
    switch result {
    case .success(let identifier):
      await logger.info("Decryption completed successfully", metadata: metadata, source: source)
      return .success(identifier)
    case .failure(let error):
      await logger.error("Decryption failed: \(error.localizedDescription)", metadata: metadata, source: source)
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
    
    // Extract metadata and source from context
    let metadata = context.metadata
    let source = context.source ?? "LoggingCryptoService"
    
    // Log the beginning of the operation
    await logger.debug("Starting hash operation", metadata: metadata, source: source)
    
    // Delegate to the wrapped implementation
    let result = await wrapped.hash(
      dataIdentifier: dataIdentifier,
      options: options
    )
    
    // Log the result
    switch result {
    case .success(let identifier):
      await logger.info("Hash operation completed successfully", metadata: metadata, source: source)
      return .success(identifier)
    case .failure(let error):
      await logger.error("Hash operation failed: \(error.localizedDescription)", metadata: metadata, source: source)
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
    
    // Extract metadata and source from context
    let metadata = context.metadata
    let source = context.source ?? "LoggingCryptoService"
    
    // Log the beginning of the operation
    await logger.debug("Starting hash verification", metadata: metadata, source: source)
    
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
      await logger.info("Hash verification completed: \(status)", metadata: metadata, source: source)
      return .success(verified)
    case .failure(let error):
      await logger.error("Hash verification failed: \(error.localizedDescription)", metadata: metadata, source: source)
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
    
    // Extract metadata and source from context
    let metadata = context.metadata
    let source = context.source ?? "LoggingCryptoService"
    
    // Log the beginning of the operation
    await logger.debug("Starting key generation", metadata: metadata, source: source)
    
    // Delegate to the wrapped implementation
    let result = await wrapped.generateKey(
      length: length,
      options: options
    )
    
    // Log the result
    switch result {
    case .success(let identifier):
      await logger.info("Key generation completed successfully", metadata: metadata, source: source)
      return .success(identifier)
    case .failure(let error):
      await logger.error("Key generation failed: \(error.localizedDescription)", metadata: metadata, source: source)
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
    
    // Extract metadata and source from context
    let metadata = context.metadata
    let source = context.source ?? "LoggingCryptoService"
    
    // Log the beginning of the operation
    await logger.debug("Starting data import", metadata: metadata, source: source)
    
    // Delegate to the wrapped implementation
    let result = await wrapped.importData(
      data,
      customIdentifier: customIdentifier
    )
    
    // Log the result
    switch result {
    case .success(let identifier):
      await logger.info("Data import completed successfully", metadata: metadata, source: source)
      return .success(identifier)
    case .failure(let error):
      await logger.error("Data import failed: \(error.localizedDescription)", metadata: metadata, source: source)
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
    
    // Extract metadata and source from context
    let metadata = context.metadata
    let source = context.source ?? "LoggingCryptoService"
    
    // Log the beginning of the operation
    await logger.debug("Starting data export", metadata: metadata, source: source)
    
    // Delegate to the wrapped implementation
    let result = await wrapped.exportData(
      identifier: identifier
    )
    
    // Log the result
    switch result {
    case .success(let data):
      await logger.info("Data export completed successfully", metadata: metadata, source: source)
      return .success(data)
    case .failure(let error):
      await logger.error("Data export failed: \(error.localizedDescription)", metadata: metadata, source: source)
      return .failure(error)
    }
  }
}

/**
 Context for logging crypto operations 
 
 Provides structured context information for privacy-aware logging in cryptographic operations.
 Follows the Alpha Dot Five architecture guidelines for privacy-preserving logging.
 */
private struct CryptoLogContext: LogContext {
  /// The domain name for the logging context
  var domainName: String
  
  /// The source of the log message (component name)
  var source: String?
  
  /// Correlation ID for tracing related operations
  var correlationID: String?
  
  /// Privacy-aware metadata for the log message
  var metadata: PrivacyMetadata = PrivacyMetadata()
  
  /// Additional parameters for the log context
  var parameters: [String: Any] = [:]
  
  /**
   Initialises a new crypto logging context
   
   - Parameters:
     - domainName: The domain this log belongs to
     - source: The source component generating the log
     - operation: The cryptographic operation being performed
   */
  init(domainName: String, source: String? = nil, operation: String) {
    self.domainName = domainName
    self.source = source
    self.parameters["operation"] = operation
    
    // Create a correlation ID for tracing related operations
    self.correlationID = UUID().uuidString
    
    // Add operation to metadata for structured logging
    self.metadata = PrivacyMetadata([
      "operation": .public(operation),
      "component": .public("CryptoServices"),
      "correlationId": .public(self.correlationID ?? "unknown")
    ])
  }
}
