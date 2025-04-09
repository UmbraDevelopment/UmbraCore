import LoggingInterfaces
import LoggingTypes

/// Standard formatting implementation for log entries
///
/// Formats log entries with consistent timestamps, log levels, and metadata
/// following the Alpha Dot Five architecture guidelines.
public struct StandardLogFormatter: LogFormatterProtocol, Sendable {
  /// Configuration for the formatter
  private var includeTimestamp: Bool=true
  private var includeLevel: Bool=true
  private var includeSource: Bool=true
  private var includeMetadata: Bool=true

  /// Create a new standard log formatter with default settings
  public init() {}

  /// Format a log entry into a string representation
  /// - Parameter entry: The log entry to format
  /// - Returns: Formatted string representation of the log entry
  public func format(_ entry: LogEntry) -> String {
    // Base message
    var formattedMessage=""

    // Add timestamp if configured
    if includeTimestamp {
      // Convert LogTimestamp to TimePointAdapter
      let timePointAdapter=TimePointAdapter(
        timeIntervalSince1970: entry.timestamp
          .secondsSinceEpoch
      )
      formattedMessage += "[\(formatTimestamp(timePointAdapter))]"
    }

    // Add log level if configured
    if includeLevel {
      // Convert LogLevel to UmbraLogLevel
      let umbraLevel=convertToUmbraLogLevel(entry.level)
      let levelString=formatLogLevel(umbraLevel)
      formattedMessage += (formattedMessage.isEmpty ? "" : " ") + "[\(levelString)]"
    }

    // Add source if available and configured
    if includeSource {
      formattedMessage += (formattedMessage.isEmpty ? "" : " ") + "[\(entry.source)]"
    }

    // Add the message content
    formattedMessage += (formattedMessage.isEmpty ? "" : " ") + entry.message

    // Add metadata if available and configured
    if includeMetadata, let metadata=entry.metadata {
      if
        let metadataString=formatMetadata(metadata),
        !metadataString.isEmpty
      {
        formattedMessage += "\nMetadata: \(metadataString)"
      }
    }

    return formattedMessage
  }

  /// Convert PrivacyMetadata to LogMetadata
  /// - Parameter metadata: PrivacyMetadata to convert
  /// - Returns: Converted LogMetadata
  private func convertToLogMetadata(_ metadata: PrivacyMetadata) -> LogMetadata {
    var logMetadata=LogMetadata()
    for (key, value) in metadata.entriesDict() {
      // Convert PrivacyMetadataValue to string
      logMetadata[key]=value.valueString
    }
    return logMetadata
  }

  /// Convert LogLevel to UmbraLogLevel
  /// - Parameter level: LogLevel to convert
  /// - Returns: Equivalent UmbraLogLevel
  private func convertToUmbraLogLevel(_ level: LogLevel) -> UmbraLogLevel {
    switch level {
      case .trace:
        .verbose
      case .debug:
        .debug
      case .info:
        .info
      case .warning:
        .warning
      case .error:
        .error
      case .critical:
        .critical
    }
  }

  /// Convert LogMetadataDTOCollection to a string representation
  /// - Parameter metadata: The metadata to format
  /// - Returns: A formatted string representation of the metadata
  public func formatMetadata(_ metadata: LoggingTypes.LogMetadataDTOCollection?) -> String? {
    guard let metadata, !metadata.isEmpty else {
      return nil
    }
    
    let metadataStrings = metadata.entries.map { entry in
      "\(entry.key): \(entry.value)"
    }
    
    if metadataStrings.isEmpty {
      return nil
    }
    
    return "{ " + metadataStrings.joined(separator: ", ") + " }"
  }

  /// Format metadata to a string (legacy method)
  /// - Parameter metadata: Metadata to format
  /// - Returns: Formatted string representation of the metadata
  public func formatMetadata(_ metadata: LoggingTypes.LogMetadata?) -> String? {
    guard let metadata else {
      return nil
    }

    let metadataStrings=metadata.asDictionary.map { key, value in
      "\(key): \(value)"
    }

    if metadataStrings.isEmpty {
      return nil
    }
    
    return "{ " + metadataStrings.joined(separator: ", ") + " }"
  }

  /// Format a timestamp to a string
  /// - Parameter timestamp: The timestamp to format
  /// - Returns: Formatted string representation of the timestamp
  public func formatTimestamp(_ timestamp: LoggingTypes.TimePointAdapter) -> String {
    // Extract components directly from the timeIntervalSince1970
    let seconds = Int(timestamp.timeIntervalSince1970)
    let milliseconds = Int((timestamp.timeIntervalSince1970 - Double(seconds)) * 1000)
    
    // Format date components manually
    let year = seconds / 31536000 + 1970
    let month = (seconds % 31536000) / 2592000 + 1
    let day = ((seconds % 31536000) % 2592000) / 86400 + 1
    
    // Format time components
    let hour = (seconds % 86400) / 3600
    let minute = (seconds % 3600) / 60
    let second = seconds % 60
    
    // Create formatted timestamp string
    return String(format: "%04d-%02d-%02d %02d:%02d:%02d.%03d", 
                 year, month, day, hour, minute, second, milliseconds)
  }

  /// Format a log level to a string
  /// - Parameter level: The log level to format
  /// - Returns: Formatted string representation of the log level
  public func formatLogLevel(_ level: LoggingTypes.UmbraLogLevel) -> String {
    switch level {
      case .verbose:
        "TRACE"
      case .debug:
        "DEBUG"
      case .info:
        "INFO"
      case .warning:
        "WARNING"
      case .error:
        "ERROR"
      case .critical:
        "CRITICAL"
    }
  }

  /// Customise the format based on configuration
  /// - Parameters:
  ///   - includeTimestamp: Whether to include timestamps in the output
  ///   - includeLevel: Whether to include log levels in the output
  ///   - includeSource: Whether to include source information in the output
  ///   - includeMetadata: Whether to include metadata in the output
  /// - Returns: A new formatter with the updated configuration
  public func withConfiguration(
    includeTimestamp: Bool,
    includeLevel: Bool,
    includeSource: Bool,
    includeMetadata: Bool
  ) -> any LogFormatterProtocol {
    var formatter=self
    formatter.includeTimestamp=includeTimestamp
    formatter.includeLevel=includeLevel
    formatter.includeSource=includeSource
    formatter.includeMetadata=includeMetadata
    return formatter
  }
}
