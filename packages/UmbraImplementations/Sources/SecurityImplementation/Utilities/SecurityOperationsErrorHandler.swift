import Foundation
import LoggingInterfaces
import SecurityCoreTypes
import SecurityTypes

/**
 # Security Operations Error Handler

 Provides operational error handling for security services.
 This utility extends the core SecurityErrorHandler with functionality
 specific to handling errors in the context of security operations.

 ## Benefits

 - Provides standardised operation-specific error handling
 - Creates consistent SecurityResultDTO objects for error conditions
 - Captures performance metrics alongside error information
 */
final class SecurityOperationsErrorHandler {
  /**
   The logger instance for recording errors
   */
  private let logger: LoggingInterfaces.LoggingProtocol

  /**
   Reference to the core error handler
   */
  private let coreErrorHandler: SecurityErrorHandler

  /**
   Initialises the operations error handler with a logger

   - Parameters:
       - logger: The logging service to use for error recording
       - coreErrorHandler: The core error handler to use for basic error processing
   */
  init(
    logger: LoggingInterfaces.LoggingProtocol,
    coreErrorHandler: SecurityErrorHandler
  ) {
    self.logger=logger
    self.coreErrorHandler=coreErrorHandler
  }

  /**
   Processes a security operation error and creates an appropriate result

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
      "errorMessage": error.localizedDescription,
      "durationMs": String(format: "%.2f", duration),
      "timestamp": "\(Date())"
    ]
  }

  /**
   Creates a standardised error result object

   - Parameters:
       - error: The error that occurred
       - duration: Duration in milliseconds before failure
   - Returns: A SecurityResultDTO representing the error
   */
  private func createErrorResult(error: Error, duration: Double) -> SecurityResultDTO {
    SecurityResultDTO(
      status: .failure,
      error: error,
      metadata: [
        "durationMs": String(format: "%.2f", duration),
        "errorMessage": error.localizedDescription,
        "errorType": "\(type(of: error))"
      ]
    )
  }
}
