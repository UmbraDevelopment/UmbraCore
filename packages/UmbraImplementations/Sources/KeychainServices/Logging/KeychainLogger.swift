import Foundation
import LoggingAdapters
import LoggingInterfaces
import LoggingTypes

/**
 # Keychain Logger

 A domain-specific privacy-aware logger for keychain operations that follows
 the Alpha Dot Five architecture principles for structured logging.

 This logger ensures that sensitive information related to keychain operations
 is properly classified with appropriate privacy levels, with British spelling
 in documentation and comments.
 
 ## Privacy Controls
 
 This logger implements comprehensive privacy controls for sensitive information:
 - Public information (like operation status) is logged normally
 - Private information (like operation types) is redacted in production builds
 - Sensitive information (like account identifiers) is always redacted
 
 ## Thread Safety
 
 As an actor, this implementation guarantees thread safety when used from multiple
 concurrent contexts, preventing data races in logging operations.
 */
public actor KeychainLogger: DomainLoggerProtocol {
  /// The domain name for this logger
  public let domainName: String = "Keychain"

  /// The underlying logging service
  private let loggingService: LoggingProtocol

  /**
   Initialises a new keychain logger.

   - Parameter logger: The core logger to wrap
   */
  public init(logger: LoggingProtocol) {
    loggingService = logger
  }

  /**
   Required by DomainLoggerProtocol - logs with context

   - Parameters:
     - level: The log level
     - message: The message to log
     - context: The context for the log entry
   */
  public func logWithContext(_ level: LogLevel, _ message: String, context: LogContextDTO) async {
    let formattedMessage = "[\(domainName)] \(message)"
    await loggingService.log(level, formattedMessage, context: context)
  }

  /**
   Log a message with the specified level

   - Parameters:
     - level: The log level
     - message: The message to log
   */
  public func log(_ level: LogLevel, _ message: String) async {
    // For backward compatibility, create a basic keychain context
    let context = KeychainLogContext(
      account: "unknown",
      operation: "generic",
      status: "info"
    )

    await logWithContext(level, message, context: context)
  }

  /**
   Log a message with the specified level and context

   - Parameters:
     - level: The log level
     - message: The message to log
     - context: The keychain context for the log entry
   */
  public func log(_ level: LogLevel, _ message: String, context: LogContextDTO) async {
    await logWithContext(level, message, context: context)
  }

  /**
   Log an error with context

   - Parameters:
     - error: The error to log
     - context: The context for the log entry
   */
  public func logError(_ error: Error, context: LogContextDTO) async {
    if let loggableError = error as? LoggableErrorProtocol {
      // Create a new context for the error
      var errorContext = BaseLogContextDTO(
        domainName: domainName,
        source: context.getSource()
      )

      // Add error-specific metadata with privacy controls
      errorContext = errorContext.withUpdatedMetadata(
        LogMetadataDTOCollection()
          .withPublic(key: "errorType", value: String(describing: type(of: loggableError)))
          .withPrivate(key: "errorMessage", value: loggableError.getLogMessage())
      )

      let formattedMessage = "[\(domainName)] \(loggableError.getLogMessage())"
      await loggingService.error(formattedMessage, context: errorContext)
    } else {
      // Handle standard errors
      let formattedMessage = "[\(domainName)] \(error.localizedDescription)"

      if let keychainContext = context as? KeychainLogContext {
        // Update the context with error information
        let updatedContext = keychainContext.withUpdatedMetadata(
          keychainContext.metadata.withPrivate(key: "error", value: error.localizedDescription)
        )
        await log(.error, formattedMessage, context: updatedContext)
      } else {
        // Use the context as is
        await log(.error, formattedMessage, context: context)
      }
    }
  }

  // MARK: - Standard logging levels with context

  /**
   Log a message with trace level and context.
   
   - Parameters:
     - message: The message to log
     - context: The context for the log entry
   */
  public func trace(_ message: String, context: LogContextDTO) async {
    await log(.trace, message, context: context)
  }

  /**
   Log a message with debug level and context.
   
   - Parameters:
     - message: The message to log
     - context: The context for the log entry
   */
  public func debug(_ message: String, context: LogContextDTO) async {
    await log(.debug, message, context: context)
  }

  /**
   Log a message with info level and context.
   
   - Parameters:
     - message: The message to log
     - context: The context for the log entry
   */
  public func info(_ message: String, context: LogContextDTO) async {
    await log(.info, message, context: context)
  }

  /**
   Log a message with warning level and context.
   
   - Parameters:
     - message: The message to log
     - context: The context for the log entry
   */
  public func warning(_ message: String, context: LogContextDTO) async {
    await log(.warning, message, context: context)
  }

  /**
   Log a message with error level and context.
   
   - Parameters:
     - message: The message to log
     - context: The context for the log entry
   */
  public func error(_ message: String, context: LogContextDTO) async {
    await log(.error, message, context: context)
  }

  /**
   Log a message with critical level and context.
   
   - Parameters:
     - message: The message to log
     - context: The context for the log entry
   */
  public func critical(_ message: String, context: LogContextDTO) async {
    await log(.critical, message, context: context)
  }

  // MARK: - Legacy logging methods

  /**
   Log a message with trace level.
   
   - Parameter message: The message to log
   */
  public func trace(_ message: String) async {
    await log(.trace, message)
  }

  /**
   Log a message with debug level.
   
   - Parameter message: The message to log
   */
  public func debug(_ message: String) async {
    await log(.debug, message)
  }

  /**
   Log a message with info level.
   
   - Parameter message: The message to log
   */
  public func info(_ message: String) async {
    await log(.info, message)
  }

  /**
   Log a message with warning level.
   
   - Parameter message: The message to log
   */
  public func warning(_ message: String) async {
    await log(.warning, message)
  }

  /**
   Log a message with error level.
   
   - Parameter message: The message to log
   */
  public func error(_ message: String) async {
    await log(.error, message)
  }

  /**
   Log a message with critical level.
   
   - Parameter message: The message to log
   */
  public func critical(_ message: String) async {
    await log(.critical, message)
  }

  // MARK: - Domain-specific logging methods

  /**
   Logs the start of a keychain operation.

   - Parameters:
     - operation: The operation being performed
     - account: The account identifier (sensitive information)
     - additionalContext: Optional additional context metadata
     - message: Optional custom message
   */
  public func logOperationStart(
    operation: String,
    account: String,
    additionalContext: LogMetadataDTOCollection? = nil,
    message: String? = nil
  ) async {
    let context = KeychainLogContext(
      account: account,
      operation: operation,
      status: "started"
    )
    
    // Add additional context if provided
    let finalContext = if let additionalContext {
      context.withAdditionalMetadata(additionalContext)
    } else {
      context
    }

    let defaultMessage = "Starting keychain operation: \(operation)"
    await info(message ?? defaultMessage, context: finalContext)
  }

  /**
   Logs the successful completion of a keychain operation.

   - Parameters:
     - operation: The operation that succeeded
     - account: The account identifier (sensitive information)
     - additionalContext: Optional additional context metadata
     - message: Optional custom message
   */
  public func logOperationSuccess(
    operation: String,
    account: String,
    additionalContext: LogMetadataDTOCollection? = nil,
    message: String? = nil
  ) async {
    let context = KeychainLogContext(
      account: account,
      operation: operation,
      status: "success"
    )
    
    // Add additional context if provided
    let finalContext = if let additionalContext {
      context.withAdditionalMetadata(additionalContext)
    } else {
      context
    }

    let defaultMessage = "Successfully completed keychain operation: \(operation)"
    await info(message ?? defaultMessage, context: finalContext)
  }

  /**
   Logs the failure of a keychain operation.

   - Parameters:
     - operation: The operation that failed
     - account: The account identifier (sensitive information)
     - error: The error that occurred
     - additionalContext: Optional additional context metadata
     - message: Optional custom message
   */
  public func logOperationError(
    operation: String,
    account: String,
    error: Error,
    additionalContext: LogMetadataDTOCollection? = nil,
    message: String? = nil
  ) async {
    let context = KeychainLogContext(
      account: account,
      operation: operation,
      status: "error"
    )
    
    // Add additional context if provided
    let contextWithAdditional = if let additionalContext {
      context.withAdditionalMetadata(additionalContext)
    } else {
      context
    }

    // Log the error first
    await logError(error, context: contextWithAdditional)

    // If a custom message was provided, log it as well
    if let message {
      await self.error(message, context: contextWithAdditional)
    }
  }
}

/**
 A basic implementation of LogContextDTO for use with the KeychainLogger.
 */
private struct BaseLogContextDTO: LogContextDTO {
  let domainName: String
  let source: String?
  let correlationID: String?
  private let metadataCollection: LogMetadataDTOCollection
  
  init(domainName: String, source: String?, correlationID: String? = nil, metadataCollection: LogMetadataDTOCollection = LogMetadataDTOCollection()) {
    self.domainName = domainName
    self.source = source
    self.correlationID = correlationID
    self.metadataCollection = metadataCollection
  }
  
  func getSource() -> String {
    source ?? "KeychainServices"
  }
  
  func getDomain() -> String {
    domainName
  }
  
  // Required by LogContextDTO protocol
  var metadata: LogMetadataDTOCollection {
    metadataCollection
  }
  
  // Required by LogContextDTO protocol
  func createMetadataCollection() -> LogMetadataDTOCollection {
    metadataCollection
  }
  
  func withUpdatedMetadata(_ updatedMetadata: LogMetadataDTOCollection) -> BaseLogContextDTO {
    BaseLogContextDTO(domainName: domainName, source: source, correlationID: correlationID, metadataCollection: updatedMetadata)
  }
}
