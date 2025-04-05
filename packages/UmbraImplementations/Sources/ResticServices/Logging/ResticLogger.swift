import Foundation
import LoggingInterfaces
import LoggingTypes

// Simple struct for privacy-annotated strings
public struct PrivacyString {
  let value: String

  public init(value: String) {
    self.value=value
  }
}

/// Restic-specific logger implementation
public actor ResticLogger {
  // Underlying logger instance
  private let underlyingLogger: any LoggingProtocol

  /// Create a new Restic logger
  public init(logger: any LoggingProtocol) {
    underlyingLogger=logger
  }

  /// Log a message with debug level
  ///
  /// - Parameters:
  ///   - message: The message to log
  ///   - metadata: Additional metadata to include
  ///   - source: The source of the message
  public func debug(_ message: String, metadata: PrivacyMetadata?, source: String) async {
    await log(.debug, message, metadata: metadata, source: source)
  }

  /// Log a message with info level
  ///
  /// - Parameters:
  ///   - message: The message to log
  ///   - metadata: Additional metadata to include
  ///   - source: The source of the message
  public func info(_ message: String, metadata: PrivacyMetadata?, source: String) async {
    await log(.info, message, metadata: metadata, source: source)
  }

  /// Log a message with warning level
  ///
  /// - Parameters:
  ///   - message: The message to log
  ///   - metadata: Additional metadata to include
  ///   - source: The source of the message
  public func warning(_ message: String, metadata: PrivacyMetadata?, source: String) async {
    await log(.warning, message, metadata: metadata, source: source)
  }

  /// Log a message with error level
  ///
  /// - Parameters:
  ///   - message: The message to log
  ///   - metadata: Additional metadata to include
  ///   - source: The source of the message
  public func error(_ message: String, metadata: PrivacyMetadata?, source: String) async {
    await log(.error, message, metadata: metadata, source: source)
  }

  /// Log a message with critical level
  ///
  /// - Parameters:
  ///   - message: The message to log
  ///   - metadata: Additional metadata to include
  ///   - source: The source of the message
  public func critical(_ message: String, metadata: PrivacyMetadata?, source: String) async {
    await log(.critical, message, metadata: metadata, source: source)
  }

  /// Log a message with a context
  ///
  /// - Parameters:
  ///  - level: Log level
  ///  - message: The message to log
  ///  - context: The logging context
  public func log(
    _ level: LogLevel,
    _ message: String,
    context: some LogContextDTO
  ) async {
    await underlyingLogger.log(
      level,
      message,
      metadata: PrivacyMetadata(),
      source: context.getSource()
    )
  }

  /// Log a message
  ///
  /// - Parameters:
  ///  - level: The log level
  ///  - message: The message to log
  ///  - metadata: Additional metadata
  ///  - source: Source of the log
  public func log(
    _ level: LogLevel,
    _ message: String,
    metadata: PrivacyMetadata?,
    source: String
  ) async {
    await underlyingLogger.log(
      level,
      message,
      metadata: metadata,
      source: source
    )
  }

  /// Log an error
  ///
  /// - Parameters:
  ///   - error: The error to log
  ///   - message: Additional message
  ///   - metadata: Additional metadata
  ///   - source: Source of the log
  public func logError(
    _ error: Error,
    message: String?=nil,
    metadata: PrivacyMetadata?=nil,
    source: String
  ) async {
    let logMessage=message ?? "Error: \(error.localizedDescription)"

    await log(
      .error,
      logMessage,
      metadata: metadata,
      source: source
    )
  }
}
