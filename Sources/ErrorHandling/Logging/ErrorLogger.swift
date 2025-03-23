import Foundation
import LoggingWrapper
import UmbraLogging
import UmbraLoggingAdapters

// Local type declarations to replace imports
// These replace the removed ErrorHandling and ErrorHandlingDomains imports

/// Error domain namespace
public enum ErrorDomain {
  /// Security domain
  public static let security="Security"
  /// Crypto domain
  public static let crypto="Crypto"
  /// Application domain
  public static let application="Application"
}

/// Error context protocol
public protocol ErrorContext {
  /// Domain of the error
  var domain: String { get }
  /// Code of the error
  var code: Int { get }
  /// Description of the error
  var description: String { get }
}

/// Base error context implementation
public struct BaseErrorContext: ErrorContext {
  /// Domain of the error
  public let domain: String
  /// Code of the error
  public let code: Int
  /// Description of the error
  public let description: String

  /// Initialise with domain, code and description
  public init(domain: String, code: Int, description: String) {
    self.domain=domain
    self.code=code
    self.description=description
  }
}

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
}

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
    severity: ErrorSeverity,
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
        metadata[key]=LogMetadata.string(value)
      }
    }

    // Log using the direct severity-to-log-level mapping
    switch severity {
      case .critical:
        await logger.error(message, metadata: metadata)
      case .error:
        await logger.error(message, metadata: metadata)
      case .warning:
        await logger.warning(message, metadata: metadata)
      case .info:
        await logger.info(message, metadata: metadata)
      case .debug:
        await logger.debug(message, metadata: metadata)
      case .trace:
        await logger.debug(message, metadata: metadata)
      @unknown default:
        await logger.error("Unknown severity level: \(message)", metadata: metadata)
    }
  }

  /// Log an error directly
  /// - Parameters:
  ///   - error: The error to log
  ///   - file: Source file (autofilled by compiler)
  ///   - function: Function name (autofilled by compiler)
  ///   - line: Line number (autofilled by compiler)
  ///   - additionalMetadata: Additional metadata to include in log
  public func logError(
    _ error: Error,
    file: String=#file,
    function: String=#function,
    line: Int=#line,
    additionalMetadata: LogMetadata?=nil
  ) async {
    // Skip if filtered out
    if isFiltered(error) { return }

    // Add file, function, and line information
    var contextInfo: [String: Any]=[:]

    if configuration.includeFileInfo {
      contextInfo["file"]=file
    }

    if configuration.includeFunctionNames {
      contextInfo["function"]=function
    }

    if configuration.includeLineNumbers {
      contextInfo["line"]=String(line)
    }

    // Add additional metadata if provided
    if let additionalMetadata {
      for (key, value) in additionalMetadata.asDictionary {
        if let stringValue=value as? String {
          contextInfo[key]=stringValue
        }
      }
    }

    // Log with error severity
    await log(error, severity: .error, additionalContext: contextInfo)
  }

  /// Log a message at warning level
  /// - Parameters:
  ///   - message: The message to log
  ///   - file: Source file (autofilled by compiler)
  ///   - function: Function name (autofilled by compiler)
  ///   - line: Line number (autofilled by compiler)
  ///   - metadata: Optional metadata to include
  public func logWarning(
    _ message: String,
    file: String=#file,
    function: String=#function,
    line: Int=#line,
    metadata: LogMetadata?=nil
  ) async {
    var contextInfo: [String: Any]=[:]

    if configuration.includeFileInfo {
      contextInfo["file"]=file
    }

    if configuration.includeFunctionNames {
      contextInfo["function"]=function
    }

    if configuration.includeLineNumbers {
      contextInfo["line"]=String(line)
    }

    // Add metadata if provided
    if let metadata {
      for (key, value) in metadata.asDictionary {
        if let stringValue=value as? String {
          contextInfo[key]=stringValue
        }
      }
    }

    // Log direct message with warning severity
    await logger.warning(message, metadata: LogMetadata.from(contextInfo) ?? LogMetadata())
  }

  /// Log a message at info level
  /// - Parameters:
  ///   - message: The message to log
  ///   - file: Source file (autofilled by compiler)
  ///   - function: Function name (autofilled by compiler)
  ///   - line: Line number (autofilled by compiler)
  ///   - metadata: Optional metadata to include
  public func logInfo(
    _ message: String,
    file: String=#file,
    function: String=#function,
    line: Int=#line,
    metadata: LogMetadata?=nil
  ) async {
    var contextInfo: [String: Any]=[:]

    if configuration.includeFileInfo {
      contextInfo["file"]=file
    }

    if configuration.includeFunctionNames {
      contextInfo["function"]=function
    }

    if configuration.includeLineNumbers {
      contextInfo["line"]=String(line)
    }

    // Add metadata if provided
    if let metadata {
      for (key, value) in metadata.asDictionary {
        if let stringValue=value as? String {
          contextInfo[key]=stringValue
        }
      }
    }

    // Log direct message with info severity
    await logger.info(message, metadata: LogMetadata.from(contextInfo) ?? LogMetadata())
  }

  /// Log a message at debug level
  /// - Parameters:
  ///   - message: The message to log
  ///   - file: Source file (autofilled by compiler)
  ///   - function: Function name (autofilled by compiler)
  ///   - line: Line number (autofilled by compiler)
  ///   - metadata: Optional metadata to include
  public func logDebug(
    _ message: String,
    file: String=#file,
    function: String=#function,
    line: Int=#line,
    metadata: LogMetadata?=nil
  ) async {
    var contextInfo: [String: Any]=[:]

    if configuration.includeFileInfo {
      contextInfo["file"]=file
    }

    if configuration.includeFunctionNames {
      contextInfo["function"]=function
    }

    if configuration.includeLineNumbers {
      contextInfo["line"]=String(line)
    }

    // Add metadata if provided
    if let metadata {
      for (key, value) in metadata.asDictionary {
        if let stringValue=value as? String {
          contextInfo[key]=stringValue
        }
      }
    }

    // Log direct message with debug severity
    await logger.debug(message, metadata: LogMetadata.from(contextInfo) ?? LogMetadata())
  }

  // MARK: - Private Helpers

  /// Creates metadata dictionary from an error
  /// - Parameter error: The error to extract metadata from
  /// - Returns: A dictionary of metadata
  private func createMetadataFromError(_ error: Error) -> LogMetadata {
    var metadata=LogMetadata()

    if let umbraError=error as? ErrorHandlingInterfaces.UmbraError {
      // Add domain and code
      metadata["domain"]=umbraError.domain
      metadata["code"]=umbraError.code

      // Add source information if available
      if let source=umbraError.source {
        metadata["sourceFile"]=source.file
        metadata["sourceLine"]=String(source.line)
        metadata["sourceFunction"]=source.function
      }

      // Add underlying error if present
      if let underlying=umbraError.underlyingError {
        metadata["underlyingError"]=String(describing: underlying)
      }

      // Add any context information
      metadata["contextType"]=String(describing: umbraError.context)
    }

    return metadata
  }

  /// Formats an error message for logging
  /// - Parameter error: The error to format
  /// - Returns: A formatted error message
  private func formatErrorMessage(_ error: Error) -> String {
    if let umbraError=error as? ErrorHandlingInterfaces.UmbraError {
      "[\(umbraError.domain):\(umbraError.code)] \(umbraError.errorDescription)"
    } else {
      error.localizedDescription
    }
  }

  /// Checks if an error should be filtered out
  /// - Parameter error: The error to check
  /// - Returns: True if the error should be filtered out
  private func isFiltered(_ error: Error) -> Bool {
    // Check each filter. If any return true, the error is filtered out
    for filter in configuration.filters {
      if filter(error) {
        return true
      }
    }

    return false
  }
}

