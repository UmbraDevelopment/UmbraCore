import Foundation
import LoggingInterfaces
import LoggingTypes

/// A file-based log destination that writes log entries to a file
/// Implementation is thread-safe via the actor model
public actor FileLogDestination: ActorLogDestination {
  /// Unique identifier for this destination
  public let identifier: String

  /// The minimum log level this destination will process
  public let minimumLogLevel: LogLevel?

  /// The URL of the file to write to
  private let fileURL: URL

  /// Whether to include timestamps in log output
  private let includeTimestamp: Bool

  /// Whether to include the log source in output
  private let includeSource: Bool

  /// Whether to include metadata in output
  private let includeMetadata: Bool

  /// File handle for writing to the log file
  private var fileHandle: FileHandle?

  /// Initialise a new file log destination
  /// - Parameters:
  ///   - fileURL: The URL of the file to write to
  ///   - identifier: Unique identifier for this destination
  ///   - minimumLogLevel: Optional minimum log level to process
  ///   - includeTimestamp: Whether to include timestamps in log output
  ///   - includeSource: Whether to include the log source in output
  ///   - includeMetadata: Whether to include metadata in output
  public init(
    fileURL: URL,
    identifier: String="file",
    minimumLogLevel: LogLevel?=nil,
    includeTimestamp: Bool=true,
    includeSource: Bool=true,
    includeMetadata: Bool=true
  ) {
    self.fileURL=fileURL
    self.identifier=identifier
    self.minimumLogLevel=minimumLogLevel
    self.includeTimestamp=includeTimestamp
    self.includeSource=includeSource
    self.includeMetadata=includeMetadata

    // We'll initialise the file in the first write operation
  }

  /// Clean up resources when the actor is deallocated
  deinit {
    // Using weak self to avoid capture of self in a closure that outlives deinit
    Task { [weak self] in
      await self?.closeFile()
    }
  }

  /// Write a log entry to the file
  /// - Parameter entry: The log entry to write
  public func write(_ entry: LogEntry) async {
    // Ensure the file is initialised
    if fileHandle == nil {
      await initialiseFile()
    }

    // Format the entry and write it to the file
    let formattedEntry=formatEntry(entry) + "\n"

    guard
      let data=formattedEntry.data(using: .utf8),
      let fileHandle
    else {
      print("Error: Failed to write log entry to file")
      return
    }

    do {
      try fileHandle.write(contentsOf: data)
    } catch {
      print("Error writing to log file: \(error.localizedDescription)")
    }
  }

  /// Initialise the log file
  private func initialiseFile() async {
    do {
      // Create the file if it doesn't exist
      if !FileManager.default.fileExists(atPath: fileURL.path) {
        FileManager.default.createFile(atPath: fileURL.path, contents: nil)
      }

      // Open the file for writing
      let fileHandle=try FileHandle(forWritingTo: fileURL)

      // Seek to the end of the file
      try fileHandle.seekToEnd()

      self.fileHandle=fileHandle
    } catch {
      print("Error initialising log file: \(error.localizedDescription)")
    }
  }

  /// Close the log file
  private func closeFile() async {
    guard let fileHandle else { return }

    do {
      try fileHandle.close()
      self.fileHandle=nil
    } catch {
      print("Error closing log file: \(error.localizedDescription)")
    }
  }

  /// Format a log entry as a string for file output
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

  /// Format a timestamp for file output
  /// - Parameter timestamp: The timestamp to format
  /// - Returns: A formatted timestamp string
  private func formatTimestamp(_ timestamp: LogTimestamp) -> String {
    let formatter=DateFormatter()
    formatter.dateFormat="yyyy-MM-dd HH:mm:ss.SSS"
    let date=Date(timeIntervalSince1970: timestamp.secondsSinceEpoch)
    return formatter.string(from: date)
  }

  /// Format metadata for file output
  /// - Parameter metadata: The metadata to format
  /// - Returns: A formatted metadata string
  private func formatMetadata(_ metadata: LogMetadataDTOCollection) -> String {
    let pairs = metadata.entries.map { entry in
      "\(entry.key): \(entry.value)"
    }
    return "{" + pairs.joined(separator: ", ") + "}"
  }
}
