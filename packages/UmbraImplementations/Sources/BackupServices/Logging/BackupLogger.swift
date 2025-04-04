import BackupInterfaces
import Foundation
import LoggingInterfaces
import LoggingTypes

/**
 * A domain-specific logger for backup operations.
 *
 * This logger provides structured, privacy-aware logging specifically for
 * backup operations, following the Alpha Dot Five architecture principles.
 * It ensures proper privacy classifications for sensitive information like
 * file paths and backup metadata.
 */
public struct BackupLogger {
  /// The base domain logger
  private let domainLogger: DomainLogger

  /**
   * Initialises a new backup logger.
   *
   * - Parameter logger: The underlying logging protocol
   */
  public init(logger: LoggingProtocol) {
    domainLogger=BaseDomainLogger(logger: logger)
  }

  /**
   * Logs the start of a backup operation.
   *
   * - Parameters:
   *   - context: The log context
   *   - message: Optional custom message
   */
  public func logOperationStart(
    context: LogContextDTO,
    message: String?=nil
  ) async {
    let defaultMessage="Starting backup operation"
    await domainLogger.logOperationStart(
      context: context,
      message: message ?? defaultMessage
    )
  }

  /**
   * Logs successful operation completion with a specific result.
   *
   * - Parameters:
   *   - context: The logging context
   *   - result: The operation result
   */
  public func logOperationSuccess<T>(
    context: BackupLogContext,
    result: T
  ) async {
    let enhancedContext = context.withPublic(
      key: "result_type",
      value: String(describing: T.self)
    )
    
    await logger.info(
      context: enhancedContext,
      message: "Operation completed successfully"
    )
  }
  
  /**
   * Logs successful operation completion with a message.
   *
   * - Parameters:
   *   - context: The logging context
   *   - message: Success message to log
   */
  public func logOperationSuccess(
    context: BackupLogContext,
    message: String
  ) async {
    await logger.info(
      context: context,
      message: message
    )
  }
  
  /**
   * Logs operation failure.
   *
   * - Parameters:
   *   - context: The logging context
   *   - error: The error that caused the failure
   */
  public func logOperationFailure(
    context: BackupLogContext,
    error: Error
  ) async {
    let enhancedContext = context.withPublic(
      key: "error_type",
      value: String(describing: type(of: error))
    )
    
    await logger.error(
      context: enhancedContext,
      message: "Operation failed: \(error.localizedDescription)",
      error: error
    )
  }

  /**
   * Logs the successful completion of a backup operation.
   *
   * - Parameters:
   *   - context: The log context
   *   - result: Optional operation result
   *   - message: Optional custom message
   */
  public func logOperationSuccess(
    context: LogContextDTO,
    result: (some Sendable)?=nil,
    message: String?=nil
  ) async {
    let defaultMessage="Backup operation completed successfully"
    await domainLogger.logOperationSuccess(
      context: context,
      result: result,
      message: message ?? defaultMessage
    )
  }

  /**
   * Logs an error that occurred during a backup operation.
   *
   * - Parameters:
   *   - context: The log context
   *   - error: The error that occurred
   *   - message: Optional custom message
   */
  public func logOperationError(
    context: LogContextDTO,
    error: Error,
    message: String?=nil
  ) async {
    let errorMessage=message ?? "Backup operation failed: \(error.localizedDescription)"
    await domainLogger.logOperationError(
      context: context,
      error: error,
      message: errorMessage
    )
  }

  /**
   * Logs a progress update for a backup operation.
   *
   * - Parameters:
   *   - context: The log context
   *   - progress: The current progress information
   *   - message: Optional custom message
   */
  public func logOperationProgress(
    context: LogContextDTO,
    progress: BackupProgress,
    message: String?=nil
  ) async {
    var progressContext=BackupLogContext()

    if let operation=(context as? BackupLogContext)?.operation {
      progressContext=progressContext.with(operation: operation)
    }

    // Add progress information with appropriate privacy levels
    progressContext=progressContext.with(
      key: "percentComplete",
      value: String(progress.percentComplete),
      privacy: .public
    )

    if let processed=progress.processedItems {
      progressContext=progressContext.with(
        key: "processedItems",
        value: String(processed),
        privacy: .public
      )
    }

    if let total=progress.totalItems {
      progressContext=progressContext.with(
        key: "totalItems",
        value: String(total),
        privacy: .public
      )
    }

    if let currentItem=progress.currentItem {
      progressContext=progressContext.with(
        key: "currentItem",
        value: currentItem,
        privacy: .private
      )
    }

    let defaultMessage="Backup operation progress: \(progress.percentComplete)% complete"
    await domainLogger.log(
      level: .debug,
      message: message ?? defaultMessage,
      metadata: PrivacyMetadata([:]),
      source: "BackupLogger"
    )
  }

