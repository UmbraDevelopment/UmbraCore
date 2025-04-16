import Foundation

/// Represents a data transfer object (DTO) for log entries in the logging system
/// This DTO facilitates data exchange between logging components and storage
public struct LogEntryDTO: Sendable, Equatable, Hashable {
  /// Log entry timestamp as seconds since epoch
  public let timestamp: Double

  /// Log severity level
  public let level: LogLevel

  /// Log message content
  public let message: String

  /// Log entry metadata with privacy annotations
  public let metadata: LogMetadataDTOCollection?

  /// Component that generated this log
  public let source: String

  /// Category for this log entry (e.g., "LoggingSystem", "Security")
  public let category: String

  /// Unique identifier for this log entry
  public let entryID: String

  /// Creates a new log entry DTO
  ///
  /// - Parameters:
  ///   - timestamp: Timestamp as seconds since epoch
  ///   - level: Log severity level
  ///   - message: Log message content
  ///   - category: Category for the log entry (e.g., "LoggingSystem", "Security")
  ///   - metadata: Optional metadata with privacy annotations
  ///   - source: Optional source component identifier
  ///   - entryID: Unique identifier
  public init(
    timestamp: Double,
    level: LogLevel,
    message: String,
    category: String="Default",
    metadata: LogMetadataDTOCollection?=nil,
    source: String="",
    entryID: String
  ) {
    self.timestamp=timestamp
    self.level=level
    self.message=message
    self.category=category
    self.metadata=metadata
    self.source=source
    self.entryID=entryID
  }

  /// Creates a new log entry DTO with the current timestamp
  ///
  /// - Parameters:
  ///   - level: Log severity level
  ///   - message: Log message content
  ///   - category: Category for the log entry (e.g., "LoggingSystem", "Security")
  ///   - metadata: Optional metadata with privacy annotations
  ///   - source: Optional source component identifier
  public init(
    level: LogLevel,
    message: String,
    category: String="Default",
    metadata: LogMetadataDTOCollection?=nil,
    source: String=""
  ) {
    timestamp=Date().timeIntervalSince1970
    self.level=level
    self.message=message
    self.category=category
    self.metadata=metadata
    self.source=source
    entryID=UUID().uuidString
  }

  /// Creates a LogEntryDTO from a LogEntry
  ///
  /// - Parameter entry: The LogEntry to convert
  /// - Returns: A LogEntryDTO instance
  public static func from(entry: LogEntry) -> LogEntryDTO {
    LogEntryDTO(
      timestamp: entry.timestamp.secondsSinceEpoch,
      level: entry.level,
      message: entry.message,
      category: "Default", // Use a default value as LogEntry doesn't have category
      metadata: entry.metadata,
      source: entry.source,
      entryID: entry.entryID.description
    )
  }

  /// Converts this DTO to a LogEntry
  ///
  /// - Returns: A LogEntry instance
  public func toLogEntry() async -> LogEntry {
    let timestamp=LogTimestamp(secondsSinceEpoch: timestamp)
    return LogEntry(
      level: level,
      message: message,
      metadata: metadata,
      source: source,
      entryID: LogIdentifier(value: entryID),
      timestamp: timestamp
    )
  }

  /// Gets the timestamp as a Date object
  public var timestampAsDate: Date {
    Date(timeIntervalSince1970: timestamp)
  }

  /// The entry ID (alias for entryID to maintain compatibility)
  public var id: String {
    entryID
  }
}

/// Extension to LogEntry for easy conversion to/from DTO
extension LogEntry {
  /// Convert this LogEntry to a LogEntryDTO
  ///
  /// - Returns: A LogEntryDTO instance
  public func toDTO() -> LogEntryDTO {
    LogEntryDTO.from(entry: self)
  }
}

/// Extension to LogEntryDTO for metadata access
extension LogEntryDTO {
  /// Gets a string value from metadata with the given key
  /// - Parameter key: The metadata key to retrieve
  /// - Returns: The string value if found, nil otherwise
  public func getMetadataString(key: String) -> String? {
    metadata?.getString(key: key)
  }

  /// Gets all metadata keys
  /// - Returns: Array of metadata keys
  public func getMetadataKeys() -> [String] {
    metadata?.getKeys() ?? []
  }
}
