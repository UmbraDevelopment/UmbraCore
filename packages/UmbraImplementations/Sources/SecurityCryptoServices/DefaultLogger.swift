import Foundation
import LoggingInterfaces
import LoggingTypes
import OSLog

/**
 # DefaultLogger

 A simple logger implementation that provides basic logging functionality
 when no other logger is provided. This ensures that logging is always available
 even in minimal configurations.

 This logger uses OSLog on Apple platforms for efficient system integration.
 */
public final class DefaultLogger: LoggingProtocol {
  /// OSLog instance for system logging
  private let logger: Logger
  
  /// The logging actor for this logger
  private let _loggingActor: SimpleLoggingActor
  
  /// Get the underlying logging actor
  public var loggingActor: LoggingActor {
    return _loggingActor
  }
  
  /// Initialise a new logger with the default subsystem and category
  public init() {
    logger = Logger(subsystem: "com.umbra.securitycryptoservices", category: "CryptoServices")
    _loggingActor = SimpleLoggingActor()
  }
  
  /// Standard logging method that all level-specific methods delegate to
  public func log(_ level: LogLevel, _ message: String, metadata: PrivacyMetadata?, source: String) async {
    let formattedMessage = "[\(source)] \(message)"
    
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
 A simple implementation of LoggingActor for the DefaultLogger
 */
final class SimpleLoggingActor: LoggingActor {
  /// The OSLog instance for system logging
  private let logger = Logger(subsystem: "com.umbra.securitycryptoservices", category: "LoggingActor")
  
  /// Log a message at the specified level
  public func log(_ level: LogLevel, _ message: String, metadata: PrivacyMetadata?, source: String) async {
    let formattedMessage = "[\(source)] \(message)"
    
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
  }
}
