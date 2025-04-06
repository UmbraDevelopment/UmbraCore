import BackupInterfaces
import Foundation
import LoggingInterfaces
import LoggingTypes
import LoggingAdapters

/**
 * A domain-specific logger for backup operations.
 *
 * This actor provides structured logging capabilities tailored for backup operations,
 * with privacy controls for sensitive information such as backup locations and
 * file paths and backup metadata.
 */
public actor BackupLogger: DomainLoggerProtocol {
  /// The domain name for this logger
  public let domainName: String = "Backup"
  
  /// The underlying logging service
  private let loggingService: LoggingProtocol
  
  /**
   * Initialises a new backup logger.
   *
   * - Parameter logger: The underlying logging service to use
   */
  public init(logger: LoggingProtocol) {
    self.loggingService = logger
  }
  
  // MARK: - Core logging methods
  
  /**
   * Logs a message with the specified level and context.
   *
   * - Parameters:
   *   - level: The severity level of the log
   *   - message: The message to log
   *   - context: The context containing metadata
   */
  public func log(_ level: LogLevel, _ message: String, context: LogContextDTO) async {
    let formattedMessage = "[\(domainName)] \(message)"
    await loggingService.log(level, formattedMessage, context: context)
  }
  
  /**
   * Logs a message with the specified level.
   *
   * - Parameters:
   *   - level: The severity level of the log
   *   - message: The message to log
   */
  public func log(_ level: LogLevel, _ message: String) async {
    // For backward compatibility, create a basic backup context
    let context = BackupLogContext(correlationID: UUID().uuidString, source: domainName)
    await log(level, message, context: context)
  }
  
  /**
   * Logs an error with additional context.
   *
   * - Parameters:
   *   - error: The error to log
   *   - context: The log context
   *   - message: Optional custom message
   */
  public func logError(_ error: Error, context: LogContextDTO, message: String? = nil) async {
    if let loggableError = error as? LoggableError {
      // Handle loggable errors with enriched metadata
      let errorMetadata = loggableError.getLogMetadata()
      let formattedMessage = message ?? "[\(domainName)] \(loggableError.getLogMessage())"
      let source = "\(loggableError.getSource()) via \(domainName)"
      
      // Create a new context with error metadata
      if let backupContext = context as? BackupLogContext {
        // Update the context with error information
        let updatedContext = backupContext.withUpdatedMetadata(
          backupContext.metadata.withPrivate(key: "error", value: error.localizedDescription)
        )
        await log(.error, formattedMessage, context: updatedContext)
      } else {
        // Use the context as is
        await log(.error, formattedMessage, context: context)
      }
    } else {
      // Handle standard errors
      let formattedMessage = "[\(domainName)] \(error.localizedDescription)"
      
      if let backupContext = context as? BackupLogContext {
        // Update the context with error information
        let updatedContext = backupContext.withUpdatedMetadata(
          backupContext.metadata.withPrivate(key: "error", value: error.localizedDescription)
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
   * Logs the start of a backup operation.
   *
   * - Parameters:
   *   - context: The log context
   *   - message: Optional custom message
   */
  public func logOperationStart(
    context: LogContextDTO,
    message: String? = nil
  ) async {
    let defaultMessage = "Starting backup operation"
    await info(message ?? defaultMessage, context: context)
  }
  
  /**
   * Logs a successful backup operation.
   *
   * - Parameters:
   *   - context: The log context
   *   - result: Optional operation result
   *   - message: Optional custom message
   */
  public func logOperationSuccess(
    context: LogContextDTO,
    result: (some Sendable)? = nil,
    message: String? = nil
  ) async {
    var defaultMessage = "Backup operation completed successfully"
    
    if let result = result {
      defaultMessage += " with result: \(String(describing: result))"
    }
    
    await info(message ?? defaultMessage, context: context)
  }
  
  /**
   * Logs a failed backup operation.
   *
   * - Parameters:
   *   - context: The log context
   *   - message: Optional custom message
   */
  public func logOperationFailure(
    context: LogContextDTO,
    message: String? = nil
  ) async {
    let defaultMessage = "Backup operation failed"
    await warning(message ?? defaultMessage, context: context)
  }
  
  /**
   * Logs an error during a backup operation.
   *
   * - Parameters:
   *   - context: The log context
   *   - error: The error that occurred
   *   - message: Optional custom message
   */
  public func logOperationError(
    context: LogContextDTO,
    error: Error,
    message: String? = nil
  ) async {
    await logError(error, context: context)
    
    if let message = message {
      await error(message, context: context)
    }
  }
  
  /**
   * Logs a cancellation of a backup operation.
   *
   * - Parameters:
   *   - context: The log context
   *   - message: Optional custom message
   */
  public func logOperationCancelled(
    context: LogContextDTO,
    message: String? = nil
  ) async {
    let defaultMessage = "Backup operation was cancelled"
    await info(message ?? defaultMessage, context: context)
  }
}
