import LoggingTypes

/// Protocol defining an actor-based destination for log entries
/// Uses Swift's Actor protocol to ensure thread-safety
public protocol ActorLogDestination: Actor, Sendable {
  /// Write a log entry to this destination
  /// - Parameter entry: The log entry to write
  func write(_ entry: LogEntry) async

  /// Unique identifier for this log destination
  var identifier: String { get }

  /// Optional minimum log level filter for this destination
  /// If not implemented, all logs will be written
  var minimumLogLevel: LogLevel? { get }
}

/// Default implementation for ActorLogDestination
extension ActorLogDestination {
  /// Default implementation provides no minimum level filtering
  public var minimumLogLevel: LogLevel? { nil }

  /// Default implementation to check if a log should be written based on its level
  /// - Parameter level: The log level to check
  /// - Returns: True if the log should be written
  public func shouldLog(level: LogLevel) -> Bool {
    if let minimumLevel=minimumLogLevel {
      return level >= minimumLevel
    }
    return true
  }
}
