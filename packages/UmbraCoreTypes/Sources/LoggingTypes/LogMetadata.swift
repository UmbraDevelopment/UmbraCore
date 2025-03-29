/// Represents metadata that can be attached to log entries
public struct LogMetadata: Sendable, Hashable, Equatable {
  private var storage: [String: String]

  /// Initialise a new LogMetadata instance
  /// - Parameter dictionary: Initial metadata key-value pairs
  public init(_ dictionary: [String: String]=[:]) {
    storage=dictionary
  }

  /// Access metadata values by key
  public subscript(_ key: String) -> String? {
    get { storage[key] }
    set { storage[key]=newValue }
  }

  /// Get all metadata as a dictionary
  public var asDictionary: [String: String] {
    storage
  }
  
  /// Equatable conformance
  public static func == (lhs: LogMetadata, rhs: LogMetadata) -> Bool {
    lhs.storage == rhs.storage
  }
  
  /// Hashable conformance
  public func hash(into hasher: inout Hasher) {
    hasher.combine(storage)
  }
}

extension LogMetadata {
  /// Create LogMetadata from a dictionary of Any values
  /// - Parameter dictionary: Dictionary to convert
  /// - Returns: New LogMetadata instance with string values
  public static func from(_ dictionary: [String: Any]?) -> LogMetadata? {
    guard let dictionary else { return nil }
    let stringDict=dictionary.compactMapValues { "\($0)" }
    return LogMetadata(stringDict)
  }
}
