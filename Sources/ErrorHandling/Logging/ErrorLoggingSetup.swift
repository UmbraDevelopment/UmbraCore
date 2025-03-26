import Foundation
import UmbraErrorsCore
import UmbraLogging

// MARK: - Domain-Specific Filters

/// Extension to provide domain-specific filtering capabilities for ErrorLogger
extension ErrorLogger {
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
}

// MARK: - Contextual Logging

extension ErrorLogger {
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
    // Skip if we shouldn't process this log based on domain filters
    guard shouldProcessLog(domain: context.domain, level: level) else {
      return
    }

    var metadata: [String: String]=[
      "domain": context.domain,
      "code": context.code,
      "errorDescription": context.description
    ]

    if configuration.includeSourceLocation {
      metadata["file"]=file
      metadata["function"]=function
      metadata["line"]=String(line)
    }

    let message="\(context.domain) [\(context.code)]: \(context.description)"

    // Use a local method to log the message instead of directly accessing the logger property
    logMessage(message, level: level, metadata: metadata)
  }

  /// Internal helper to log a message with the appropriate level
  /// - Parameters:
  ///   - message: The message to log
  ///   - level: The severity level
  ///   - metadata: Metadata to include with the log
  private func logMessage(_ message: String, level: ErrorLoggingLevel, metadata: [String: String]) {
    // This method uses the internal log methods which have access to the logger
    switch level {
      case .debug:
        debug(message, metadata: metadata)
      case .info:
        info(message, metadata: metadata)
      case .warning:
        warning(message, metadata: metadata)
      case .error:
        error(message, metadata: metadata)
      case .critical:
        critical(message, metadata: metadata)
    }
  }
}

// MARK: - Error Logging Level

/// Error logging level enum - will be mapped to UmbraErrorsCore.ErrorSeverity
public enum ErrorLoggingLevel: String, Codable, Comparable, Sendable {
  /// Critical errors that require immediate attention
  case critical
  /// Serious errors that affect functionality
  case error
  /// Less severe issues that may affect performance
  case warning
  /// Informational messages that don't indicate problems
  case info
  /// Detailed information for debugging
  case debug

  /// Map to ErrorSeverity
  public var toErrorSeverity: UmbraErrorsCore.ErrorSeverity {
    switch self {
      case .critical:
        .critical
      case .error:
        .error
      case .warning:
        .warning
      case .info:
        .info
      case .debug:
        .debug
    }
  }

  /// Order for comparison
  private var order: Int {
    switch self {
      case .critical: 0
      case .error: 1
      case .warning: 2
      case .info: 3
      case .debug: 4
    }
  }

  /// Enable comparison between levels
  public static func < (lhs: ErrorLoggingLevel, rhs: ErrorLoggingLevel) -> Bool {
    lhs.order < rhs.order
  }
}
