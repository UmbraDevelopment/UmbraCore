import Foundation
import LoggingAdapters
import LoggingInterfaces
import LoggingTypes

/**
 # Bookmark Logger

 A domain-specific privacy-aware logger for security bookmark operations that follows
 the Alpha Dot Five architecture principles for structured logging.

 This logger ensures that sensitive information related to bookmark operations
 is properly classified with appropriate privacy levels, with British spelling
 in documentation and comments.
 */
public actor BookmarkLogger: DomainLoggerProtocol {
  /// The domain name for this logger
  public let domainName: String="BookmarkServices"

  /// The underlying logging service
  private let loggingService: LoggingProtocol

  /**
   Initialises a new bookmark logger.

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
    // For backward compatibility, create a basic bookmark context
    let context=BookmarkLogContext(
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
     - context: The bookmark context for the log entry
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

      if let bookmarkContext=context as? BookmarkLogContext {
        // Update the context with error information
        let updatedContext=bookmarkContext.withUpdatedMetadata(
          bookmarkContext.metadata.withPrivate(key: "error", value: error.localizedDescription)
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
   Logs the start of a bookmark operation.

   - Parameters:
     - operation: The operation being performed
     - identifier: The bookmark identifier (optional)
     - additionalContext: Optional additional context to merge with the primary context
     - message: Optional custom message
   */
  public func logOperationStart(
    operation: String,
    identifier: String? = nil,
    additionalContext: LogMetadataDTOCollection? = nil,
    message: String? = nil
  ) async {
    var context = BookmarkLogContext(
      operation: operation,
      identifier: identifier,
      status: "started"
    )
    
    // Merge additional context if provided
    if let additionalContext {
      context = context.withAdditionalMetadata(additionalContext)
    }

    let defaultMessage = "Starting bookmark operation: \(operation)"
    await info(message ?? defaultMessage, context: context)
  }

  /**
   Logs the successful completion of a bookmark operation.

   - Parameters:
     - operation: The operation that succeeded
     - identifier: The bookmark identifier (optional)
     - additionalContext: Optional additional context to merge with the primary context
     - message: Optional custom message
   */
  public func logOperationSuccess(
    operation: String,
    identifier: String? = nil,
    additionalContext: LogMetadataDTOCollection? = nil,
    message: String? = nil
  ) async {
    var context = BookmarkLogContext(
      operation: operation,
      identifier: identifier,
      status: "success"
    )
    
    // Merge additional context if provided
    if let additionalContext {
      context = context.withAdditionalMetadata(additionalContext)
    }

    let defaultMessage = "Bookmark operation completed successfully: \(operation)"
    await info(message ?? defaultMessage, context: context)
  }

  /**
   Logs a warning during a bookmark operation.

   - Parameters:
     - operation: The operation
     - warningMessage: The warning message
     - identifier: The bookmark identifier (optional)
     - additionalContext: Optional additional context to merge with the primary context
   */
  public func logOperationWarning(
    operation: String,
    warningMessage: String,
    identifier: String? = nil,
    additionalContext: LogMetadataDTOCollection? = nil
  ) async {
    var metadata = LogMetadataDTOCollection()
    metadata = metadata.withPrivate(key: "warning", value: warningMessage)

    var context = BookmarkLogContext(
      operation: operation,
      identifier: identifier,
      status: "warning",
      metadata: metadata
    )
    
    // Merge additional context if provided
    if let additionalContext {
      context = context.withAdditionalMetadata(additionalContext)
    }

    let defaultMessage = "Warning during bookmark operation: \(operation)"
    await warning(defaultMessage, context: context)
  }

  /**
   Logs the failure of a bookmark operation.

   - Parameters:
     - operation: The operation that failed
     - error: The error that occurred
     - identifier: The bookmark identifier (optional)
     - additionalContext: Optional additional context to merge with the primary context
     - message: Optional custom message
   */
  public func logOperationError(
    operation: String,
    error: Error,
    identifier: String? = nil,
    additionalContext: LogMetadataDTOCollection? = nil,
    message: String? = nil
  ) async {
    var context = BookmarkLogContext(
      operation: operation,
      identifier: identifier,
      status: "error"
    )
    
    // Merge additional context if provided
    if let additionalContext {
      context = context.withAdditionalMetadata(additionalContext)
    }

    if let loggableError = error as? LoggableErrorProtocol {
      // Get metadata from the loggable error
      let errorMetadata = loggableError.createMetadataCollection()
      
      // Merge with the context
      context = context.withAdditionalMetadata(errorMetadata)
      
      // Use the error's log message if no custom message is provided
      let errorMessage = message ?? "Bookmark operation failed: \(operation) - \(loggableError.getLogMessage())"
      await self.error(errorMessage, context: context)
    } else {
      // For standard errors, add the error description to the context
      let errorMetadata = LogMetadataDTOCollection().withPrivate(key: "error", value: error.localizedDescription)
      context = context.withAdditionalMetadata(errorMetadata)
      
      // Use a generic error message if no custom message is provided
      let errorMessage = message ?? "Bookmark operation failed: \(operation) - \(error.localizedDescription)"
      await self.error(errorMessage, context: context)
    }
  }
}
