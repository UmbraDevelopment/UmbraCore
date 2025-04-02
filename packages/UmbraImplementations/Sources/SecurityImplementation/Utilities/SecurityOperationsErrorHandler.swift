import CoreSecurityTypes
import Foundation
import LoggingInterfaces
import LoggingServices
import LoggingTypes

/**
 # Security Operations Error Handler

 Provides operational error handling for security services.
 This utility extends the core SecurityErrorHandler with functionality
 specific to handling errors in the context of security operations.

 ## Benefits

 - Provides standardised operation-specific error handling
 - Creates consistent SecurityResultDTO objects for error conditions
 - Captures performance metrics alongside error information

 ## Privacy-Aware Logging

 Implements privacy-aware error logging through SecureLoggerActor, ensuring that
 sensitive information in error contexts is properly tagged with privacy levels
 according to the Alpha Dot Five architecture principles.
 */
final class SecurityOperationsErrorHandler {
  /**
   The logger instance for recording general errors
   */
  private let logger: LoggingInterfaces.LoggingProtocol

  /**
   The secure logger for privacy-aware logging of sensitive error information

   This logger ensures proper privacy tagging for all security-sensitive error details
   in accordance with Alpha Dot Five architecture principles.
   */
  private let secureLogger: SecureLoggerActor

  /**
   Reference to the core error handler
   */
  private let coreErrorHandler: SecurityErrorHandler

  /**
   Initialises the operations error handler with loggers and core handler

   - Parameters:
       - logger: The logging service to use for general error recording
       - secureLogger: The secure logger for privacy-aware error logging (optional)
       - coreErrorHandler: The core error handler to use for basic error processing
   */
  init(
    logger: LoggingInterfaces.LoggingProtocol,
    secureLogger: SecureLoggerActor?=nil,
    coreErrorHandler: SecurityErrorHandler
  ) {
    self.logger=logger
    self.secureLogger=secureLogger ?? SecureLoggerActor(
      subsystem: "com.umbra.security",
      category: "SecurityOperationsErrorHandler",
      includeTimestamps: true
    )
    self.coreErrorHandler=coreErrorHandler
  }

  /**
   Processes a security operation error and creates an appropriate result with privacy controls

   - Parameters:
       - error: The error that occurred
       - operation: The operation that triggered the error
       - operationID: Unique identifier for the operation
       - startTime: Time when the operation started
   - Returns: A SecurityResultDTO representing the error condition
   */
  func handleOperationError(
    _ error: Error,
    operation: SecurityOperation,
    operationID: String,
    startTime: Date
  ) async -> SecurityResultDTO {
    // Calculate duration before failure
    let duration=Date().timeIntervalSince(startTime) * 1000

    // Create error metadata for logging
    let errorMetadata: LoggingInterfaces.LogMetadata=createErrorMetadata(
      error: error,
      operation: operation,
      operationID: operationID,
      duration: duration
    )

    // Log the error with appropriate context
    await logger.error(
      "Security operation failed: \(operation.description) - \(error.localizedDescription)",
      metadata: errorMetadata
    )

    // Log with secure logger for enhanced privacy awareness
    await secureLogger.securityEvent(
      action: "SecurityOperationError",
      status: .failed,
      subject: nil,
      resource: nil,
      additionalMetadata: [
        "operationId": PrivacyTaggedValue(value: operationID, privacyLevel: .public),
        "operation": PrivacyTaggedValue(value: operation.rawValue, privacyLevel: .public),
        "durationMs": PrivacyTaggedValue(value: Int(duration), privacyLevel: .public),
        "errorType": PrivacyTaggedValue(value: String(describing: type(of: error)),
                                        privacyLevel: .public),
        "errorDescription": PrivacyTaggedValue(value: sanitizeErrorMessage(error
            .localizedDescription), privacyLevel: .restricted)
      ]
    )

    // Return a standardised error result
    return createErrorResult(error: error, duration: duration)
  }

