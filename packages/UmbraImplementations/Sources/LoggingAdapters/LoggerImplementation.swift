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

  // MARK: - CoreLoggingProtocol Implementation
  
  /// Logs a message with the specified level and context
  /// - Parameters:
  ///   - level: The severity level of the log entry
  ///   - message: The message to log
  ///   - context: The logging context containing metadata and source information
  public func log(_ level: LogLevel, _ message: String, context: LogContextDTO) async {
    // Log locally
    await log(LoggingTypes.LogEntry(
      level: LoggingTypes.LogLevel(rawValue: level.rawValue) ?? .info,
      message: message,
      metadata: context.metadata.toPrivacyMetadata(),
      source: context.source,
      entryID: nil,
      timestamp: LogTimestamp.now()
    ))
    
    // Also log to the actor (actor expects proper underscore-prefixed parameters)
    await loggingActor.log(level, message, context: context)
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
    let context = LogContext(source: source, metadata: metadata)
    await loggingActor.log(.trace, message, context: context)
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
    let context = LogContext(source: source, metadata: metadata)
    await loggingActor.log(.debug, message, context: context)
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
    let context = LogContext(source: source, metadata: metadata)
    await loggingActor.log(.info, message, context: context)
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
    let context = LogContext(source: source, metadata: metadata)
    await loggingActor.log(.warning, message, context: context)
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
    let context = LogContext(source: source, metadata: metadata)
    await loggingActor.log(.error, message, context: context)
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
    let context = LogContext(source: source, metadata: metadata)
    await loggingActor.log(.critical, message, context: context)
  }

  public func log(
    level: LogLevel,
    message: PrivacyString,
    metadata: PrivacyMetadata?,
    source: String
  ) async {
    let stringMessage = message.processForLogging()
    let context = LogContext(source: source, metadata: metadata)
    
    await loggingActor.log(level: level, message: stringMessage, context: context)
    
    // Log locally if needed
    switch level {
    case .trace:
      await trace(stringMessage, metadata: metadata, source: source)
    case .debug:
      await debug(stringMessage, metadata: metadata, source: source)
    case .info:
      await info(stringMessage, metadata: metadata, source: source)
    case .warning:
      await warning(stringMessage, metadata: metadata, source: source)
    case .error:
      await error(stringMessage, metadata: metadata, source: source)
    case .critical:
      await critical(stringMessage, metadata: metadata, source: source)
    }
  }
}
