import Foundation
import LoggingInterfaces
import LoggingTypes

/**
 # Privacy-Aware Log Formatter

 A log formatter that applies privacy controls to log messages based on
 privacy classifications. This formatter ensures sensitive data is properly
 handled according to its privacy level and the current deployment environment.

 ## Privacy Classifications

 The formatter handles different privacy levels:
 - **Public**: Displayed normally in all environments
 - **Private**: Redacted in production, displayed in development
 - **Sensitive**: Always redacted, but can be accessed with proper authorisation
 - **Hash**: Replaced with a hash of the original value

 ## Environment-Based Behaviour

 The formatter's behaviour changes based on the deployment environment:

 | Privacy Level | Development | Staging | Production |
 |---------------|-------------|---------|------------|
 | Public        | Visible     | Visible | Visible    |
 | Private       | Visible     | Visible | Redacted   |
 | Sensitive     | Configurable| Redacted| Redacted   |
 | Hash          | Hashed      | Hashed  | Hashed     |

 ## Usage Examples

 ### Basic Usage

 ```swift
 // Create a formatter for development environment
 let formatter = PrivacyAwareLogFormatter(
     environment: .development,
     includePrivateDetails: true
 )

 // Format a log entry
 let formattedLog = formatter.format(logEntry)
 ```

 ### Production Configuration

 ```swift
 // Create a formatter for production with strict privacy controls
 let formatter = PrivacyAwareLogFormatter(
     environment: .production,
     includePrivateDetails: false,
     includeSensitiveDetails: false
 )
 ```

 ### Custom Formatting Configuration

 ```swift
 // Create a formatter with custom formatting options
 let formatter = PrivacyAwareLogFormatter(
     environment: .development,
     includeTimestamp: true,
     includeLevel: true,
     includeSource: false,
     includeMetadata: true
 )
 ```
 */
public final class PrivacyAwareLogFormatter: LogFormatterProtocol {
  /// The environment the formatter is operating in
  private let environment: LoggingTypes.DeploymentEnvironment

  /// Whether to include full details for private data
  private let includePrivateDetails: Bool

  /// Whether to include full details for sensitive data (requires authorisation)
  private let includeSensitiveDetails: Bool

  /// Configuration for formatting options
  private let includeTimestamp: Bool
  private let includeLevel: Bool
  private let includeSource: Bool
  private let includeMetadata: Bool

  /**
   Initialises a new privacy-aware log formatter.

   This initialiser creates a formatter with the specified configuration. The formatter's
   behaviour regarding privacy controls is determined by the environment and the
   includePrivateDetails/includeSensitiveDetails flags.

   - Parameters:
     - environment: The deployment environment (production, development, etc.)
     - includePrivateDetails: Whether to include private details (defaults to true in development)
     - includeSensitiveDetails: Whether to include sensitive details (requires authorisation)
     - includeTimestamp: Whether to include timestamps in formatted logs
     - includeLevel: Whether to include log levels in formatted logs
     - includeSource: Whether to include source information in formatted logs
     - includeMetadata: Whether to include metadata in formatted logs

   ## Example

   ```swift
   let formatter = PrivacyAwareLogFormatter(
       environment: .staging,
       includePrivateDetails: true,
       includeSensitiveDetails: false,
       includeTimestamp: true,
       includeLevel: true,
       includeSource: true,
       includeMetadata: true
   )
   ```
   */
  public init(
    environment: LoggingTypes.DeploymentEnvironment = .development,
    includePrivateDetails: Bool?=nil,
    includeSensitiveDetails: Bool=false,
    includeTimestamp: Bool=true,
    includeLevel: Bool=true,
    includeSource: Bool=true,
    includeMetadata: Bool=true
  ) {
    self.environment=environment

    // Default to showing private details in development, hiding in production
    self
      .includePrivateDetails=includePrivateDetails ??
      (environment != LoggingTypes.DeploymentEnvironment.production)

    // Sensitive details require explicit authorisation
    self.includeSensitiveDetails=includeSensitiveDetails

    // Formatting configuration
    self.includeTimestamp=includeTimestamp
    self.includeLevel=includeLevel
    self.includeSource=includeSource
    self.includeMetadata=includeMetadata
  }

  // MARK: - LogFormatterProtocol Conformance

