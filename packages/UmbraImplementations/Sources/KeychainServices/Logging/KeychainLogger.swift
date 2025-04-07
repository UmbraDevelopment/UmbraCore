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
 */
public actor KeychainLogger: DomainLoggerProtocol {
  /// The domain name for this logger
  public let domainName: String="Keychain"

  /// The underlying logging service
  private let loggingService: LoggingProtocol

  /**
   Initialises a new keychain logger.

   - Parameter logger: The core logger to wrap
   */
  public init(logger: LoggingProtocol) {
    loggingService=logger
  }

  /**
   Required by DomainLoggerProtocol - logs with context

   - Parameters:
     - level: The log level
     - message: The message to log
     - context: The context for the log entry
   */
  public func logWithContext(_ level: LogLevel, _ message: String, context: LogContextDTO) async {
    let formattedMessage="[\(domainName)] \(message)"
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
    let context=KeychainLogContext(
      operation: "generic",
      account: "unknown",
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
    if let loggableError=error as? LoggableErrorProtocol {
      // Create a new context for the error
      var errorContext=BaseLogContextDTO(
        domainName: domainName,
        source: context.getSource()
      )

      // Add error-specific metadata
      errorContext=errorContext.withUpdatedMetadata(
        LogMetadataDTOCollection()
          .withPrivate(key: "errorType", value: String(describing: type(of: loggableError)))
          .withPrivate(key: "errorMessage", value: loggableError.getLogMessage())
      )

      let formattedMessage="[\(domainName)] \(loggableError.getLogMessage())"
      await loggingService.error(formattedMessage, context: errorContext)
    } else {
      // Handle standard errors
      let formattedMessage="[\(domainName)] \(error.localizedDescription)"

      if let keychainContext=context as? KeychainLogContext {
        // Update the context with error information
        let updatedContext=keychainContext.withUpdatedMetadata(
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

  /// Log a message with trace level
  public func trace(_ message: String) async {
    await log(.trace, message)
  }

  /// Log a message with debug level
  public func debug(_ message: String) async {
    await log(.debug, message)
  }

  /// Log a message with info level
  public func info(_ message: String) async {
    await log(.info, message)
  }

  /// Log a message with warning level
  public func warning(_ message: String) async {
    await log(.warning, message)
  }

  /// Log a message with error level
  public func error(_ message: String) async {
    await log(.error, message)
  }

  /// Log a message with critical level
  public func critical(_ message: String) async {
    await log(.critical, message)
  }

  // MARK: - Domain-specific logging methods

  /**
   Logs the start of a keychain operation.

   - Parameters:
     - operation: The operation being performed
     - account: The account identifier (private metadata)
     - message: Optional custom message
   */
  public func logOperationStart(
    operation: String,
    account: String,
    message: String?=nil
  ) async {
    let context=KeychainLogContext(
      operation: operation,
      account: account,
      status: "started"
    )

    let defaultMessage="Starting keychain operation: \(operation)"
    await info(message ?? defaultMessage, context: context)
  }

  /**
   Logs the successful completion of a keychain operation.

   - Parameters:
     - operation: The operation that succeeded
     - account: The account identifier (private metadata)
     - message: Optional custom message
   */
  public func logOperationSuccess(
    operation: String,
    account: String,
    message: String?=nil
  ) async {
    let context=KeychainLogContext(
      operation: operation,
      account: account,
      status: "success"
    )

    let defaultMessage="Successfully completed keychain operation: \(operation)"
    await info(message ?? defaultMessage, context: context)
  }

  /**
   Logs the failure of a keychain operation.

   - Parameters:
     - operation: The operation that failed
     - account: The account identifier (private metadata)
     - error: The error that occurred
     - message: Optional custom message
   */
  public func logOperationError(
    operation: String,
    account: String,
    error: Error,
    message: String?=nil
  ) async {
    let context=KeychainLogContext(
      operation: operation,
      account: account,
      status: "error"
    )

    // Log the error first
    await logError(error, context: context)

    // If a custom message was provided, log it as well
    if let message {
      await self.error(message, context: context)
    }
  }
}
