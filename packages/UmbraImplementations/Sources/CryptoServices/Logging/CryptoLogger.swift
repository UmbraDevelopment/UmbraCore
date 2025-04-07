import Foundation
import LoggingInterfaces
import LoggingTypes

/**
 Domain-specific logger for cryptographic operations.

 This class implements the PrivacyAwareLoggingProtocol and provides
 specialised logging for cryptographic operations. It ensures that all
 sensitive cryptographic information is properly classified and logged
 with appropriate privacy controls.

 Following the Alpha Dot Five architecture, this logger:
 - Uses the privacy-enhanced DTO-based logging system
 - Provides domain-specific methods for common crypto operations
 - Ensures consistent taxonomy of log entries
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

  /// Log a message at the specified level with context
  public func log(_ level: LogLevel, _ message: PrivacyString, context: LogContextDTO) async {
    await baseLogger.log(level, message, context: context)
  }

  /// Log a message with context using a standard string (will be treated as public)
  public func log(_ level: LogLevel, _ message: String, context: LogContextDTO) async {
    let privacyString=PrivacyString(stringLiteral: message)
    await baseLogger.log(level, privacyString, context: context)
  }

  /// Log sensitive information with explicit privacy metadata
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

  /// Log an error with context
  public func logError(_ error: Error, context: LogContextDTO) async {
    await baseLogger.logError(error, context: context)
  }

  /// Log an error with specific privacy level and context
  public func logError(
    _ error: Error,
    privacyLevel: LogPrivacyLevel,
    context: LogContextDTO
  ) async {
    await baseLogger.logError(error, privacyLevel: privacyLevel, context: context)
  }

  /// Log a debug message with context
  public func debug(_ message: String, context: LogContextDTO) async {
    await log(.debug, message, context: context)
  }

  /// Log an info message with context
  public func info(_ message: String, context: LogContextDTO) async {
    await log(.info, message, context: context)
  }

  /// Log a warning message with context
  public func warning(_ message: String, context: LogContextDTO) async {
    await log(.warning, message, context: context)
  }

  /// Log an error message with context
  public func error(_ message: String, context: LogContextDTO) async {
    await log(.error, message, context: context)
  }

  /// Log a critical message with context
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
    dataIdentifier: String?=nil,
    keyIdentifier _: String?=nil,
    status: String,
    metadata: LogMetadataDTOCollection?=nil
  ) async {
    let context=CryptoLogContext(
      operation: "encrypt",
      identifier: dataIdentifier,
      status: status,
      metadata: metadata ?? LogMetadataDTOCollection()
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
    dataIdentifier: String?=nil,
    keyIdentifier _: String?=nil,
    status: String,
    metadata: LogMetadataDTOCollection?=nil
  ) async {
    let context=CryptoLogContext(
      operation: "decrypt",
      identifier: dataIdentifier,
      status: status,
      metadata: metadata ?? LogMetadataDTOCollection()
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
    keyIdentifier: String?=nil,
    algorithm: String?=nil,
    status: String,
    metadata: LogMetadataDTOCollection?=nil
  ) async {
    var contextMetadata=metadata ?? LogMetadataDTOCollection()

    if let algorithm {
      contextMetadata=contextMetadata.withPublic(key: "algorithm", value: algorithm)
    }

    let context=CryptoLogContext(
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
    dataIdentifier: String?=nil,
    storageType: String?=nil,
    status: String,
    metadata: LogMetadataDTOCollection?=nil
  ) async {
    var contextMetadata=metadata ?? LogMetadataDTOCollection()

    if let storageType {
      contextMetadata=contextMetadata.withPublic(key: "storageType", value: storageType)
    }

    let context=CryptoLogContext(
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
    dataIdentifier: String?=nil,
    algorithm: String?=nil,
    status: String,
    metadata: LogMetadataDTOCollection?=nil
  ) async {
    var contextMetadata=metadata ?? LogMetadataDTOCollection()

    if let algorithm {
      contextMetadata=contextMetadata.withPublic(key: "algorithm", value: algorithm)
    }

    let context=CryptoLogContext(
      operation: "hash",
      identifier: dataIdentifier,
      status: status,
      metadata: contextMetadata
    )

    await log(.info, message, context: context)
  }
}
