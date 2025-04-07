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
    context: LogContextDTO
  ) async {
    await underlyingLogger.log(level, message, context: context)
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
    // Create a LogContextDTO from the metadata and source
    let context=BaseLogContextDTO(
      domainName: "ResticServices",
      source: source,
      metadata: metadata ?? PrivacyMetadata()
    )

    await underlyingLogger.log(level, message, context: context)
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
    message: String,
    metadata: PrivacyMetadata?,
    source: String
  ) async {
    // Check if the error provides logging information
    if let loggableError=error as? LoggableErrorProtocol {
      // Create a context with combined metadata
      let metadataCollection=loggableError.createMetadataCollection()
      let errorMessage=loggableError.getLogMessage()

      // Create metadata with error type information
      let metadataWithErrorInfo=PrivacyMetadata([
        "error.type": (value: String(describing: type(of: error)), privacy: LogPrivacyLevel.public)
      ])

      // Create combined metadata by merging all sources
      let combinedMetadata=(metadata ?? PrivacyMetadata())
        .merging(metadataWithErrorInfo)
        .merging(metadataCollection.toPrivacyMetadata())

      let context=BaseLogContextDTO(
        domainName: "ResticServices",
        source: source,
        metadata: combinedMetadata
      )

      await underlyingLogger.log(.error, "\(message): \(errorMessage)", context: context)
    } else {
      // Basic error logging for non-loggable errors
      // Create metadata with error type information
      let errorTypeMetadata=PrivacyMetadata([
        "error.type": (value: String(describing: type(of: error)), privacy: LogPrivacyLevel.public)
      ])

      // Combine with any existing metadata
      let combinedMetadata=(metadata ?? PrivacyMetadata()).merging(errorTypeMetadata)

      let context=BaseLogContextDTO(
        domainName: "ResticServices",
        source: source,
        metadata: combinedMetadata
      )

      await underlyingLogger.log(
        .error,
        "\(message): \(error.localizedDescription)",
        context: context
      )
    }
  }
}
