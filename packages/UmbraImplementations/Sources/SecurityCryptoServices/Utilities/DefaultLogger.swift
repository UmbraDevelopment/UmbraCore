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
  
  /// The underlying logging actor
  public let loggingActor: LoggingActor
  
  /// Initialise a new logger with the default subsystem and category
  public init() {
    logger = Logger(subsystem: "com.umbra.securitycryptoservices", category: "SecurityCryptoServices")
    loggingActor = LoggingActor(destinations: [])
  }
  
  /// Core logging method implementation
  public func logMessage(_ level: LogLevel, _ message: String, context: LogContext) async {
    switch level {
      case .debug:
        logger.debug("\(message)")
      case .info:
        logger.info("\(message)")
      case .warning:
        logger.warning("\(message)")
      case .error:
        logger.error("\(message)")
      case .critical:
        logger.critical("\(message)")
    }
  }

  /// Log debug message
  public func debug(_ message: String, metadata: LogMetadata?) async {
    await logMessage(.debug, message, context: LogContext(metadata: metadata ?? [:]))
  }

  /// Log info message
  public func info(_ message: String, metadata: LogMetadata?) async {
    await logMessage(.info, message, context: LogContext(metadata: metadata ?? [:]))
  }

  /// Log warning message
  public func warning(_ message: String, metadata: LogMetadata?) async {
    await logMessage(.warning, message, context: LogContext(metadata: metadata ?? [:]))
  }

  /// Log error message
  public func error(_ message: String, metadata: LogMetadata?) async {
    await logMessage(.error, message, context: LogContext(metadata: metadata ?? [:]))
  }
}
