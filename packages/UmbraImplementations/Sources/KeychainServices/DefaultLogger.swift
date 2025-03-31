import Foundation
import LoggingInterfaces
import LoggingTypes
import os

/**
 # Default Logger

 A simple logger implementation that uses the Apple OSLog system.
 This implementation follows the Alpha Dot Five architecture's privacy-by-design
 principles, ensuring sensitive information is properly redacted in logs.
 */
public final class DefaultLogger: LoggingProtocol, CoreLoggingProtocol {
  private let logger: Logger

  /// Creates a new DefaultLogger
  public init() {
    logger=Logger(subsystem: "com.umbra.keychainservices", category: "KeychainServices")
  }

  /// The actor used for all logging operations
  private let _loggingActor=LoggingActor(destinations: [], minimumLogLevel: .info)

  /// Get the underlying logging actor
  public var loggingActor: LoggingActor {
    _loggingActor
  }

  /// Required CoreLoggingProtocol implementation
  public func logMessage(_ level: LogLevel, _ message: String, context: LogContext) async {
    switch level {
      case .trace:
        // Forward to debug since we don't have trace
        await debug(message, metadata: context.metadata, source: context.source)
      case .debug:
        await debug(message, metadata: context.metadata, source: context.source)
      case .info:
        await info(message, metadata: context.metadata, source: context.source)
      case .warning:
        await warning(message, metadata: context.metadata, source: context.source)
      case .error:
        await error(message, metadata: context.metadata, source: context.source)
      case .critical:
        await critical(message, metadata: context.metadata, source: context.source)
    }
  }

  /// Log a debug message
  public func debug(_ message: String, metadata: LogMetadata?, source: String?) async {
    let logContext=buildLogContext(metadata: metadata, source: source)
    logger.debug("\(message, privacy: .public)")
    await loggingActor.log(level: .debug, message: message, context: logContext)
  }

  /// Log an info message
  public func info(_ message: String, metadata: LogMetadata?, source: String?) async {
    let logContext=buildLogContext(metadata: metadata, source: source)
    logger.info("\(message, privacy: .public)")
    await loggingActor.log(level: .info, message: message, context: logContext)
  }

  /// Log a warning message
  public func warning(_ message: String, metadata: LogMetadata?, source: String?) async {
    let logContext=buildLogContext(metadata: metadata, source: source)
    logger.warning("\(message, privacy: .public)")
    await loggingActor.log(level: .warning, message: message, context: logContext)
  }

  /// Log an error message
  public func error(_ message: String, metadata: LogMetadata?, source: String?) async {
    let logContext=buildLogContext(metadata: metadata, source: source)
    logger.error("\(message, privacy: .public)")
    await loggingActor.log(level: .error, message: message, context: logContext)
  }

  /// Log a critical error message
  public func critical(_ message: String, metadata: LogMetadata?, source: String?) async {
    let logContext=buildLogContext(metadata: metadata, source: source)
    logger.critical("\(message, privacy: .public)")
    await loggingActor.log(level: .critical, message: message, context: logContext)
  }

  /// Build a log context for logging
  private func buildLogContext(metadata: LogMetadata?, source: String?) -> LogContext {
    var context=LogContext(timestamp: Date())
    if let metadata {
      context.metadata=metadata
    }
    if let source {
      context.source=source
    }
    return context
  }
}
