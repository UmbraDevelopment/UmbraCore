import Foundation

/// Represents a log entry in the system
public struct LogEntry: Sendable {
  /// The timestamp when the log entry was created
  public let timestamp: Date

  /// The log level
  public let level: UmbraLogLevel

  /// The message to log
  public let message: String

  /// Optional metadata associated with the log entry
  public let metadata: LogMetadata?

  /// Initialise a new log entry
  /// - Parameters:
  ///   - level: The log level
  ///   - message: The message to log
  ///   - metadata: Optional metadata
  public init(level: UmbraLogLevel, message: String, metadata: LogMetadata? = nil) {
    timestamp = Date()
    self.level = level
    self.message = message
    self.metadata = metadata
  }
}
