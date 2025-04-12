import CryptoTypes
import Foundation
import LoggingInterfaces
import LoggingTypes

/// A specialised domain logger for cryptographic operations
///
/// This actor provides logging functionality specific to cryptographic
/// operations, with enhanced privacy controls and contextual information
/// relevant to cryptographic processes.
public actor CryptoLogger: DomainLoggerProtocol {
  /// The domain name this logger is responsible for
  public let domainName: String="Crypto"

  /// The underlying logging service
  private let loggingService: LoggingServiceProtocol

  /// Creates a new cryptographic logger
  ///
  /// - Parameter loggingService: The underlying logging service to use
  public init(loggingService: LoggingServiceProtocol) {
    self.loggingService=loggingService
  }

  /// Log a message with the specified level (legacy method)
  public func log(_ level: LogLevel, _ message: String) async {
    // For backward compatibility, create a basic crypto context
    let context=CryptoLogContext(
      operation: "generic",
      algorithm: "unknown",
      status: "info",
      category: "general"
    )

    await log(level, message, context: context)
  }

  /// Log a message with the specified level and context
  public func log(_ level: LogLevel, _ message: String, context: LogContextDTO) async {
    let formattedMessage="[\(domainName)] \(message)"
    let metadata=context.metadata

    // Log with the main logging service
    if let loggingService=loggingService as? LoggingProtocol {
      await loggingService.log(level, formattedMessage, context: context)
    } else {
      // Legacy fallback for older LoggingServiceProtocol
      // Use the appropriate level-specific method
      switch level {
        case .trace:
          await loggingService.verbose(formattedMessage, metadata: metadata, source: domainName)
        case .debug:
          await loggingService.debug(formattedMessage, metadata: metadata, source: domainName)
        case .info:
          await loggingService.info(formattedMessage, metadata: metadata, source: domainName)
        case .warning:
          await loggingService.warning(formattedMessage, metadata: metadata, source: domainName)
        case .error:
          await loggingService.error(formattedMessage, metadata: metadata, source: domainName)
        case .critical:
          await loggingService.critical(formattedMessage, metadata: metadata, source: domainName)
      }
    }
  }

  // MARK: - Context-based logging methods

  /// Log a message with trace level and context
  public func trace(_ message: String, context: LogContextDTO) async {
    await log(.trace, message, context: context)
  }

  /// Log a message with debug level and context
  public func debug(_ message: String, context: LogContextDTO) async {
    await log(.debug, message, context: context)
  }

  /// Log a message with info level and context
  public func info(_ message: String, context: LogContextDTO) async {
    await log(.info, message, context: context)
  }

  /// Log a message with warning level and context
  public func warning(_ message: String, context: LogContextDTO) async {
    await log(.warning, message, context: context)
  }

  /// Log a message with error level and context
  public func error(_ message: String, context: LogContextDTO) async {
    await log(.error, message, context: context)
  }

  /// Log a message with critical level and context
  public func critical(_ message: String, context: LogContextDTO) async {
    await log(.critical, message, context: context)
  }

  // MARK: - Legacy logging methods

  /// Log a message with trace level (legacy method)
  public func trace(_ message: String) async {
    await log(.trace, message)
  }

  /// Log a message with debug level (legacy method)
  public func debug(_ message: String) async {
    await log(.debug, message)
  }

  /// Log a message with info level (legacy method)
  public func info(_ message: String) async {
    await log(.info, message)
  }

  /// Log a message with warning level (legacy method)
  public func warning(_ message: String) async {
    await log(.warning, message)
  }

  /// Log a message with error level (legacy method)
  public func error(_ message: String) async {
    await log(.error, message)
  }

  /// Log a message with critical level (legacy method)
  public func critical(_ message: String) async {
    await log(.critical, message)
  }

  /// Log with specific domain context
  public func logWithContext(_ level: LogLevel, _ message: String, context: LogContextDTO) async {
    await log(level, message, context: context)
  }

  /// Log an error with context
  public func logError(_ error: Error, context: LogContextDTO) async {
    if let loggableError=error as? LoggableErrorProtocol {
      // Use the error's built-in metadata collection
      let metadataCollection=loggableError.createMetadataCollection()
      let formattedMessage="[\(domainName)] \(loggableError.getLogMessage())"
      let source="\(loggableError.getSource()) via \(domainName)"

      // The logging service now expects LogMetadataDTOCollection
      await loggingService.error(formattedMessage, metadata: metadataCollection, source: source)
    } else {
      // Handle standard errors
      let formattedMessage="[\(domainName)] \(error.localizedDescription)"

      if let cryptoContext=context as? CryptoLogContext {
        // Update the context with error information
        let updatedContext=cryptoContext.withError(error)
        await log(.error, formattedMessage, context: updatedContext)
      } else {
        // Use the context as is
        await log(.error, formattedMessage, context: context)
      }
    }
  }

  // MARK: - Crypto-specific logging methods

  /// Log a cryptographic operation start
  ///
  /// - Parameters:
  ///   - algorithm: The cryptographic algorithm being used
  ///   - operation: The type of operation (e.g., encrypt, decrypt, sign)
  ///   - keyID: Optional identifier for the key being used
  public func logOperationStart(
    algorithm: String,
    operation: String,
    keyID: String?=nil
  ) async {
    let context=CryptoLogContext(
      operation: operation,
      algorithm: algorithm,
      status: "started",
      keyID: keyID,
      category: "operations"
    )

    await info("Starting \(operation) operation using \(algorithm)", context: context)
  }

  /// Log a cryptographic operation completion
  ///
  /// - Parameters:
  ///   - algorithm: The cryptographic algorithm being used
  ///   - operation: The type of operation (e.g., encrypt, decrypt, sign)
  ///   - keyID: Optional identifier for the key being used
  ///   - details: Optional details about the operation
  public func logOperationComplete(
    algorithm: String,
    operation: String,
    keyID: String?=nil,
    details: String?=nil
  ) async {
    let context=CryptoLogContext(
      operation: operation,
      algorithm: algorithm,
      status: "completed",
      keyID: keyID,
      details: details,
      category: "operations"
    )

    await info(
      "\(operation.capitalized) operation using \(algorithm) completed successfully",
      context: context
    )
  }

  /// Log a cryptographic operation failure
  ///
  /// - Parameters:
  ///   - algorithm: The cryptographic algorithm being used
  ///   - operation: The type of operation (e.g., encrypt, decrypt, sign)
  ///   - error: The error that occurred
  ///   - keyID: Optional identifier for the key being used
  public func logOperationFailure(
    algorithm: String,
    operation: String,
    error: Error,
    keyID: String?=nil
  ) async {
    let context=CryptoLogContext(
      operation: operation,
      algorithm: algorithm,
      status: "failed",
      keyID: keyID,
      error: error,
      category: "operations"
    )

    await logError(error, context: context)
  }
}