/// Configuration options for the ErrorLogger
public struct ErrorLoggerConfiguration {
  /// The minimum severity level to output
  public var minimumSeverity: ErrorSeverity

  /// Whether to use OSLog API instead of print for console output
  public var useOSLog: Bool

  /// The subsystem to use for OSLog (if enabled)
  public var osLogSubsystem: String

  /// The category to use for OSLog (if enabled)
  public var osLogCategory: String

  /// Whether to include file information in logs
  public var includeFileInfo: Bool

  /// Whether to include line numbers in logs
  public var includeLineNumbers: Bool

  /// Whether to include function names in logs
  public var includeFunctionNames: Bool

  /// Whether to include timestamps in logs
  public var includeTimestamps: Bool

  /// Whether to include JSON format for logs (useful for parsing)
  public var useJsonFormat: Bool

  /// Filters to apply to error logs
  public var filters: [(Error) -> Bool]

  /// Initialises with default values
  public init(
    minimumSeverity: ErrorSeverity = .info,
    useOSLog: Bool=true,
    osLogSubsystem: String="com.umbracorp.umbra",
    osLogCategory: String="errors",
    includeFileInfo: Bool=true,
    includeLineNumbers: Bool=true,
    includeFunctionNames: Bool=true,
    includeTimestamps: Bool=true,
    useJsonFormat: Bool=false,
    filters: [(Error) -> Bool]=[]
  ) {
    self.minimumSeverity=minimumSeverity
    self.useOSLog=useOSLog
    self.osLogSubsystem=osLogSubsystem
    self.osLogCategory=osLogCategory
    self.includeFileInfo=includeFileInfo
    self.includeLineNumbers=includeLineNumbers
    self.includeFunctionNames=includeFunctionNames
    self.includeTimestamps=includeTimestamps
    self.useJsonFormat=useJsonFormat
    self.filters=filters
  }
}

// MARK: - SwiftyBeaver Configuration Setup

extension ErrorLogger {
  /// Configures the logger for development environment
  /// - Returns: The configured logger instance
  public static func configureForDevelopment() -> ErrorLogger {
    let logger=ErrorLogger.shared

    return logger.configure { config in
      config.minimumSeverity = .debug
      config.useJsonFormat=false
      config.includeFileInfo=true
      config.includeLineNumbers=true
      config.includeFunctionNames=true
    }
  }

  /// Configures the logger for production environment
  /// - Returns: The configured logger instance
  public static func configureForProduction() -> ErrorLogger {
    let logger=ErrorLogger.shared

    return logger.configure { config in
      config.minimumSeverity = .warning
      config.useJsonFormat=true // For easier parsing of logs in production
      config.includeFileInfo=true
      config.includeLineNumbers=true
    }
  }

  /// Configures the logger for testing environment
  /// - Returns: The configured logger instance
  public static func configureForTesting() -> ErrorLogger {
    let logger=ErrorLogger.shared

    return logger.configure { config in
      config.minimumSeverity = .error // Only log errors during tests
      config.useJsonFormat=false
      config.includeFileInfo=true
      config.includeLineNumbers=true
    }
  }

  /// Configures the logger with a custom configuration block
  /// - Parameter configurator: A closure that applies configuration changes
  /// - Returns: The configured logger instance
  public func configure(_ configurator: (inout ErrorLoggerConfiguration) -> Void) -> ErrorLogger {
    // Create a mutable copy of the current configuration
    var updatedConfig=configuration

    // Apply the configurator
    configurator(&updatedConfig)

    // Return a new instance with the updated configuration
    return ErrorLogger(logger: logger, configuration: updatedConfig)
  }
}
