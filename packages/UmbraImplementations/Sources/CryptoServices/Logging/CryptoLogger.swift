import Foundation
import LoggingInterfaces
import LoggingTypes

/**
 # Domain-specific Logger for Cryptographic Operations

 This class implements the PrivacyAwareLoggingProtocol and provides
 specialised logging for cryptographic operations. It ensures that all
 sensitive cryptographic information is properly classified and logged
 with appropriate privacy controls.

 Following the Alpha Dot Five architecture, this logger:
 - Uses the privacy-enhanced DTO-based logging system
 - Provides domain-specific methods for common crypto operations
 - Ensures consistent taxonomy of log entries
 - Maintains thread safety through actor isolation

 ## Privacy Controls

 This logger implements comprehensive privacy controls for sensitive information:
 - Public information is logged normally
 - Private information is redacted in production builds
 - Sensitive information is always redacted
 - Hash values are specially marked
 */
public actor CryptoLogger: PrivacyAwareLoggingProtocol {
  // MARK: - Properties

  /// The wrapped logger implementation
  private let baseLogger: PrivacyAwareLoggingProtocol

  /// The underlying logging actor, populated at init time
  private let _loggingActor: LoggingActor

  /// The logging actor used by this logger (non-async property to satisfy protocol)
  public nonisolated var loggingActor: LoggingActor {
    _loggingActor
  }

  // MARK: - Initialization

  /**
   Creates a new crypto logger that wraps the provided base logger.

   - Parameter baseLogger: The underlying logger to use
   */
  public init(baseLogger: PrivacyAwareLoggingProtocol) async {
    self.baseLogger=baseLogger
    _loggingActor=await baseLogger.loggingActor
  }

  // MARK: - PrivacyAwareLoggingProtocol Implementation

  /**
   Log a message at the specified level with context.

   - Parameters:
     - level: The log level
     - message: The privacy-aware message
     - context: The log context
   */
  public func log(_ level: LogLevel, _ message: PrivacyString, context: LogContextDTO) async {
    await baseLogger.log(level, message, context: context)
  }

  /**
   Log a message with context using a standard string (will be treated as public).

   - Parameters:
     - level: The log level
     - message: The message to log
     - context: The log context
   */
  public func log(_ level: LogLevel, _ message: String, context: LogContextDTO) async {
    let privacyString=PrivacyString(stringLiteral: message)
    await baseLogger.log(level, privacyString, context: context)
  }

  /**
   Log sensitive information with explicit metadata collection.

   - Parameters:
     - level: The log level
     - message: The message to log
     - metadata: The privacy-aware metadata collection
     - context: The log context
   */
  public func logWithMetadata(
    _ level: LogLevel,
    _ message: String,
    metadata: LogMetadataDTOCollection,
    context: LogContextDTO
  ) async {
    // Create a new context that includes our metadata
    let updatedContext: LogContextDTO=if let cryptoContext=context as? CryptoLogContext {
      // If it's already a CryptoLogContext, merge the metadata
      cryptoContext.withMergedMetadata(metadata)
    } else {
      // Otherwise, create a new CryptoLogContext with the metadata
      CryptoLogContext(
        operation: "generic",
        source: context.source,
        metadata: metadata,
        correlationID: context.correlationID,
        category: context.category
      )
    }

    await log(level, message, context: updatedContext)
  }

  /**
   Log an error with context.

   - Parameters:
     - error: The error to log
     - context: The log context
   */
  public func logError(_ error: Error, context: LogContextDTO) async {
    await baseLogger.logError(error, context: context)
  }

  /**
   Log an error with specific privacy level and context.

   - Parameters:
     - error: The error to log
     - privacyLevel: The privacy level for the error
     - context: The log context
   */
  public func logError(
    _ error: Error,
    privacyLevel: LogPrivacyLevel,
    context: LogContextDTO
  ) async {
    await baseLogger.logError(error, privacyLevel: privacyLevel, context: context)
  }

  /**
   Log a debug message with context.

   - Parameters:
     - message: The message to log
     - context: The log context
   */
  public func debug(_ message: String, context: LogContextDTO) async {
    await log(.debug, message, context: context)
  }

  /**
   Log an info message with context.

   - Parameters:
     - message: The message to log
     - context: The log context
   */
  public func info(_ message: String, context: LogContextDTO) async {
    await log(.info, message, context: context)
  }

  /**
   Log a warning message with context.

   - Parameters:
     - message: The message to log
     - context: The log context
   */
  public func warning(_ message: String, context: LogContextDTO) async {
    await log(.warning, message, context: context)
  }

  /**
   Log an error message with context.

   - Parameters:
     - message: The message to log
     - context: The log context
   */
  public func error(_ message: String, context: LogContextDTO) async {
    await log(.error, message, context: context)
  }

  /**
   Log a critical message with context.

   - Parameters:
     - message: The message to log
     - context: The log context
   */
  public func critical(_ message: String, context: LogContextDTO) async {
    await log(.critical, message, context: context)
  }

  /**
   Log sensitive information with appropriate redaction using context.

   This method ensures that sensitive cryptographic values are properly handled
   with appropriate privacy controls.

   - Parameters:
     - level: The severity level of the log
     - message: The basic message without sensitive content
     - sensitiveValues: Sensitive values that should be handled with privacy controls
     - context: The logging context DTO containing metadata, source, etc.
   */
  public func logSensitive(
    _ level: LogLevel,
    _ message: String,
    sensitiveValues: LoggingTypes.LogMetadata,
    context: LogContextDTO
  ) async {
    // Create a crypto-specific context with the sensitive values
    let cryptoContext=CryptoLogContext(
      operation: "sensitive_operation",
      source: context.source,
      metadata: context.metadata,
      correlationID: context.correlationID,
      category: context.category
    )

    // Add sensitive values with proper privacy classification
    var enhancedContext=cryptoContext
    for (key, value) in sensitiveValues.asDictionary {
      enhancedContext=enhancedContext.withSensitiveMetadata(key: key, value: value)
    }

    // Delegate to the base logger
    await baseLogger.log(level, message, context: enhancedContext)
  }

  // MARK: - Crypto-Specific Logging Methods

  /**
   Log an encryption operation.

   - Parameters:
     - message: The log message
     - dataIdentifier: The identifier for the data being encrypted
     - keyIdentifier: The identifier for the encryption key
     - algorithm: Optional encryption algorithm
     - metadata: Optional additional metadata
   */
  public func logEncryption(
    _ message: String,
    dataIdentifier: String,
    keyIdentifier: String,
    algorithm: String?=nil,
    metadata: LogMetadataDTOCollection?=nil
  ) async {
    var contextMetadata=metadata ?? LogMetadataDTOCollection()

    // Add standard encryption metadata
    contextMetadata=contextMetadata
      .withPublic(key: "dataIdentifier", value: dataIdentifier)
      .withPrivate(key: "keyIdentifier", value: keyIdentifier)

    if let algorithm {
      contextMetadata=contextMetadata.withPublic(key: "algorithm", value: algorithm)
    }

    let context=CryptoLogContext(
      operation: "encrypt",
      source: "encryption",
      metadata: contextMetadata,
      correlationID: nil,
      category: "Security"
    )

    await info(message, context: context)
  }

  /**
   Log a decryption operation.

   - Parameters:
     - message: The log message
     - dataIdentifier: The identifier for the encrypted data
     - keyIdentifier: The identifier for the decryption key
     - algorithm: Optional decryption algorithm
     - metadata: Optional additional metadata
   */
  public func logDecryption(
    _ message: String,
    dataIdentifier: String,
    keyIdentifier: String,
    algorithm: String?=nil,
    metadata: LogMetadataDTOCollection?=nil
  ) async {
    var contextMetadata=metadata ?? LogMetadataDTOCollection()

    // Add standard decryption metadata
    contextMetadata=contextMetadata
      .withPublic(key: "dataIdentifier", value: dataIdentifier)
      .withPrivate(key: "keyIdentifier", value: keyIdentifier)

    if let algorithm {
      contextMetadata=contextMetadata.withPublic(key: "algorithm", value: algorithm)
    }

    let context=CryptoLogContext(
      operation: "decrypt",
      source: "decryption",
      metadata: contextMetadata,
      correlationID: nil,
      category: "Security"
    )

    await info(message, context: context)
  }

  /**
   Log a key generation operation.

   - Parameters:
     - message: The log message
     - keyIdentifier: The identifier for the generated key
     - keyType: The type of key generated
     - metadata: Optional additional metadata
   */
  public func logKeyGeneration(
    _ message: String,
    keyIdentifier: String,
    keyType: String,
    metadata: LogMetadataDTOCollection?=nil
  ) async {
    var contextMetadata=metadata ?? LogMetadataDTOCollection()

    // Add standard key generation metadata
    contextMetadata=contextMetadata
      .withSensitive(key: "keyIdentifier", value: keyIdentifier)
      .withPublic(key: "keyType", value: keyType)

    let context=CryptoLogContext(
      operation: "generateKey",
      source: "keyGeneration",
      metadata: contextMetadata,
      correlationID: nil,
      category: "Security"
    )

    await info(message, context: context)
  }

  /**
   Log a data storage operation.

   - Parameters:
     - message: The log message
     - dataIdentifier: The identifier for the stored data
     - storageType: The type of storage
     - metadata: Optional additional metadata
   */
  public func logDataStorage(
    _ message: String,
    dataIdentifier: String,
    storageType: String,
    metadata: LogMetadataDTOCollection?=nil
  ) async {
    var contextMetadata=metadata ?? LogMetadataDTOCollection()

    // Add standard data storage metadata
    contextMetadata=contextMetadata
      .withPublic(key: "dataIdentifier", value: dataIdentifier)
      .withPublic(key: "storageType", value: storageType)

    let context=CryptoLogContext(
      operation: "storeData",
      source: "dataStorage",
      metadata: contextMetadata,
      correlationID: nil,
      category: "Security"
    )

    await info(message, context: context)
  }

  /**
   Log a hashing operation.

   - Parameters:
     - message: The log message
     - dataIdentifier: The identifier for the data being hashed
     - algorithm: Optional hashing algorithm
     - metadata: Optional additional metadata
   */
  public func logHashing(
    _ message: String,
    dataIdentifier: String,
    algorithm: String?=nil,
    metadata: LogMetadataDTOCollection?=nil
  ) async {
    var contextMetadata=metadata ?? LogMetadataDTOCollection()

    // Add standard hashing metadata
    contextMetadata=contextMetadata
      .withPublic(key: "dataIdentifier", value: dataIdentifier)

    if let algorithm {
      contextMetadata=contextMetadata.withPublic(key: "algorithm", value: algorithm)
    }

    let context=CryptoLogContext(
      operation: "hash",
      source: "hashing",
      metadata: contextMetadata,
      correlationID: nil,
      category: "Security"
    )

    await info(message, context: context)
  }

  /**
   Log a signature verification operation.

   - Parameters:
     - message: The log message
     - dataIdentifier: The identifier for the data being verified
     - signatureIdentifier: The identifier for the signature
     - keyIdentifier: The identifier for the verification key
     - metadata: Optional additional metadata
   */
  public func logSignatureVerification(
    _ message: String,
    dataIdentifier: String,
    signatureIdentifier: String,
    keyIdentifier: String,
    metadata: LogMetadataDTOCollection?=nil
  ) async {
    var contextMetadata=metadata ?? LogMetadataDTOCollection()

    // Add standard signature verification metadata
    contextMetadata=contextMetadata
      .withPublic(key: "dataIdentifier", value: dataIdentifier)
      .withPublic(key: "signatureIdentifier", value: signatureIdentifier)
      .withPrivate(key: "keyIdentifier", value: keyIdentifier)

    let context=CryptoLogContext(
      operation: "verifySignature",
      source: "signatureVerification",
      metadata: contextMetadata,
      correlationID: nil,
      category: "Security"
    )

    await info(message, context: context)
  }

  /**
   Log a data signing operation.

   - Parameters:
     - message: The log message
     - dataIdentifier: The identifier for the data being signed
     - keyIdentifier: The identifier for the signing key
     - algorithm: Optional signing algorithm
     - metadata: Optional additional metadata
   */
  public func logSigning(
    _ message: String,
    dataIdentifier: String,
    keyIdentifier: String,
    algorithm: String?=nil,
    metadata: LogMetadataDTOCollection?=nil
  ) async {
    var contextMetadata=metadata ?? LogMetadataDTOCollection()

    // Add standard signing metadata
    contextMetadata=contextMetadata
      .withPublic(key: "dataIdentifier", value: dataIdentifier)
      .withPrivate(key: "keyIdentifier", value: keyIdentifier)

    if let algorithm {
      contextMetadata=contextMetadata.withPublic(key: "algorithm", value: algorithm)
    }

    let context=CryptoLogContext(
      operation: "sign",
      source: "signing",
      metadata: contextMetadata,
      correlationID: nil,
      category: "Security"
    )

    await info(message, context: context)
  }
}
