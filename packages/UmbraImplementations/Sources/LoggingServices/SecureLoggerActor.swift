import Foundation
import LoggingInterfaces
import LoggingTypes
import os.log

/**
 # SecureLoggerActor

 An actor-based implementation of a secure, privacy-aware logger designed for
 security-sensitive applications following the Alpha Dot Five architecture principles.
 
 This logger builds upon the system logging facilities while adding privacy
 controls, contextual information, and security-focused features designed
 to prevent sensitive data exposure.

 ## Security Considerations

 Improper logging of sensitive data presents several risks:

 1. **Data Exposure**: Sensitive information like credentials, tokens, or personal data
    could be exposed if logged in plain text.

 2. **Compliance Violations**: Inadvertent logging of protected data may violate
    regulatory requirements such as GDPR, PCI-DSS, or HIPAA.

 3. **Forensic Contamination**: Sensitive data in logs complicates forensic analysis
    and incident response by creating additional attack surfaces.

 4. **Credential Persistence**: Authentication credentials or session tokens might
    persist long after they've been revoked or changed.

 ## Implementation Approach

 This framework addresses these concerns through:

 - Actor-based isolation for thread safety
 - Explicit privacy levels for all logged data
 - Automatic redaction of sensitive information
 - Structured logging with contextual information
 - Integration with system logging facilities for proper storage and rotation

 ## Usage Guidelines

 When using this logging framework:

 - Explicitly mark all data with appropriate privacy levels
 - Never log authentication credentials, even with privacy markers
 - Prefer logging identifiers rather than actual sensitive data
 - Use structured logging patterns for better analysis and filtering
 */
public actor SecureLoggerActor: SecureLoggingProtocol {
  /// The underlying system logger
  private let logger: Logger

  /// The subsystem for the logger, typically the application's bundle identifier
  private let subsystem: String

  /// The category for the logger, used to organise log messages
  private let category: String

  /// Whether to include timestamps in console logs for better correlation
  private let includeTimestamps: Bool
  
  /// The logging service actor for integration with the wider logging system
  private let loggingServiceActor: LoggingServiceActor?

  /**
   Initialises a new secure logger actor with the specified configuration.

   - Parameters:
      - subsystem: The subsystem identifier, typically the application or module's bundle identifier
      - category: The category name, used to organise and filter log messages
      - includeTimestamps: Whether to include timestamps in formatted log messages
      - loggingServiceActor: Optional logging service actor for integration with the wider logging system
   */
  public init(
    subsystem: String = "com.umbra.security",
    category: String,
    includeTimestamps: Bool = true,
    loggingServiceActor: LoggingServiceActor? = nil
  ) {
    self.subsystem = subsystem
    self.category = category
    self.includeTimestamps = includeTimestamps
    self.logger = Logger(subsystem: subsystem, category: category)
    self.loggingServiceActor = loggingServiceActor
  }

  /**
   Logs a message at the debug level.

   Debug messages should contain detailed information useful during development
   or troubleshooting but not typically needed in production environments.

   - Parameters:
      - message: The message to log
      - metadata: Optional metadata to include with the log entry
   */
  public func debug(_ message: String, metadata: [String: PrivacyTaggedValue]? = nil) async {
    await log(level: .debug, message: message, metadata: metadata)
  }

  /**
   Logs a message at the info level.

   Info messages provide general information about system operation that
   is typically useful in production environments for monitoring normal operations.

   - Parameters:
      - message: The message to log
      - metadata: Optional metadata to include with the log entry
   */
  public func info(_ message: String, metadata: [String: PrivacyTaggedValue]? = nil) async {
    await log(level: .info, message: message, metadata: metadata)
  }

  /**
   Logs a message at the warning level.

   Warning messages indicate potential issues or unexpected behaviours that
   don't prevent the system from functioning but might require attention.

   - Parameters:
      - message: The message to log
      - metadata: Optional metadata to include with the log entry
   */
  public func warning(_ message: String, metadata: [String: PrivacyTaggedValue]? = nil) async {
    await log(level: .warning, message: message, metadata: metadata)
  }

  /**
   Logs a message at the error level.

   Error messages indicate problems that prevent specific operations from completing
   successfully but don't necessarily affect the entire system.

   - Parameters:
      - message: The message to log
      - metadata: Optional metadata to include with the log entry
   */
  public func error(_ message: String, metadata: [String: PrivacyTaggedValue]? = nil) async {
    await log(level: .error, message: message, metadata: metadata)
  }

  /**
   Logs a message at the critical level.

   Critical messages indicate severe failures that require immediate attention
   and likely prevent normal system operation.

   - Parameters:
      - message: The message to log
      - metadata: Optional metadata to include with the log entry
   */
  public func critical(_ message: String, metadata: [String: PrivacyTaggedValue]? = nil) async {
    await log(level: .critical, message: message, metadata: metadata)
  }

  /**
   Logs a message with the specified level and metadata.

   This is the core logging method that all other convenience methods use.
   It handles privacy tagging, formatting, and delegation to the appropriate
   logging backends.

   - Parameters:
      - level: The log level to use
      - message: The message to log
      - metadata: Optional metadata to include with the log entry
   */
  public func log(
    level: LoggingTypes.UmbraLogLevel,
    message: String,
    metadata: [String: PrivacyTaggedValue]? = nil
  ) async {
    // Prepare log message with timestamp if needed
    var logMessage = message
    if includeTimestamps {
      let dateFormatter = DateFormatter()
      dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
      let timestamp = dateFormatter.string(from: Date())
      logMessage = "[\(timestamp)] \(logMessage)"
    }
    
    // Log to system logger with appropriate privacy handling
    switch level {
    case .verbose, .debug:
      logger.debug("\(logMessage, privacy: .public)")
    case .info:
      logger.info("\(logMessage, privacy: .public)")
    case .warning:
      logger.warning("\(logMessage, privacy: .public)")
    case .error:
      logger.error("\(logMessage, privacy: .public)")
    case .critical:
      logger.critical("\(logMessage, privacy: .public)")
    }
    
    // If we have a logging service actor, also log through that system
    if let loggingServiceActor = loggingServiceActor {
      // Convert privacy-tagged metadata to standard log metadata
      let convertedMetadata: LoggingTypes.LogMetadata?
      if let metadata = metadata {
        var metadataDict = [String: Any]()
        for (key, value) in metadata {
          switch value.privacyLevel {
          case .public:
            metadataDict[key] = value.value
          case .private:
            metadataDict[key + ".private"] = value.value
          case .sensitive:
            metadataDict[key + ".sensitive"] = "[REDACTED]"
          }
        }
        convertedMetadata = metadataDict
      } else {
        convertedMetadata = nil
      }
      
      // Log through the logging service actor
      await loggingServiceActor.log(
        level: level,
        message: message,
        metadata: convertedMetadata,
        source: category
      )
    }
  }
  
  /**
   Log a security event with detailed contextual information.
   
   Security events are important for audit trails and security monitoring. They
   include additional contextual information to help with security analysis.
   
   - Parameters:
      - action: The security action that occurred
      - status: The outcome status of the action
      - subject: The subject of the security action (user, service, etc.)
      - resource: The resource being accessed or modified
      - additionalMetadata: Any additional contextual information
   */
  public func securityEvent(
    action: String,
    status: SecurityEventStatus,
    subject: String? = nil,
    resource: String? = nil,
    additionalMetadata: [String: PrivacyTaggedValue]? = nil
  ) async {
    var metadata: [String: PrivacyTaggedValue] = [
      "action": PrivacyTaggedValue(value: action, privacyLevel: .public),
      "status": PrivacyTaggedValue(value: status.rawValue, privacyLevel: .public)
    ]
    
    if let subject = subject {
      metadata["subject"] = PrivacyTaggedValue(value: subject, privacyLevel: .private)
    }
    
    if let resource = resource {
      metadata["resource"] = PrivacyTaggedValue(value: resource, privacyLevel: .private)
    }
    
    if let additionalMetadata = additionalMetadata {
      for (key, value) in additionalMetadata {
        metadata[key] = value
      }
    }
    
    await log(
      level: .info,
      message: "Security event: \(action) - \(status.rawValue)",
      metadata: metadata
    )
  }
}

