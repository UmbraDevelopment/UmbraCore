import LoggingTypes

/// Protocol defining the logging interface
public protocol LoggingProtocol: Sendable {
  /// Log a debug message
  /// - Parameters:
  ///   - message: The message to log
  ///   - metadata: Optional metadata
  ///   - source: Optional source component identifier
  func debug(_ message: String, metadata: LoggingTypes.LogMetadata?, source: String?) async

  /// Log an info message
  /// - Parameters:
  ///   - message: The message to log
  ///   - metadata: Optional metadata
  ///   - source: Optional source component identifier
  func info(_ message: String, metadata: LoggingTypes.LogMetadata?, source: String?) async

  /// Log a warning message
  /// - Parameters:
  ///   - message: The message to log
  ///   - metadata: Optional metadata
  ///   - source: Optional source component identifier
  func warning(_ message: String, metadata: LoggingTypes.LogMetadata?, source: String?) async

  /// Log an error message
  /// - Parameters:
  ///   - message: The message to log
  ///   - metadata: Optional metadata
  ///   - source: Optional source component identifier
  func error(_ message: String, metadata: LoggingTypes.LogMetadata?, source: String?) async
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
  case filteredByLevel(messageLevel: LoggingTypes.UmbraLogLevel, minimumLevel: LoggingTypes.UmbraLogLevel)
  
  /// Invalid configuration provided
  case invalidConfiguration(description: String)
  
  /// Operation not supported by this logger
  case operationNotSupported(description: String)
  
  /// Destination with specified identifier not found
  case destinationNotFound(identifier: String)
  
  /// Duplicate destination identifier
  case duplicateDestination(identifier: String)
}
