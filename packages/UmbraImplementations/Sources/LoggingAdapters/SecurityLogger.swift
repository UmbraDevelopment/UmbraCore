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
   Create a new security logger

   - Parameter loggingService: The underlying logging service to use
   */
  public init(loggingService: LoggingServiceProtocol) {
    self.loggingService=loggingService
    secureLogger=SecureLoggerActor(
      subsystem: "com.umbra.security",
      category: "SecurityOperations",
      includeTimestamps: true,
      loggingServiceActor: nil
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
   Log a security-related audit event

   - Parameters:
     - message: The audit message
     - metadata: Additional metadata for the audit event
     - source: The source of the event
   */
  public func auditLog(
    _ message: String,
    metadata: LogMetadata?=nil,
    source: String?=nil
  ) async {
    // Add domain tagging
    let formattedMessage="[\(domainName)] [AUDIT] \(message)"
    let auditSource=source ?? domainName

    // Log with high visibility as both info (for monitoring) and security event
    await loggingService.info(formattedMessage, metadata: metadata, source: auditSource)

    // Also record as a security event for security monitoring
    await secureLogger.securityEvent(
      action: "audit_logged",
      status: .success,
      subject: nil,
      resource: auditSource,
      additionalMetadata: nil
    )
  }

  /// Enum representing access status for security operations
  public enum AccessStatus {
    case granted
    case denied
  }

  /**
   Log a security access event

   - Parameters:
     - status: The access status (success, denied)
     - subject: The subject requesting access
     - resource: The resource being accessed
     - metadata: Additional metadata about the access
   */
  public func accessLog(
    status: AccessStatus,
    subject: String,
    resource: String,
    metadata: LogMetadata?=nil
  ) async {
    let statusString=switch status {
      case .granted: "granted"
      case .denied: "denied"
    }

    // Constructed message with key details
    let message="Access \(statusString) for \(subject) to \(resource)"

    // Create standard structured log
    await loggingService.info("[\(domainName)] \(message)", metadata: metadata, source: domainName)

    // Create security event with proper tagging
    await secureLogger.securityEvent(
      action: "access_logged",
      status: status == .granted ? .success : .denied,
      subject: subject,
      resource: resource,
      additionalMetadata: nil
    )
  }

  /**
   Log an error with domain-specific context

   - Parameters:
     - error: The error to log
     - context: Domain-specific context for the log
     - privacyLevel: The privacy level for the error details
   */
  public func logError(
    _ error: Error,
    context: any LogContextDTO,
    privacyLevel _: PrivacyClassification
  ) async {
    // Log with standard error method
    await loggingService.error(
      "[\(domainName)] Error: \(error.localizedDescription)",
      metadata: context.asLogMetadata(),
      source: context.getSource()
    )

    // We don't currently use the privacy level in this implementation
    // but we keep the parameter for protocol conformance

    // Check if we have an NSError for additional details
    if let _=error as NSError? {
      // No need to add additional metadata here since we're passing nil below
    }

    // Log through secure logger with enhanced privacy controls
    await secureLogger.securityEvent(
      action: "error_logged",
      status: .failed,
      subject: nil,
      resource: context.getSource(),
      additionalMetadata: nil // We don't pass metadata here since the API has changed
    )
  }

  /**
   Log a message with the specified context

   - Parameters:
     - level: The log level
     - message: The message to log
     - context: Additional context information
   */
  public func logWithContext(
    _ level: LogLevel,
    _ message: String,
    context: any LogContextDTO
  ) async {
    let formattedMessage="[\(domainName)] \(message)"

    // Use the appropriate method based on the log level
    switch level {
      case .trace:
        await loggingService.verbose(
          formattedMessage,
          metadata: context.asLogMetadata(),
          source: context.getSource()
        )
      case .debug:
        await loggingService.debug(
          formattedMessage,
          metadata: context.asLogMetadata(),
          source: context.getSource()
        )
      case .info:
        await loggingService.info(
          formattedMessage,
          metadata: context.asLogMetadata(),
          source: context.getSource()
        )
      case .warning:
        await loggingService.warning(
          formattedMessage,
          metadata: context.asLogMetadata(),
          source: context.getSource()
        )
      case .error:
        await loggingService.error(
          formattedMessage,
          metadata: context.asLogMetadata(),
          source: context.getSource()
        )
      case .critical:
        await loggingService.critical(
          formattedMessage,
          metadata: context.asLogMetadata(),
          source: context.getSource()
        )
    }

    // Also log through secure logger with privacy controls
    let secureLevel: UmbraLogLevel=switch level {
      case .trace, .debug: .debug
      case .info: .info
      case .warning: .warning
      case .error: .error
      case .critical: .critical
    }

    // Pass to secure logger
    await secureLogger.log(
      level: secureLevel,
      message: message,
      metadata: nil
    )
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
    // Create security context DTO
    let context=SecurityLogContext(
      operation: operation,
      resource: keyIdentifier,
      status: "started",
      details: details
    )

    // Log with standard logging
    await logWithContext(.info, "Started \(operation) operation", context: context)

    // Log as a security event
    await secureLogger.securityEvent(
      action: "\(operation)_started",
      status: .success,
      subject: nil,
      resource: keyIdentifier,
      additionalMetadata: nil
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
    // Create security context DTO
    let context=SecurityLogContext(
      operation: operation,
      resource: keyIdentifier,
      status: "completed",
      details: details
    )

    // Log with standard logging
    await logWithContext(.info, "Completed \(operation) operation", context: context)

    // Log as a security event
    await secureLogger.securityEvent(
      action: "\(operation)_completed",
      status: .success,
      subject: nil,
      resource: keyIdentifier,
      additionalMetadata: nil
    )
  }

  /**
   Log a security operation failure event.

   - Parameters:
     - keyIdentifier: The identifier of the key being operated on
     - operation: The name of the operation
     - error: The error that caused the failure
     - details: Optional additional details about the operation
   */
  public func logOperationFailure(
    keyIdentifier: String,
    operation: String,
    error: Error,
    details: String?=nil
  ) async {
    // Create security context DTO
    let context=SecurityLogContext(
      operation: operation,
      resource: keyIdentifier,
      status: "failed",
      error: error,
      details: details
    )

    // Log with standard logging
    await logWithContext(
      .error,
      "Failed \(operation) operation: \(error.localizedDescription)",
      context: context
    )

    // Log as a security event
    await secureLogger.securityEvent(
      action: "\(operation)_failed",
      status: .failed,
      subject: nil,
      resource: keyIdentifier,
      additionalMetadata: nil
    )
  }
}

/**
 Security-specific log context implementation complying with LogContextDTO protocol
 */
private struct SecurityLogContext: LogContextDTO {
  // Required properties from LogContextDTO
  let domainName: String="Security"
  let correlationID: String?
  let source: String?="SecurityService"
  let metadata: LogMetadataDTOCollection

  // Additional security-specific properties
  let operation: String
  let resource: String
  let status: String
  let error: Error?
  let details: String?

  init(
    operation: String,
    resource: String,
    status: String,
    error: Error?=nil,
    details: String?=nil,
    correlationID: String?=UUID().uuidString
  ) {
    self.operation=operation
    self.resource=resource
    self.status=status
    self.error=error
    self.details=details
    self.correlationID=correlationID

    // Build metadata collection
    var metadataBuilder=LogMetadataDTOCollection()
    metadataBuilder=metadataBuilder.withPublic(key: "operation", value: operation)
    metadataBuilder=metadataBuilder.withPrivate(key: "resource", value: resource)
    metadataBuilder=metadataBuilder.withPublic(key: "status", value: status)
    metadataBuilder=metadataBuilder.withPublic(
      key: "correlationId",
      value: correlationID ?? UUID().uuidString
    )

    if let details {
      metadataBuilder=metadataBuilder.withPublic(key: "details", value: details)
    }

    if let error {
      metadataBuilder=metadataBuilder.withPrivate(
        key: "errorDescription",
        value: error.localizedDescription
      )

      // Add additional error information if available
      if let nsError=error as NSError? {
        metadataBuilder=metadataBuilder.withPublic(key: "errorCode", value: String(nsError.code))
        metadataBuilder=metadataBuilder.withPublic(key: "errorDomain", value: nsError.domain)
      }
    }

    metadata=metadataBuilder
  }

  func asLogMetadata() -> LogMetadata? {
    var result: [String: Any]=[
      "operation": operation,
      "resource": resource,
      "status": status,
      "correlationId": correlationID ?? UUID().uuidString
    ]

    if let details {
      result["details"]=details
    }

    if let error {
      result["errorDescription"]=error.localizedDescription
    }

    return LogMetadata.from(result)
  }

  func withUpdatedMetadata(_: LogMetadataDTOCollection) -> Self {
    // Create a new context with the same basic properties
    SecurityLogContext(
      operation: operation,
      resource: resource,
      status: status,
      error: error,
      details: details,
      correlationID: correlationID
    )
  }

  func toPrivacyMetadata() -> PrivacyMetadata {
    // Create a simple privacy metadata instance
    PrivacyMetadata()
  }

  func getSource() -> String {
    source ?? "SecurityService"
  }

  func toMetadata() -> LogMetadataDTOCollection {
    metadata
  }
}
