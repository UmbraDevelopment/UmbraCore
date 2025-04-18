import Foundation

/// Operations that can be performed in filter rules
public enum FilterOperation: String, Sendable, Equatable, Codable {
  case equals
  case contains
  case startsWith
  case endsWith
  case matches
  case greaterThan
  case lessThan
}

/// Extension to provide compatibility with legacy logging code
extension UmbraLogFilterRuleDTO {
  /// The field to filter on (extracted from criteria)
  public var field: String {
    if criteria.level != nil {
      "level"
    } else if criteria.source != nil {
      "source"
    } else if criteria.messageContains != nil {
      "message"
    } else if let key=criteria.metadataKey {
      "metadata.\(key)"
    } else {
      "any" // Default field type if no criteria specified
    }
  }

  /// The operation to perform (always contains for now)
  public var operation: FilterOperation {
    .contains
  }

  /// The value to compare against (extracted from criteria)
  public var value: String {
    if let level=criteria.level {
      String(level.rawValue)
    } else if let source=criteria.source {
      source
    } else if let message=criteria.messageContains {
      message
    } else if let value=criteria.metadataValue {
      value
    } else {
      "" // Default empty string if no value specified
    }
  }

  /// Target fields for this rule (simplified for compatibility)
  public var targetFields: [String] {
    if criteria.metadataKey != nil {
      [field]
    } else if criteria.hasMetadataKey != nil {
      [field]
    } else {
      [] // Empty array means apply to all fields
    }
  }

  /// Fields that should be preserved from redaction
  public var preserveFields: [String] {
    [] // No preserved fields by default
  }

  /// Pattern for regex matching (if applicable)
  public var pattern: String? {
    criteria.messageContains
  }
}
