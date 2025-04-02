import Foundation
import LoggingInterfaces
import LoggingServices
import LoggingTypes
import OSLog

/**
 # DefaultLogger

 A simple logger implementation that provides basic logging functionality
 when no other logger is provided. This ensures that logging is always available
 even in minimal configurations.

 This implementation follows the Alpha Dot Five architecture principles:
 - Uses actor-based concurrency for thread safety
 - Provides proper privacy handling for sensitive data
 - Integrates with the broader logging system

 This logger uses OSLog on Apple platforms for efficient system integration
 and the SecureLoggerActor for enhanced security features.
 */
public final class DefaultLogger: LoggingProtocol {
  /// Secure logger actor for thread-safe logging
  private let secureLogger: SecureLoggerActor

  /// Category name for this logger
  private let category: String

  /// Convenience property to access the logging actor
  public var loggingActor: LoggingActor {
    SimpleLoggingActor(secureLogger: secureLogger, category: category)
  }

  /// Initialise a new logger with the default subsystem and category
  public init(category: String="CryptoServices") {
    self.category=category
    secureLogger=SecureLoggerActor(
      subsystem: "com.umbra.securitycryptoservices",
      category: category,
      includeTimestamps: true
    )
  }

  /// Standard logging method that all level-specific methods delegate to
  public func log(
    _ level: LogLevel,
    _ message: String,
    metadata: PrivacyMetadata?,
    source: String
  ) async {
    // Convert LogLevel to UmbraLogLevel
    let umbraLevel: LoggingTypes.UmbraLogLevel=switch level {
      case .trace, .debug:
        .debug
      case .info:
        .info
      case .warning:
        .warning
      case .error:
        .error
      case .critical:
        .critical
    }

    // Convert metadata to privacy-tagged values if present
    var privacyMetadata: [String: PrivacyTaggedValue]?
    if let metadata {
      var metadataMap: [String: PrivacyTaggedValue]=[:]
      for (key, value) in metadata {
        // Determine appropriate privacy level based on key naming conventions
        let privacyLevel: LogPrivacyLevel=if
          key.hasSuffix("Password") || key
            .hasSuffix("Token") || key.hasSuffix("Key")
        {
          .sensitive
        } else if key.hasSuffix("Id") || key.hasSuffix("Email") || key.hasSuffix("Name") {
          .private
        } else {
          .public
        }

        metadataMap[key]=PrivacyTaggedValue(value: value, privacyLevel: privacyLevel)
      }
      privacyMetadata=metadataMap
    }

    await secureLogger.log(
      level: umbraLevel,
      message: "[\(source)] \(message)",
      metadata: privacyMetadata
    )
  }

  /// Log trace message
  public func trace(_ message: String, metadata: PrivacyMetadata?, source: String) async {
    await log(.trace, message, metadata: metadata, source: source)
  }

  /// Log debug message
  public func debug(_ message: String, metadata: PrivacyMetadata?, source: String) async {
    await log(.debug, message, metadata: metadata, source: source)
  }

  /// Log info message
  public func info(_ message: String, metadata: PrivacyMetadata?, source: String) async {
    await log(.info, message, metadata: metadata, source: source)
  }

  /// Log warning message
  public func warning(_ message: String, metadata: PrivacyMetadata?, source: String) async {
    await log(.warning, message, metadata: metadata, source: source)
  }

  /// Log error message
  public func error(_ message: String, metadata: PrivacyMetadata?, source: String) async {
    await log(.error, message, metadata: metadata, source: source)
  }

  /// Log critical message
  public func critical(_ message: String, metadata: PrivacyMetadata?, source: String) async {
    await log(.critical, message, metadata: metadata, source: source)
  }
}

/**
 A simple implementation of LoggingActor that delegates to SecureLoggerActor
 */
actor SimpleLoggingActor: LoggingActor {
  /// The secure logger actor for delegating log operations
  private let secureLogger: SecureLoggerActor

  /// Category for this logger
  private let category: String

  /// Initialise with a secure logger actor
  init(secureLogger: SecureLoggerActor, category: String) {
    self.secureLogger=secureLogger
    self.category=category
  }

  /// Log a message at the specified level
  public func log(
    _ level: LogLevel,
    _ message: String,
    metadata: PrivacyMetadata?,
    source: String
  ) async {
    // Convert LogLevel to UmbraLogLevel
    let umbraLevel: LoggingTypes.UmbraLogLevel=switch level {
      case .trace, .debug:
        .debug
      case .info:
        .info
      case .warning:
        .warning
      case .error:
        .error
      case .critical:
        .critical
    }

    // Convert metadata to privacy-tagged values if present
    var privacyMetadata: [String: PrivacyTaggedValue]?
    if let metadata {
      var metadataMap: [String: PrivacyTaggedValue]=[:]
      for (key, value) in metadata {
        // Determine appropriate privacy level based on key naming conventions
        let privacyLevel: LogPrivacyLevel=if
          key.hasSuffix("Password") || key
            .hasSuffix("Token") || key.hasSuffix("Key")
        {
          .sensitive
        } else if key.hasSuffix("Id") || key.hasSuffix("Email") || key.hasSuffix("Name") {
          .private
        } else {
          .public
        }

        metadataMap[key]=PrivacyTaggedValue(value: value, privacyLevel: privacyLevel)
      }
      privacyMetadata=metadataMap
    }

    await secureLogger.log(
      level: umbraLevel,
      message: "[\(source)] \(message)",
      metadata: privacyMetadata
    )
  }
}