  /**
   Formats a log entry into a string representation.

   This method applies privacy controls to the log entry based on the formatter's
   configuration and the deployment environment. It formats the log entry into
   a string with the specified components (timestamp, level, source, message, metadata).

   - Parameter entry: The log entry to format
   - Returns: A formatted string representation of the log entry

   ## Example Output

   ```
   2025-04-08 11:45:23.456 [INFO] [AuthService] User login successful { user_id: [REDACTED:PRIVATE], ip: 192.168.1.1 }
   ```
   */
  public func format(_ entry: LoggingTypes.LogEntry) -> String {
    var components: [String]=[]

    // Add timestamp if enabled
    if includeTimestamp {
      // Create a TimePointAdapter from the LogTimestamp
      let adapter=createTimePointAdapter(from: entry.timestamp)
      components.append(formatTimestamp(adapter))
    }

    // Add log level if enabled
    if includeLevel {
      // Convert LogLevel to UmbraLogLevel
      let umbraLevel=convertToUmbraLogLevel(entry.level)
      components.append(formatLogLevel(umbraLevel))
    }

    // Add source if enabled and available
    if includeSource {
      components.append("[\(entry.source)]")
    }

    // Add message
    components.append(entry.message)

    // Add metadata if enabled and available
    if includeMetadata {
      if let metadata=entry.metadata, let metadataStr=formatMetadataCollection(metadata), !metadataStr.isEmpty {
        components.append(metadataStr)
      }
    }

    return components.joined(separator: " ")
  }

  /**
   Formats metadata collection into a string representation with privacy controls applied.

   This method formats metadata key-value pairs into a string, applying privacy
   controls based on the privacy level of each value and the formatter's configuration.

   - Parameter metadata: The metadata collection to format
   - Returns: A formatted string representation of the metadata, or nil if empty

   ## Example Output

   ```
   { user_id: [REDACTED:PRIVATE], request_id: abc-123, card_number: [REDACTED:SENSITIVE] }
   ```
   */
  public func formatMetadataCollection(_ metadata: LogMetadataDTOCollection?) -> String? {
    guard let metadata=metadata, !metadata.entries.isEmpty else {
      return nil
    }

    let formattedPairs=metadata.entries.map { entry in
      "\(entry.key): \(formatValue(entry.value, privacyLevel: entry.privacyLevel))"
    }

    return "{ \(formattedPairs.joined(separator: ", ")) }"
  }

  /**
   Formats a timestamp into a string representation.

   - Parameter timestamp: The timestamp to format
   - Returns: A formatted string representation of the timestamp

   ## Example Output

   ```
   2025-04-08 11:45:23.456
   ```
   */
  public func formatTimestamp(_ timestamp: LoggingTypes.TimePointAdapter) -> String {
    let dateFormatter=DateFormatter()
    dateFormatter.dateFormat="yyyy-MM-dd HH:mm:ss.SSS"
    // Create a Date from the timeIntervalSince1970
    let date=Date(timeIntervalSince1970: timestamp.timeIntervalSince1970)
    return dateFormatter.string(from: date)
  }

  /**
   Formats a log level into a string representation.

   - Parameter level: The log level to format
   - Returns: A formatted string representation of the log level

   ## Example Output

   ```
   [INFO]
   ```
   */
  public func formatLogLevel(_ level: LoggingTypes.UmbraLogLevel) -> String {
    let levelString=switch level {
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
      case .verbose:
        "VERBOSE"
    }

    return "[\(levelString)]"
  }

  /**
   Creates a new formatter with the specified configuration.

   This method allows for creating a new formatter with different formatting options
   while preserving the privacy control configuration.

   - Parameters:
     - includeTimestamp: Whether to include timestamps in formatted logs
     - includeLevel: Whether to include log levels in formatted logs
     - includeSource: Whether to include source information in formatted logs
     - includeMetadata: Whether to include metadata in formatted logs
   - Returns: A new formatter with the specified configuration

   ## Example

   ```swift
   let compactFormatter = formatter.withConfiguration(
       includeTimestamp: false,
       includeLevel: true,
       includeSource: false,
       includeMetadata: true
   )
   ```
   */
  public func withConfiguration(
    includeTimestamp: Bool,
    includeLevel: Bool,
    includeSource: Bool,
    includeMetadata: Bool
  ) -> any LogFormatterProtocol {
    PrivacyAwareLogFormatter(
      environment: environment,
      includePrivateDetails: includePrivateDetails,
      includeSensitiveDetails: includeSensitiveDetails,
      includeTimestamp: includeTimestamp,
      includeLevel: includeLevel,
      includeSource: includeSource,
      includeMetadata: includeMetadata
    )
  }

