import CoreSecurityTypes
import Foundation
import LoggingInterfaces
import LoggingTypes
import LoggingServices

/// Helper function to create LogMetadataDTOCollection from dictionary
private func createLogMetadataCollection(_ dict: [String: String]) -> LogMetadataDTOCollection {
  var metadataCollection = LogMetadataDTOCollection()
  for (key, value) in dict {
    metadataCollection = metadataCollection.withPublic(key: key, value: value)
  }
  return metadataCollection
}

/// Helper function to convert metadata to privacy-tagged values for security events
private func createSecurityEventMetadata(_ metadata: [String: (value: String, privacyLevel: LogPrivacyLevel)]) -> [String: PrivacyTaggedValue] {
  var result: [String: PrivacyTaggedValue] = [:]
  
  for (key, entry) in metadata {
    result[key] = PrivacyTaggedValue(
      value: entry.privacyLevel == .public && Int(entry.value) != nil 
        ? PrivacyMetadataValue.int(Int(entry.value)!) 
        : PrivacyMetadataValue.string(entry.value),
      privacyLevel: entry.privacyLevel
    )
  }
  
  return result
}

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
   Handles a security operation error with appropriate logging and metrics
   
   - Parameters:
     - error: The error that occurred
     - operation: The security operation that was being performed
     - operationID: Unique identifier for the operation instance
     - duration: Duration of the operation before it failed
   */
  func handleOperationError(
    _ error: Error,
    operation: SecurityOperation,
    operationID: String,
    duration: Double
  ) async {
    // Calculate duration before failure
    let duration=Date().timeIntervalSince(startTime) * 1000

    // Create error metadata for logging
    let errorMetadata=createLogMetadataCollection([
      "operationId": operationID,
      "operation": operation.rawValue,
      "durationMs": String(format: "%.2f", duration),
      "errorType": String(describing: type(of: error)),
      "errorMessage": sanitizeErrorMessage(error.localizedDescription)
    ])

    // Log the error with appropriate context
    await logger.error(
      "Security operation failed: \(operation.description) - \(error.localizedDescription)", 
      metadata: errorMetadata,
      source: "SecurityImplementation"
    )

    // Log with secure logger for enhanced privacy awareness
    await secureLogger.securityEvent(
      action: "SecurityOperationError",
      status: .failed,
      subject: nil,
      resource: nil,
      additionalMetadata: createSecurityEventMetadata([
        "operationId": (value: operationID, privacyLevel: .public),
        "operation": (value: operation.rawValue, privacyLevel: .public),
        "durationMs": (value: String(Int(duration)), privacyLevel: .public),
        "errorType": (value: String(describing: type(of: error)), privacyLevel: .public),
        "errorDescription": (value: sanitizeErrorMessage(error.localizedDescription), privacyLevel: .sensitive)
      ])
    )

    // Return a standardised error result
    return createErrorResult(error: error, duration: duration)
  }

  /**
   Creates standardised metadata for error logging
   
   - Parameters:
     - error: The error that occurred
     - operation: The security operation that was being performed
     - operationID: Unique identifier for the operation instance
     - duration: Duration of the operation before it failed
   - Returns: Metadata for logging
   */
  private func createErrorMetadata(
    error: Error,
    operation: SecurityOperation,
    operationID: String,
    duration: Double
  ) -> LogMetadataDTOCollection {
    return createLogMetadataCollection([
      "operationId": operationID,
      "operation": operation.rawValue,
      "durationMs": String(format: "%.2f", duration),
      "errorType": String(describing: type(of: error)),
      "errorMessage": sanitizeErrorMessage(error.localizedDescription)
    ])
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

    return SecurityResultDTO.failure(errorDetails: "Operation failed", executionTimeMs: duration, metadata: ["errorType": String(describing: type(of: error)),
        "errorMessage": safeErrorMessage,
        "durationMs": String(format: "%.2f", duration)])
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
    // Create standard metadata
    let standardMetadata = createLogMetadataCollection([
      "operationId": operationID,
      "operation": operation.rawValue,
      "durationMs": String(format: "%.2f", duration),
      "errorType": String(describing: type(of: error)),
      "errorMessage": sanitizeErrorMessage(error.localizedDescription)
    ])

    // Log the error
    await logger.error(
      "Security error in \(operation.description): \(sanitizeErrorMessage(error.localizedDescription))", 
      metadata: standardMetadata,
      source: "SecurityImplementation"
    )

    // Create privacy-tagged metadata for secure logger
    var secureMetadata: [String: (value: String, privacyLevel: LogPrivacyLevel)] = [
      "errorType": (value: String(describing: type(of: error)), privacyLevel: .public),
      "operation": (value: operation.rawValue, privacyLevel: .public),
      "errorDescription": (value: error.localizedDescription, privacyLevel: .sensitive)
    ]

    // Add context with privacy tagging
    for (key, value) in context {
      secureMetadata[key] = (value: value, privacyLevel: .public)
    }

    // Add sensitive data with appropriate privacy levels
    for (key, value) in sensitiveData {
      secureMetadata[key] = (value: String(describing: value), privacyLevel: .sensitive)
    }

    // Log with secure logger for enhanced privacy awareness
    await secureLogger.securityEvent(
      action: "SecurityError",
      status: .failed,
      subject: nil,
      resource: nil,
      additionalMetadata: createSecurityEventMetadata(secureMetadata)
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
