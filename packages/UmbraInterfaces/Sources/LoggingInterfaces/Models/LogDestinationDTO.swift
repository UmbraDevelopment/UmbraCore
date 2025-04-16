import Foundation
import SchedulingTypes

/**
 Represents a destination for log entries.

 Defines where log entries will be written to, such as a file,
 console, or network endpoint.
 */
public struct LogDestinationDTO: Codable, Equatable, Sendable {
  /// Unique identifier for the destination
  public let id: String

  /// Human-readable name of the destination
  public let name: String

  /// Type of log destination
  public let type: LogDestinationType

  /// Configuration for the destination
  public let configuration: LogDestinationConfigDTO

  /// Enabled status of the destination
  public let isEnabled: Bool

  /// Minimum log level to record at this destination
  public let minimumLevel: LogLevel

  /// Optional formatter configuration for this destination
  public let formatterOptions: LogFormatterOptionsDTO?

  /**
   Initialises a log destination.

   - Parameters:
      - id: Unique identifier for the destination
      - name: Human-readable name of the destination
      - type: Type of log destination
      - configuration: Configuration for the destination
      - isEnabled: Whether the destination is active
      - minimumLevel: Minimum log level to record
      - formatterOptions: Optional formatter configuration
   */
  public init(
    id: String=UUID().uuidString,
    name: String,
    type: LogDestinationType,
    configuration: LogDestinationConfigDTO,
    isEnabled: Bool=true,
    minimumLevel: LogLevel = .info,
    formatterOptions: LogFormatterOptionsDTO?=nil
  ) {
    self.id=id
    self.name=name
    self.type=type
    self.configuration=configuration
    self.isEnabled=isEnabled
    self.minimumLevel=minimumLevel
    self.formatterOptions=formatterOptions
  }
}

/**
 Types of log destinations supported by the system.
 */
public enum LogDestinationType: String, Codable, Sendable {
  /// Console/standard output
  case console
  /// File on disk
  case file
  /// System log facility (e.g., OSLog, syslog)
  case system
  /// Network destination (HTTP, syslog server, etc.)
  case network
  /// Database storage
  case database
  /// In-memory buffer
  case memory
  /// Custom destination type
  case custom
}

/**
 Configuration for a log destination.
 */
public struct LogDestinationConfigDTO: Codable, Equatable, Sendable {
  /// Configuration parameters specific to the destination type
  public let parameters: [String: String]

  /// Retention policy for logs at this destination
  public let retentionPolicy: LogRetentionPolicyDTO?

  /// Filtering rules for this destination
  public let filterRules: [LogFilterRuleDTO]?

  /// Redaction rules for sensitive information
  public let redactionRules: [LogRedactionRuleDTO]?

  /**
   Initialises a log destination configuration.

   - Parameters:
      - parameters: Configuration parameters specific to the destination type
      - retentionPolicy: Retention policy for logs at this destination
      - filterRules: Filtering rules for this destination
      - redactionRules: Redaction rules for sensitive information
   */
  public init(
    parameters: [String: String]=[:],
    retentionPolicy: LogRetentionPolicyDTO?=nil,
    filterRules: [LogFilterRuleDTO]?=nil,
    redactionRules: [LogRedactionRuleDTO]?=nil
  ) {
    self.parameters=parameters
    self.retentionPolicy=retentionPolicy
    self.filterRules=filterRules
    self.redactionRules=redactionRules
  }

