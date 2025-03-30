import Foundation
import LoggingInterfaces
import LoggingTypes
import OSLog

/**
 # DefaultLogger
 
 Basic logger implementation for when no logger is provided.
 This is used as a fallback to ensure logging is always available.
 */
public final class DefaultLogger: LoggingProtocol {
  /// The system logger for output
  private let logger: Logger
  
  /// The logging actor for this logger
  private let _loggingActor: LoggingActor
  
  /// Get the underlying logging actor
  public var loggingActor: LoggingActor {
    return _loggingActor
  }
  
  /// Initialise a new default logger
  public init() {
    logger = Logger(subsystem: "com.umbra.securitykeymanagement", category: "KeyManagement")
    
    // Initialize with a console log destination
    _loggingActor = LoggingActor(
      destinations: [ConsoleLogDestination()],
      minimumLogLevel: .debug
    )
  }
  
  /// Log a message at the specified level
  public func log(_ level: LogLevel, _ message: String, metadata: PrivacyMetadata?, source: String) async {
    let formattedMessage = "[\(source)] \(message)"
    
    // Log to OSLog
    switch level {
      case .trace:
        logger.debug("TRACE: \(formattedMessage)")
      case .debug:
        logger.debug("\(formattedMessage)")
      case .info:
        logger.info("\(formattedMessage)")
      case .warning:
        logger.warning("\(formattedMessage)")
      case .error:
        logger.error("\(formattedMessage)")
      case .critical:
        logger.critical("\(formattedMessage)")
    }
    
    // Also log to LoggingActor with a context
    let context = LogContext(
      source: source,
      metadata: metadata ?? PrivacyMetadata()
    )
    
    await loggingActor.log(
      level: level,
      message: message,
      context: context
    )
  }
  
  /// Support for the legacy CoreLoggingProtocol method
  public func logMessage(_ level: LogLevel, _ message: String, context: LogContext) async {
    let source = context.source
    // Use the metadata directly without downcasting
    await log(level, message, metadata: nil, source: source)
  }
  
  /// Log trace message
  public func trace(_ message: String, metadata: PrivacyMetadata?, source: String) async {
    await log(.trace, message, metadata: metadata, source: source)
  }

  /// Log debug message
  public func debug(_ message: String, metadata: PrivacyMetadata?, source: String) async {
    await log(.debug, message, metadata: metadata, source: source)
  }

  /// Log info message
  public func info(_ message: String, metadata: PrivacyMetadata?, source: String) async {
    await log(.info, message, metadata: metadata, source: source)
  }

  /// Log warning message
  public func warning(_ message: String, metadata: PrivacyMetadata?, source: String) async {
    await log(.warning, message, metadata: metadata, source: source)
  }

  /// Log error message
  public func error(_ message: String, metadata: PrivacyMetadata?, source: String) async {
    await log(.error, message, metadata: metadata, source: source)
  }
  
  /// Log critical message
  public func critical(_ message: String, metadata: PrivacyMetadata?, source: String) async {
    await log(.critical, message, metadata: metadata, source: source)
  }
}

/**
 A simple console log destination for the LoggingActor
 */
actor ConsoleLogDestination: ActorLogDestination {
  /// The identifier for this log destination
  public let identifier: String = "console"
  
  /// The minimum log level to process (nil means use the parent's level)
  public let minimumLogLevel: LogLevel? = nil
  
  /// Initializer
  public init() {}
  
  /// Determine if this destination should log the given level
  public func shouldLog(level: LogLevel) async -> Bool {
    return true // Log all levels
  }
  
  /// Write a log entry to this destination
  public func write(_ entry: LogEntry) async {
    // Format and print the log message
    let formattedMessage = "[\(entry.context.source)] [\(entry.level.rawValue)] \(entry.message)"
    print(formattedMessage)
  }
}