  /**
   * Logs a cancellation of a backup operation.
   *
   * - Parameters:
   *   - context: The log context
   *   - message: Optional custom message
   */
  public func logOperationCancelled(
    context _: LogContextDTO,
    message: String?=nil
  ) async {
    let defaultMessage="Backup operation was cancelled"
    await domainLogger.log(
      level: .info,
      message: message ?? defaultMessage,
      metadata: PrivacyMetadata([:]),
      source: "BackupLogger"
    )
  }
}

/**
 * The base domain logger implementation for common logging patterns.
 *
 * This class provides standardised logging methods that are used by
 * domain-specific loggers to ensure consistent log formatting and
 * privacy handling across the application.
 */
private struct BaseDomainLogger: DomainLogger {
  /// The underlying logging protocol
  private let logger: LoggingProtocol

  /**
   * Initialises a new base domain logger.
   *
   * - Parameter logger: The underlying logging protocol
   */
  init(logger: LoggingProtocol) {
    self.logger=logger
  }

  /**
   * Logs an operation start.
   *
   * - Parameters:
   *   - context: The log context
   *   - message: The message to log
   */
  func logOperationStart(
    context _: LogContextDTO,
    message: String
  ) async {
    await logger.log(
      .info,
      message,
      metadata: PrivacyMetadata([:]),
      source: "BaseDomainLogger"
    )
  }

  /**
   * Logs an operation success.
   *
   * - Parameters:
   *   - context: The log context
   *   - result: Optional operation result
   *   - message: The message to log
   */
  func logOperationSuccess(
    context _: LogContextDTO,
    result _: (some Sendable)?,
    message: String
  ) async {
    await logger.log(
      .info,
      message,
      metadata: PrivacyMetadata([:]),
      source: "BaseDomainLogger"
    )
  }

  /**
   * Logs an operation error.
   *
   * - Parameters:
   *   - context: The log context
   *   - error: The error that occurred
   *   - message: The message to log
   */
  func logOperationError(
    context _: LogContextDTO,
    error _: Error,
    message: String
  ) async {
    await logger.log(
      .error,
      message,
      metadata: PrivacyMetadata([:]),
      source: "BaseDomainLogger"
    )
  }

  /**
   * Logs a general message.
   *
   * - Parameters:
   *   - level: The log level
   *   - message: The message to log
   *   - metadata: The metadata to log
   *   - source: The source of the log
   */
  func log(
    level: LogLevel,
    message: String,
    metadata: PrivacyMetadata,
    source: String
  ) async {
    await logger.log(
      level,
      message,
      metadata: metadata,
      source: source
    )
  }
}

/**
 * Protocol defining common logging patterns for domain loggers.
 *
 * This protocol establishes a consistent interface for all domain-specific
 * loggers to ensure standardised logging patterns throughout the application.
 */
private protocol DomainLogger {
  /**
   * Logs an operation start.
   *
   * - Parameters:
   *   - context: The log context
   *   - message: The message to log
   */
  func logOperationStart(
    context: LogContextDTO,
    message: String
  ) async

  /**
   * Logs an operation success.
   *
   * - Parameters:
   *   - context: The log context
   *   - result: Optional operation result
   *   - message: The message to log
   */
  func logOperationSuccess<R: Sendable>(
    context: LogContextDTO,
    result: R?,
    message: String
  ) async

  /**
   * Logs an operation error.
   *
   * - Parameters:
   *   - context: The log context
   *   - error: The error that occurred
   *   - message: The message to log
   */
  func logOperationError(
    context: LogContextDTO,
    error: Error,
    message: String
  ) async

  /**
   * Logs a general message.
   *
   * - Parameters:
   *   - level: The log level
   *   - message: The message to log
   *   - metadata: The metadata to log
   *   - source: The source of the log
   */
  func log(
    level: LogLevel,
    message: String,
    metadata: PrivacyMetadata,
    source: String
  ) async
}
