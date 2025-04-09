import Foundation
import LoggingInterfaces
import LoggingTypes

/**
 # Console Logging Backend
 
 A simple console-based logging backend implementation that writes logs to standard output.
 Useful for development and testing purposes.
 
 This implementation follows the Alpha Dot Five architecture principles by:
 1. Using proper British spelling in documentation
 2. Providing comprehensive privacy controls for sensitive data
 3. Supporting modern metadata handling with functional approach
 */
public struct ConsoleLoggingBackend: LoggingBackend {
  /// Initialises a new console logging backend
  public init() {}

  /**
   Writes a log message to the console with formatting based on the log level.
   
   - Parameters:
     - level: The severity level of the log
     - message: The message to log
     - context: Contextual information about the log
     - subsystem: The subsystem identifier
   */
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
    if !context.metadata.isEmpty {
      metadataString=" " + formatMetadataCollection(context.metadata)
    }

    // Format and print the log message
    // Use safe accessors for optional properties
    let sourceText=context.getSource()
    let correlationText=context.correlationID ?? "none"

    let formattedMessage="\(colourCode)\(timestamp) \(emoji) [\(level)] [\(subsystem):\(sourceText)] \(message)\(metadataString) [correlation: \(correlationText)]\u{001B}[0m"
    print(formattedMessage)
  }

  /**
   Formats a timestamp into a human-readable string.
   
   - Parameter timestamp: The timestamp to format
   - Returns: A formatted timestamp string
   */
  private func formatTimestamp(_ timestamp: LogTimestamp) -> String {
    // Extract components directly from the secondsSinceEpoch
    let seconds = Int(timestamp.secondsSinceEpoch)
    let milliseconds = Int((timestamp.secondsSinceEpoch - Double(seconds)) * 1000)
    
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

  /**
   Provides formatting information for each log level.
   
   - Parameter level: The log level to format
   - Returns: A tuple containing an emoji and ANSI colour code for the log level
   */
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

  /**
   Formats a metadata collection for display with privacy controls.
   
   - Parameter metadata: The metadata collection to format
   - Returns: A formatted string representation of the metadata
   */
  private func formatMetadataCollection(_ metadata: LogMetadataDTOCollection) -> String {
    var parts: [String]=[]

    for entry in metadata.entries {
      let key = entry.key
      let value = entry.value
      let privacyLevel = entry.privacyLevel

      // Format based on privacy level
      let formattedValue: String

      switch privacyLevel {
        case .public:
          // Public data can be shown as-is
          formattedValue="\(key): \(value)"

        case .private:
          // In debug builds, show private data with a marker
          #if DEBUG
            formattedValue="\(key): 🔒[\(value)]"
          #else
            formattedValue="\(key): 🔒[REDACTED]"
          #endif

        case .sensitive:
          // Sensitive data is always redacted, even in debug builds
          formattedValue="\(key): 🔐[REDACTED]"

        case .hash:
          // Hash values are shown with a special marker
          formattedValue="\(key): 🔢[\(value)]"

        case .auto:
          // Auto-detected sensitive data is treated as sensitive
          formattedValue="\(key): 🔍[REDACTED]"
      }

      parts.append(formattedValue)
    }

    return "{" + parts.joined(separator: ", ") + "}"
  }

  /**
   Determines if a log should be processed based on its level.
   
   - Parameters:
     - level: The log level to check
     - minimumLevel: The minimum log level to process
   - Returns: True if the log should be processed, false otherwise
   */
  public func shouldLog(level: LogLevel, minimumLevel: LogLevel) -> Bool {
    level.rawValue >= minimumLevel.rawValue
  }
  
  /**
   Formats metadata for display (deprecated method).
   
   - Parameter metadata: The metadata to format
   - Returns: A formatted string representation of the metadata
   */
  @available(*, deprecated, message: "Use formatMetadataCollection instead")
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
          // Sensitive data is always redacted, even in debug builds
          formattedValue="\(key): 🔐[REDACTED]"

        case .hash:
          // Hash values are shown with a special marker
          formattedValue="\(key): 🔢[\(value.valueString)]"
          
        case .auto:
          // Auto-classified values are shown with a special marker
          #if DEBUG
            formattedValue="\(key): 🔄[\(value.valueString)]"
          #else
            formattedValue="\(key): 🔄[AUTO-CLASSIFIED]"
          #endif
      }

      parts.append(formattedValue)
    }

    return "{" + parts.joined(separator: ", ") + "}"
  }
}
