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

  /// Initialise a new logger with the default subsystem and category
  public init() {
    logger=Logger(subsystem: "com.umbra.securitycryptoservices", category: "SecurityCryptoServices")
  }

  /// Log debug message
  public func debug(_ message: String, metadata _: LogMetadata?) async {
    logger.debug("DEBUG: \(message)")
  }

  /// Log info message
  public func info(_ message: String, metadata _: LogMetadata?) async {
    logger.info("INFO: \(message)")
  }

  /// Log warning message
  public func warning(_ message: String, metadata _: LogMetadata?) async {
    logger.warning("WARNING: \(message)")
  }

  /// Log error message
  public func error(_ message: String, metadata _: LogMetadata?) async {
    logger.error("ERROR: \(message)")
  }
}
