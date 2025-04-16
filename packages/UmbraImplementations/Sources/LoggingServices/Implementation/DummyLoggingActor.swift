import Foundation
import LoggingInterfaces
import LoggingTypes

/// Implementation of a logging actor for bootstrap purposes
/// Provides a minimal implementation to satisfy protocol requirements
public actor DummyLoggingActor: PrivacyAwareLoggingProtocol, LoggingProtocol {
  /// The logging actor used by this logger
  public nonisolated var loggingActor: LoggingActor {
    LoggingActor(destinations: [])
  }

  /// The minimum log level for this actor
  private var minimumLogLevel: LogLevel = .info

  /// Create a new dummy logging actor
  public init() {}

  /// Log a message with the given level
  public func log(_ level: LogLevel, _ message: String, context _: LogContextDTO) async {
    // Only print messages at or above the minimum level
    if level.rawValue >= minimumLogLevel.rawValue {
      print("[\(level.rawValue.uppercased())] \(message)")
    }
  }

  /// Log an error
  public func logError(
    _ error: Error,
    privacyLevel _: LogPrivacyLevel,
    context: LogContextDTO
  ) async {
    await log(.error, "Error: \(error.localizedDescription)", context: context)
  }

  /// Log a message with privacy annotations
  public func log(_ level: LogLevel, _ message: PrivacyString, context: LogContextDTO) async {
    // For dummy implementation, just log the raw value
    await log(level, message.content, context: context)
  }

  /// Log sensitive information with appropriate privacy controls
  public func logSensitive(
    _: LogLevel,
    _: String,
    sensitiveValues _: LoggingTypes.LogMetadata,
    context _: LogContextDTO
  ) async {
    // No-op implementation for bootstrap purposes
  }

  /// Log a string directly
  public func logString(_ level: LogLevel, _ message: String, context: LogContextDTO) async {
    await log(level, message, context: context)
  }
}
