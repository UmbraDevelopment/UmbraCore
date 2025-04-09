#if canImport(OSLog)
  import OSLog
#endif
import LoggingInterfaces
import LoggingTypes

/**
 # OSLog Privacy Backend
 
 Logging backend that uses Apple's OSLog system with privacy annotations.
 This backend applies the privacy controls defined in LogPrivacyLevel
 to the OSLog privacy annotations.
 
 This implementation follows the Alpha Dot Five architecture principles by:
 1. Using proper British spelling in documentation
 2. Providing comprehensive privacy controls for sensitive data
 3. Supporting modern metadata handling with functional approach
 4. Leveraging Apple's OSLog privacy features
 */
public struct OSLogPrivacyBackend: LoggingBackend {
  /// The default log subsystem identifier
  private let defaultSubsystem: String

  /**
   Creates a new OSLog backend with the specified subsystem.
   
   - Parameter subsystem: The subsystem identifier to use for logs
   */
  public init(subsystem: String) {
    defaultSubsystem=subsystem
  }

  /**
   Writes a log message to OSLog with appropriate privacy annotations.
   
   - Parameters:
     - level: The severity level of the log
     - message: The message to log
     - context: Contextual information about the log
     - subsystem: The subsystem identifier (defaults to the one provided at initialisation)
   */
  public func writeLog(
    level: LogLevel,
    message: String,
    context: LogContext,
    subsystem: String
  ) async {
    #if canImport(OSLog)
      let subsystemToUse=subsystem.isEmpty ? defaultSubsystem : subsystem
      // Handle optional source with a default value
      let category=context.getSource()

      let logger=Logger(subsystem: subsystemToUse, category: category)

      // Map LogLevel to OSLogType
      let osLogType: OSLogType=switch level {
        case .trace: .debug
        case .debug: .debug
        case .info: .info
        case .warning: .default
        case .error: .error
        case .critical: .fault
      }

      // Create metadata string if present
      var logMessage=message
      if !context.metadata.isEmpty {
        let metadataString=formatMetadataWithPrivacy(context.metadata)
        logMessage += " \(metadataString)"
      }

      // Add correlation ID
      let correlationString=context.correlationID ?? "none"

      logger.log(level: osLogType, "\(logMessage) [correlation: \(correlationString)]")
    #else
      // Fallback for platforms without OSLog
      print(
        "[\(level)] \(message) [source: \(context.source), correlation: \(context.correlationID ?? "none")]"
      )
    #endif
  }

  /**
   Formats metadata with appropriate privacy annotations for OSLog.
   
   - Parameter metadata: The metadata collection with privacy annotations
   - Returns: A formatted string with OSLog privacy qualifiers
   */
  private func formatMetadataWithPrivacy(_ metadata: LogMetadataDTOCollection) -> String {
    var parts: [String]=[]

    // Iterate through each entry in the collection
    for entry in metadata.entries {
      let key = entry.key
      let value = entry.value
      let privacyLevel = entry.privacyLevel

      let privacyAnnotation: String

      // Apply appropriate privacy annotation based on the privacy level
      switch privacyLevel {
        case .public:
          privacyAnnotation="%{public}"
        case .private, .sensitive, .hash, .auto:
          privacyAnnotation="%{private}"
      }

      parts.append("\(key): \(privacyAnnotation)\(value)")
    }

    return parts.isEmpty ? "" : "{" + parts.joined(separator: ", ") + "}"
  }

  /**
   Formats metadata with appropriate privacy annotations for OSLog (deprecated method).
   
   - Parameter metadata: The metadata with privacy annotations
   - Returns: A formatted string with OSLog privacy qualifiers
   */
  @available(*, deprecated, message: "Use formatMetadataWithPrivacy with LogMetadataDTOCollection instead")
  private func formatMetadataWithPrivacy(_ metadata: PrivacyMetadata) -> String {
    var parts: [String]=[]

    // Iterate through each key-value pair
    for key in metadata.keys {
      guard let value=metadata[key] else { continue }

      let privacyAnnotation: String
      let stringValue=value.valueString

      // Apply appropriate privacy annotation based on the privacy level
      switch value.privacy {
        case .public:
          privacyAnnotation="%{public}"
        case .private, .sensitive, .hash, .auto:
          privacyAnnotation="%{private}"
      }

      parts.append("\(key): \(privacyAnnotation)\(stringValue)")
    }

    return parts.isEmpty ? "" : "{" + parts.joined(separator: ", ") + "}"
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
}
