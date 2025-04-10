import Foundation
import LoggingInterfaces
import LoggingTypes

/// Adapter that converts a LoggingProtocol to a LoggingServiceProtocol
///
/// This adapter allows modern privacy-aware logging implementations to be used with
/// the LoggingServiceProtocol interface.
public actor LoggingServiceAdapter: LoggingServiceProtocol {
  /// The underlying logger implementation
  private let logger: LoggingProtocol

  /// Default source when none is provided
  private let defaultSource="LoggingServiceAdapter"

  /// Default minimum log level when not specified
  private var minimumLogLevel: UmbraLogLevel = .info

  /// Tracking for destinations since the underlying logger may not support them
  private var destinations: [String: LogDestination]=[:]

  /// Initialise a new logging service adapter
  /// - Parameter logger: The logger to adapt
  public init(logger: LoggingProtocol) {
    self.logger=logger
  }

  /// Log a trace message
  /// - Parameters:
  ///   - message: The message to log
  ///   - metadata: Optional metadata with privacy annotations
  ///   - source: The source of the log message
  public func verbose(
    _ message: String,
    metadata: LogMetadataDTOCollection?,
    source: String?
  ) async {
    let actualSource=source ?? defaultSource

    // Create a LogContext object for context-based logging
    let context=BaseLogContextDTO(
      domainName: "LoggingService",
      source: actualSource,
      metadata: metadata ?? LogMetadataDTOCollection()
    )

    await logger.trace(message, context: context)
  }

  /// Log a debug message
  /// - Parameters:
  ///   - message: The message to log
  ///   - metadata: Optional metadata with privacy annotations
  ///   - source: The source of the log message
  public func debug(_ message: String, metadata: LogMetadataDTOCollection?, source: String?) async {
    let actualSource=source ?? defaultSource

    // Create a LogContext object for context-based logging
    let context=BaseLogContextDTO(
      domainName: "LoggingService",
      source: actualSource,
      metadata: metadata ?? LogMetadataDTOCollection()
    )

    await logger.debug(message, context: context)
  }

  /// Log an info message
  /// - Parameters:
  ///   - message: The message to log
  ///   - metadata: Optional metadata with privacy annotations
  ///   - source: The source of the log message
  public func info(_ message: String, metadata: LogMetadataDTOCollection?, source: String?) async {
    let actualSource=source ?? defaultSource

    // Create a LogContext object for context-based logging
    let context=BaseLogContextDTO(
      domainName: "LoggingService",
      source: actualSource,
      metadata: metadata ?? LogMetadataDTOCollection()
    )

    await logger.info(message, context: context)
  }

  /// Log a warning message
  /// - Parameters:
  ///   - message: The message to log
  ///   - metadata: Optional metadata with privacy annotations
  ///   - source: The source of the log message
  public func warning(
    _ message: String,
    metadata: LogMetadataDTOCollection?,
    source: String?
  ) async {
    let actualSource=source ?? defaultSource

    // Create a LogContext object for context-based logging
    let context=BaseLogContextDTO(
      domainName: "LoggingService",
      source: actualSource,
      metadata: metadata ?? LogMetadataDTOCollection()
    )

    await logger.warning(message, context: context)
  }

  /// Log an error message
  /// - Parameters:
  ///   - message: The message to log
  ///   - metadata: Optional metadata with privacy annotations
  ///   - source: The source of the log message
  public func error(_ message: String, metadata: LogMetadataDTOCollection?, source: String?) async {
    let actualSource=source ?? defaultSource

    // Create a LogContext object for context-based logging
    let context=BaseLogContextDTO(
      domainName: "LoggingService",
      source: actualSource,
      metadata: metadata ?? LogMetadataDTOCollection()
    )

    await logger.error(message, context: context)
  }

  /// Log a critical message
  /// - Parameters:
  ///   - message: The message to log
  ///   - metadata: Optional metadata with privacy annotations
  ///   - source: The source of the log message
  public func critical(
    _ message: String,
    metadata: LogMetadataDTOCollection?,
    source: String?
  ) async {
    let actualSource=source ?? defaultSource

    // Create a LogContext object for context-based logging
    let context=BaseLogContextDTO(
      domainName: "LoggingService",
      source: actualSource,
      metadata: metadata ?? LogMetadataDTOCollection()
    )

    await logger.critical(message, context: context)
  }

  /// Add a log destination
  /// - Parameter destination: The destination to add
  public func addDestination(_ destination: LoggingTypes.LogDestination) async throws {
    let id=LogIdentifier(value: UUID().uuidString).description
    destinations[id]=destination

    await info(
      "Added log destination: \(destination.identifier)",
      metadata: LogMetadataDTOCollection().withPublic(key: "id", value: id),
      source: defaultSource
    )
  }

  /// Remove a log destination
  /// - Parameter identifier: The identifier of the destination to remove
  /// - Returns: True if the destination was removed, false otherwise
  public func removeDestination(withIdentifier identifier: String) async -> Bool {
    // Try to remove from our tracking
    if destinations.removeValue(forKey: identifier) != nil {
      await debug(
        "Removed log destination: \(identifier)",
        metadata: nil,
        source: defaultSource
      )
      return true
    }

    return false
  }

  /// Set the minimum log level
  /// - Parameter level: The minimum log level
  public func setMinimumLogLevel(_ level: UmbraLogLevel) async {
    minimumLogLevel=level

    await debug(
      "Set minimum log level to \(level)",
      metadata: nil,
      source: defaultSource
    )
  }

  /// Get the minimum log level
  /// - Returns: The minimum log level
  public func getMinimumLogLevel() async -> UmbraLogLevel {
    minimumLogLevel
  }

  /// Flush all destinations
  /// - Throws: An error if flushing fails
  public func flushAllDestinations() async throws {
    for (id, destination) in destinations {
      if let flushable=destination as? FlushableLogDestination {
        do {
          try await flushable.flush()
          await debug(
            "Flushed log destination: \(destination.identifier)",
            metadata: LogMetadataDTOCollection().withPublic(key: "id", value: id),
            source: defaultSource
          )
        } catch {
          await self.error(
            "Failed to flush log destination: \(destination.identifier)",
            metadata: LogMetadataDTOCollection()
              .withPublic(key: "id", value: id)
              .withPrivate(key: "error", value: error.localizedDescription),
            source: defaultSource
          )
          throw error
        }
      }
    }
  }
}

/// Protocol for log destinations that can be flushed
protocol FlushableLogDestination: LogDestination {
  /// Flush any pending log messages
  func flush() async throws
}
