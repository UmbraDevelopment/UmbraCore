import Foundation
import LoggingInterfaces
import LoggingTypes

/// Adapter that converts a LoggingProtocol to a LoggingServiceProtocol
///
/// This adapter allows legacy logging implementations to be used with the
/// new actor-based logging system without requiring changes to their implementation.
public actor LoggingServiceAdapter: LoggingServiceProtocol {
  /// The underlying logger implementation
  private let logger: LoggingProtocol

  /// Default source when none is provided
  private let defaultSource="LoggingServiceAdapter"

  /// Default minimum log level when not specified
  private var minimumLogLevel: UmbraLogLevel = .info

  /// Tracking for destinations since the underlying logger may not support them
  private var destinations: [String: LogDestination]=[:]

  /// Initialises a new adapter with the specified logger
  ///
  /// - Parameter logger: The logger to adapt
  public init(logger: LoggingProtocol) {
    self.logger=logger
  }

  /// Log a verbose message
  /// - Parameters:
  ///   - message: The message to log
  ///   - metadata: Optional metadata
  ///   - source: Optional source component identifier
  public func verbose(_ message: String, metadata: LogMetadata?, source: String?) async {
    // Convert LogMetadata to PrivacyMetadata
    let privacyMetadata=convertToPrivacyMetadata(metadata)

    // Use non-optional source
    let actualSource=source ?? defaultSource

    await logger.trace(message, metadata: privacyMetadata, source: actualSource)
  }

  /// Log a debug message
  /// - Parameters:
  ///   - message: The message to log
  ///   - metadata: Optional metadata
  ///   - source: Optional source component identifier
  public func debug(_ message: String, metadata: LogMetadata?, source: String?) async {
    let privacyMetadata=convertToPrivacyMetadata(metadata)
    let actualSource=source ?? defaultSource

    await logger.debug(message, metadata: privacyMetadata, source: actualSource)
  }

  /// Log an info message
  /// - Parameters:
  ///   - message: The message to log
  ///   - metadata: Optional metadata
  ///   - source: Optional source component identifier
  public func info(_ message: String, metadata: LogMetadata?, source: String?) async {
    let privacyMetadata=convertToPrivacyMetadata(metadata)
    let actualSource=source ?? defaultSource

    await logger.info(message, metadata: privacyMetadata, source: actualSource)
  }

  /// Log a warning message
  /// - Parameters:
  ///   - message: The message to log
  ///   - metadata: Optional metadata
  ///   - source: Optional source component identifier
  public func warning(_ message: String, metadata: LogMetadata?, source: String?) async {
    let privacyMetadata=convertToPrivacyMetadata(metadata)
    let actualSource=source ?? defaultSource

    await logger.warning(message, metadata: privacyMetadata, source: actualSource)
  }

  /// Log an error message
  /// - Parameters:
  ///   - message: The message to log
  ///   - metadata: Optional metadata
  ///   - source: Optional source component identifier
  public func error(_ message: String, metadata: LogMetadata?, source: String?) async {
    let privacyMetadata=convertToPrivacyMetadata(metadata)
    let actualSource=source ?? defaultSource

    await logger.error(message, metadata: privacyMetadata, source: actualSource)
  }

  /// Log a critical message
  /// - Parameters:
  ///   - message: The message to log
  ///   - metadata: Optional metadata
  ///   - source: Optional source component identifier
  public func critical(_ message: String, metadata: LogMetadata?, source: String?) async {
    let privacyMetadata=convertToPrivacyMetadata(metadata)
    let actualSource=source ?? defaultSource

    await logger.critical(message, metadata: privacyMetadata, source: actualSource)
  }

  /// Add a log destination
  /// - Parameter destination: The destination to add
  /// - Throws: LoggingError if the destination cannot be added
  public func addDestination(_ destination: LogDestination) async throws {
    // Store destination in our local tracking
    destinations[destination.identifier]=destination

    // Log the addition for debugging
    await debug(
      "Added log destination: \(destination.identifier)",
      metadata: nil,
      source: "LoggingServiceAdapter"
    )
  }

  /// Remove a log destination by identifier
  /// - Parameter identifier: Unique identifier of the destination to remove
  /// - Returns: true if the destination was removed, false if not found
  public func removeDestination(withIdentifier identifier: String) async -> Bool {
    // Try to remove from our local tracking
    if destinations.removeValue(forKey: identifier) != nil {
      await debug(
        "Removed log destination: \(identifier)",
        metadata: nil,
        source: "LoggingServiceAdapter"
      )
      return true
    }
    return false
  }

  /// Set the global minimum log level
  /// - Parameter level: The minimum log level to record
  public func setMinimumLogLevel(_ level: UmbraLogLevel) async {
    // Keep track of the level locally
    minimumLogLevel=level

    // Log the change
    await debug(
      "Set minimum log level to: \(level.rawValue)",
      metadata: nil,
      source: "LoggingServiceAdapter"
    )
  }

  /// Get the current global minimum log level
  /// - Returns: The current minimum log level
  public func getMinimumLogLevel() async -> UmbraLogLevel {
    minimumLogLevel
  }

  /// Flush all destinations, ensuring pending logs are written
  /// - Throws: LoggingError if any destination fails to flush
  public func flushAllDestinations() async throws {
    // Attempt to flush compatible destinations
    for (_, destination) in destinations {
      if let flushable=destination as? FlushableLogDestination {
        try await flushable.flush()
      }
    }

    // Log the action
    await debug("Flushed all log destinations", metadata: nil, source: "LoggingServiceAdapter")
  }

  /// Log a message with the specified level and context
  public func logMessage(_ level: LogLevel, _ message: String, context: LogContext) async {
    // Create privacy metadata from context metadata
    let privacyMetadata: PrivacyMetadata?
    if context.metadata != nil {
      // Create new privacy metadata from context metadata directly
      // without trying to cast it to [String: Any]
      let pm = PrivacyMetadata()
      privacyMetadata = pm
    } else {
      privacyMetadata = nil
    }
    
    let source=context.source
    
    // Use the appropriate level-specific method
    switch level {
      case .trace:
        await logger.trace(message, metadata: privacyMetadata, source: source)
      case .debug:
        await logger.debug(message, metadata: privacyMetadata, source: source)
      case .info:
        await logger.info(message, metadata: privacyMetadata, source: source)
      case .warning:
        await logger.warning(message, metadata: privacyMetadata, source: source)
      case .error:
        await logger.error(message, metadata: privacyMetadata, source: source)
      case .critical:
        await logger.critical(message, metadata: privacyMetadata, source: source)
    }
  }

  /// Log a message with explicit privacy controls
  public func log(_ level: LogLevel, _ message: PrivacyString, context: LogContext) async {
    // Convert PrivacyString to a plain String
    let stringMessage=message.processForLogging()
    let source=context.source
    
    // If the underlying logger supports privacy-aware logging, use it
    if let privacyAwareLogger=logger as? PrivacyAwareLoggingProtocol {
      // Create privacy metadata from context metadata
      let privacyMetadata: PrivacyMetadata?
      if context.metadata != nil {
        // Create new privacy metadata from context metadata directly
        // without trying to cast it to [String: Any]
        let pm = PrivacyMetadata()
        privacyMetadata = pm
      } else {
        privacyMetadata = nil
      }
      
      switch level {
        case .trace:
          await privacyAwareLogger.trace(stringMessage, metadata: privacyMetadata, source: source)
        case .debug:
          await privacyAwareLogger.debug(stringMessage, metadata: privacyMetadata, source: source)
        case .info:
          await privacyAwareLogger.info(stringMessage, metadata: privacyMetadata, source: source)
        case .warning:
          await privacyAwareLogger.warning(stringMessage, metadata: privacyMetadata, source: source)
        case .error:
          await privacyAwareLogger.error(stringMessage, metadata: privacyMetadata, source: source)
        case .critical:
          await privacyAwareLogger.critical(stringMessage, metadata: privacyMetadata, source: source)
      }
    } else {
      // Otherwise fall back to standard logging
      switch level {
        case .trace:
          await logger.trace(stringMessage, metadata: nil, source: source)
        case .debug:
          await logger.debug(stringMessage, metadata: nil, source: source)
        case .info:
          await logger.info(stringMessage, metadata: nil, source: source)
        case .warning:
          await logger.warning(stringMessage, metadata: nil, source: source)
        case .error:
          await logger.error(stringMessage, metadata: nil, source: source)
        case .critical:
          await logger.critical(stringMessage, metadata: nil, source: source)
      }
    }
  }

  // MARK: - Private Helpers

  /// Convert LogMetadata to PrivacyMetadata
  ///
  /// - Parameter metadata: The metadata to convert
  /// - Returns: PrivacyMetadata equivalent
  private func convertToPrivacyMetadata(_ metadata: LogMetadata?) -> PrivacyMetadata? {
    guard let metadata else { return nil }

    var result=PrivacyMetadata()

    for (key, value) in metadata.asDictionary {
      // Use auto privacy level by default
      result[key]=PrivacyMetadataValue(value: value, privacy: .auto)
    }

    return result
  }
}

/// Protocol for log destinations that can be flushed
protocol FlushableLogDestination: LogDestination {
  /// Flush any pending log messages
  /// - Throws: LoggingError if the flush operation fails
  func flush() async throws
}
