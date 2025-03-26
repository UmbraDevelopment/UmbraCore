import Foundation
import Interfaces
import UmbraErrorsCore
import UmbraLogging

// MARK: - Logging Adapter

/// A logging adapter that conforms to LoggingProtocol
public final class LoggingWrapperAdapter: LoggingProtocol, Sendable {
  public init() {}

  public func error(_ message: String, metadata: LogMetadata?) async {
    // Convert metadata to a string format that Logger can accept
    let metadataStr=metadata != nil ? " \(metadata!.asDictionary)" : ""
    Logger.error("\(message)\(metadataStr)", file: #file, function: #function, line: #line)
  }

  public func warning(_ message: String, metadata: LogMetadata?) async {
    // Convert metadata to a string format that Logger can accept
    let metadataStr=metadata != nil ? " \(metadata!.asDictionary)" : ""
    Logger.warning("\(message)\(metadataStr)", file: #file, function: #function, line: #line)
  }

  public func info(_ message: String, metadata: LogMetadata?) async {
    // Convert metadata to a string format that Logger can accept
    let metadataStr=metadata != nil ? " \(metadata!.asDictionary)" : ""
    Logger.info("\(message)\(metadataStr)", file: #file, function: #function, line: #line)
  }

  public func debug(_ message: String, metadata: LogMetadata?) async {
    // Convert metadata to a string format that Logger can accept
    let metadataStr=metadata != nil ? " \(metadata!.asDictionary)" : ""
    Logger.debug("\(message)\(metadataStr)", file: #file, function: #function, line: #line)
  }

  // Add critical method for completeness
  public func critical(_ message: String, metadata: LogMetadata?) async {
    // Convert metadata to a string format that Logger can accept
    let metadataStr=metadata != nil ? " \(metadata!.asDictionary)" : ""
    Logger.error(
      "[CRITICAL] \(message)\(metadataStr)",
      file: #file,
      function: #function,
      line: #line
    )
  }
}

// MARK: - Error Logger

/// Main error logger class that manages logging errors with appropriate context
@MainActor
public class ErrorLogger {
  /// The shared instance
  public static let shared=ErrorLogger()

  /// The underlying logger
  private let logger: LoggingProtocol

  /// Configuration for the error logger
  private let configuration: ErrorLoggerConfiguration

  /// Initialises with the default logger and configuration
  public init(
    logger: LoggingProtocol=LoggingWrapperAdapter(),
    configuration: ErrorLoggerConfiguration=ErrorLoggerConfiguration()
  ) {
    self.logger=logger
    self.configuration=configuration
  }

  /// Log an error with a specific severity level
  /// - Parameters:
  ///   - error: The error to log
  ///   - severity: The severity level of the error
  ///   - additionalContext: Additional context to include in the log
  public func log(
    _ error: Error,
    severity: UmbraErrorsCore.ErrorSeverity,
    additionalContext: [String: Any]?=nil
  ) async {
    // Skip if severity is below minimum level
    guard severity >= configuration.minimumSeverity else {
      return
    }

    // Create error message
    let message=formatErrorMessage(error)

    // Create metadata from error and add additional context
    var metadata=createMetadataFromError(error)
    if let additionalContext {
      for (key, value) in additionalContext {
        metadata[key]=LogMetadata.string("\(value)")
      }
    }

    // Log using the direct severity-to-log-level mapping
    switch severity {
      case .critical:
        await logger.critical(message, metadata: metadata)
      case .error:
        await logger.error(message, metadata: metadata)
      case .warning:
        await logger.warning(message, metadata: metadata)
      case .info:
        await logger.info(message, metadata: metadata)
      case .debug, .trace:
        await logger.debug(message, metadata: metadata)
      @unknown default:
        await logger.error("Unknown severity level: \(message)", metadata: metadata)
    }
  }

  /// Convenience method for critical logs
  public func critical(_ message: String, metadata: LogMetadata?=nil) async {
    await logger.critical(message, metadata: metadata)
  }

  /// Convenience method for error logs
  public func error(_ message: String, metadata: LogMetadata?=nil) async {
    await logger.error(message, metadata: metadata)
  }

  /// Convenience method for warning logs
  public func warning(_ message: String, metadata: LogMetadata?=nil) async {
    await logger.warning(message, metadata: metadata)
  }

  /// Convenience method for info logs
  public func info(_ message: String, metadata: LogMetadata?=nil) async {
    await logger.info(message, metadata: metadata)
  }

  /// Convenience method for debug logs
  public func debug(_ message: String, metadata: LogMetadata?=nil) async {
    await logger.debug(message, metadata: metadata)
  }

  /// Formats an error into a human-readable message
  /// - Parameter error: The error to format
  /// - Returns: A formatted error message
  private func formatErrorMessage(_ error: Error) -> String {
    if let umbraError=error as? UmbraErrorsCore.UmbraError {
      "\(umbraError.domain).\(umbraError.code): \(umbraError.description)"
    } else {
      "\(type(of: error)): \(error.localizedDescription)"
    }
  }

  /// Creates metadata from an error
  /// - Parameter error: The error to extract metadata from
  /// - Returns: A LogMetadata instance with error information
  private func createMetadataFromError(_ error: Error) -> LogMetadata {
    var metadata=LogMetadata()

    if let umbraError=error as? UmbraErrorsCore.UmbraError {
      // Add context information from UmbraError
      metadata=LogMetadata(umbraError.context.asMetadataDictionary())

      // Add other UmbraError properties
      metadata["domain"] = .string(umbraError.domain)
      metadata["code"] = .string(umbraError.code)
      metadata["description"] = .string(umbraError.description)
      metadata["severity"] = .string("\(umbraError.severity)")
    } else {
      // For non-UmbraErrors, add basic information
      metadata["error_type"] = .string("\(type(of: error))")
      metadata["description"] = .string(error.localizedDescription)
    }

    // Include source location if enabled
    if configuration.includeSourceLocation {
      metadata["file"] = .string(#file)
      metadata["function"] = .string(#function)
      metadata["line"] = .string("\(#line)")
    }

    return metadata
  }
}

// MARK: - Logger Configuration

/// Comprehensive configuration options for the ErrorLogger
public struct ErrorLoggerConfiguration {
  /// The minimum severity level to output
  public var minimumSeverity: UmbraErrorsCore.ErrorSeverity

  /// Whether to include source location information in logs
  public var includeSourceLocation: Bool

  /// Whether to include stack traces in logs
  public var includeStackTraces: Bool

  /// Whether to include metadata in logs
  public var includeMetadata: Bool

  /// Whether to include file information in logs
  public var includeFileInfo: Bool

  /// Create a new ErrorLoggerConfiguration with the specified options
  /// - Parameters:
  ///   - minimumSeverity: The minimum severity level to log
  ///   - includeSourceLocation: Whether to include source location information
  ///   - includeStackTraces: Whether to include stack traces
  ///   - includeMetadata: Whether to include metadata
  ///   - includeFileInfo: Whether to include file information
  public init(
    minimumSeverity: UmbraErrorsCore.ErrorSeverity = .debug,
    includeSourceLocation: Bool=true,
    includeStackTraces: Bool=false,
    includeMetadata: Bool=true,
    includeFileInfo: Bool=true
  ) {
    self.minimumSeverity=minimumSeverity
    self.includeSourceLocation=includeSourceLocation
    self.includeStackTraces=includeStackTraces
    self.includeMetadata=includeMetadata
    self.includeFileInfo=includeFileInfo
  }

  /// Create from the legacy ErrorLoggingLevel
  /// - Parameter level: The legacy logging level
  /// - Returns: A new configuration with the equivalent severity
  public static func from(loggingLevel level: ErrorLoggingLevel) -> ErrorLoggerConfiguration {
    ErrorLoggerConfiguration(minimumSeverity: level.toErrorSeverity)
  }
}

// MARK: - ErrorContext Extensions

extension UmbraErrorsCore.ErrorContext {
  /// Convert the ErrorContext to a dictionary suitable for logging metadata
  /// - Returns: A dictionary with string keys and Any values
  public func asMetadataDictionary() -> [String: Any] {
    var result: [String: Any]=[:]

    // Add primary properties
    if let source {
      result["source"]=source
    }
    if let operation {
      result["operation"]=operation
    }
    if let details {
      result["details"]=details
    }

    result["file"]=file
    result["line"]=line
    result["function"]=function

    // Add any context storage values
    for key in ["domain", "code", "description"] {
      if let value=value(for: key) {
        result[key]=value
      }
    }

    return result
  }
}
