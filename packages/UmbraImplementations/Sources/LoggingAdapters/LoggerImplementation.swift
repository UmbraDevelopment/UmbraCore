import LoggingInterfaces
import LoggingTypes
import LoggingWrapperInterfaces
import LoggingWrapperServices

/// A thread-safe logging service implementation that adapts
/// the LoggingInterfaces to LoggingWrapperServices
public actor LoggerImplementation: LoggingProtocol, CoreLoggingProtocol {
  /// The shared logger instance
  public static let shared=LoggerImplementation()
  
  /// The underlying logging actor
  public var loggingActor: LoggingActor {
    self
  }

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
      let sourceInfo=entry.source != nil ? " | Source: \(entry.source!)" : ""
      Logger.log(logLevel, "\(entry.message)\(sourceInfo) | Metadata: \(formatMetadata(metadata))")
    } else {
      let sourceInfo=entry.source != nil ? " | Source: \(entry.source!)" : ""
      Logger.log(logLevel, "\(entry.message)\(sourceInfo)")
    }
  }

  /// Format metadata into a string representation
  /// - Parameter metadata: The metadata to format
  /// - Returns: A string representation of the metadata
  private func formatMetadata(_ metadata: LoggingTypes.PrivacyMetadata) -> String {
    let dict = metadata.entries().reduce(into: [String: String]()) { result, key in
        if let value = metadata[key] {
            result[key] = String(describing: value)
        }
    }
    
    if dict.isEmpty {
      return "{}"
    }

    let entries=dict.map { key, value in
      "\"\(key)\": \"\(value)\""
    }
    return "{ \(entries.joined(separator: ", ")) }"
  }
  
  /// Log a message with the specified level and context
  /// - Parameters:
  ///   - level: The severity level of the log
  ///   - message: The message to log
  ///   - context: The context information for the log
  public func logMessage(_ level: LogLevel, _ message: String, context: LogContext) async {
    await log(LoggingTypes.LogEntry(
      timestamp: LogTimestamp.now(),
      level: level,
      message: message,
      metadata: context.metadata,
      source: context.source,
      entryID: nil
    ))
  }

  // MARK: - LoggingProtocol Implementation
  
  /// Log a trace message
  /// - Parameters:
  ///   - message: The message to log
  ///   - metadata: Optional metadata
  ///   - source: Source component identifier
  public func trace(_ message: String, metadata: LoggingTypes.PrivacyMetadata?, source: String) async {
    await log(LoggingTypes.LogEntry(
      timestamp: LogTimestamp.now(),
      level: .trace,
      message: message,
      metadata: metadata,
      source: source,
      entryID: nil
    ))
  }

  /// Log a debug message
  /// - Parameters:
  ///   - message: The message to log
  ///   - metadata: Optional metadata
  ///   - source: Optional source component identifier
  public func debug(_ message: String, metadata: LoggingTypes.PrivacyMetadata?, source: String) async {
    await log(LoggingTypes.LogEntry(
      timestamp: LogTimestamp.now(),
      level: .debug,
      message: message,
      metadata: metadata,
      source: source,
      entryID: nil
    ))
  }

  /// Log an info message
  /// - Parameters:
  ///   - message: The message to log
  ///   - metadata: Optional metadata
  ///   - source: Optional source component identifier
  public func info(_ message: String, metadata: LoggingTypes.PrivacyMetadata?, source: String) async {
    await log(LoggingTypes.LogEntry(
      timestamp: LogTimestamp.now(),
      level: .info,
      message: message,
      metadata: metadata,
      source: source,
      entryID: nil
    ))
  }

  /// Log a warning message
  /// - Parameters:
  ///   - message: The message to log
  ///   - metadata: Optional metadata
  ///   - source: Optional source component identifier
  public func warning(
    _ message: String,
    metadata: LoggingTypes.PrivacyMetadata?,
    source: String
  ) async {
    await log(LoggingTypes.LogEntry(
      timestamp: LogTimestamp.now(),
      level: .warning,
      message: message,
      metadata: metadata,
      source: source,
      entryID: nil
    ))
  }

  /// Log an error message
  /// - Parameters:
  ///   - message: The message to log
  ///   - metadata: Optional metadata
  ///   - source: Optional source component identifier
  public func error(_ message: String, metadata: LoggingTypes.PrivacyMetadata?, source: String) async {
    await log(LoggingTypes.LogEntry(
      timestamp: LogTimestamp.now(),
      level: .error,
      message: message,
      metadata: metadata,
      source: source,
      entryID: nil
    ))
  }
  
  /// Log a critical message
  /// - Parameters:
  ///   - message: The message to log
  ///   - metadata: Optional metadata
  ///   - source: Source component identifier
  public func critical(_ message: String, metadata: LoggingTypes.PrivacyMetadata?, source: String) async {
    await log(LoggingTypes.LogEntry(
      timestamp: LogTimestamp.now(),
      level: .critical,
      message: message,
      metadata: metadata,
      source: source,
      entryID: nil
    ))
  }
}
