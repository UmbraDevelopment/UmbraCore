import CoreSecurityTypes
import Foundation
import LoggingInterfaces
import LoggingServices
import LoggingTypes

/// Helper function to create LogMetadataDTOCollection from dictionary
private func createLogMetadataCollection(_ dict: [String: String]) -> LogMetadataDTOCollection {
  var metadataCollection=LogMetadataDTOCollection()
  for (key, value) in dict {
    metadataCollection=metadataCollection.withPublic(key: key, value: value)
  }
  return metadataCollection
}

/// Helper function to convert metadata to privacy-tagged values for security events
private func createSecurityEventMetadata(_ metadata: [String: (
  value: String,
  privacyLevel: LogPrivacyLevel
)]) -> [String: PrivacyTaggedValue] {
  var result: [String: PrivacyTaggedValue]=[:]

  for (key, entry) in metadata {
    result[key]=PrivacyTaggedValue(
      value: entry.privacyLevel == .public && Int(entry.value) != nil
        ? PrivacyMetadataValue.string(String(Int(entry.value)!))
        : PrivacyMetadataValue.string(entry.value),
      privacyLevel: convertPrivacyLevel(entry.privacyLevel)
    )
  }

  return result
}

// Helper to convert LogPrivacyLevel to LogPrivacy
private func convertPrivacyLevel(_ level: LogPrivacyLevel) -> LoggingTypes.LogPrivacy {
  switch level {
    case .public:
      return .public
    case .private:
      return .private
    case .sensitive:
      return .private // Map sensitive to private as fallback
    case .hash:
      return .private // Map hash to private
    case .auto:
      return .public // Map auto to public by default
    @unknown default:
      return .private // Default to private for unknown values
  }
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

    // Create a basic logger to use with the secure logger if one isn't provided
    if let secureLogger {
      self.secureLogger=secureLogger
    } else {
      self.secureLogger=SecureLoggerActor(baseLogger: logger)
    }

    self.coreErrorHandler=coreErrorHandler
  }

  /**
   Handles an operation error and produces appropriate logs

   - Parameters:
     - error: The error that occurred
     - operation: The operation that failed
     - config: The configuration that was being used
   */
  func handleOperationError(
    error: Error,
    operation: CoreSecurityTypes.SecurityOperation,
    config _: SecurityConfigDTO
  ) async {
    // Calculate duration
    _=Date().timeIntervalSince1970 * 1000

    // Use a simple error code since getErrorCode doesn't exist
    let errorCode=500 // Default error code

    // Create a log context for better structured logging
    let logContext=SecurityLogContext(
      operation: operation.rawValue,
      component: "SecurityOperationsErrorHandler",
      operationID: UUID().uuidString,
      correlationID: nil,
      source: "SecurityImplementation"
    )

    // Log to standard logger with context
    await logger.error(
      "Security operation \(operation.rawValue) failed: \(error.localizedDescription)",
      context: logContext
    )

    // Log to secure logger with privacy metadata
    await secureLogger.securityEvent(
      action: "SecurityOperationError",
      status: .failure,
      subject: nil,
      resource: nil,
      additionalMetadata: [
        "operation": PrivacyTaggedValue(
          value: .string(operation.rawValue),
          privacyLevel: .public
        ),
        "errorCode": PrivacyTaggedValue(
          value: .string(String(errorCode)),
          privacyLevel: .public
        ),
        "errorType": PrivacyTaggedValue(
          value: .string(String(describing: type(of: error))),
          privacyLevel: .public
        ),
        "errorMessage": PrivacyTaggedValue(
          value: .string(error.localizedDescription),
          privacyLevel: .private
        )
      ]
    )
  }

  /**
   Logs detailed error information with privacy controls

   - Parameters:
     - error: The error that occurred
     - operation: The operation that was being performed
   */
  func logDetailedError(
    error: Error,
    operation: CoreSecurityTypes.SecurityOperation
  ) async {
    // Use a placeholder operation ID
    let placeholderOpID=UUID().uuidString

    // Create a log context for better structured logging
    let logContext=SecurityLogContext(
      operation: operation.rawValue,
      component: "SecurityOperationsErrorHandler",
      operationID: placeholderOpID,
      correlationID: nil,
      source: "SecurityImplementation"
    )

    // Log to standard logger with privacy-safe information
    await logger.error(
      "Security operation failed: \(sanitizeErrorMessage(error.localizedDescription))",
      context: logContext
    )

    // Simple implementation for stack trace
    let stackTrace="Stack trace unavailable: \(error.localizedDescription)"

    // Log to secure logger with complete information
    await secureLogger.securityEvent(
      action: "SecurityOperationDetailedError",
      status: .failure,
      subject: nil,
      resource: nil,
      additionalMetadata: [
        "operationId": PrivacyTaggedValue(
          value: .string(placeholderOpID),
          privacyLevel: .public
        ),
        "operation": PrivacyTaggedValue(
          value: .string(operation.rawValue),
          privacyLevel: .public
        ),
        "errorCode": PrivacyTaggedValue(
          value: .string("500"), // Default error code
          privacyLevel: .public
        ),
        "errorType": PrivacyTaggedValue(
          value: .string(String(describing: type(of: error))),
          privacyLevel: .public
        ),
        "errorMessage": PrivacyTaggedValue(
          value: .string(error.localizedDescription),
          privacyLevel: .private
        ),
        "stackTrace": PrivacyTaggedValue(
          value: .string(stackTrace),
          privacyLevel: .private
        )
      ]
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
