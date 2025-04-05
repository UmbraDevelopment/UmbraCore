import LoggingTypes

/// A protocol that provides privacy-aware logging capabilities.
/// This extends the standard LoggingProtocol with privacy controls.
public protocol PrivacyAwareLoggingProtocol: LoggingProtocol {
  /// Log a message with explicit privacy controls
  /// - Parameters:
  ///   - level: The severity level of the log
  ///   - message: The message with privacy annotations
  ///   - metadata: Additional structured data with privacy annotations
  ///   - source: The component that generated the log
  func log(
    _ level: LogLevel,
    _ message: PrivacyString,
    metadata: PrivacyMetadata?,
    source: String
  ) async

  /// Log sensitive information with appropriate redaction
  /// - Parameters:
  ///   - level: The severity level of the log
  ///   - message: The basic message without sensitive content
  ///   - sensitiveValues: Sensitive values that should be handled with privacy controls
  ///   - source: The component that generated the log
  func logSensitive(
    _ level: LogLevel,
    _ message: String,
    sensitiveValues: LoggingTypes.LogMetadata,
    source: String
  ) async

  /// Log an error with privacy controls
  /// - Parameters:
  ///   - error: The error to log
  ///   - privacyLevel: The privacy level to apply to the error details
  ///   - metadata: Additional structured data with privacy annotations
  ///   - source: The component that generated the log
  func logError(
    _ error: Error,
    privacyLevel: LogPrivacyLevel,
    metadata: PrivacyMetadata?,
    source: String
  ) async
}

/// Default implementations for PrivacyAwareLoggingProtocol to reduce boilerplate
extension PrivacyAwareLoggingProtocol {
  /// Log sensitive information with a default info level
  /// - Parameters:
  ///   - message: The basic message without sensitive content
  ///   - sensitiveValues: Sensitive values that should be handled with privacy controls
  ///   - source: The component that generated the log
  public func logSensitive(
    _ message: String,
    sensitiveValues: LoggingTypes.LogMetadata,
    source: String
  ) async {
    await logSensitive(.info, message, sensitiveValues: sensitiveValues, source: source)
  }

  /// Log an error with default error level and privacy controls
  /// - Parameters:
  ///   - error: The error to log
  ///   - source: The component that generated the log
  public func logError(
    _ error: Error,
    source: String
  ) async {
    await logError(error, privacyLevel: .private, metadata: nil, source: source)
  }
}
