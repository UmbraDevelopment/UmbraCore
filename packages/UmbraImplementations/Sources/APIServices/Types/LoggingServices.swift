import Foundation
import LoggingInterfaces
import LoggingTypes

/**
 * Factory for creating domain-specific loggers.
 * Provides a standardised way to create loggers for different domains.
 */
public enum LoggingServices {
  /**
   * Creates a domain-specific logger.
   *
   * @param domain The domain name for the logger
   * @param category The category for the logger
   * @return A logger configured for the specified domain
   */
  public static func createDomainLogger(domain: String, category: String) -> LoggingProtocol {
    createLogger(domain: domain, category: category)
  }

  /**
   * Creates a standard logger with the given domain and category.
   * This maintains compatibility with existing code.
   *
   * @param domain The domain to log for
   * @param category The category to log under
   * @return A configured logger
   */
  public static func createLogger(domain: String, category: String) -> LoggingProtocol {
    // Create a Logger with the appropriate subsystem and category
    let subsystem="com.umbra.\(domain.lowercased())"

    return LoggerFactory.createLogger(
      subsystem: subsystem,
      category: category
    )
  }

  /**
   * Creates a logger with the specified privacy configuration.
   *
   * - Parameters:
   *   - subsystem: The subsystem for the logger
   *   - category: The category for the logger
   *   - privacyLevel: The default privacy level for the logger
   * - Returns: A configured logger
   */
  public static func createPrivacyLogger(
    subsystem: String,
    category: String,
    privacyLevel: LogPrivacyLevel = .private
  ) -> LoggingProtocol {
    LoggerFactory.createLogger(
      subsystem: subsystem,
      category: category,
      privacyLevel: privacyLevel
    )
  }

  /**
   * Creates a logger for API services.
   *
   * - Parameters:
   *   - name: The name for the logger
   *   - privacyLevel: The default privacy level for the logger
   * - Returns: A configured logger
   */
  public static func createAPILogger(
    name: String,
    privacyLevel: LogPrivacyLevel = .private
  ) -> LoggingProtocol {
    createPrivacyLogger(
      subsystem: "com.umbra.api",
      category: name,
      privacyLevel: privacyLevel
    )
  }

  /**
   * Alias for createDomainLogger to maintain compatibility with existing code.
   */
  public static func DomainLogger(domain: String, category: String) -> LoggingProtocol {
    createDomainLogger(domain: domain, category: category)
  }
}

/**
 * Factory for creating loggers.
 */
private enum LoggerFactory {
  /**
   * Creates a logger with the specified configuration.
   *
   * - Parameters:
   *   - subsystem: The subsystem for the logger
   *   - category: The category for the logger
   *   - privacyLevel: The default privacy level for the logger
   * - Returns: A configured logger
   */
  static func createLogger(
    subsystem: String,
    category: String,
    privacyLevel _: LogPrivacyLevel = .private
  ) -> LoggingProtocol {
    // In a full implementation, this would create a real logger
    // For now, returning a basic console logger
    ConsoleLogger(subsystem: subsystem, category: category)
  }
}

/**
 * Basic console logger implementation for development and testing.
 */
private class ConsoleLogger: LoggingProtocol {
  private let subsystem: String
  private let category: String

  init(subsystem: String, category: String) {
    self.subsystem=subsystem
    self.category=category
  }

  func debug(_ message: String, metadata _: LogMetadataDTOCollection) async {
    print("[\(subsystem):\(category)] DEBUG: \(message)")
  }

  func info(_ message: String, metadata _: LogMetadataDTOCollection) async {
    print("[\(subsystem):\(category)] INFO: \(message)")
  }

  func warning(_ message: String, metadata _: LogMetadataDTOCollection) async {
    print("[\(subsystem):\(category)] WARNING: \(message)")
  }

  func error(_ message: String, metadata _: LogMetadataDTOCollection) async {
    print("[\(subsystem):\(category)] ERROR: \(message)")
  }

  func critical(_ message: String, metadata _: LogMetadataDTOCollection) async {
    print("[\(subsystem):\(category)] CRITICAL: \(message)")
  }
}

/**
 * Basic wrapper around OSLog for testing and development.
 */
private class OSLogWrapper: LoggingProtocol {
  private let subsystem: String
  private let category: String

  init(subsystem: String, category: String) {
    self.subsystem=subsystem
    self.category=category
  }

  // Implement the logging protocol methods
  public func debug(_ message: String, metadata _: PrivacyMetadata?, source _: String) async {
    print("[\(subsystem):\(category)] DEBUG: \(message)")
  }

  public func info(_ message: String, metadata _: PrivacyMetadata?, source _: String) async {
    print("[\(subsystem):\(category)] INFO: \(message)")
  }

  public func warn(_ message: String, metadata _: PrivacyMetadata?, source _: String) async {
    print("[\(subsystem):\(category)] WARN: \(message)")
  }

  public func error(_ message: String, metadata _: PrivacyMetadata?, source _: String) async {
    print("[\(subsystem):\(category)] ERROR: \(message)")
  }

  public func trace(_ message: String, metadata _: PrivacyMetadata?, source _: String) async {
    print("[\(subsystem):\(category)] TRACE: \(message)")
  }

  public func debug(_ message: String, context _: LogContextDTO) async {
    print("[\(subsystem):\(category)] DEBUG: \(message)")
  }

  public func info(_ message: String, context _: LogContextDTO) async {
    print("[\(subsystem):\(category)] INFO: \(message)")
  }

  public func warn(_ message: String, context _: LogContextDTO) async {
    print("[\(subsystem):\(category)] WARN: \(message)")
  }

  public func error(_ message: String, context _: LogContextDTO) async {
    print("[\(subsystem):\(category)] ERROR: \(message)")
  }

  public func trace(_ message: String, context _: LogContextDTO) async {
    print("[\(subsystem):\(category)] TRACE: \(message)")
  }
}

/**
 * Basic implementation of the LoggingProtocol.
 */
private class BasicLogger: LoggingProtocol {
  private let domain: String
  private let category: String

  init(domain: String, category: String) {
    self.domain=domain
    self.category=category
  }

  public func debug(_ message: String, context _: LogContext?) async {
    print("[\(domain):\(category)] DEBUG: \(message)")
  }

  public func info(_ message: String, context _: LogContext?) async {
    print("[\(domain):\(category)] INFO: \(message)")
  }

  public func warning(_ message: String, context _: LogContext?) async {
    print("[\(domain):\(category)] WARNING: \(message)")
  }

  public func error(_ message: String, context _: LogContext?, error: Error?) async {
    print("[\(domain):\(category)] ERROR: \(message)")
    if let error {
      print("[\(domain):\(category)] ERROR DETAIL: \(error)")
    }
  }

  public func critical(_ message: String, context _: LogContext?, error: Error?) async {
    print("[\(domain):\(category)] CRITICAL: \(message)")
    if let error {
      print("[\(domain):\(category)] CRITICAL DETAIL: \(error)")
    }
  }
}

/**
 * Basic implementation of LogContext.
 */
public struct CoreLogContext: LogContext {
  public let source: String
  public let metadata: LogMetadataCollection?
  public let error: Error?

  public init(source: String, metadata: LogMetadataCollection?=nil, error: Error?=nil) {
    self.source=source
    self.metadata=metadata
    self.error=error
  }
}
