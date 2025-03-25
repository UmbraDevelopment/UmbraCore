import Foundation

import UmbraErrorsCore

/// Domain identifier for logging errors
public enum LoggingErrorDomain: String, CaseIterable, Sendable {
  /// Domain identifier
  public static let domain="Logging"

  // Error codes within the logging domain
  case configurationError="CONFIGURATION_ERROR"
  case logWriteFailed="LOG_WRITE_FAILED"
  case logReadFailed="LOG_READ_FAILED"
  case logFormatError="LOG_FORMAT_ERROR"
  case logLevelError="LOG_LEVEL_ERROR"
  case logRotationError="LOG_ROTATION_ERROR"
  case logFileSizeExceeded="LOG_FILE_SIZE_EXCEEDED"
  case generalError="GENERAL_ERROR"
}

/// Enhanced implementation of a LoggingError
public struct LoggingError: UmbraError {
  /// Domain identifier
  public let domain: String=LoggingErrorDomain.domain

  /// The type of logging error
  public enum ErrorType: Sendable, Equatable {
    /// Configuration error
    case configuration
    /// Log write failure
    case logWrite
    /// Log read failure
    case logRead
    /// Log format error
    case logFormat
    /// Log level error
    case logLevel
    /// Log rotation error
    case logRotation
    /// Log file size exceeded
    case logFileSize
    /// General error
    case general
  }

  /// The specific error type
  public let type: ErrorType

  /// Error code used for serialisation and identification
  public let code: String

  /// Human-readable description of the error
  public let description: String

  /// Additional context information about the error
  public let context: ErrorContext

  /// The underlying error, if any
  public let underlyingError: Error?

  /// Source information about where the error occurred
  public let source: ErrorSource?

  /// Human-readable description of the error (UmbraError protocol requirement)
  public var errorDescription: String {
    if let details=context.typedValue(for: "details") as String?, !details.isEmpty {
      return "\(description): \(details)"
    }
    return description
  }

  /// Creates a formatted description of the error
  public var localizedDescription: String {
    if let details=context.typedValue(for: "details") as String?, !details.isEmpty {
      return "\(description): \(details)"
    }
    return description
  }

  /// Creates a new LoggingError
  /// - Parameters:
  ///   - type: The error type
  ///   - code: The error code
  ///   - description: Human-readable description
  ///   - context: Additional context information
  ///   - underlyingError: Optional underlying error
  ///   - source: Optional source information
  public init(
    type: ErrorType,
    code: String,
    description: String,
    context: ErrorContext=ErrorContext(),
    underlyingError: Error?=nil,
    source: ErrorSource?=nil
  ) {
    self.type=type
    self.code=code
    self.description=description
    self.context=context
    self.underlyingError=underlyingError
    self.source=source
  }

  /// Creates a new instance of the error with additional context
  public func with(context: ErrorContext) -> LoggingError {
    LoggingError(
      type: type,
      code: code,
      description: description,
      context: context,
      underlyingError: underlyingError,
      source: source
    )
  }

  /// Creates a new instance of the error with a specified underlying error
  public func with(underlyingError: Error) -> LoggingError {
    LoggingError(
      type: type,
      code: code,
      description: description,
      context: context,
      underlyingError: underlyingError,
      source: source
    )
  }

  /// Creates a new instance of the error with source information
  public func with(source: ErrorSource) -> LoggingError {
    LoggingError(
      type: type,
      code: code,
      description: description,
      context: context,
      underlyingError: underlyingError,
      source: source
    )
  }
}

/// Convenience functions for creating specific logging errors
extension LoggingError {
  /// Creates a configuration error
  /// - Parameters:
  ///   - issue: The specific configuration issue
  ///   - context: Additional context information
  ///   - underlyingError: Optional underlying error
  /// - Returns: A fully configured LoggingError
  public static func configurationError(
    issue: String,
    context: [String: Any]=[:],
    underlyingError: Error?=nil
  ) -> LoggingError {
    var contextDict=context
    contextDict["issue"]=issue
    contextDict["details"]="Configuration error: \(issue)"

    let errorContext=ErrorContext(contextDict)

    return LoggingError(
      type: .configuration,
      code: LoggingErrorDomain.configurationError.rawValue,
      description: "Logging configuration error",
      context: errorContext,
      underlyingError: underlyingError
    )
  }

  /// Creates a log write failure error
  /// - Parameters:
  ///   - logFile: The log file path
  ///   - reason: The reason the write failed
  ///   - context: Additional context information
  ///   - underlyingError: Optional underlying error
  /// - Returns: A fully configured LoggingError
  public static func logWriteFailed(
    logFile: String,
    reason: String,
    context: [String: Any]=[:],
    underlyingError: Error?=nil
  ) -> LoggingError {
    var contextDict=context
    contextDict["logFile"]=logFile
    contextDict["reason"]=reason
    contextDict["details"]="Failed to write to log file '\(logFile)': \(reason)"

    let errorContext=ErrorContext(contextDict)

    return LoggingError(
      type: .logWrite,
      code: LoggingErrorDomain.logWriteFailed.rawValue,
      description: "Log write failure",
      context: errorContext,
      underlyingError: underlyingError
    )
  }

  /// Creates a log read failure error
  /// - Parameters:
  ///   - logFile: The log file path
  ///   - reason: The reason the read failed
  ///   - context: Additional context information
  ///   - underlyingError: Optional underlying error
  /// - Returns: A fully configured LoggingError
  public static func logReadFailed(
    logFile: String,
    reason: String,
    context: [String: Any]=[:],
    underlyingError: Error?=nil
  ) -> LoggingError {
    var contextDict=context
    contextDict["logFile"]=logFile
    contextDict["reason"]=reason
    contextDict["details"]="Failed to read from log file '\(logFile)': \(reason)"

    let errorContext=ErrorContext(contextDict)

    return LoggingError(
      type: .logRead,
      code: LoggingErrorDomain.logReadFailed.rawValue,
      description: "Log read failure",
      context: errorContext,
      underlyingError: underlyingError
    )
  }

  /// Creates a general logging error
  /// - Parameters:
  ///   - message: A descriptive message about the error
  ///   - context: Additional context information
  ///   - underlyingError: Optional underlying error
  /// - Returns: A fully configured LoggingError
  public static func generalError(
    message: String,
    context: [String: Any]=[:],
    underlyingError: Error?=nil
  ) -> LoggingError {
    var contextDict=context
    contextDict["details"]=message

    let errorContext=ErrorContext(contextDict)

    return LoggingError(
      type: .general,
      code: LoggingErrorDomain.generalError.rawValue,
      description: "Logging error",
      context: errorContext,
      underlyingError: underlyingError
    )
  }
}