  /**
   Creates a file destination configuration.

   - Parameters:
      - filePath: Path to the log file
      - maxFileSizeBytes: Maximum size of the log file before rotation
      - maxBackupCount: Maximum number of rotated backup files to keep
      - appendToFile: Whether to append to existing file
   - Returns: Configured log destination config for a file
   */
  public static func fileConfig(
    filePath: String,
    maxFileSizeBytes: Int=10_485_760, // 10 MB
    maxBackupCount: Int=5,
    appendToFile: Bool=true
  ) -> LogDestinationConfigDTO {
    let parameters: [String: String]=[
      "filePath": filePath,
      "maxFileSizeBytes": String(maxFileSizeBytes),
      "maxBackupCount": String(maxBackupCount),
      "appendToFile": String(appendToFile)
    ]

    let retentionPolicy=LogRetentionPolicyDTO(
      maxEntries: nil,
      maxBytes: UInt64(maxFileSizeBytes),
      maxAgeSeconds: nil,
      rotationStrategy: .size
    )

    return LogDestinationConfigDTO(
      parameters: parameters,
      retentionPolicy: retentionPolicy
    )
  }

  /**
   Creates a console destination configuration.

   - Parameters:
      - useColours: Whether to use coloured output
      - includeSourceLocation: Whether to include source code location
   - Returns: Configured log destination config for console
   */
  public static func consoleConfig(
    useColours: Bool=true,
    includeSourceLocation: Bool=true
  ) -> LogDestinationConfigDTO {
    let parameters: [String: String]=[
      "useColours": String(useColours),
      "includeSourceLocation": String(includeSourceLocation)
    ]

    return LogDestinationConfigDTO(parameters: parameters)
  }

  /**
   Creates a network destination configuration.

   - Parameters:
      - endpoint: URL of the logging endpoint
      - method: HTTP method to use
      - authToken: Optional authentication token
      - batchSize: Number of log entries to batch before sending
   - Returns: Configured log destination config for network
   */
  public static func networkConfig(
    endpoint: String,
    method: String="POST",
    authToken: String?=nil,
    batchSize: Int=10
  ) -> LogDestinationConfigDTO {
    var parameters: [String: String]=[
      "endpoint": endpoint,
      "method": method,
      "batchSize": String(batchSize)
    ]

    if let authToken {
      parameters["authToken"]=authToken
    }

    return LogDestinationConfigDTO(parameters: parameters)
  }
}

/**
 Retention policy for logs at a destination.
 */
public struct LogRetentionPolicyDTO: Codable, Equatable, Sendable {
  /// Maximum number of log entries to keep
  public let maxEntries: Int?

  /// Maximum size in bytes for stored logs
  public let maxBytes: UInt64?

  /// Maximum age in seconds for log entries
  public let maxAgeSeconds: TimeInterval?

  /// Strategy for rotating or archiving logs
  public let rotationStrategy: LogRotationStrategy

  /**
   Initialises a log retention policy.

   - Parameters:
      - maxEntries: Maximum number of log entries to keep
      - maxBytes: Maximum size in bytes for stored logs
      - maxAgeSeconds: Maximum age in seconds for log entries
      - rotationStrategy: Strategy for rotating or archiving logs
   */
  public init(
    maxEntries: Int?=nil,
    maxBytes: UInt64?=nil,
    maxAgeSeconds: TimeInterval?=nil,
    rotationStrategy: LogRotationStrategy = .none
  ) {
    self.maxEntries=maxEntries
    self.maxBytes=maxBytes
    self.maxAgeSeconds=maxAgeSeconds
    self.rotationStrategy=rotationStrategy
  }
}

/**
 Strategy for rotating or archiving logs.
 */
public enum LogRotationStrategy: String, Codable, Sendable {
  /// No rotation strategy
  case none
  /// Rotate logs based on size
  case size
  /// Rotate logs based on time
  case time
  /// Rotate logs based on entry count
  case count
  /// Custom rotation strategy
  case custom
}

/**
 Filter rule for determining if a log entry should be recorded.
 */
public struct LogFilterRuleDTO: Codable, Equatable, Sendable {
  /// Field to filter on
  public let field: String

  /// Comparison operator
  public let operation: FilterOperation

  /// Value to compare against
  public let value: String

  /// Whether to include or exclude matching entries
  public let isIncludeRule: Bool

