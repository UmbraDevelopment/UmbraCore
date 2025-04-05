import Foundation
import LoggingTypes

/// Protocol defining the standard logging interface
public protocol LoggingProtocol: CoreLoggingProtocol {
  /// Log a trace message
  /// - Parameters:
  ///   - message: The message to log
  ///   - metadata: Optional metadata
  ///   - source: Source component identifier
  func trace(_ message: String, metadata: LoggingTypes.PrivacyMetadata?, source: String) async

  /// Log a debug message
  /// - Parameters:
  ///   - message: The message to log
  ///   - context: The logging context DTO containing metadata and source
  func debug(_ message: String, context: LogContextDTO) async

  /// Log an info message
  /// - Parameters:
  ///   - message: The message to log
  ///   - context: The logging context DTO containing metadata and source
  func info(_ message: String, context: LogContextDTO) async

  /// Log a notice message
  /// - Parameters:
  ///   - message: The message to log
  ///   - context: The logging context DTO containing metadata and source
  func notice(_ message: String, context: LogContextDTO) async

  /// Log a warning message
  /// - Parameters:
  ///   - message: The message to log
  ///   - metadata: Optional metadata
  ///   - source: Source component identifier
  func warning(_ message: String, metadata: LoggingTypes.PrivacyMetadata?, source: String) async

  /// Log an error message
  /// - Parameters:
  ///   - message: The message to log
  ///   - context: The logging context DTO containing metadata and source
  func error(_ message: String, context: LogContextDTO) async

  /// Log a critical message
  /// - Parameters:
  ///   - message: The message to log
  ///   - context: The logging context DTO containing metadata and source
  func critical(_ message: String, context: LogContextDTO) async

  /// Get the underlying logging actor
  /// - Returns: The logging actor used by this logger
  var loggingActor: LoggingActor { get }
}

/// Default implementations for LoggingProtocol to ensure compatibility with CoreLoggingProtocol
extension LoggingProtocol {
  /// Maps the individual log level methods to the core logMessage method
  /// - Parameters:
  ///   - level: The LogLevel
  ///   - message: The message to log
  ///   - metadata: Optional **PrivacyMetadata** (from LoggingTypes)
  ///   - source: Source component identifier
  public func log(
    _ level: LogLevel,
    _ message: String,
    metadata: LoggingTypes.PrivacyMetadata?,
    source: String
  ) async {
    // Default implementation uses the newer context-based log method.
    // We need to construct a context. As this is a fallback, a BaseLogContextDTO is suitable.
    let collection = LogMetadataDTOCollection(entries: []) // Start empty
    // Note: Converting PrivacyMetadata back to LogMetadataDTOCollection is complex
    // and potentially lossy. This default implementation might be limited.
    // A proper implementation should handle context creation more robustly.
    let context = BaseLogContextDTO(domainName: "DefaultDomain", source: source, metadata: collection)
    await log(level, message, context: context) // Call the context-based log
  }

  /// Implementation of the core logging method using a context DTO
  /// Conforming types MUST provide an implementation for this.
  func log(
    _ level: LogLevel,
    _ message: String,
    context: LogContextDTO
  ) async

  // --- Convenience methods using Context DTO ---

  /// Implementation of trace level logging using the context DTO
  func trace(_ message: String, context: LogContextDTO) async {
    await log(.trace, message, context: context)
  }

  /// Implementation of debug level logging using the context DTO
  func debug(_ message: String, context: LogContextDTO) async {
    await log(.debug, message, context: context)
  }

  /// Implementation of info level logging using the context DTO
  func info(_ message: String, context: LogContextDTO) async {
    await log(.info, message, context: context)
  }

  /// Implementation of notice level logging using the context DTO
  func notice(_ message: String, context: LogContextDTO) async {
    await log(.notice, message, context: context)
  }

  /// Implementation of warning level logging using the context DTO
  func warning(_ message: String, context: LogContextDTO) async {
    await log(.warning, message, context: context)
  }

  /// Implementation of error level logging using the context DTO
  func error(_ message: String, context: LogContextDTO) async {
    await log(.error, message, context: context)
  }

  /// Implementation of critical level logging using the context DTO
  func critical(_ message: String, context: LogContextDTO) async {
    await log(.critical, message, context: context)
  }
}

/// Errors that can occur during logging operations
public enum LoggingError: Error, Sendable, Hashable {
  /// Failed to initialise logging system
  case initialisationFailed(reason: String)

  /// Failed to write log
  case writeFailed(reason: String)

  /// Failed to write to log destination
  case destinationWriteFailed(destination: String, reason: String)

  /// Log level filter prevented message from being logged
  case filteredByLevel(
    messageLevel: LogLevel,
    minimumLevel: LogLevel
  )

  /// Invalid configuration provided
  case invalidConfiguration(description: String)

  /// Operation not supported by this logger
  case operationNotSupported(description: String)

  /// Destination with specified identifier not found
  case destinationNotFound(identifier: String)

  /// Duplicate destination identifier
  case duplicateDestination(identifier: String)

  /// Error during privacy processing
  case privacyProcessingFailed(reason: String)
}

public enum LogLevel: Int, Sendable, Comparable {
  case trace = -1
  case debug = 0
  case info = 1
  case notice = 2
  case warning = 3
  case error = 4
  case critical = 5

  // Manual implementation for Comparable
  public static func < (lhs: LogLevel, rhs: LogLevel) -> Bool {
    lhs.rawValue < rhs.rawValue
  }
}
