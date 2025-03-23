import Foundation

/// Log level for entries
public enum LogLevel: String, Sendable {
  case debug = "DEBUG"
  case info = "INFO"
  case warning = "WARNING"
  case error = "ERROR"
}

/// A log entry with message and metadata
public struct LogEntry: Sendable, Identifiable {
  // MARK: - Properties

  /// Unique identifier
  public let id: String

  /// Timestamp when the log entry was created (seconds since epoch)
  public let timestamp: Int

  /// Log level
  public let level: LogLevel

  /// Log message
  public let message: String

  /// Optional metadata
  public let metadata: [String: String]?

  /// Source file
  public let file: String

  /// Source function
  public let function: String

  /// Source line
  public let line: Int

  // MARK: - Computed Properties

  /// Formatted message including metadata
  public var formattedMessage: String {
    var result = message
    if let metadata, !metadata.isEmpty {
      let metadataString = metadata.map { "\($0.key)=\($0.value)" }.joined(separator: ", ")
      result += " {\(metadataString)}"
    }
    return result
  }

  /// Source location string
  public var sourceLocation: String {
    "\(file):\(line) - \(function)"
  }

  // MARK: - Initialization

  /// Initialize a log entry
  /// - Parameters:
  ///   - id: Unique identifier
  ///   - timestamp: Timestamp in seconds since epoch
  ///   - level: Log level
  ///   - message: Log message
  ///   - metadata: Optional metadata
  ///   - file: Source file
  ///   - function: Source function
  ///   - line: Source line
  public init(
    id: String = String(Int.random(in: 0..<Int.max)),
    timestamp: Int = Int(Date().timeIntervalSince1970),
    level: LogLevel,
    message: String,
    metadata: [String: String]? = nil,
    file: String = #file,
    function: String = #function,
    line: Int = #line
  ) {
    self.id = id
    self.timestamp = timestamp
    self.level = level
    self.message = message
    self.metadata = metadata
    self.file = file
    self.function = function
    self.line = line
  }

  /// Create a copy of this entry with updated metadata
  /// - Parameter metadata: New metadata to merge with existing
  /// - Returns: New log entry with updated metadata
  public func with(metadata: [String: String]) -> LogEntry {
    var newMetadata = self.metadata ?? [:]
    metadata.forEach { newMetadata[$0.key] = $0.value }

    return LogEntry(
      id: id,
      timestamp: timestamp,
      level: level,
      message: message,
      metadata: newMetadata,
      file: file,
      function: function,
      line: line
    )
  }

  /// Create a copy of this entry with a new message
  /// - Parameter message: New message
  /// - Returns: New log entry with updated message
  public func with(message: String) -> LogEntry {
    LogEntry(
      id: id,
      timestamp: timestamp,
      level: level,
      message: message,
      metadata: metadata,
      file: file,
      function: function,
      line: line
    )
  }
}

/// String representation of a log entry
extension LogEntry: CustomStringConvertible {
  public var description: String {
    """
    [\(timestamp)][\(level.rawValue)] \(message)
    Source: \(sourceLocation)
    \(metadata?.isEmpty == false ? "Metadata: \(metadata!)" : "")
    """
  }
}

// MARK: - Comparable

extension LogEntry: Comparable {
  public static func < (lhs: LogEntry, rhs: LogEntry) -> Bool {
    lhs.timestamp < rhs.timestamp
  }
}
