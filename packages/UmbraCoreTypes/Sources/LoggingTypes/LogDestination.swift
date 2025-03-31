/// Protocol defining a destination for log entries
///
/// A log destination represents a target where log entries are written,
/// such as the console, a file, or a network service. This protocol
/// establishes the core requirements for any log destination implementation.
@preconcurrency
public protocol LogDestination: Sendable {
  /// Unique identifier for this destination
  var identifier: String { get }

  /// Minimum log level this destination will accept
  var minimumLevel: UmbraLogLevel { get }

  /// Write a log entry to this destination
  /// - Parameter entry: The log entry to write
  /// - Throws: LoggingError if writing fails
  func write(_ entry: LogEntry) async throws

  /// Flush any pending entries (if applicable)
  /// - Throws: LoggingError if flushing fails
  func flush() async throws
}
