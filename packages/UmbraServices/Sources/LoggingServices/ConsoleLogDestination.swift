import Foundation
import LoggingInterfaces
import LoggingTypes

/// A console-based log destination that writes log entries to standard output
/// Implementation is thread-safe via the actor model
public actor ConsoleLogDestination: ActorLogDestination {
  /// Unique identifier for this destination
  public let identifier: String

  /// The minimum log level this destination will process
  public let minimumLogLevel: LogLevel?

  /// Whether to include timestamps in log output
  private let includeTimestamp: Bool

  /// Whether to include the log source in output
  private let includeSource: Bool

  /// Whether to include metadata in output
  private let includeMetadata: Bool

  /// Initialise a new console log destination
  /// - Parameters:
  ///   - identifier: Unique identifier for this destination
  ///   - minimumLogLevel: Optional minimum log level to process
  ///   - includeTimestamp: Whether to include timestamps in log output
  ///   - includeSource: Whether to include the log source in output
  ///   - includeMetadata: Whether to include metadata in output
  public init(
    identifier: String="console",
    minimumLogLevel: LogLevel?=nil,
    includeTimestamp: Bool=true,
    includeSource: Bool=true,
    includeMetadata: Bool=true
  ) {
    self.identifier=identifier
    self.minimumLogLevel=minimumLogLevel
    self.includeTimestamp=includeTimestamp
    self.includeSource=includeSource
    self.includeMetadata=includeMetadata
  }

  /// Write a log entry to the console
  /// - Parameter entry: The log entry to write
  public func write(_ entry: LogEntry) async {
    // Since this method runs on the actor, it's already thread-safe
    print(formatEntry(entry))
  }

  /// Format a log entry as a string for console output
  /// - Parameter entry: The log entry to format
  /// - Returns: A formatted string representation of the log entry
  private func formatEntry(_ entry: LogEntry) -> String {
    var components: [String]=[]

    // Add log level
    components.append("[\(entry.level.rawValue.uppercased())]")

    // Add timestamp if enabled
    if includeTimestamp {
      components.append("[\(formatTimestamp(entry.timestamp))]")
    }

    // Add source if enabled
    if includeSource && !entry.source.isEmpty {
      components.append("[\(entry.source)]")
    }

    // Add message
    components.append(entry.message)

    // Add metadata if enabled and present
    if includeMetadata, let metadata=entry.metadata, !metadata.isEmpty {
      components.append("- Metadata: \(formatMetadata(metadata))")
    }

    return components.joined(separator: " ")
  }

  /// Format a timestamp for console output
  /// - Parameter timestamp: The timestamp to format
  /// - Returns: A formatted timestamp string
  private func formatTimestamp(_ timestamp: LogTimestamp) -> String {
    let formatter=DateFormatter()
    formatter.dateFormat="yyyy-MM-dd HH:mm:ss.SSS"
    let date=Date(timeIntervalSince1970: timestamp.secondsSinceEpoch)
    return formatter.string(from: date)
  }

  /// Format metadata for console output
  /// - Parameter metadata: The metadata to format
  /// - Returns: A formatted metadata string
  private func formatMetadata(_ metadata: LogMetadataDTOCollection) -> String {
    let pairs = metadata.entries.map { entry in
      "\(entry.key): \(entry.value)"
    }
    return "{" + pairs.joined(separator: ", ") + "}"
  }
}
