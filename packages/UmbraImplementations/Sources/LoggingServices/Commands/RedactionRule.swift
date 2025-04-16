import Foundation
import LoggingInterfaces
import LoggingTypes

/**
 Rule for redacting sensitive information in log entries.

 Redaction rules define patterns of sensitive data that should be redacted
 in log entries before they are sent to destinations.
 */
public struct RedactionRule: Sendable {
  /// Categories to which this rule applies (empty means all)
  public let categories: Set<String>

  /// Fields to which this rule applies (empty means all)
  public let targetFields: Set<String>

  /// Fields that should be preserved (not redacted)
  public let preserveFields: Set<String>

  /// Pattern to match for redaction
  public let pattern: String

  /// Replacement string for matches
  public let replacement: String

  /// Whether the pattern is a regular expression
  public let isRegex: Bool

  /// The regular expression pattern to use for matching
  private let regexPattern: NSRegularExpression?

  /**
   Initialises a new redaction rule.

   - Parameters:
      - pattern: Pattern to match for redaction
      - replacement: Replacement string for matches
      - isRegex: Whether the pattern is a regular expression
      - categories: Categories to which this rule applies
      - targetFields: Fields to which this rule applies
      - preserveFields: Fields that should be preserved
   */
  public init(
    pattern: String,
    replacement: String="***",
    isRegex: Bool=true,
    categories: Set<String>=[],
    targetFields: Set<String>=[],
    preserveFields: Set<String>=[]
  ) {
    self.pattern=pattern
    self.replacement=replacement
    self.isRegex=isRegex
    self.categories=categories
    self.targetFields=targetFields
    self.preserveFields=preserveFields

    // Compile regex pattern if needed
    if isRegex {
      do {
        regexPattern=try NSRegularExpression(pattern: pattern, options: [])
      } catch {
        print("Failed to compile regex pattern: \(error.localizedDescription)")
        regexPattern=nil
      }
    } else {
      regexPattern=nil
    }
  }

  /**
   Apply redaction to a string.

   - Parameter string: The string to redact
   - Returns: The redacted string
   */
  public func redact(_ string: String) -> String {
    if isRegex, let regex=regexPattern {
      let range=NSRange(location: 0, length: string.utf16.count)
      return regex.stringByReplacingMatches(
        in: string,
        options: [],
        range: range,
        withTemplate: replacement
      )
    } else {
      // Use simple string replacement if not regex
      return string.replacingOccurrences(of: pattern, with: replacement)
    }
  }

  /**
   Apply redaction to a metadata collection.

   - Parameter metadata: The metadata to redact
   - Returns: The redacted metadata
   */
  public func redact(metadata: LogMetadataDTOCollection) -> LogMetadataDTOCollection {
    // No redaction needed for empty metadata
    let keys=metadata.getKeys()
    guard !keys.isEmpty else {
      return metadata
    }

    var result=metadata

    for key in keys {
      // Skip preserved fields
      if preserveFields.contains(key) {
        continue
      }

      // Skip fields that don't match target fields
      if !targetFields.isEmpty && !targetFields.contains(key) {
        continue
      }

      // Get string value and apply redaction
      if let value=metadata.getString(key: key) {
        let redactedValue=redact(value)
        if value != redactedValue {
          // Only update if actually changed
          result=result.with(key: key, value: redactedValue, privacyLevel: .public)
        }
      }
    }

    return result
  }
}
