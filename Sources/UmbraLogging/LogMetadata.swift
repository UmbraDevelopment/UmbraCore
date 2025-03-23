import Foundation

/// Represents metadata that can be attached to log entries
public struct LogMetadata: Sendable {
  private var storage: [String: String]

  /// Initialize a new LogMetadata instance
  /// - Parameter dictionary: Initial metadata key-value pairs
  public init(_ dictionary: [String: String] = [:]) {
    storage = dictionary
  }

  /// Access metadata values by key
  public subscript(_ key: String) -> String? {
    get { storage[key] }
    set { storage[key] = newValue }
  }

  /// Get all metadata as a dictionary
  public var asDictionary: [String: Any] {
    storage
  }
}

extension LogMetadata {
  /// Create LogMetadata from a dictionary of Any values
  /// - Parameter dictionary: Dictionary to convert
  /// - Returns: New LogMetadata instance with string values
  public static func from(_ dictionary: [String: Any]?) -> LogMetadata? {
    guard let dictionary else { return nil }
    let stringDict = dictionary.compactMapValues { "\($0)" }
    return LogMetadata(stringDict)
  }

  /// Create a string value for the metadata
  /// - Parameter value: The value to convert to a string
  /// - Returns: The string representation of the value
  public static func string(_ value: Any) -> String {
    "\(value)"
  }
}
