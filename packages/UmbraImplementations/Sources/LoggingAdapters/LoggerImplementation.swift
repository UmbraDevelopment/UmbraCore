import LoggingInterfaces
import LoggingTypes
import LoggingWrapperInterfaces
import LoggingWrapperServices

/**
 # LoggerImplementation

 A thread-safe logging service implementation that adapts the LoggingInterfaces
 to LoggingWrapperServices following the Alpha Dot Five architecture.

 This implementation provides:
 - Actor-based concurrency for thread safety
 - Privacy-aware logging with proper metadata handling
 - Async/await API integration
 */
@preconcurrency
public actor LoggerImplementation: LoggingProtocol, CoreLoggingProtocol {
  /// The shared logger instance
  public static let shared=LoggerImplementation()

  /// The underlying logging actor for isolated access
  private let _internalLoggingActor=LoggingInterfaces.LoggingActor(destinations: [])

  /// The underlying logging actor (nonisolated for protocol conformance)
  public nonisolated var loggingActor: LoggingInterfaces.LoggingActor {
    // Return the internal logging actor for nonisolated access
    _internalLoggingActor
  }

  /// Initialise the logger with default configuration
  public init() {
    // LoggingWrapper has its own internal configuration
    Logger.configure(LoggingWrapperInterfaces.LoggerConfiguration.standard)
  }

  /// Swift 6-compatible factory method to create a logger with specific destinations
  /// - Parameter destinations: Array of Sendable-compliant destinations
  /// - Returns: A new LoggerImplementation instance
  public static func withDestinations(_: [some Sendable]) -> LoggerImplementation {
    // Create a new logger instance
    let logger=LoggerImplementation()

    // Configure the logger
    Logger.configure(LoggingWrapperInterfaces.LoggerConfiguration.standard)

    return logger
  }

  /// Log a message at the specified level
  /// - Parameter entry: The log entry to record
  private func log(_ entry: LoggingTypes.LogEntry) {
    // Convert LoggingTypes.LogLevel to UmbraLogLevel for the adapter
    let umbraLevel=convertToUmbraLevel(entry.level)
    let logLevel=LoggingLevelAdapter.convertLevel(umbraLevel)

    if let metadata=entry.metadata {
      // If we have metadata, include it in the message
      let sourceInfo = !entry.source.isEmpty ? " | Source: \(entry.source)" : ""
      let metadataInfo=" | Metadata: \(formatMetadata(metadata))"
      Logger.log(logLevel, "\(entry.message)\(sourceInfo)\(metadataInfo)")
    } else {
      // Simple log without metadata
      let sourceInfo = !entry.source.isEmpty ? " | Source: \(entry.source)" : ""
      Logger.log(logLevel, "\(entry.message)\(sourceInfo)")
    }
  }

  /// Converts LoggingTypes.LogLevel to UmbraLogLevel
  /// - Parameter level: The LogLevel to convert
  /// - Returns: The equivalent UmbraLogLevel
  private func convertToUmbraLevel(_ level: LoggingTypes.LogLevel) -> UmbraLogLevel {
    switch level {
      case .trace:
        .verbose
      case .debug:
        .debug
      case .info:
        .info
      case .warning:
        .warning
      case .error:
        .error
      case .critical:
        .critical
    }
  }

  /// Format metadata for logging
  /// - Parameter metadata: The metadata to format
  /// - Returns: A formatted string representation of the metadata
  private func formatMetadata(_ metadata: LoggingTypes.PrivacyMetadata?) -> String {
    guard let metadata else { return "{}" }

    // Format the keys and values from the metadata entries
    let entries=metadata.entries().map { key in
      if let value=metadata[key] {
        "\(key)=\(String(describing: value))"
      } else {
        "\(key)=nil"
      }
    }

    if entries.isEmpty {
      return "{}"
    }

    // Return formatted string
    return "{ \(entries.joined(separator: ", ")) }"
  }

  // MARK: - LoggingProtocol Implementation

  public func trace(
    _ message: String,
    metadata: PrivacyMetadata?,
    source: String
  ) async {
    // Log locally
    await log(LoggingTypes.LogEntry(
      level: LoggingTypes.LogLevel.trace,
      message: message,
      metadata: metadata,
      source: source,
      entryID: nil,
      timestamp: LogTimestamp.now()
    ))

    // Also log to the actor
    let context=LogContext(source: source)
    await loggingActor.log(level: .trace, message: message, context: context)
  }

  public func debug(
    _ message: String,
    metadata: PrivacyMetadata?,
    source: String
  ) async {
    // Log locally
    await log(LoggingTypes.LogEntry(
      level: LoggingTypes.LogLevel.debug,
      message: message,
      metadata: metadata,
      source: source,
      entryID: nil,
      timestamp: LogTimestamp.now()
    ))

    // Also log to the actor
    let context=LogContext(source: source)
    await loggingActor.log(level: .debug, message: message, context: context)
  }

  public func info(
    _ message: String,
    metadata: PrivacyMetadata?,
    source: String
  ) async {
    // Log locally
    await log(LoggingTypes.LogEntry(
      level: LoggingTypes.LogLevel.info,
      message: message,
      metadata: metadata,
      source: source,
      entryID: nil,
      timestamp: LogTimestamp.now()
    ))

    // Also log to the actor
    let context=LogContext(source: source)
    await loggingActor.log(level: .info, message: message, context: context)
  }

  public func warning(
    _ message: String,
    metadata: PrivacyMetadata?,
    source: String
  ) async {
    // Log locally
    await log(LoggingTypes.LogEntry(
      level: LoggingTypes.LogLevel.warning,
      message: message,
      metadata: metadata,
      source: source,
      entryID: nil,
      timestamp: LogTimestamp.now()
    ))

    // Also log to the actor
    let context=LogContext(source: source)
    await loggingActor.log(level: .warning, message: message, context: context)
  }

  public func error(
    _ message: String,
    metadata: PrivacyMetadata?,
    source: String
  ) async {
    // Log locally
    await log(LoggingTypes.LogEntry(
      level: LoggingTypes.LogLevel.error,
      message: message,
      metadata: metadata,
      source: source,
      entryID: nil,
      timestamp: LogTimestamp.now()
    ))

    // Also log to the actor
    let context=LogContext(source: source)
    await loggingActor.log(level: .error, message: message, context: context)
  }

  public func critical(
    _ message: String,
    metadata: PrivacyMetadata?,
    source: String
  ) async {
    // Log locally
    await log(LoggingTypes.LogEntry(
      level: LoggingTypes.LogLevel.critical,
      message: message,
      metadata: metadata,
      source: source,
      entryID: nil,
      timestamp: LogTimestamp.now()
    ))

    // Also log to the actor
    let context=LogContext(source: source)
    await loggingActor.log(level: .critical, message: message, context: context)
  }

  /// Log a message with the specified log level and context
  /// - Parameters:
  ///   - level: The level to log at
  ///   - message: The message to log
  ///   - context: The context information for the log
  public func logMessage(
    _ level: LoggingTypes.LogLevel,
    _ message: String,
    context: LogContext
  ) async {
    // Log locally
    await log(LoggingTypes.LogEntry(
      level: level,
      message: message,
      metadata: nil,
      source: context.source,
      entryID: nil,
      timestamp: LogTimestamp.now()
    ))

    // Also log to the actor
    await loggingActor.log(level: level, message: message, context: context)
  }
}
