import CoreSecurityTypes
import Foundation
import LoggingInterfaces
import LoggingTypes
import UmbraErrors

/// Helper function to create LogMetadataDTOCollection from dictionary
private func createMetadataCollection(_ dict: [String: String]) -> LogMetadataDTOCollection {
  var collection=LogMetadataDTOCollection()
  for (key, value) in dict {
    collection=collection.withPublic(key: key, value: value)
  }
  return collection
}

/**
 # SecurityErrorHandler

 Provides standardised error handling for the security subsystem.

 ## Responsibilities

 This class helps map various error types to the domain-specific SecurityError type
 and logs error information using the provided logger.

 ## Usage

 ```swift
 let errorHandler = SecurityErrorHandler(logger: logger)
 let securityError = await errorHandler.handleError(error, operation: .encrypt)
 ```
 */
public struct SecurityErrorHandler {
  /// Logger for recording error information
  private let logger: LoggingProtocol

  /**
   Initialises a new SecurityErrorHandler with the specified logger.

   - Parameter logger: The logger to use for recording errors
   */
  public init(logger: LoggingProtocol) {
    self.logger=logger
  }

  /**
   Maps and logs an error that occurred during a security operation.

   - Parameters:
     - error: The original error that occurred
     - operation: The security operation that was being performed
     - source: The source of the error (default: "SecurityErrorHandler")
   - Returns: A SecurityError that can be used for further error handling
   */
  public func handleError(
    _ error: Error,
    operation: SecurityOperation,
    source: String="SecurityErrorHandler"
  ) async -> SecurityError {
    // Map the error to a SecurityError
    let securityError=Self.mapError(error, operation: operation)

    // Create metadata for logging
    let metadata=createMetadataCollection([
      "operation": operation.rawValue,
      "errorCode": securityError.code,
      "errorType": String(describing: type(of: error))
    ])

    // Log the error with appropriate privacy level
    await logger.error(
      "Security operation failed: \(securityError.message)",
      metadata: metadata,
      source: source
    )

    return securityError
  }

  /**
   Maps an error to a SecurityError.

   - Parameters:
     - error: The error to map
     - operation: The security operation that was being performed
   - Returns: A SecurityError
   */
  private static func mapError(_ error: Error, operation: SecurityOperation) -> SecurityError {
    // If it's already a SecurityError, return it
    if let securityError=error as? SecurityError {
      return securityError
    }

    // If it's a CoreSecurityError, map it to a SecurityError
    if let coreError=error as? CoreSecurityError {
      return mapCoreSecurityError(coreError, operation: operation)
    }

    // If it's an NSError, map it to a SecurityError
    if let nsError=error as NSError {
      return mapSecurityFrameworkError(nsError)
    }

    // Default case: create a generic error
    return SecurityError(
      code: "UNKNOWN_ERROR",
      message: "An unknown error occurred during \(operation.rawValue): \(error.localizedDescription)"
    )
  }

  /**
   Maps a CoreSecurityError to a SecurityError.

   - Parameters:
     - error: The CoreSecurityError to map
     - operation: The security operation that was being performed
   - Returns: A SecurityError
   */
  private static func mapCoreSecurityError(
    _ error: CoreSecurityError,
    operation: SecurityOperation
  ) -> SecurityError {
    // Create a SecurityError with appropriate code and message
    SecurityError(
      code: String(describing: error).uppercased(),
      message: "Security operation \(operation.rawValue) failed: \(error.localizedDescription)"
    )
  }

  /**
   Maps an NSError from a security framework to a SecurityError.

   - Parameter error: The NSError to map
   - Returns: A SecurityError
   */
  private static func mapSecurityFrameworkError(_ error: NSError) -> SecurityError {
    switch error.code {
      // Map various error codes to appropriate SecurityError cases
      case -25291, -25292, -25293:
        SecurityError(
          code: "AUTHENTICATION_FAILED",
          message: "Authentication failed: \(error.localizedDescription)"
        )
      case -25294, -25295:
        SecurityError(
          code: "ACCESS_DENIED",
          message: "Access denied: \(error.localizedDescription)"
        )
      case -25296, -25297, -25298:
        SecurityError(
          code: "INVALID_INPUT",
          message: "Invalid input: \(error.localizedDescription)"
        )
      case -25299, -25300:
        SecurityError(
          code: "OPERATION_FAILED",
          message: "Operation failed: \(error.localizedDescription)"
        )
      default:
        SecurityError(
          code: "SECURITY_FRAMEWORK_ERROR",
          message: "Security framework error (\(error.code)): \(error.localizedDescription)"
        )
    }
  }
}

/**
 # SecurityError

 Represents an error that occurred during a security operation.

 This error type provides detailed information about the failure,
 including a code and message suitable for logging and debugging.
 */
public struct SecurityError: Error, Equatable, Sendable {
  /// A code identifying the type of error
  public let code: String

  /// A human-readable message describing the error
  public let message: String

  /**
   Initialises a new SecurityError.

   - Parameters:
     - code: A code identifying the type of error
     - message: A human-readable message describing the error
   */
  public init(code: String, message: String) {
    self.code=code
    self.message=message
  }
}
