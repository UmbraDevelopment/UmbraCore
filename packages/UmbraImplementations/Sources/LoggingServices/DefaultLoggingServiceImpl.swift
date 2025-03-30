import LoggingInterfaces
import LoggingTypes

/// Default implementation of the LoggingProtocol
///
/// This implementation provides a basic logging service that can be used
/// throughout the application. It follows the Alpha Dot Five architecture
/// pattern of having concrete implementations separate from interfaces.
public final class DefaultLoggingServiceImpl: LoggingProtocol {

  /// Initialises a new DefaultLoggingServiceImpl
  public init() {
    // Implementation-specific initialisation can be added here
  }

  /// Log a debug message
  /// - Parameters:
  ///   - message: The message to log
  ///   - metadata: Optional metadata
  ///   - source: Optional source component identifier
  public func debug(_ message: String, metadata: LoggingTypes.LogMetadata?, source: String?) async {
    await log(
      level: LoggingTypes.UmbraLogLevel.debug,
      message: message,
      metadata: metadata,
      source: source
    )
  }

  /// Log an info message
  /// - Parameters:
  ///   - message: The message to log
  ///   - metadata: Optional metadata
  ///   - source: Optional source component identifier
  public func info(_ message: String, metadata: LoggingTypes.LogMetadata?, source: String?) async {
    await log(
      level: LoggingTypes.UmbraLogLevel.info,
      message: message,
      metadata: metadata,
      source: source
    )
  }

  /// Log a warning message
  /// - Parameters:
  ///   - message: The message to log
  ///   - metadata: Optional metadata
  ///   - source: Optional source component identifier
  public func warning(
    _ message: String,
    metadata: LoggingTypes.LogMetadata?,
    source: String?
  ) async {
    await log(
      level: LoggingTypes.UmbraLogLevel.warning,
      message: message,
      metadata: metadata,
      source: source
    )
  }

  /// Log an error message
  /// - Parameters:
  ///   - message: The message to log
  ///   - metadata: Optional metadata
  ///   - source: Optional source component identifier
  public func error(_ message: String, metadata: LoggingTypes.LogMetadata?, source: String?) async {
    await log(
      level: LoggingTypes.UmbraLogLevel.error,
      message: message,
      metadata: metadata,
      source: source
    )
  }

  // MARK: - Private Methods

  /// Internal logging implementation
  /// - Parameters:
  ///   - level: Log level
  ///   - message: Message to log
  ///   - metadata: Optional metadata
  ///   - source: Optional source component identifier
  private func log(
    level: LoggingTypes.UmbraLogLevel,
    message: String,
    metadata: LoggingTypes.LogMetadata?,
    source: String?
  ) async {
    // Implementation would typically forward to a logger or console
    // This is a simplified implementation

    // Convert metadata to the format expected by LogEntry
    let typedMetadata=metadata

    // Create the log entry - not used in this implementation but would be in a real one
    _=LoggingTypes.LogEntry(level: level, message: message, metadata: typedMetadata, source: source)

    // In a real implementation, this would:
    // 1. Write to console
    // 2. Save to file
    // 3. Send to network service, etc.

    // For now, just print to the console
    print("[\(level)] \(message)")

    if let metadata=typedMetadata, !metadata.asDictionary.isEmpty {
      print("  Metadata: \(metadata.asDictionary)")
    }

    if let source {
      print("  Source: \(source)")
    }
  }
}
