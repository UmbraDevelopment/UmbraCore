import Foundation
import Interfaces
import UmbraErrorsCore
import UmbraLogging
import LoggingWrapper

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
  
  /// Domain-specific log level filters
  private var domainFilters: [String: ErrorLoggingLevel] = [:]

  /// Initialises with the default logger and configuration
  public init(
    logger: LoggingProtocol=LoggingWrapperAdapter(),
    configuration: ErrorLoggerConfiguration=ErrorLoggerConfiguration()
  ) {
    self.logger=logger
    self.configuration=configuration
  }
  
  // MARK: - Domain-Specific Filters
  
  /// Sets up domain-specific logging filter for a certain domain
  /// - Parameters:
  ///   - domain: The domain to filter
  ///   - level: The minimum log level for this domain
  public func setDomainFilter(domain: String, level: ErrorLoggingLevel) {
    domainFilters[domain]=level
  }

  /// Clears a specific domain filter
  /// - Parameter domain: The domain to clear the filter for
  public func clearDomainFilter(domain: String) {
    domainFilters.removeValue(forKey: domain)
  }

  /// Clears all domain filters
  public func clearAllDomainFilters() {
    domainFilters.removeAll()
  }

  /// Internal method to check if a log should be processed based on domain filters
  /// - Parameters:
  ///   - domain: The domain of the error
  ///   - level: The severity level of the error
  /// - Returns: True if the log should be processed, false otherwise
  func shouldProcessLog(domain: String, level: ErrorLoggingLevel) -> Bool {
    // If no domain filter exists, use the global minimum level
    guard let minLevel=domainFilters[domain] else {
      return level.rawValue >= configuration.minimumLevel.rawValue
    }

    // Otherwise, use the domain-specific minimum level
    return level.rawValue >= minLevel.rawValue
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
    // Get the logging level from the severity
    _ = mapSeverityToLevel(severity)

    // Format a human-readable message for the error
    let message=formatErrorMessage(error)

    // Create metadata from error and add additional context
    var metadata=createMetadataFromError(error)
    if let additionalContext {
      if var metadataDict = metadata?.asDictionary as? [String: String] {
        for (key, value) in additionalContext {
          metadataDict[key] = "\(value)"
        }
        metadata = LogMetadata(metadataDict)
      }
    }

    // Route to the appropriate log level
    switch severity {
      case .critical:
        // Use error level with a CRITICAL prefix since LoggingProtocol doesn't have critical
        await logger.error("[CRITICAL] \(message)", metadata: metadata)
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
    // Use error level with a CRITICAL prefix since LoggingProtocol doesn't have critical
    await logger.error("[CRITICAL] \(message)", metadata: metadata)
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
  
  // MARK: - Contextual Logging
  
  /// Logs an error with contextual information
  /// - Parameters:
  ///   - error: The error to log
  ///   - context: Additional context for the error
  ///   - level: The severity level
  ///   - file: The file where the error occurred
  ///   - function: The function where the error occurred
  ///   - line: The line where the error occurred
  public func logWithContext(
    _: Error,
    context: UmbraErrorsCore.ErrorContext,
    level: ErrorLoggingLevel,
    file: String=#file,
    function: String=#function,
    line: Int=#line
  ) {
    // Extract domain from context or use default
    let domain = context.value(for: "domain") as? String ?? "UnknownDomain"
    
    // Skip if we shouldn't process this log based on domain filters
    guard shouldProcessLog(domain: domain, level: level) else {
      return
    }

    var metadata: [String: String] = [
      "domain": domain,
      "code": context.value(for: "code") as? String ?? "unknown",
      "errorDescription": context.value(for: "description") as? String ?? "No description"
    ]

    // Include source location if enabled
    if configuration.includeSourceLocation {
      metadata["file"] = file
      metadata["function"] = function
      metadata["line"] = String(line)
    }

    let message = "\(domain) [\(metadata["code"]!)]: \(metadata["errorDescription"]!)"

    // Use a local method to log the message asynchronously
    Task {
      await logMessageAsync(message, level: level, metadata: metadata)
    }
  }

  /// Internal helper to log a message with the appropriate level
  /// - Parameters:
  ///   - message: The message to log
  ///   - level: The severity level
  ///   - metadata: Metadata to include with the log
  private func logMessageAsync(_ message: String, level: ErrorLoggingLevel, metadata: [String: String]) async {
    // Convert string dictionary to LogMetadata
    let logMetadata = LogMetadata(metadata)
    
    // This method uses the internal log methods which have access to the logger
    switch level {
      case .trace:
        await debug(message, metadata: logMetadata)
      case .debug:
        await debug(message, metadata: logMetadata)
      case .info:
        await info(message, metadata: logMetadata)
      case .warning:
        await warning(message, metadata: logMetadata)
      case .error:
        await error(message, metadata: logMetadata)
      case .critical:
        // For critical errors, use error level since LoggingProtocol doesn't have critical
        await error("[CRITICAL] \(message)", metadata: logMetadata)
    }
  }

  /// Formats an error into a human-readable message
  /// - Parameter error: The error to format
  /// - Returns: A formatted error message
  private func formatErrorMessage(_ error: Error) -> String {
    if let umbraError=error as? UmbraErrorsCore.UmbraError {
      "\(umbraError.domain).\(umbraError.code): \(umbraError.errorDescription)"
    } else {
      "\(type(of: error)): \(error.localizedDescription)"
    }
  }

  /// Creates metadata from an error
  /// - Parameter error: The error to extract metadata from
  /// - Returns: A LogMetadata instance with error information
  private func createMetadataFromError(_ error: Error) -> LogMetadata? {
    if let umbraError = error as? UmbraErrorsCore.UmbraError {
      // Convert context to metadata dictionary
      let contextDict = convertContextToMetadata(umbraError.context)
      let metadata = LogMetadata(contextDict)
      
      // Add other UmbraError properties as strings
      var metadataDict = metadata.asDictionary as? [String: String] ?? [:]
      metadataDict["domain"] = umbraError.domain
      metadataDict["code"] = umbraError.code
      metadataDict["description"] = umbraError.errorDescription
      
      return LogMetadata(metadataDict)
    } else {
      // For non-UmbraErrors, add basic information
      var metadataDict: [String: String] = [
        "error_type": "\(type(of: error))",
        "description": error.localizedDescription
      ]
      
      // Include source location if enabled
      if configuration.includeSourceLocation {
        metadataDict["file"] = #file
        metadataDict["function"] = #function
        metadataDict["line"] = "\(#line)"
      }
      
      return LogMetadata(metadataDict)
    }
  }
  
  /// Converts ErrorContext to a metadata dictionary
  /// - Parameter context: The error context to convert
  /// - Returns: Dictionary with string keys and string values
  private func convertContextToMetadata(_ context: ErrorContext) -> [String: String] {
    var result: [String: String] = [:]
    
    // Add primary properties if they exist
    if let source = context.source {
      result["source"] = "\(source)"
    }
    
    if let operation = context.operation {
      result["operation"] = "\(operation)"
    }
    
    if let details = context.details {
      result["details"] = "\(details)"
    }
    
    // Add function, file, line info
    result["file"] = context.file
    result["function"] = context.function
    result["line"] = "\(context.line)"
    
    // Try to add common context values by known keys
    for key in ["domain", "code", "description", "errorCode", "errorDomain", "errorDescription"] {
      if let value = context.value(for: key) {
        result[key] = "\(value)"
      }
    }
    
    return result
  }
  
  /// Maps a UmbraErrorsCore.ErrorSeverity to an ErrorLoggingLevel
  /// - Parameter severity: The severity to map
  /// - Returns: The corresponding logging level
  private func mapSeverityToLevel(_ severity: UmbraErrorsCore.ErrorSeverity) -> ErrorLoggingLevel {
    switch severity {
      case .trace, .debug:
        return .debug
      case .info:
        return .info
      case .warning:
        return .warning
      case .error:
        return .error
      case .critical:
        return .critical
      @unknown default:
        return .error
    }
  }
}

// MARK: - Logger Configuration

/// Comprehensive configuration options for the ErrorLogger
public struct ErrorLoggerConfiguration {
  /// The minimum severity level to output
  public var minimumSeverity: UmbraErrorsCore.ErrorSeverity
  
  /// The minimum logging level to output
  public var minimumLevel: ErrorLoggingLevel

  /// Whether to include source location information in logs
  public var includeSourceLocation: Bool

  /// Whether to include stack traces in logs
  public var includeStackTraces: Bool

  /// Whether to include metadata in logs
  public var includeMetadata: Bool

  /// Whether to include file information in logs
  public var includeFileInfo: Bool

  /// Default configuration initialiser
  public init(
    minimumSeverity: UmbraErrorsCore.ErrorSeverity = .info,
    minimumLevel: ErrorLoggingLevel = .info,
    includeSourceLocation: Bool = true,
    includeStackTraces: Bool = true,
    includeMetadata: Bool = true,
    includeFileInfo: Bool = true
  ) {
    self.minimumSeverity=minimumSeverity
    self.minimumLevel=minimumLevel
    self.includeSourceLocation=includeSourceLocation
    self.includeStackTraces=includeStackTraces
    self.includeMetadata=includeMetadata
    self.includeFileInfo=includeFileInfo
  }
}

/// Available logging levels
public enum ErrorLoggingLevel: Int, Comparable {
  case trace=0
  case debug=1
  case info=2
  case warning=3
  case error=4
  case critical=5
  
  public static func < (lhs: ErrorLoggingLevel, rhs: ErrorLoggingLevel) -> Bool {
    return lhs.rawValue < rhs.rawValue
  }
}
