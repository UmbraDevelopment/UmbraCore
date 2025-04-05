import Foundation
import LoggingInterfaces
import LoggingTypes

/// A simple console-based logging backend implementation that writes logs to standard output.
/// Useful for development and testing purposes.
public struct ConsoleLoggingBackend: LoggingBackend {
  /// Initialises a new console logging backend
  public init() {}

  /// Writes a log message to the console with formatting based on the log level
  /// - Parameters:
  ///   - level: The severity level of the log
  ///   - message: The message to log
  ///   - context: Contextual information about the log
  ///   - subsystem: The subsystem identifier
  public func writeLog(
    level: LogLevel,
    message: String,
    context: LogContext,
    subsystem: String
  ) async {
    // Format timestamp
    let timestamp=formatTimestamp(context.timestamp)

    // Create colour and emoji prefix based on log level
    let (emoji, colourCode)=formatForLevel(level)

    // Format metadata if present
    var metadataString=""
    // Convert the DTO collection to PrivacyMetadata and format it
    if !context.metadata.isEmpty {
      // Use the extension method to convert to the format expected by the formatter
      let privacyMetadata=context.toPrivacyMetadata()
      metadataString=" " + formatPrivacyMetadata(privacyMetadata)
    }

    // Format and print the log message
    // Use safe accessors for optional properties
    let sourceText=context.getSource()
    let correlationText=context.correlationID ?? "none"

    let formattedMessage="\(colourCode)\(timestamp) \(emoji) [\(level)] [\(subsystem):\(sourceText)] \(message)\(metadataString) [correlation: \(correlationText)]\u{001B}[0m"
    print(formattedMessage)
  }

  /// Formats a timestamp for display
  /// - Parameter timestamp: The timestamp to format
  /// - Returns: A formatted timestamp string
  private func formatTimestamp(_ timestamp: LogTimestamp) -> String {
    let date=Date(timeIntervalSince1970: timestamp.secondsSinceEpoch)
    let formatter=DateFormatter()
    formatter.dateFormat="yyyy-MM-dd HH:mm:ss.SSS"
    return formatter.string(from: date)
  }

  /// Provides formatting information for each log level
  /// - Parameter level: The log level to format
  /// - Returns: A tuple containing an emoji and ANSI colour code for the log level
  private func formatForLevel(_ level: LogLevel) -> (String, String) {
    switch level {
      case .trace:
        ("🔍", "\u{001B}[90m") // Dark grey
      case .debug:
        ("🐞", "\u{001B}[36m") // Cyan
      case .info:
        ("ℹ️", "\u{001B}[32m") // Green
      case .warning:
        ("⚠️", "\u{001B}[33m") // Yellow
      case .error:
        ("❌", "\u{001B}[31m") // Red
      case .critical:
        ("🚨", "\u{001B}[35m") // Magenta
    }
  }

  /// Formats metadata for display
  /// - Parameter metadata: The metadata to format
  /// - Returns: A formatted string representation of the metadata
  private func formatPrivacyMetadata(_ metadata: PrivacyMetadata) -> String {
    var parts: [String]=[]

    for key in metadata.keys {
      guard let value=metadata[key] else { continue }

      // Access the value based on privacy level
      let formattedValue: String

      switch value.privacy {
        case .public:
          // Public data can be shown as-is
          formattedValue="\(key): \(value.valueString)"

        case .private:
          // In debug builds, show private data with a marker
          #if DEBUG
            formattedValue="\(key): 🔒[\(value.valueString)]"
          #else
            formattedValue="\(key): 🔒[REDACTED]"
          #endif

        case .sensitive:
          // Sensitive data gets additional protection
          #if DEBUG
            formattedValue="\(key): 🔐[\(value.valueString)]"
          #else
            formattedValue="\(key): 🔐[SENSITIVE]"
          #endif

        case .hash:
          // Hashed data shows a placeholder
          formattedValue="\(key): 🔏[HASHED]"

        case .auto:
          // Auto adapts based on build configuration
          #if DEBUG
            formattedValue="\(key): \(value.valueString)"
          #else
            formattedValue="\(key): [REDACTED]"
          #endif
      }

      parts.append(formattedValue)
    }

    return parts.isEmpty ? "" : "{" + parts.joined(separator: ", ") + "}"
  }

  /// Whether the specified log level should be logged given the minimum level
  /// - Parameters:
  ///   - level: The log level to check
  ///   - minimumLevel: The minimum level to log
  /// - Returns: True if the level should be logged
  public func shouldLog(level: LogLevel, minimumLevel: LogLevel) -> Bool {
    level >= minimumLevel
  }
}