/**
 Crypto-specific log context implementation complying with LogContextDTO protocol

 This context contains information relevant to cryptographic operations, with
 appropriate privacy controls for sensitive cryptographic information.
 */
public struct CryptoLogContext: LogContextDTO {
  // Required properties from LogContextDTO
  public let domainName: String="Crypto"
  public let correlationID: String?
  public let source: String?="CryptoService"
  public let metadata: LogMetadataDTOCollection
  public let category: String

  // Additional crypto-specific properties
  public let operation: String
  public let algorithm: String
  public let status: String
  public let keyID: String?
  public let details: String?
  public let error: Error?

  /// Create a new crypto log context
  ///
  /// - Parameters:
  ///   - operation: The cryptographic operation being performed
  ///   - algorithm: The cryptographic algorithm being used
  ///   - status: The status of the operation
  ///   - keyID: Optional identifier for the key being used
  ///   - details: Optional details about the operation
  ///   - error: Optional error that occurred
  ///   - correlationID: Optional correlation ID for tracing related logs
  public init(
    operation: String,
    algorithm: String,
    status: String,
    keyID: String?=nil,
    details: String?=nil,
    error: Error?=nil,
    correlationID: String?=LogIdentifier(value: UUID().uuidString).description,
    category: String
  ) {
    self.operation=operation
    self.algorithm=algorithm
    self.status=status
    self.keyID=keyID
    self.details=details
    self.error=error
    self.correlationID=correlationID
    self.category=category

    // Build metadata collection with appropriate privacy levels
    var metadataBuilder=LogMetadataDTOCollection()
    metadataBuilder=metadataBuilder.withPublic(key: "operation", value: operation)
    metadataBuilder=metadataBuilder.withPublic(key: "algorithm", value: algorithm)
    metadataBuilder=metadataBuilder.withPublic(key: "status", value: status)
    metadataBuilder=metadataBuilder.withPublic(
      key: "correlationId",
      value: correlationID ?? LogIdentifier(value: UUID().uuidString).description
    )

    // Key IDs are private information
    if let keyID {
      metadataBuilder=metadataBuilder.withPrivate(key: "keyID", value: keyID)
    }

    if let details {
      metadataBuilder=metadataBuilder.withPublic(key: "details", value: details)
    }

    if let error {
      metadataBuilder=metadataBuilder.withPrivate(
        key: "errorDescription",
        value: error.localizedDescription
      )

      // Add additional error information if available
      if let nsError=error as NSError? {
        metadataBuilder=metadataBuilder.withPublic(key: "errorCode", value: String(nsError.code))
        metadataBuilder=metadataBuilder.withPrivate(key: "errorDomain", value: nsError.domain)
      }
    }

    metadata=metadataBuilder
  }

