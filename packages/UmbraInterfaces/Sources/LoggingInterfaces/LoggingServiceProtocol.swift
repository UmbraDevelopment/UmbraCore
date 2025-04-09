import LoggingTypes

/// Protocol defining the comprehensive logging service interface
///
/// This protocol provides a standard API for logging operations throughout the application,
/// following the Alpha Dot Five architecture. It includes support for:
///
/// - Multiple log levels from verbose to critical
/// - Metadata attachment to log messages
/// - Dynamic destination configuration
/// - Thread-safe operations via async methods
///
/// Implementations should ensure thread safety, typically through an actor-based approach.
public protocol LoggingServiceProtocol: Sendable {
  /// Log a verbose message
  /// - Parameters:
  ///   - message: The message to log
  ///   - metadata: Optional metadata
  ///   - source: Optional source component identifier
  func verbose(_ message: String, metadata: LoggingTypes.LogMetadataDTOCollection?, source: String?) async

  /// Log a debug message
  /// - Parameters:
  ///   - message: The message to log
  ///   - metadata: Optional metadata
  ///   - source: Optional source component identifier
  func debug(_ message: String, metadata: LoggingTypes.LogMetadataDTOCollection?, source: String?) async

  /// Log an info message
  /// - Parameters:
  ///   - message: The message to log
  ///   - metadata: Optional metadata
  ///   - source: Optional source component identifier
  func info(_ message: String, metadata: LoggingTypes.LogMetadataDTOCollection?, source: String?) async

  /// Log a warning message
  /// - Parameters:
  ///   - message: The message to log
  ///   - metadata: Optional metadata
  ///   - source: Optional source component identifier
  func warning(_ message: String, metadata: LoggingTypes.LogMetadataDTOCollection?, source: String?) async

  /// Log an error message
  /// - Parameters:
  ///   - message: The message to log
  ///   - metadata: Optional metadata
  ///   - source: Optional source component identifier
  func error(_ message: String, metadata: LoggingTypes.LogMetadataDTOCollection?, source: String?) async

  /// Log a critical message
  /// - Parameters:
  ///   - message: The message to log
  ///   - metadata: Optional metadata
  ///   - source: Optional source component identifier
  func critical(_ message: String, metadata: LoggingTypes.LogMetadataDTOCollection?, source: String?) async

  /// Add a log destination
  /// - Parameter destination: The destination to add
  /// - Throws: LoggingError if the destination cannot be added
  func addDestination(_ destination: LoggingTypes.LogDestination) async throws

  /// Remove a log destination by identifier
  /// - Parameter identifier: Unique identifier of the destination to remove
  /// - Returns: true if the destination was removed, false if not found
  func removeDestination(withIdentifier identifier: String) async -> Bool

  /// Set the global minimum log level
  /// - Parameter level: The minimum log level to record
  func setMinimumLogLevel(_ level: LoggingTypes.UmbraLogLevel) async

  /// Get the current global minimum log level
  /// - Returns: The current minimum log level
  func getMinimumLogLevel() async -> LoggingTypes.UmbraLogLevel

  /// Flush all destinations, ensuring pending logs are written
  /// - Throws: LoggingError if any destination fails to flush
  func flushAllDestinations() async throws
}
