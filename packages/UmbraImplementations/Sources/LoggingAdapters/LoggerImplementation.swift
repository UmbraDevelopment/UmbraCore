import LoggingInterfaces
import LoggingTypes
import LoggingWrapperInterfaces
import LoggingWrapperServices

/// A thread-safe logging service implementation that adapts
/// the LoggingInterfaces to LoggingWrapperServices
public actor LoggerImplementation: LoggingProtocol {
  /// The shared logger instance
  public static let shared=LoggerImplementation()

  /// Initialise the logger with default configuration
  public init() {
    // LoggingWrapper has its own internal configuration
    Logger.configure()
  }

  /// Initialise the logger with specific destinations
  /// - Parameter destinations: Array of log destinations
  private init(destinations _: [Any]) {
    // LoggingWrapper handles destinations internally
    Logger.configure()
  }

  /// Swift 6-compatible factory method to create a logger with specific destinations
  /// - Parameter destinations: Array of Sendable-compliant destinations
  /// - Returns: A new LoggerImplementation instance
  public static func withDestinations(_: [some Sendable]) -> LoggerImplementation {
    // Create a new logger instance with default configuration
    // LoggingWrapper doesn't expose destination configuration in the same way as SwiftyBeaver
    let logger=LoggerImplementation()

    // Configure the logger
    Logger.configure()

    return logger
  }

  /// Log a message at the specified level
  /// - Parameter entry: The log entry to record
  private func log(_ entry: LoggingTypes.LogEntry) {
    let logLevel=LoggingLevelAdapter.convertLevel(entry.level)

    if let metadata=entry.metadata {
      // If we have metadata, include it in the message
      Logger.log(logLevel, "\(entry.message) | Metadata: \(formatMetadata(metadata))")
    } else {
      Logger.log(logLevel, entry.message)
    }
  }

  /// Format metadata into a string representation
  /// - Parameter metadata: The metadata to format
  /// - Returns: A string representation of the metadata
  private func formatMetadata(_ metadata: LoggingTypes.LogMetadata) -> String {
    let dict=metadata.asDictionary
    if dict.isEmpty {
      return "{}"
    }

    let entries=dict.map { key, value in
      "\"\(key)\": \"\(value)\""
    }
    return "{ \(entries.joined(separator: ", ")) }"
  }

  // MARK: - LoggingProtocol Implementation

  /// Log a debug message
  /// - Parameters:
  ///   - message: The message to log
  ///   - metadata: Optional metadata
  public func debug(_ message: String, metadata: LoggingTypes.LogMetadata?) async {
    await log(LoggingTypes.LogEntry(level: .debug, message: message, metadata: metadata))
  }

  /// Log an info message
  /// - Parameters:
  ///   - message: The message to log
  ///   - metadata: Optional metadata
  public func info(_ message: String, metadata: LoggingTypes.LogMetadata?) async {
    await log(LoggingTypes.LogEntry(level: .info, message: message, metadata: metadata))
  }

  /// Log a warning message
  /// - Parameters:
  ///   - message: The message to log
  ///   - metadata: Optional metadata
  public func warning(_ message: String, metadata: LoggingTypes.LogMetadata?) async {
    await log(LoggingTypes.LogEntry(level: .warning, message: message, metadata: metadata))
  }

  /// Log an error message
  /// - Parameters:
  ///   - message: The message to log
  ///   - metadata: Optional metadata
  public func error(_ message: String, metadata: LoggingTypes.LogMetadata?) async {
    await log(LoggingTypes.LogEntry(level: .error, message: message, metadata: metadata))
  }
}
