import Foundation // For UUID

/// Represents a log entry in the system
public struct LogEntry: Sendable, Hashable {
  /// The timestamp when the log entry was created
  public let timestamp: TimePointAdapter

  /// The log level
  public let level: UmbraLogLevel

  /// The message to log
  public let message: String

  /// Optional metadata associated with the log entry
  public let metadata: LogMetadata?
  
  /// Unique identifier for this log entry
  public let entryId: String
  
  /// The source component that generated this log entry (if known)
  public let source: String?

  /// Initialise a new log entry
  /// - Parameters:
  ///   - level: The log level
  ///   - message: The message to log
  ///   - metadata: Optional metadata
  ///   - source: Optional source component identifier
  ///   - entryId: Optional unique identifier (auto-generated if nil)
  public init(
    level: UmbraLogLevel, 
    message: String, 
    metadata: LogMetadata? = nil,
    source: String? = nil,
    entryId: String? = nil
  ) {
    timestamp = TimePointAdapter.now()
    self.level = level
    self.message = message
    self.metadata = metadata
    self.source = source
    self.entryId = entryId ?? UUID().uuidString
  }
  
  /// Create a copy of this log entry with updated metadata
  /// - Parameter newMetadata: The new metadata to merge with existing metadata
  /// - Returns: A new log entry with combined metadata
  public func withUpdatedMetadata(_ newMetadata: LogMetadata) -> LogEntry {
    let combinedMetadata: LogMetadata
    if let existingMetadata = self.metadata {
      var combinedDict = existingMetadata.asDictionary
      for (key, value) in newMetadata.asDictionary {
        combinedDict[key] = value
      }
      combinedMetadata = LogMetadata(combinedDict)
    } else {
      combinedMetadata = newMetadata
    }
    
    return LogEntry(
      level: self.level,
      message: self.message,
      metadata: combinedMetadata,
      source: self.source,
      entryId: self.entryId
    )
  }
}
