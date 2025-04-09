import LoggingTypes

/// Protocol defining log formatting capabilities
///
/// This protocol standardises how log entries are converted to strings for output.
/// Implementations can provide different formatting styles for different contexts.
public protocol LogFormatterProtocol: Sendable {
  /// Format a log entry to a string
  /// - Parameter entry: The log entry to format
  /// - Returns: Formatted string representation of the log entry
  func format(_ entry: LoggingTypes.LogEntry) -> String

  /// Format metadata to a string
  /// - Parameter metadata: Metadata to format
  /// - Returns: Formatted string representation of the metadata
  func formatMetadata(_ metadata: LoggingTypes.LogMetadataDTOCollection?) -> String?

  /// Format a timestamp to a string
  /// - Parameter timestamp: The timestamp to format
  /// - Returns: Formatted string representation of the timestamp
  func formatTimestamp(_ timestamp: LoggingTypes.TimePointAdapter) -> String

  /// Format a log level to a string
  /// - Parameter level: The log level to format
  /// - Returns: Formatted string representation of the log level
  func formatLogLevel(_ level: LoggingTypes.UmbraLogLevel) -> String

  /// Customise the format based on configuration
  /// - Parameters:
  ///   - includeTimestamp: Whether to include timestamps in the output
  ///   - includeLevel: Whether to include log levels in the output
  ///   - includeSource: Whether to include source information in the output
  ///   - includeMetadata: Whether to include metadata in the output
  /// - Returns: A new formatter with the specified configuration
  func withConfiguration(
    includeTimestamp: Bool,
    includeLevel: Bool,
    includeSource: Bool,
    includeMetadata: Bool
  ) -> LogFormatterProtocol
}
