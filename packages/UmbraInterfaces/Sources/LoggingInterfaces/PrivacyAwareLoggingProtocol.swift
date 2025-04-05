import LoggingTypes

/// A protocol that provides privacy-aware logging capabilities.
/// This extends the standard LoggingProtocol with privacy controls, using LogContextDTO.
public protocol PrivacyAwareLoggingProtocol: LoggingProtocol {
  /// Log a message with explicit privacy controls using context
  /// - Parameters:
  ///   - level: The severity level of the log
  ///   - message: The message with privacy annotations (consider embedding in context)
  ///   - context: The logging context DTO containing metadata, source, and privacy info
  func log(
    _ level: LogLevel,
    _ message: PrivacyString,
    context: LogContextDTO
  ) async

  /// Log sensitive information with appropriate redaction using context
  /// - Parameters:
  ///   - level: The severity level of the log
  ///   - message: The basic message without sensitive content
  ///   - sensitiveValues: Sensitive values (consider embedding in context)
  ///   - context: The logging context DTO containing metadata, source, etc.
  func logSensitive(
    _ level: LogLevel,
    _ message: String,
    sensitiveValues: LoggingTypes.LogMetadata,
    context: LogContextDTO
  ) async

  /// Log an error with privacy controls using context
  /// - Parameters:
  ///   - error: The error to log
  ///   - privacyLevel: The privacy level to apply to the error details
  ///   - context: The logging context DTO containing metadata, source, etc.
  func logError(
    _ error: Error,
    privacyLevel: LogPrivacyLevel,
    context: LogContextDTO
  ) async
}

/// Default implementations for PrivacyAwareLoggingProtocol to reduce boilerplate
extension PrivacyAwareLoggingProtocol {
  /// Log sensitive information with a default info level
  /// - Parameters:
  ///   - message: The basic message without sensitive content
  ///   - sensitiveValues: Sensitive values that should be handled with privacy controls
  ///   - context: The logging context DTO containing metadata, source, etc.
  public func logSensitive(
    _ message: String,
    sensitiveValues: LoggingTypes.LogMetadata,
    context: LogContextDTO
  ) async {
    await logSensitive(.info, message, sensitiveValues: sensitiveValues, context: context)
  }

  /// Log an error with default error level and privacy controls
  /// - Parameters:
  ///   - error: The error to log
  ///   - context: The logging context DTO containing metadata, source, etc.
  public func logError(
    _ error: Error,
    context: LogContextDTO
  ) async {
    await logError(error, privacyLevel: .private, context: context)
  }
}
