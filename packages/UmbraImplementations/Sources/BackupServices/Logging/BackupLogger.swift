import BackupInterfaces
import Foundation
import LoggingInterfaces
import LoggingTypes

/**
 * A backup-specific log context for structured logging of backup operations.
 *
 * This provides metadata tailored for backup operations including operation type,
 * backup location, and status information with appropriate privacy controls.
 */
public struct BackupLogContext: LogContextDTO {
  /// The source of the log entry
  public let source: String?
  
  /// The metadata collection for this log entry
  public let metadata: LogMetadataDTOCollection
  
  /// The type of backup operation being performed
  public let operation: String
  
  /// The backup location or identifier (with privacy protection)
  public let location: String
  
  /// The status of the operation
  public let status: String
  
  /**
   * Creates a new backup log context.
   *
   * - Parameters:
   *   - operation: The type of backup operation
   *   - location: The backup location or identifier
   *   - status: The status of the operation
   *   - source: The source of the log (optional)
   *   - metadata: Additional metadata for the log entry
   */
  public init(
    operation: String,
    location: String,
    status: String,
    source: String? = "BackupLogger",
    metadata: LogMetadataDTOCollection = LogMetadataDTOCollection()
  ) {
    self.operation = operation
    self.location = location
    self.status = status
    self.source = source
    
    // Create a new metadata collection with backup-specific fields
    var enhancedMetadata = metadata
    enhancedMetadata.addPrivate(key: "operation", value: operation)
    enhancedMetadata.addPrivate(key: "location", value: location)
    enhancedMetadata.addPublic(key: "status", value: status)
    
    self.metadata = enhancedMetadata
  }
  
  /**
   * Creates an updated copy of this context with new metadata.
   *
   * - Parameter metadata: The new metadata collection
   * - Returns: A new context with updated metadata
   */
  public func withUpdatedMetadata(_ metadata: LogMetadataDTOCollection) -> BackupLogContext {
    BackupLogContext(
      operation: operation,
      location: location,
      status: status,
      source: source,
      metadata: metadata
    )
  }
  
  /**
   * Returns the source of the log entry.
   *
   * - Returns: The source string or nil if not available
   */
  public func getSource() -> String? {
    return source
  }
  
  /**
   * Converts the context to standard log metadata.
   *
   * - Returns: The log metadata representation of this context
   */
  public func asLogMetadata() -> LogMetadata {
    let logMetadata = LogMetadata()
    // Convert necessary fields from the metadata collection
    // This is a simplified conversion
    return logMetadata
  }
}

/**
 * A domain-specific logger for backup operations.
 *
 * This logger provides structured, privacy-aware logging specifically for
 * backup operations, following the Alpha Dot Five architecture principles.
 * It ensures proper privacy classifications for sensitive information like
 * file paths and backup metadata.
 */
public actor BackupLogger: DomainLoggerProtocol {
  /// The domain name for this logger
  public let domainName: String = "Backup"
  
  /// The underlying logging service
  private let loggingService: LoggingProtocol
  
  /**
   * Create a new backup logger
   *
   * - Parameter logger: The underlying logging service to use
   */
  public init(logger: LoggingProtocol) {
    self.loggingService = logger
  }
  
  /**
   * Log a message with the specified level
   *
   * - Parameters:
   *   - level: The log level
   *   - message: The message to log
   */
  public func log(_ level: LogLevel, _ message: String) async {
    // For backward compatibility, create a basic backup context
    let context = BackupLogContext(
      operation: "generic",
      location: "unknown",
      status: "info"
    )
    
    await log(level, message, context: context)
  }
  
  /**
   * Log a message with the specified level and context
   *
   * - Parameters:
   *   - level: The log level
   *   - message: The message to log
   *   - context: The backup context for the log entry
   */
  public func log(_ level: LogLevel, _ message: String, context: LogContextDTO) async {
    let formattedMessage = "[\(domainName)] \(message)"
    
    // Use the appropriate loggers
    if let loggingService = self.loggingService as? LoggingProtocol {
      await loggingService.log(level, formattedMessage, context: context)
    } else {
      // Legacy fallback for older LoggingServiceProtocol
      let metadata = context.asLogMetadata()
      
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
  
  /**
   * Log an error with context
   *
   * - Parameters:
   *   - error: The error to log
   *   - context: The context for the log entry
   */
  public func logError(_ error: Error, context: LogContextDTO) async {
    if let loggableError = error as? LoggableErrorProtocol {
      // Use the error's built-in privacy metadata
      let errorMetadata = loggableError.getPrivacyMetadata().toLogMetadata()
      let formattedMessage = "[\(domainName)] \(loggableError.getLogMessage())"
      let source = "\(loggableError.getSource()) via \(domainName)"

      await loggingService.error(formattedMessage, metadata: errorMetadata, source: source)
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
    let defaultMessage = "Error during backup operation: \(error.localizedDescription)"
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
