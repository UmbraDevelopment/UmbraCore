import Foundation
import LoggingInterfaces
import LoggingServices
import LoggingTypes

/**
 # SecurityLogger

 A specialised domain logger for security operations following
 the Alpha Dot Five architecture principles.

 This actor provides logging functionality specific to security operations,
 with enhanced privacy controls and contextual information. It uses the
 SecureLoggerActor internally for privacy-aware logging.

 ## Security Features

 * Privacy-aware logging with proper data classification
 * Structured metadata for improved analysis
 * Contextual information for security auditing
 * Thread safety through actor isolation

 ## Usage Example

 ```swift
 // Create a security logger
 let loggingService = await LoggingServiceFactory.createDefaultService()
 let securityLogger = SecurityLogger(loggingService: loggingService)

 // Log security operations with proper context
 await securityLogger.logOperationStart(
   keyIdentifier: "master-key",
   operation: "encrypt"
 )

 // Log operation success
 await securityLogger.logOperationSuccess(
   keyIdentifier: "master-key",
   operation: "encrypt",
   details: "Data encrypted successfully"
 )
 ```
 */
public actor SecurityLogger: DomainLoggerProtocol {
  /// The domain name for this logger
  public let domainName: String="Security"

  /// The underlying logging service
  private let loggingService: LoggingServiceProtocol

  /// The secure logger for privacy-aware logging
  private let secureLogger: SecureLoggerActor

  /**
   Creates a new security logger with the specified logging service.

   - Parameter loggingService: The underlying logging service to use
   */
  public init(loggingService: LoggingServiceProtocol) {
    self.loggingService=loggingService
    secureLogger=SecureLoggerActor(
      subsystem: "com.umbra.security",
      category: "SecurityOperations",
      includeTimestamps: true
    )
  }

  /**
   Log a message with the specified level

   - Parameters:
     - level: The log level
     - message: The message to log
   */
  public func log(_ level: LogLevel, _ message: String) async {
    let formattedMessage="[\(domainName)] \(message)"

    // Use the appropriate level-specific method
    switch level {
      case .trace:
        await loggingService.verbose(formattedMessage, metadata: nil, source: domainName)
      case .debug:
        await loggingService.debug(formattedMessage, metadata: nil, source: domainName)
      case .info:
        await loggingService.info(formattedMessage, metadata: nil, source: domainName)
      case .warning:
        await loggingService.warning(formattedMessage, metadata: nil, source: domainName)
      case .error:
        await loggingService.error(formattedMessage, metadata: nil, source: domainName)
      case .critical:
        await loggingService.critical(formattedMessage, metadata: nil, source: domainName)
    }

    // Also log through secure logger for enhanced privacy controls
    let secureLevel: UmbraLogLevel=switch level {
      case .trace, .debug: .debug
      case .info: .info
      case .warning: .warning
      case .error: .error
      case .critical: .critical
    }

    await secureLogger.log(level: secureLevel, message: message, metadata: nil)
  }

  /// Log a message with trace level
  public func trace(_ message: String) async {
    await log(.trace, message)
  }

  /// Log a message with debug level
  public func debug(_ message: String) async {
    await log(.debug, message)
  }

  /// Log a message with info level
  public func info(_ message: String) async {
    await log(.info, message)
  }

  /// Log a message with warning level
  public func warning(_ message: String) async {
    await log(.warning, message)
  }

  /// Log a message with error level
  public func error(_ message: String) async {
    await log(.error, message)
  }

  /// Log a message with critical level
  public func critical(_ message: String) async {
    await log(.critical, message)
  }

  /**
   Log a message with the specified context

   - Parameters:
     - level: The log level
     - message: The message to log
     - context: Additional context information
   */
  public func logWithContext(_ level: LogLevel, _ message: String, context: LogContextDTO) async {
    let formattedMessage="[\(domainName)] \(message)"

    // Convert LogContextDTO to LogMetadata using our extension
    let logMetadata=context.asLogMetadata()

    // Use the appropriate method based on the log level
    switch level {
      case .trace:
        await loggingService.verbose(formattedMessage, metadata: logMetadata, source: domainName)
      case .debug:
        await loggingService.debug(formattedMessage, metadata: logMetadata, source: domainName)
      case .info:
        await loggingService.info(formattedMessage, metadata: logMetadata, source: domainName)
      case .warning:
        await loggingService.warning(formattedMessage, metadata: logMetadata, source: domainName)
      case .error:
        await loggingService.error(formattedMessage, metadata: logMetadata, source: domainName)
      case .critical:
        await loggingService.critical(formattedMessage, metadata: logMetadata, source: domainName)
    }

    // Also log through secure logger with privacy controls
    let secureLevel: UmbraLogLevel=switch level {
      case .trace, .debug: .debug
      case .info: .info
      case .warning: .warning
      case .error: .error
      case .critical: .critical
    }

    // Convert to privacy-tagged metadata
    var privacyMetadata: [String: PrivacyTaggedValue]=[:]
    for (key, value) in context.parameters {
      // Apply privacy tag based on key naming conventions
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

      privacyMetadata[key]=PrivacyTaggedValue(value: value, privacyLevel: privacyLevel)
    }

    await secureLogger.log(level: secureLevel, message: message, metadata: privacyMetadata)
  }

  /**
   Log a security operation start event.

   - Parameters:
     - keyIdentifier: The identifier of the key being operated on
     - operation: The name of the operation
     - details: Optional additional details about the operation
   */
  public func logOperationStart(
    keyIdentifier: String,
    operation: String,
    details: String?=nil
  ) async {
    var context=LogContextDTO()
    context.parameters["keyId"]=keyIdentifier
    context.parameters["operation"]=operation

    if let details {
      context.parameters["details"]=details
    }

    // Log with standard logging
    await logWithContext(.info, "Started \(operation) operation", context: context)

    // Log as a security event with proper privacy controls
    await secureLogger.securityEvent(
      action: operation,
      status: .success,
      subject: nil,
      resource: keyIdentifier,
      additionalMetadata: [
        "phase": PrivacyTaggedValue(value: "start", privacyLevel: .public),
        "details": PrivacyTaggedValue(value: details ?? "N/A", privacyLevel: .public)
      ]
    )
  }

  /**
   Log a security operation success event.

   - Parameters:
     - keyIdentifier: The identifier of the key being operated on
     - operation: The name of the operation
     - details: Optional additional details about the operation
   */
  public func logOperationSuccess(
    keyIdentifier: String,
    operation: String,
    details: String?=nil
  ) async {
    var context=LogContextDTO()
    context.parameters["keyId"]=keyIdentifier
    context.parameters["operation"]=operation
    context.parameters["status"]="success"

    if let details {
      context.parameters["details"]=details
    }

    // Log with standard logging
    await logWithContext(.info, "Successfully completed \(operation) operation", context: context)

    // Log as a security event with proper privacy controls
    await secureLogger.securityEvent(
      action: operation,
      status: .success,
      subject: nil,
      resource: keyIdentifier,
      additionalMetadata: [
        "phase": PrivacyTaggedValue(value: "complete", privacyLevel: .public),
        "details": PrivacyTaggedValue(value: details ?? "N/A", privacyLevel: .public)
      ]
    )
  }

  /**
   Log a security operation error event.

   - Parameters:
     - keyIdentifier: The identifier of the key being operated on
     - operation: The name of the operation
     - error: The error that occurred
     - details: Optional additional details about the operation
   */
  public func logOperationError(
    keyIdentifier: String,
    operation: String,
    error: Error,
    details: String?=nil
  ) async {
    var context=LogContextDTO()
    context.parameters["keyId"]=keyIdentifier
    context.parameters["operation"]=operation
    context.parameters["status"]="error"
    context.parameters["errorDescription"]=error.localizedDescription

    if let details {
      context.parameters["details"]=details
    }

    // Log with standard logging
    await logWithContext(
      .error,
      "Error during \(operation) operation: \(error.localizedDescription)",
      context: context
    )

    // Log as a security event with proper privacy controls
    await secureLogger.securityEvent(
      action: operation,
      status: .failed,
      subject: nil,
      resource: keyIdentifier,
      additionalMetadata: [
        "errorDescription": PrivacyTaggedValue(value: error.localizedDescription,
                                               privacyLevel: .public),
        "details": PrivacyTaggedValue(value: details ?? "N/A", privacyLevel: .public)
      ]
    )
  }
}