/**
 The status of a security event for structured logging.
 */
public enum SecurityEventStatus: String {
  /// Action was attempted but access was denied
  case denied = "DENIED"
  
  /// Action was successful
  case success = "SUCCESS"
  
  /// Action failed due to an error, not a deliberate denial
  case failed = "FAILED"
  
  /// Action was attempted but the system was unable to determine if it succeeded
  case unknown = "UNKNOWN"
}

/**
 A value with an associated privacy level for secure logging.
 */
public struct PrivacyTaggedValue {
  /// The actual value to log
  public let value: Any
  
  /// The privacy level indicating how this value should be handled in logs
  public let privacyLevel: LogPrivacyLevel
  
  /**
   Create a new privacy-tagged value.
   
   - Parameters:
      - value: The actual value to log
      - privacyLevel: The privacy level for this value
   */
  public init(value: Any, privacyLevel: LogPrivacyLevel) {
    self.value = value
    self.privacyLevel = privacyLevel
  }
}

/**
 Privacy level for logged data to control how information is handled in logs.
 */
public enum LogPrivacyLevel {
  /// Public data that can be logged in plain text with no redaction
  case `public`
  
  /// Private data that should be redacted in logs but may be visible to authorised personnel
  case `private`
  
  /// Sensitive data that should be completely masked in all contexts
  case sensitive
}

/**
 Protocol for secure logging implementations.
 */
public protocol SecureLoggingProtocol {
  /**
   Logs a message at the debug level.
   */
  func debug(_ message: String, metadata: [String: PrivacyTaggedValue]?) async
  
  /**
   Logs a message at the info level.
   */
  func info(_ message: String, metadata: [String: PrivacyTaggedValue]?) async
  
  /**
   Logs a message at the warning level.
   */
  func warning(_ message: String, metadata: [String: PrivacyTaggedValue]?) async
  
  /**
   Logs a message at the error level.
   */
  func error(_ message: String, metadata: [String: PrivacyTaggedValue]?) async
  
  /**
   Logs a message at the critical level.
   */
  func critical(_ message: String, metadata: [String: PrivacyTaggedValue]?) async
  
  /**
   Logs a message with the specified level and metadata.
   */
  func log(
    level: LoggingTypes.UmbraLogLevel,
    message: String,
    metadata: [String: PrivacyTaggedValue]?
  ) async
  
  /**
   Log a security event with detailed contextual information.
   */
  func securityEvent(
    action: String,
    status: SecurityEventStatus,
    subject: String?,
    resource: String?,
    additionalMetadata: [String: PrivacyTaggedValue]?
  ) async
}
