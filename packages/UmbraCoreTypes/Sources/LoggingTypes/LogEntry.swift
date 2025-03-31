/// Represents a log entry in the system
public struct LogEntry: Sendable, Equatable, Hashable {
  /// Log entry timestamp
  public let timestamp: LogTimestamp

  /// Log severity level
  public let level: LogLevel

  /// Log message content
  public let message: String

  /// Log entry metadata with privacy annotations
  public let metadata: PrivacyMetadata?

  /// Component that generated this log
  public let source: String

  /// Unique identifier for this log entry
  public let entryID: LogIdentifier

  /// Rich context information
  public var context: LogContext {
    LogContext(
      source: source,
      metadata: metadata,
      correlationID: entryID,
      timestamp: timestamp
    )
  }

  /// Creates a new log entry
  ///
  /// Note: This initialiser requires a pre-generated timestamp for non-async contexts.
  ///
  /// - Parameters:
  ///   - level: Log severity level
  ///   - message: Log message content
  ///   - metadata: Optional metadata with privacy annotations
  ///   - source: Optional source component identifier
  ///   - entryId: Optional unique identifier (auto-generated if nil)
  ///   - timestamp: The timestamp for this log entry
  public init(
    level: LogLevel,
    message: String,
    metadata: PrivacyMetadata?=nil,
    source: String="",
    entryID: LogIdentifier?=nil,
    timestamp: LogTimestamp
  ) {
    self.timestamp=timestamp
    self.level=level
    self.message=message
    self.metadata=metadata
    self.source=source
    self.entryID=entryID ?? LogIdentifier.unique()
  }

  /// Creates a new log entry with the current time
  ///
  /// - Parameters:
  ///   - level: Log severity level
  ///   - message: Log message content
  ///   - metadata: Optional metadata with privacy annotations
  ///   - source: Optional source component identifier
  ///   - entryId: Optional unique identifier (auto-generated if nil)
  public static func create(
    level: LogLevel,
    message: String,
    metadata: PrivacyMetadata?=nil,
    source: String="",
    entryID: LogIdentifier?=nil
  ) async -> LogEntry {
    let timestamp=await LogTimestamp.now()
    return LogEntry(
      level: level,
      message: message,
      metadata: metadata,
      source: source,
      entryID: entryID,
      timestamp: timestamp
    )
  }

  /// Creates a new log entry with context
  ///
  /// - Parameters:
  ///   - level: Log severity level
  ///   - message: Log message content
  ///   - context: Contextual information
  public init(
    level: LogLevel,
    message: String,
    context: LogContext
  ) {
    timestamp=context.timestamp
    self.level=level
    self.message=message
    metadata=context.metadata
    source=context.source
    entryID=context.correlationID
  }
}
