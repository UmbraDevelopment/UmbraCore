import Foundation
import LoggingInterfaces
import LoggingTypes

/**
 # Logging Adapter

 This adapter wraps a LoggingServiceProtocol instance and adapts it to the
 LoggingProtocol interface, compatible with the Alpha Dot Five architecture.

 It enables using logging services across module boundaries while maintaining
 type safety and privacy controls.
 */
public final class LoggingAdapter: LoggingProtocol, CoreLoggingProtocol {
  private let loggingService: LoggingServiceProtocol
  private let _loggingActor=LoggingActor(destinations: [], minimumLogLevel: .info)

  /// Get the underlying logging actor
  public var loggingActor: LoggingActor {
    _loggingActor
  }

  // Removed CustomMetadata typealias - directly use [String: String] instead

  /**
   Create a new logging adapter wrapping the given logging service.

   - Parameter loggingService: The logging service to wrap
   */
  public init(wrapping loggingService: LoggingServiceProtocol) {
    self.loggingService=loggingService
  }

  /// Required CoreLoggingProtocol implementation
  public func logMessage(_ level: LogLevel, _ message: String, context: LogContext) async {
    switch level {
      case .trace:
        // Forward to the debug level since we don't have trace
        await debug(
          message,
          metadata: extractLegacyMetadata(from: context.metadata),
          source: context.source
        )
      case .debug:
        await debug(
          message,
          metadata: extractLegacyMetadata(from: context.metadata),
          source: context.source
        )
      case .info:
        await info(
          message,
          metadata: extractLegacyMetadata(from: context.metadata),
          source: context.source
        )
      case .warning:
        await warning(
          message,
          metadata: extractLegacyMetadata(from: context.metadata),
          source: context.source
        )
      case .error:
        await error(
          message,
          metadata: extractLegacyMetadata(from: context.metadata),
          source: context.source
        )
      case .critical:
        await critical(
          message,
          metadata: extractLegacyMetadata(from: context.metadata),
          source: context.source
        )
    }
  }

  /// Extract legacy metadata format from privacy metadata
  private func extractLegacyMetadata(from privacyMetadata: PrivacyMetadata?) -> [String: String]? {
    guard let privacyMetadata, !privacyMetadata.isEmpty else {
      return nil
    }

    var result=[String: String]()
    for (key, value) in privacyMetadata.entriesDict() {
      result[key]=value.valueString
    }
    return result
  }

  /// Log a debug message
  public func debug(_ message: String, metadata: [String: String]?, source: String?) async {
    let context=buildLogContext(metadata: metadata, source: source)
    // Convert our custom metadata to nil if empty to match LoggingServiceProtocol expectations
    let systemMetadata: LoggingTypes.LogMetadata?=convertToSystemMetadata(metadata)
    await loggingService.debug(message, metadata: systemMetadata, source: source)
    await loggingActor.log(level: .debug, message: message, context: context)
  }

  /// Log an info message
  public func info(_ message: String, metadata: [String: String]?, source: String?) async {
    let context=buildLogContext(metadata: metadata, source: source)
    let systemMetadata: LoggingTypes.LogMetadata?=convertToSystemMetadata(metadata)
    await loggingService.info(message, metadata: systemMetadata, source: source)
    await loggingActor.log(level: .info, message: message, context: context)
  }

  /// Log a warning message
  public func warning(_ message: String, metadata: [String: String]?, source: String?) async {
    let context=buildLogContext(metadata: metadata, source: source)
    let systemMetadata: LoggingTypes.LogMetadata?=convertToSystemMetadata(metadata)
    await loggingService.warning(message, metadata: systemMetadata, source: source)
    await loggingActor.log(level: .warning, message: message, context: context)
  }

  /// Log an error message
  public func error(_ message: String, metadata: [String: String]?, source: String?) async {
    let context=buildLogContext(metadata: metadata, source: source)
    let systemMetadata: LoggingTypes.LogMetadata?=convertToSystemMetadata(metadata)
    await loggingService.error(message, metadata: systemMetadata, source: source)
    await loggingActor.log(level: .error, message: message, context: context)
  }

  /// Log a critical error message
  public func critical(_ message: String, metadata: [String: String]?, source: String?) async {
    let context=buildLogContext(metadata: metadata, source: source)
    let systemMetadata: LoggingTypes.LogMetadata?=convertToSystemMetadata(metadata)
    await loggingService.critical(message, metadata: systemMetadata, source: source)
    await loggingActor.log(level: .critical, message: message, context: context)
  }

  /// Convert our custom metadata to the system LogMetadata type
  private func convertToSystemMetadata(_ metadata: [String: String]?) -> LoggingTypes.LogMetadata? {
    guard let metadata, !metadata.isEmpty else {
      return nil
    }

    var result=LoggingTypes.LogMetadata()
    for (key, value) in metadata {
      result[key]=value
    }
    return result
  }

  /// Build a log context for logging
  private func buildLogContext(metadata: [String: String]?, source: String?) -> LogContext {
    let sourceValue=source ?? "KeychainServices"
    let timestamp=LogTimestamp(secondsSinceEpoch: Date().timeIntervalSince1970)
    let privacyMetadata=createPrivacyMetadata(from: metadata)
    return LogContext(source: sourceValue, metadata: privacyMetadata, timestamp: timestamp)
  }

  /// Create privacy metadata from legacy metadata
  private func createPrivacyMetadata(from metadata: [String: String]?) -> PrivacyMetadata? {
    guard let metadata, !metadata.isEmpty else {
      return nil
    }

    var result=PrivacyMetadata()
    for (key, value) in metadata {
      // In KeychainServices, we treat all metadata as private by default
      result[key]=PrivacyMetadataValue(value: value, privacy: .private)
    }
    return result
  }
}
