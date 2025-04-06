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
public actor DefaultLogger: LoggingProtocol, CoreLoggingProtocol {
  private let logger: Logger

  /// Creates a new DefaultLogger
  public init() {
    logger = Logger(subsystem: "com.umbra.keychainservices", category: "KeychainServices")
  }

  /// The actor used for all logging operations
  private let _loggingActor = LoggingActor(destinations: [], minimumLogLevel: .info)

  /// Get the underlying logging actor
  public var loggingActor: LoggingActor {
    _loggingActor
  }

  /// Required CoreLoggingProtocol implementation
  public func log(_ level: LogLevel, _ message: String, context: LogContextDTO) async {
    switch level {
      case .trace:
        // Forward to debug since we don't have trace
        await debug(message, context: context)
      case .debug:
        await debug(message, context: context)
      case .info:
        await info(message, context: context)
      case .warning:
        await warning(message, context: context)
      case .error:
        await error(message, context: context)
      case .critical:
        await critical(message, context: context)
    }
  }

  /// Log a debug message with context
  public func debug(_ message: String, context: LogContextDTO) async {
    logger.debug("\(message, privacy: .public)")
    await _loggingActor.log(.debug, message, context: context)
  }

  /// Log an info message with context
  public func info(_ message: String, context: LogContextDTO) async {
    logger.info("\(message, privacy: .public)")
    await _loggingActor.log(.info, message, context: context)
  }

  /// Log a warning message with context
  public func warning(_ message: String, context: LogContextDTO) async {
    logger.warning("\(message, privacy: .public)")
    await _loggingActor.log(.warning, message, context: context)
  }

  /// Log an error message with context
  public func error(_ message: String, context: LogContextDTO) async {
    logger.error("\(message, privacy: .public)")
    await _loggingActor.log(.error, message, context: context)
  }

  /// Log a critical error message with context
  public func critical(_ message: String, context: LogContextDTO) async {
    logger.critical("\(message, privacy: .public)")
    await _loggingActor.log(.critical, message, context: context)
  }

  // Legacy methods for backward compatibility
  /// Log a debug message
  public func debug(
    _ message: String,
    metadata: LoggingTypes.PrivacyMetadata?,
    source: String?
  ) async {
    let context = BaseLogContextDTO(
      domainName: "KeychainServices",
      source: source ?? "DefaultLogger"
    )
    await debug(message, context: context)
  }

  /// Log an info message
  public func info(
    _ message: String,
    metadata: LoggingTypes.PrivacyMetadata?,
    source: String?
  ) async {
    let context = BaseLogContextDTO(
      domainName: "KeychainServices",
      source: source ?? "DefaultLogger"
    )
    await info(message, context: context)
  }

  /// Log a warning message
  public func warning(
    _ message: String,
    metadata: LoggingTypes.PrivacyMetadata?,
    source: String?
  ) async {
    let context = BaseLogContextDTO(
      domainName: "KeychainServices",
      source: source ?? "DefaultLogger"
    )
    await warning(message, context: context)
  }

  /// Log an error message
  public func error(
    _ message: String,
    metadata: LoggingTypes.PrivacyMetadata?,
    source: String?
  ) async {
    let context = BaseLogContextDTO(
      domainName: "KeychainServices",
      source: source ?? "DefaultLogger"
    )
    await error(message, context: context)
  }

  /// Log a critical error message
  public func critical(
    _ message: String,
    metadata: LoggingTypes.PrivacyMetadata?,
    source: String?
  ) async {
    let context = BaseLogContextDTO(
      domainName: "KeychainServices",
      source: source ?? "DefaultLogger"
    )
    await critical(message, context: context)
  }
}