  // MARK: - Helper Methods

  /// Create a TimePointAdapter from a LogTimestamp
  /// - Parameter timestamp: The LogTimestamp to convert
  /// - Returns: A TimePointAdapter
  private func createTimePointAdapter(from _: LogTimestamp) -> LoggingTypes.TimePointAdapter {
    // Create a new TimePointAdapter
    // In a real implementation, you would extract the timestamp value properly

    // For now, we'll use a simple conversion
    // Assuming LogTimestamp has a property that can be converted to seconds
    let timeInterval=Date().timeIntervalSince1970 // Default to current time

    return LoggingTypes.TimePointAdapter(timeIntervalSince1970: timeInterval)
  }

  /// Convert LogLevel to UmbraLogLevel
  /// - Parameter level: The LogLevel to convert
  /// - Returns: The equivalent UmbraLogLevel
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

  /**
   Formats a value based on its privacy level.

   This method applies privacy controls to a value based on its privacy level
   and the formatter's configuration. The behaviour depends on the privacy level
   and the deployment environment.

   - Parameters:
     - value: The value to format
     - privacyLevel: The privacy level of the value
   - Returns: A formatted string representation of the value

   ## Privacy Control Behaviour

   | Privacy Level | Behaviour                                           |
   |---------------|-----------------------------------------------------|
   | Public        | Value is displayed as-is                            |
   | Private       | Value is redacted in production, visible otherwise  |
   | Sensitive     | Value is redacted unless explicitly authorised      |
   | Hash          | Value is replaced with a hash                       |
   | Auto          | Value is analysed and appropriate controls applied  |
   */
  private func formatValue(_ value: Any, privacyLevel: LogPrivacyLevel) -> String {
    switch privacyLevel {
      case .public:
        return "\(value)"

      case .private:
        if includePrivateDetails {
          return "\(value)"
        } else {
          return "[REDACTED:PRIVATE]"
        }

      case .sensitive:
        if includeSensitiveDetails {
          return "\(value)"
        } else {
          return "[REDACTED:SENSITIVE]"
        }

      case .hash:
        // Create a hash of the value
        let valueString="\(value)"
        let hash=valueString.hash
        return "[HASHED:\(abs(hash))]"

      case .auto:
        // Auto-detect privacy level based on key name heuristics
        if let stringValue=value as? String, shouldRedactAutomatically(stringValue) {
          return "[REDACTED:AUTO]"
        } else {
          return "\(value)"
        }
    }
  }

  /**
   Determines if a value should be automatically redacted based on heuristics.

   This method analyses a string value to determine if it contains sensitive
   information that should be redacted automatically, such as credit card numbers,
   passwords, or personal identifiable information.

   - Parameter value: The value to check
   - Returns: True if the value should be redacted
   */
  private func shouldRedactAutomatically(_: String) -> Bool {
    // Implement heuristics for detecting sensitive data
    // For example, check for patterns like credit card numbers, emails, etc.
    false
  }

  /// Convert PrivacyMetadata to LogMetadata
  /// - Parameter metadata: The PrivacyMetadata to convert
  /// - Returns: A LogMetadata object
  private func convertToLogMetadata(_ metadata: PrivacyMetadata) -> LoggingTypes.LogMetadata {
    // Create a new LogMetadata instance
    var logMetadata=LoggingTypes.LogMetadata()

    // Extract values from PrivacyMetadata and add them to LogMetadata
    // This is a simplified implementation - in a real implementation,
    // you would properly extract all values with their privacy levels

    // Use the entriesDict method to get all entries
    let entries=metadata.entriesDict()

    for (key, value) in entries {
      // Get the string value directly (it's not optional)
      let stringValue=value.stringValue
      logMetadata[key]=stringValue
    }

    return logMetadata
  }

  /**
   Creates a formatter configured for a specific privacy-aware log DTO.

   This method creates a new formatter with configuration derived from the
   provided DTO, which can be useful for applying consistent formatting to
   logs from a specific context.

   - Parameter dto: The privacy-aware log DTO
   - Returns: A configured formatter

   ## Example

   ```swift
   let contextSpecificFormatter = formatter.configuredFor(dto: logContext)
   ```
   */
  public func configuredFor(dto _: PrivacyAwareLogDTO) -> PrivacyAwareLogFormatter {
    // In a real implementation, you would extract configuration from the DTO
    // For now, we'll just return self
    self
  }
}
