import Foundation
import UmbraLogging
import UmbraErrorsCore

// MARK: - Domain-Specific Filters

/// Extension to provide domain-specific filtering capabilities for ErrorLogger
extension ErrorLogger {
  /// Sets up domain-specific logging filter for a certain domain
  /// - Parameters:
  ///   - domain: The domain to filter
  ///   - level: The minimum log level for this domain
  public func setDomainFilter(domain: String, level: ErrorLoggingLevel) {
    domainFilters[domain] = level
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
  internal func shouldProcessLog(domain: String, level: ErrorLoggingLevel) -> Bool {
    // If no domain filter exists, use the global minimum level
    guard let minLevel = domainFilters[domain] else {
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
    _ error: Error,
    context: ErrorContext,
    level: ErrorLoggingLevel,
    file: String = #file,
    function: String = #function,
    line: Int = #line
  ) {
    // Skip if we shouldn't process this log based on domain filters
    guard shouldProcessLog(domain: context.domain, level: level) else {
      return
    }

    var metadata: [String: Any] = [
      "domain": context.domain,
      "code": context.code,
      "errorDescription": context.description
    ]

    if configuration.includeSourceLocation {
      metadata["file"] = file
      metadata["function"] = function
      metadata["line"] = line
    }

    let message = "\(context.domain) [\(context.code)]: \(context.description)"
    
    switch level {
    case .debug:
      logger.debug(message, metadata: LogMetadata(metadata))
    case .info:
      logger.info(message, metadata: LogMetadata(metadata))
    case .warning:
      logger.warning(message, metadata: LogMetadata(metadata))
    case .error:
      logger.error(message, metadata: LogMetadata(metadata))
    case .critical:
      logger.critical(message, metadata: LogMetadata(metadata))
    }
  }
}

// MARK: - Error Logging Level

/// Defines the severity levels for error logging
public enum ErrorLoggingLevel: Int, Comparable {
  case debug = 0
  case info = 1
  case warning = 2
  case error = 3
  case critical = 4
  
  public static func < (lhs: ErrorLoggingLevel, rhs: ErrorLoggingLevel) -> Bool {
    return lhs.rawValue < rhs.rawValue
  }
}

// MARK: - Logger Configuration

/// Configuration for the ErrorLogger
public struct ErrorLoggerConfiguration {
  /// The minimum severity level to log globally
  public var minimumLevel: ErrorLoggingLevel = .debug
  
  /// Whether to include source location information in logs
  public var includeSourceLocation: Bool = true
  
  /// Whether to include stack traces in logs
  public var includeStackTraces: Bool = false
  
  /// Default initialiser
  public init(
    minimumLevel: ErrorLoggingLevel = .debug,
    includeSourceLocation: Bool = true,
    includeStackTraces: Bool = false
  ) {
    self.minimumLevel = minimumLevel
    self.includeSourceLocation = includeSourceLocation
    self.includeStackTraces = includeStackTraces
  }
}
