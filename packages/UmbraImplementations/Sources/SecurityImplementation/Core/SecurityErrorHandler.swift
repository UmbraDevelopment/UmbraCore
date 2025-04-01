import CoreSecurityTypes
import Foundation
import LoggingInterfaces
import LoggingTypes
import UmbraErrors

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
     - operation: The security operation during which the error occurred
     - context: Additional context to include in logs
   - Returns: A SecurityError instance representing the mapped error
   */
  public func handleError(
    _ error: Error,
    operation: SecurityOperation,
    context: [String: String]=[:]
  ) async -> SecurityError {
    // Map to a SecurityError if not already
    let securityError=Self.mapError(error)

    // Create log metadata
    var metadata=context
    metadata["operation"]=operation.rawValue
    metadata["errorType"]=String(describing: type(of: error))
    metadata["errorDescription"]=error.localizedDescription

    let logMetadata: LoggingInterfaces.LogMetadata=metadata

    // Log the error with appropriate level based on error type
    switch securityError {
      case .invalidInput, .invalidKey, .invalidData, .invalidDataFormat:
        // User input errors are warnings
        await logger.warning(
          "Security operation failed: \(operation.description) - \(securityError.localizedDescription)",
          metadata: logMetadata
        )
      case .unsupportedOperation:
        // Unsupported operations are errors
        await logger.error(
          "Unsupported security operation attempted: \(operation.description) - \(securityError.localizedDescription)",
          metadata: logMetadata
        )
      case .cryptoError, .keyManagementError, .storageError, .networkError,
           .systemError, .unknownError:
        // System errors are critical security issues
        await logger.error(
          "Critical security failure: \(operation.description) - \(securityError.localizedDescription)",
          metadata: logMetadata
        )
      case .authenticationFailed, .verificationFailed:
        // Authentication errors are important to log
        await logger.error(
          "Security authentication or verification failed: \(operation.description) - \(securityError.localizedDescription)",
          metadata: logMetadata
        )
      case .operationFailed, .serviceUnavailable, .interactionNotAllowed:
        // Operation failures need to be investigated
        await logger.error(
          "Security operation failed: \(operation.description) - \(securityError.localizedDescription)",
          metadata: logMetadata
        )
      case .itemNotFound, .duplicateItem:
        // Item not found or duplicate items are warnings
        await logger.warning(
          "Security item issue: \(operation.description) - \(securityError.localizedDescription)",
          metadata: logMetadata
        )
      case .unspecifiedError:
        // Unspecified errors should be investigated
        await logger.error(
          "Unspecified security error: \(operation.description) - \(securityError.localizedDescription)",
          metadata: logMetadata
        )
    }

    return securityError
  }

  /**
   Maps an arbitrary error to a SecurityError.

   - Parameter error: The error to map
   - Returns: A SecurityError representation
   */
  static func mapError(_ error: Error) -> SecurityError {
    // If it's already a SecurityError, return it directly
    if let securityError=error as? SecurityError {
      return securityError
    }

    // Map other error types to appropriate SecurityError cases
    if let nsError=error as NSError? {
      switch nsError.domain {
        case "Security":
          return mapSecurityFrameworkError(nsError)
        case "Keychain":
          return mapKeychainError(nsError)
        case "Crypto":
          return .cryptoError("Cryptographic error: \(nsError.localizedDescription)")
        case NSURLErrorDomain:
          return .networkError("Network error: \(nsError.localizedDescription)")
        default:
          return .unknownError("Unknown error: \(nsError.localizedDescription)")
      }
    }

    // Default to unknown error
    return .unknownError("Unmapped error: \(error.localizedDescription)")
  }

  /**
   Maps a Security framework error to a SecurityError.

   - Parameter error: The NSError to map
   - Returns: A SecurityError representation
   */
  private static func mapSecurityFrameworkError(_ error: NSError) -> SecurityError {
    switch error.code {
      // Map various error codes to appropriate SecurityError cases
      case -25291, -25292, -25293:
        .authenticationFailed("Authentication failed: \(error.localizedDescription)")
      case -25294, -25295:
        .invalidKey("Invalid key: \(error.localizedDescription)")
      default:
        .systemError("Security framework error: \(error.localizedDescription)")
    }
  }

  /**
   Maps a Keychain error to a SecurityError.

   - Parameter error: The NSError to map
   - Returns: A SecurityError representation
   */
  private static func mapKeychainError(_ error: NSError) -> SecurityError {
    switch error.code {
      case -25300:
        .itemNotFound("Item not found in keychain")
      case -25299:
        .duplicateItem("Duplicate item in keychain")
      case -25308:
        .interactionNotAllowed("Keychain interaction not allowed")
      default:
        .keyManagementError("Keychain error: \(error.localizedDescription)")
    }
  }
}

/**
 # SecurityError

 Domain-specific error type for security operations, following the Alpha Dot Five
 architecture's error handling principles with clear categorisation and detailed messages.
 */
public enum SecurityError: Error, Equatable, Sendable {
  /// Invalid input parameters
  case invalidInput(String)

  /// Invalid cryptographic key
  case invalidKey(String)

  /// Invalid data format
  case invalidData(String)

  /// Invalid data format
  case invalidDataFormat(String)

  /// Authentication failed
  case authenticationFailed(String)

  /// Verification failed
  case verificationFailed(String)

  /// Operation failed
  case operationFailed(String)

  /// Cryptographic error
  case cryptoError(String)

  /// Key management error
  case keyManagementError(String)

  /// Storage error
  case storageError(String)

  /// Network error
  case networkError(String)

  /// Unsupported operation
  case unsupportedOperation(String)

  /// Service unavailable
  case serviceUnavailable(String)

  /// System error
  case systemError(String)

  /// Item not found
  case itemNotFound(String)

  /// Duplicate item
  case duplicateItem(String)

  /// User interaction not allowed
  case interactionNotAllowed(String)

  /// Unknown error
  case unknownError(String)

  /// Unspecified error
  case unspecifiedError(String)

  public static func == (lhs: SecurityError, rhs: SecurityError) -> Bool {
    String(describing: lhs) == String(describing: rhs)
  }
}