  /**
   Initialises a log filter rule.

   - Parameters:
      - field: Field to filter on
      - operation: Comparison operator
      - value: Value to compare against
      - isIncludeRule: Whether to include or exclude matching entries
   */
  public init(
    field: String,
    operation: FilterOperation,
    value: String,
    isIncludeRule: Bool=true
  ) {
    self.field=field
    self.operation=operation
    self.value=value
    self.isIncludeRule=isIncludeRule
  }

  /**
   Filter operation types.
   */
  public enum FilterOperation: String, Codable, Sendable {
    /// Field equals value
    case equals
    /// Field contains value
    case contains
    /// Field matches regex pattern
    case matches
    /// Field starts with value
    case startsWith
    /// Field ends with value
    case endsWith
    /// Field greater than value
    case greaterThan
    /// Field less than value
    case lessThan
  }
}

/**
 Rule for redacting sensitive information in log entries.
 */
public struct LogRedactionRuleDTO: Codable, Equatable, Sendable {
  /// Pattern to match for redaction
  public let pattern: String

  /// Whether the pattern is a regular expression
  public let isRegex: Bool

  /// Replacement text for matched content
  public let replacement: String

  /// Fields to apply this redaction to (empty means all fields)
  public let targetFields: [String]

  /**
   Initialises a log redaction rule.

   - Parameters:
      - pattern: Pattern to match for redaction
      - isRegex: Whether the pattern is a regular expression
      - replacement: Replacement text for matched content
      - targetFields: Fields to apply this redaction to
   */
  public init(
    pattern: String,
    isRegex: Bool=false,
    replacement: String="[REDACTED]",
    targetFields: [String]=[]
  ) {
    self.pattern=pattern
    self.isRegex=isRegex
    self.replacement=replacement
    self.targetFields=targetFields
  }
}

/**
 Formatter options for log entries.
 */
public struct LogFormatterOptionsDTO: Codable, Equatable, Sendable {
  /// Format template for log entries
  public let template: String?

  /// Date format for timestamps
  public let dateFormat: String

  /// Whether to include timestamps
  public let includeTimestamp: Bool

  /// Whether to include log level
  public let includeLevel: Bool

  /// Whether to include category/subsystem
  public let includeCategory: Bool

  /// Whether to include source code location
  public let includeSourceLocation: Bool

  /// Whether to include thread/task identifier
  public let includeThreadInfo: Bool

  /// Whether to pretty-print JSON or other structured formats
  public let prettyPrint: Bool

  /// Maximum length for message (truncated if longer)
  public let maxMessageLength: Int?

  /**
   Initialises log formatter options.

   - Parameters:
      - template: Format template for log entries
      - dateFormat: Date format for timestamps
      - includeTimestamp: Whether to include timestamps
      - includeLevel: Whether to include log level
      - includeCategory: Whether to include category/subsystem
      - includeSourceLocation: Whether to include source code location
      - includeThreadInfo: Whether to include thread/task identifier
      - prettyPrint: Whether to pretty-print JSON or other structured formats
      - maxMessageLength: Maximum length for message
   */
  public init(
    template: String?=nil,
    dateFormat: String="yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ",
    includeTimestamp: Bool=true,
    includeLevel: Bool=true,
    includeCategory: Bool=true,
    includeSourceLocation: Bool=false,
    includeThreadInfo: Bool=false,
    prettyPrint: Bool=false,
    maxMessageLength: Int?=nil
  ) {
    self.template=template
    self.dateFormat=dateFormat
    self.includeTimestamp=includeTimestamp
    self.includeLevel=includeLevel
    self.includeCategory=includeCategory
    self.includeSourceLocation=includeSourceLocation
    self.includeThreadInfo=includeThreadInfo
    self.prettyPrint=prettyPrint
    self.maxMessageLength=maxMessageLength
  }

  /// Default formatter options
  public static let `default`=LogFormatterOptionsDTO()
}
