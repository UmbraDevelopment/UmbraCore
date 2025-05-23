import BackupInterfaces
import Foundation
import LoggingInterfaces
import LoggingTypes
import UmbraErrors

/**
 * A domain-specific logger for backup operations.
 *
 * This actor provides structured logging capabilities tailored for backup operations,
 * with privacy controls for sensitive information such as backup locations and
 * file paths and backup metadata.
 */
public actor BackupLogger: DomainLoggerProtocol {
  /// The underlying logger
  private let loggingService: any LoggingProtocol

  /// The domain name for this logger
  private let domainName: String

  /**
   * Initialises a new backup logger.
   *
   * - Parameters:
   *   - loggingService: The underlying logger
   *   - domainName: The domain name for this logger
   */
  public init(loggingService: any LoggingProtocol, domainName: String="Backup") {
    self.loggingService=loggingService
    self.domainName=domainName
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
  public func log(_ level: LogLevel, _ message: String, context: BackupLogContext) async {
    let formattedMessage="[\(domainName)] \(message)"
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
    let context=BackupLogContextImpl(
      domainName: domainName,
      source: domainName
    )
    await log(level, message, context: context)
  }

  /**
   * Logs with a specific domain context.
   *
   * - Parameters:
   *   - level: The severity level of the log
   *   - message: The message to log
   *   - context: The log context
   */
  public func logWithContext(
    _ level: LogLevel,
    _ message: String,
    context: BackupLogContext
  ) async {
    await log(level, message, context: context)
  }

  /**
   * Logs an error with additional context and optional message.
   *
   * - Parameters:
   *   - error: The error to log
   *   - context: The log context
   *   - additionalContext: Optional additional context to merge with the primary context
   *   - message: Optional custom message
   */
  public func logError(
    _ error: Error,
    context: BackupLogContext,
    additionalContext: LogMetadataDTOCollection?=nil,
    message: String?=nil
  ) async {
    // Create the final context by merging the additional context if provided
    let finalContext=if let additionalContext {
      context.withUpdatedMetadata(context.metadata.merging(with: additionalContext))
    } else {
      context
    }

    if let loggableError=error as? LoggableErrorProtocol {
      // Handle loggable errors with enriched metadata
      let errorMetadata=loggableError.createMetadataCollection()
      let formattedMessage=message ?? "[\(domainName)] \(loggableError.getLogMessage())"
      let source="\(loggableError.getSource()) via \(domainName)"

      // Create a new context with error information
      if let backupContext=finalContext as? BackupLogContextImpl {
        // Update the context with error information
        let updatedContext=backupContext.withUpdatedMetadata(
          backupContext.metadata.merging(with: errorMetadata).withPrivate(
            key: "error",
            value: error.localizedDescription
          )
        )
        await log(.error, formattedMessage, context: updatedContext)
      } else {
        // Use the context as is
        await log(.error, formattedMessage, context: finalContext)
      }
    } else {
      // Handle standard errors
      let formattedMessage=message ?? "[\(domainName)] \(error.localizedDescription)"

      if let backupContext=finalContext as? BackupLogContextImpl {
        // Update the context with error information
        let updatedContext=backupContext.withUpdatedMetadata(
          backupContext.metadata.withPrivate(key: "error", value: error.localizedDescription)
        )
        await log(.error, formattedMessage, context: updatedContext)
      } else {
        // Use the context as is
        await log(.error, formattedMessage, context: finalContext)
      }
    }
  }

  /**
   * Logs a message with the specified log level.
   *
   * - Parameters:
   *   - level: The log level
   *   - context: The log context
   *   - additionalContext: Optional additional context to merge with the primary context
   *   - message: The message to log
   */
  public func log(
    level: LogLevel,
    context: BackupLogContext,
    additionalContext: LogMetadataDTOCollection?=nil,
    message: String
  ) async {
    // Create the final context by merging the additional context if provided
    let finalContext=if let additionalContext {
      context.withUpdatedMetadata(context.metadata.merging(with: additionalContext))
    } else {
      context
    }

    let enhancedContext=enhanceContext(finalContext)

    await loggingService.log(
      level,
      message,
      context: enhancedContext
    )
  }

  /**
   * Enhances a log context with additional information.
   *
   * - Parameter context: The context to enhance
   * - Returns: The enhanced context
   */
  private func enhanceContext(_ context: BackupLogContext) -> BackupLogContextImpl {
    if let backupContext=context as? BackupLogContextImpl {
      return backupContext
    }

    // Create a new context with the same information
    return BackupLogContextImpl(
      domainName: context.domainName,
      metadata: context.getMetadata()
    )
  }

  // MARK: - Standard logging levels with context

  /// Log a message with trace level and context
  public func trace(
    _ message: String,
    context: BackupLogContext,
    additionalContext: LogMetadataDTOCollection?=nil
  ) async {
    await log(
      level: .trace,
      context: context,
      additionalContext: additionalContext,
      message: message
    )
  }

  /// Log a message with debug level and context
  public func debug(
    _ message: String,
    context: BackupLogContext,
    additionalContext: LogMetadataDTOCollection?=nil
  ) async {
    await log(
      level: .debug,
      context: context,
      additionalContext: additionalContext,
      message: message
    )
  }

  /// Log a message with info level and context
  public func info(
    _ message: String,
    context: BackupLogContext,
    additionalContext: LogMetadataDTOCollection?=nil
  ) async {
    await log(
      level: .info,
      context: context,
      additionalContext: additionalContext,
      message: message
    )
  }

  /// Log a message with warning level and context
  public func warning(
    _ message: String,
    context: BackupLogContext,
    additionalContext: LogMetadataDTOCollection?=nil
  ) async {
    await log(
      level: .warning,
      context: context,
      additionalContext: additionalContext,
      message: message
    )
  }

  /// Log a message with error level and context
  public func error(
    _ message: String,
    context: BackupLogContext,
    additionalContext: LogMetadataDTOCollection?=nil
  ) async {
    await log(
      level: .error,
      context: context,
      additionalContext: additionalContext,
      message: message
    )
  }

  /// Log a message with critical level and context
  public func critical(
    _ message: String,
    context: BackupLogContext,
    additionalContext: LogMetadataDTOCollection?=nil
  ) async {
    await log(
      level: .critical,
      context: context,
      additionalContext: additionalContext,
      message: message
    )
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
   *   - additionalContext: Optional additional context to merge with the primary context
   *   - message: Optional custom message
   */
  public func logOperationStart(
    context: BackupLogContext,
    additionalContext: LogMetadataDTOCollection?=nil,
    message: String?=nil
  ) async {
    let defaultMessage="Starting backup operation"
    await info(
      message ?? defaultMessage,
      context: context,
      additionalContext: additionalContext
    )
  }

  /**
   * Logs a successful backup operation.
   *
   * - Parameters:
   *   - context: The log context
   *   - additionalContext: Optional additional context to merge with the primary context
   *   - result: Optional operation result
   *   - message: Optional custom message
   */
  public func logOperationSuccess(
    context: BackupLogContext,
    additionalContext: LogMetadataDTOCollection?=nil,
    result _: (some Sendable)?=nil,
    message: String?=nil
  ) async {
    // Create the final context by merging the additional context if provided
    let finalContext=if let additionalContext {
      context.withUpdatedMetadata(context.metadata.merging(with: additionalContext))
    } else {
      context
    }

    let enhancedContext=enhanceContext(finalContext)
      .withPublic(key: "status", value: "success")

    let defaultMessage="Backup operation completed successfully"
    await loggingService.log(
      .info,
      message ?? defaultMessage,
      context: enhancedContext
    )
  }

  /**
   * Logs an operation failure.
   *
   * - Parameters:
   *   - context: The log context
   *   - additionalContext: Optional additional context to merge with the primary context
   *   - message: The failure message
   */
  public func logOperationFailure(
    context: BackupLogContext,
    additionalContext: LogMetadataDTOCollection?=nil,
    message: String
  ) async {
    // Create the final context by merging the additional context if provided
    let finalContext=if let additionalContext {
      context.withUpdatedMetadata(context.metadata.merging(with: additionalContext))
    } else {
      context
    }

    let enhancedContext=enhanceContext(finalContext)
      .withPublic(key: "status", value: "failure")

    await loggingService.log(
      .error,
      message,
      context: enhancedContext
    )
  }

  /**
   * Logs an error during a backup operation.
   *
   * - Parameters:
   *   - context: The log context
   *   - additionalContext: Optional additional context to merge with the primary context
   *   - error: The error that occurred
   *   - message: Optional custom message
   */
  public func logOperationError(
    context: BackupLogContext,
    additionalContext: LogMetadataDTOCollection?=nil,
    error: Error,
    message: String?=nil
  ) async {
    await logError(error, context: context, additionalContext: additionalContext)

    if let message {
      // Use the error method, not try to call error as a function
      await self.error(message, context: context, additionalContext: additionalContext)
    }
  }

  /**
   * Logs a cancellation of a backup operation.
   *
   * - Parameters:
   *   - context: The log context
   *   - additionalContext: Optional additional context to merge with the primary context
   *   - message: Optional custom message
   */
  public func logOperationCancelled(
    context: BackupLogContext,
    additionalContext: LogMetadataDTOCollection?=nil,
    message: String?=nil
  ) async {
    // Create the final context by merging the additional context if provided
    let finalContext=if let additionalContext {
      context.withUpdatedMetadata(context.metadata.merging(with: additionalContext))
    } else {
      context
    }

    let enhancedContext=enhanceContext(finalContext)
      .withPublic(key: "status", value: "cancelled")

    let defaultMessage="Backup operation was cancelled"
    await loggingService.log(
      .info,
      message ?? defaultMessage,
      context: enhancedContext
    )
  }
}

extension BackupLogContext {
  func getMetadata() -> MetadataCollection {
    // Convert the BackupLogContext to a LogMetadataDTOCollection
    // This ensures all privacy annotations are properly maintained
    let metadataCollection=toMetadataCollection()

    // Convert to the legacy MetadataCollection format
    // This is needed for compatibility with the existing logging system
    var legacyMetadata=MetadataCollection()

    // Transfer all metadata with their privacy levels preserved
    for item in metadataCollection.items {
      switch item.privacyLevel {
        case .public:
          legacyMetadata.add(key: item.key, value: item.value, isPrivate: false)
        case .private, .sensitive, .hash:
          legacyMetadata.add(key: item.key, value: item.value, isPrivate: true)
        case .auto:
          // For auto privacy level, use the system's automatic detection
          legacyMetadata.add(key: item.key, value: item.value, isPrivate: false)
      }
    }

    return legacyMetadata
  }
}
