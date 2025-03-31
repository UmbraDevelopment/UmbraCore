import Foundation
import UmbraLogging

/// Protocol defining log formatting capabilities
public protocol LogFormatterProtocol: Sendable {
  /// Format a log entry to a string
  /// - Parameter entry: The log entry to format
  /// - Returns: Formatted string representation of the log entry
  func format(_ entry: LogEntry) -> String

  /// Format metadata to a string
  /// - Parameter metadata: Metadata to format
  /// - Returns: Formatted string representation of the metadata
  func formatMetadata(_ metadata: LogMetadata?) -> String?
}