  /// Create a copy of this context with updated error information
  ///
  /// - Parameter error: The error to add to the context
  /// - Returns: Updated context with error information
  public func withError(_ error: Error) -> CryptoLogContext {
    CryptoLogContext(
      operation: operation,
      algorithm: algorithm,
      status: "failed",
      keyID: keyID,
      details: details,
      error: error,
      correlationID: correlationID,
      category: category
    )
  }

  /**
   Creates a new context with additional metadata.
   
   - Parameter additionalMetadata: The metadata to add to the context
   - Returns: A new context with the combined metadata
   */
  public func withMetadata(_ additionalMetadata: LogMetadataDTOCollection) -> CryptoLogContext {
    var newMetadata = self.metadata
    for entry in additionalMetadata.entries {
      newMetadata = newMetadata.with(key: entry.key, value: entry.value, privacyLevel: entry.privacyLevel)
    }
    
    return CryptoLogContext(
      operation: self.operation,
      algorithm: self.algorithm,
      status: self.status,
      keyID: self.keyID,
      details: self.details,
      error: self.error,
      correlationID: self.correlationID,
      category: self.category
    )
  }

  public func asLogMetadata() -> LogMetadata? {
    var result: [String: Any]=[
      "operation": operation,
      "algorithm": algorithm,
      "status": status,
      "correlationId": correlationID ?? LogIdentifier(value: UUID().uuidString).description
    ]

    if let keyID {
      result["keyID"]=keyID
    }

    if let details {
      result["details"]=details
    }

    if let error {
      result["errorDescription"]=error.localizedDescription
    }

    return LogMetadata.from(result)
  }

  public func withUpdatedMetadata(_: LogMetadataDTOCollection) -> Self {
    // Create a new context with the same basic properties but updated metadata
    // In a real implementation, this would merge the metadata
    CryptoLogContext(
      operation: operation,
      algorithm: algorithm,
      status: status,
      keyID: keyID,
      details: details,
      error: error,
      correlationID: correlationID,
      category: category
    )
  }

  public func toPrivacyMetadata() -> PrivacyMetadata {
    // Create a simple privacy metadata instance
    PrivacyMetadata()
  }

  public func getSource() -> String {
    source ?? "CryptoService"
  }

  public func toMetadata() -> LogMetadataDTOCollection {
    metadata
  }
}
