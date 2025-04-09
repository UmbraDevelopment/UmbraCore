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
    self.baseLogger = baseLogger
    _loggingActor = await baseLogger.loggingActor
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
    let privacyString = PrivacyString(stringLiteral: message)
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
    let updatedContext: LogContextDTO
    
    if let cryptoContext = context as? CryptoLogContext {
      // If it's already a CryptoLogContext, merge the metadata
      updatedContext = cryptoContext.withMergedMetadata(metadata)
    } else {
      // Otherwise, create a new CryptoLogContext with the metadata
      updatedContext = CryptoLogContext(
        operation: "generic",
        source: context.getSource(),
        correlationID: context.getCorrelationID(),
        metadata: metadata
      )
    }
    
    await log(level, message, context: updatedContext)
  }

  /**
   Log sensitive information with explicit privacy metadata.
   
   - Parameters:
     - level: The log level
     - message: The message to log
     - sensitiveValues: The sensitive values to include
     - context: The log context
   */
  @available(*, deprecated, message: "Use logWithMetadata(_:_:metadata:context:) with LogMetadataDTOCollection instead")
  public func logSensitive(
    _ level: LogLevel,
    _ message: String,
    sensitiveValues: LogMetadata,
    context: LogContextDTO
  ) async {
    await baseLogger.logSensitive(
      level,
      message,
      sensitiveValues: sensitiveValues,
      context: context
    )
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

  // MARK: - Crypto-Specific Logging Methods

  /**
   Log an encryption operation.

   - Parameters:
     - message: The log message
     - dataIdentifier: Optional identifier for the data
     - keyIdentifier: Optional identifier for the key
     - status: The operation status
     - metadata: Optional additional metadata
   */
  public func logEncryption(
    _ message: String,
    dataIdentifier: String? = nil,
    keyIdentifier: String? = nil,
    status: String,
    metadata: LogMetadataDTOCollection? = nil
  ) async {
    var contextMetadata = metadata ?? LogMetadataDTOCollection()
    
    // Add key identifier as private data if provided
    if let keyIdentifier {
      contextMetadata = contextMetadata.withPrivate(key: "keyIdentifier", value: keyIdentifier)
    }
    
    let context = CryptoLogContext(
      operation: "encrypt",
      identifier: dataIdentifier,
      status: status,
      metadata: contextMetadata
    )

    await log(.info, message, context: context)
  }

  /**
   Log a decryption operation.

   - Parameters:
     - message: The log message
     - dataIdentifier: Optional identifier for the encrypted data
     - keyIdentifier: Optional identifier for the key
     - status: The operation status
     - metadata: Optional additional metadata
   */
  public func logDecryption(
    _ message: String,
    dataIdentifier: String? = nil,
    keyIdentifier: String? = nil,
    status: String,
    metadata: LogMetadataDTOCollection? = nil
  ) async {
    var contextMetadata = metadata ?? LogMetadataDTOCollection()
    
    // Add key identifier as private data if provided
    if let keyIdentifier {
      contextMetadata = contextMetadata.withPrivate(key: "keyIdentifier", value: keyIdentifier)
    }
    
    let context = CryptoLogContext(
      operation: "decrypt",
      identifier: dataIdentifier,
      status: status,
      metadata: contextMetadata
    )

    await log(.info, message, context: context)
  }

  /**
   Log a key generation operation.

   - Parameters:
     - message: The log message
     - keyIdentifier: Optional identifier for the generated key
     - algorithm: Optional algorithm used
     - status: The operation status
     - metadata: Optional additional metadata
   */
  public func logKeyGeneration(
    _ message: String,
    keyIdentifier: String? = nil,
    algorithm: String? = nil,
    status: String,
    metadata: LogMetadataDTOCollection? = nil
  ) async {
    var contextMetadata = metadata ?? LogMetadataDTOCollection()

    if let algorithm {
      contextMetadata = contextMetadata.withPublic(key: "algorithm", value: algorithm)
    }
    
    // Add key identifier as sensitive data if provided
    if let keyIdentifier {
      contextMetadata = contextMetadata.withSensitive(key: "keyIdentifier", value: keyIdentifier)
    }

    let context = CryptoLogContext(
      operation: "generateKey",
      identifier: keyIdentifier,
      status: status,
      metadata: contextMetadata
    )

    await log(.info, message, context: context)
  }

  /**
   Log a data storage operation.

   - Parameters:
     - message: The log message
     - dataIdentifier: Optional identifier for the stored data
     - storageType: Optional type of storage
     - status: The operation status
     - metadata: Optional additional metadata
   */
  public func logDataStorage(
    _ message: String,
    dataIdentifier: String? = nil,
    storageType: String? = nil,
    status: String,
    metadata: LogMetadataDTOCollection? = nil
  ) async {
    var contextMetadata = metadata ?? LogMetadataDTOCollection()

    if let storageType {
      contextMetadata = contextMetadata.withPublic(key: "storageType", value: storageType)
    }

    let context = CryptoLogContext(
      operation: "storeData",
      identifier: dataIdentifier,
      status: status,
      metadata: contextMetadata
    )

    await log(.info, message, context: context)
  }

  /**
   Log a hashing operation.

   - Parameters:
     - message: The log message
     - dataIdentifier: Optional identifier for the data
     - algorithm: Optional hashing algorithm
     - status: The operation status
     - metadata: Optional additional metadata
   */
  public func logHashing(
    _ message: String,
    dataIdentifier: String? = nil,
    algorithm: String? = nil,
    status: String,
    metadata: LogMetadataDTOCollection? = nil
  ) async {
    var contextMetadata = metadata ?? LogMetadataDTOCollection()

    if let algorithm {
      contextMetadata = contextMetadata.withPublic(key: "algorithm", value: algorithm)
    }

    let context = CryptoLogContext(
      operation: "hash",
      identifier: dataIdentifier,
      status: status,
      metadata: contextMetadata
    )

    await log(.info, message, context: context)
  }
  
  /**
   Log a signature verification operation.

   - Parameters:
     - message: The log message
     - dataIdentifier: Optional identifier for the data
     - signatureIdentifier: Optional identifier for the signature
     - keyIdentifier: Optional identifier for the verification key
     - status: The operation status
     - metadata: Optional additional metadata
   */
  public func logSignatureVerification(
    _ message: String,
    dataIdentifier: String? = nil,
    signatureIdentifier: String? = nil,
    keyIdentifier: String? = nil,
    status: String,
    metadata: LogMetadataDTOCollection? = nil
  ) async {
    var contextMetadata = metadata ?? LogMetadataDTOCollection()

    if let signatureIdentifier {
      contextMetadata = contextMetadata.withPublic(key: "signatureIdentifier", value: signatureIdentifier)
    }
    
    if let keyIdentifier {
      contextMetadata = contextMetadata.withPrivate(key: "keyIdentifier", value: keyIdentifier)
    }

    let context = CryptoLogContext(
      operation: "verifySignature",
      identifier: dataIdentifier,
      status: status,
      metadata: contextMetadata
    )

    await log(.info, message, context: context)
  }
  
  /**
   Log a data signing operation.

   - Parameters:
     - message: The log message
     - dataIdentifier: Optional identifier for the data
     - keyIdentifier: Optional identifier for the signing key
     - algorithm: Optional signing algorithm
     - status: The operation status
     - metadata: Optional additional metadata
   */
  public func logSigning(
    _ message: String,
    dataIdentifier: String? = nil,
    keyIdentifier: String? = nil,
    algorithm: String? = nil,
    status: String,
    metadata: LogMetadataDTOCollection? = nil
  ) async {
    var contextMetadata = metadata ?? LogMetadataDTOCollection()

    if let algorithm {
      contextMetadata = contextMetadata.withPublic(key: "algorithm", value: algorithm)
    }
    
    if let keyIdentifier {
      contextMetadata = contextMetadata.withPrivate(key: "keyIdentifier", value: keyIdentifier)
    }

    let context = CryptoLogContext(
      operation: "sign",
      identifier: dataIdentifier,
      status: status,
      metadata: contextMetadata
    )

    await log(.info, message, context: context)
  }
}