  /**
   Creates metadata for error logging

   - Parameters:
       - error: The error that occurred
       - operation: The operation that triggered the error
       - operationID: Unique identifier for the operation
       - duration: Duration in milliseconds before failure
   - Returns: Structured metadata for logging
   */
  private func createErrorMetadata(
    error: Error,
    operation: SecurityOperation,
    operationID: String,
    duration: Double
  ) -> LoggingInterfaces.LogMetadata {
    [
      "operationId": operationID,
      "operation": operation.rawValue,
      "errorType": "\(type(of: error))",
      "errorMessage": sanitizeErrorMessage(error.localizedDescription),
      "durationMs": String(format: "%.2f", duration)
    ]
  }

  /**
   Creates a standardised error result DTO

   - Parameters:
       - error: The error that occurred
       - duration: Duration in milliseconds before failure
   - Returns: SecurityResultDTO with error information
   */
  private func createErrorResult(
    error: Error,
    duration: Double
  ) -> SecurityResultDTO {
    // Create a safe error message
    let safeErrorMessage=sanitizeErrorMessage(error.localizedDescription)

    return SecurityResultDTO(
      status: .failure,
      data: nil,
      metadata: [
        "errorType": String(describing: type(of: error)),
        "errorMessage": safeErrorMessage,
        "durationMs": String(format: "%.2f", duration)
      ]
    )
  }

  /**
   Logs a detailed security error with privacy controls

   - Parameters:
       - error: The error that occurred
       - operation: The operation that triggered the error
       - context: Additional context about the error
       - sensitiveData: Optional map of sensitive data associated with the error
   */
  func logSecurityError(
    _ error: Error,
    operation: SecurityOperation,
    context: [String: String]=[:],
    sensitiveData: [String: Any]=[:]
  ) async {
    // Log to standard logger with sanitized information
    var standardMetadata: [String: String]=[
      "errorType": String(describing: type(of: error)),
      "operation": operation.rawValue
    ]

    // Add context to standard metadata
    for (key, value) in context {
      standardMetadata[key]=value
    }

    await logger.error(
      "Security error in \(operation.description): \(sanitizeErrorMessage(error.localizedDescription))",
      metadata: standardMetadata
    )

    // Create privacy-tagged metadata for secure logger
    var secureMetadata: [String: PrivacyTaggedValue]=[
      "errorType": PrivacyTaggedValue(value: String(describing: type(of: error)),
                                      privacyLevel: .public),
      "operation": PrivacyTaggedValue(value: operation.rawValue, privacyLevel: .public),
      "errorDescription": PrivacyTaggedValue(value: error.localizedDescription,
                                             privacyLevel: .restricted)
    ]

    // Add context with privacy tagging
    for (key, value) in context {
      secureMetadata[key]=PrivacyTaggedValue(value: value, privacyLevel: .public)
    }

    // Add sensitive data with appropriate privacy levels
    for (key, value) in sensitiveData {
      secureMetadata[key]=PrivacyTaggedValue(value: value, privacyLevel: .sensitive)
    }

    // Log with secure logger for enhanced privacy awareness
    await secureLogger.securityEvent(
      action: "SecurityError",
      status: .failed,
      subject: nil,
      resource: nil,
      additionalMetadata: secureMetadata
    )
  }

  /**
   Sanitises error messages to remove potential sensitive information

   - Parameter message: The original error message
   - Returns: A sanitised version of the message safe for logging
   */
  private func sanitizeErrorMessage(_ message: String) -> String {
    // Check for potential sensitive patterns like keys, tokens, passwords
    if
      message.contains("key") ||
      message.contains("token") ||
      message.contains("password") ||
      message.contains("credential") ||
      message.contains("secret")
    {
      return "[SENSITIVE ERROR DETAILS REDACTED]"
    }

    // For other error messages, return as is
    return message
  }
}
