import Foundation

/// Represents a filtering rule for log entries
/// Used to specify criteria for including or excluding log entries
/// in operations like querying logs
public struct UmbraLogFilterCriteriaDTO: Sendable, Equatable, Hashable, Codable {
  /// Filter by log level
  public let level: UmbraLogLevel?

  /// Filter by source component
  public let source: String?

  /// Filter by message content (substring match)
  public let messageContains: String?

  /// Filter by metadata key presence
  public let hasMetadataKey: String?

  /// Filter by metadata key-value pair
  public let metadataKey: String?
  public let metadataValue: String?

  /// Time range start (ISO 8601 string)
  public let timeRangeStart: String?

  /// Time range end (ISO 8601 string)
  public let timeRangeEnd: String?

  /// Creates a new log filter rule
  ///
  /// - Parameters:
  ///   - level: Optional log level to match
  ///   - source: Optional source component to match
  ///   - messageContains: Optional substring to match in log messages
  ///   - hasMetadataKey: Optional metadata key that must be present
  ///   - metadataKey: Optional metadata key to match
  ///   - metadataValue: Optional metadata value to match
  ///   - timeRangeStart: Optional start of time range (ISO 8601)
  ///   - timeRangeEnd: Optional end of time range (ISO 8601)
  public init(
    level: UmbraLogLevel?=nil,
    source: String?=nil,
    messageContains: String?=nil,
    hasMetadataKey: String?=nil,
    metadataKey: String?=nil,
    metadataValue: String?=nil,
    timeRangeStart: String?=nil,
    timeRangeEnd: String?=nil
  ) {
    self.level=level
    self.source=source
    self.messageContains=messageContains
    self.hasMetadataKey=hasMetadataKey
    self.metadataKey=metadataKey
    self.metadataValue=metadataValue
    self.timeRangeStart=timeRangeStart
    self.timeRangeEnd=timeRangeEnd
  }

  /// Creates a filter rule that matches a specific log level
  ///
  /// - Parameter level: The log level to match
  /// - Returns: A filter rule that matches the specified log level
  public static func forLevel(_ level: UmbraLogLevel) -> UmbraLogFilterCriteriaDTO {
    UmbraLogFilterCriteriaDTO(level: level)
  }

  /// Creates a filter rule that matches a specific source
  ///
  /// - Parameter source: The source to match
  /// - Returns: A filter rule that matches the specified source
  public static func forSource(_ source: String) -> UmbraLogFilterCriteriaDTO {
    UmbraLogFilterCriteriaDTO(source: source)
  }

  /// Creates a filter rule that matches log entries within a time range
  ///
  /// - Parameters:
  ///   - start: The start of the time range (ISO 8601 string)
  ///   - end: The end of the time range (ISO 8601 string)
  /// - Returns: A filter rule that matches logs in the specified time range
  public static func forTimeRange(start: String, end: String) -> UmbraLogFilterCriteriaDTO {
    UmbraLogFilterCriteriaDTO(timeRangeStart: start, timeRangeEnd: end)
  }

  /// Creates a filter rule that matches entries with a specific metadata key-value pair
  ///
  /// - Parameters:
  ///   - key: The metadata key to match
  ///   - value: The metadata value to match
  /// - Returns: A filter rule that matches logs with the specified metadata
  public static func forMetadata(key: String, value: String) -> UmbraLogFilterCriteriaDTO {
    UmbraLogFilterCriteriaDTO(metadataKey: key, metadataValue: value)
  }
}

/**
 # Log Filter Rule DTO

 Defines rules for filtering log entries based on criteria like level,
 source, and content.

 These rules control which log entries are included or excluded for
 a specific log destination.
 */
public struct UmbraLogFilterRuleDTO: Codable, Equatable, Sendable {
  /// Type of action this rule performs
  public enum ActionType: String, Codable, Sendable {
    /// Include matching entries
    case include
    /// Exclude matching entries
    case exclude
  }

  /// Unique identifier for this rule
  public let id: String

  /// Name for this rule
  public let name: String

  /// Whether this rule includes or excludes matching entries
  public let action: ActionType

  /// Criteria for matching log entries
  public let criteria: UmbraLogFilterCriteriaDTO

  /// Priority of this rule (higher numbers take precedence)
  public let priority: Int

  /// Whether this rule is enabled
  public let isEnabled: Bool

  /**
   Initialises a log filter rule.

   - Parameters:
      - id: Unique identifier for this rule
      - name: Name for this rule
      - action: Whether to include or exclude matching entries
      - criteria: Criteria for matching log entries
      - priority: Priority of this rule (higher numbers take precedence)
      - isEnabled: Whether this rule is enabled
   */
  public init(
    id: String=UUID().uuidString,
    name: String,
    action: ActionType,
    criteria: UmbraLogFilterCriteriaDTO,
    priority: Int=100,
    isEnabled: Bool=true
  ) {
    self.id=id
    self.name=name
    self.action=action
    self.criteria=criteria
    self.priority=priority
    self.isEnabled=isEnabled
  }
}
