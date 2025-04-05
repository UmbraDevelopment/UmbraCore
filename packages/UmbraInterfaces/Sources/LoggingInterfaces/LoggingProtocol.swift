import Foundation
import LoggingTypes

/**
 # Core Logging Protocol

 Defines the fundamental logging method required by all logging implementations.
 This protocol ensures that conforming types can process log messages with
 severity levels and associated context.

 Conforming types are expected to be actors to ensure thread safety.
 */
public protocol CoreLoggingProtocol: Actor {
  /// Logs a message with the specified severity level and context.
  /// This is the core method that concrete logging implementations must provide.
  ///
  /// - Parameters:
  ///   - level: The severity level of the log entry (e.g., debug, info, error).
  ///   - message: The textual content of the log message.
  ///   - context: A `LogContextDTO` containing contextual information (like source, metadata,
  /// correlation ID).
  func log(_ level: LogLevel, _ message: String, context: LogContextDTO) async
}

/**
 # Standard Logging Protocol

 Extends `CoreLoggingProtocol` with convenience methods for standard log levels
 (trace, debug, info, notice, warning, error, critical). These methods simplify
 common logging tasks by providing direct functions for each level.
 */
public protocol LoggingProtocol: CoreLoggingProtocol {
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
  // --- Convenience methods using Context DTO ---

  public func debug(_ message: String, context: LogContextDTO) async {
    await log(.debug, message, context: context)
  }

  public func trace(_ message: String, context: LogContextDTO) async {
    await log(.trace, message, context: context)
  }

  public func info(_ message: String, context: LogContextDTO) async {
    await log(.info, message, context: context)
  }

  public func notice(_ message: String, context: LogContextDTO) async {
    // Map notice level appropriately if needed, or use info/debug
    await log(.info, message, context: context) // Use .info as notice is not defined
  }

  public func warning(_ message: String, context: LogContextDTO) async {
    await log(.warning, message, context: context)
  }

  public func error(_ message: String, context: LogContextDTO) async {
    await log(.error, message, context: context)
  }

  public func critical(_ message: String, context: LogContextDTO) async {
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

// MARK: - Log Context DTO Protocol

/// Protocol defining the structure for log context information.
