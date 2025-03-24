import Foundation
import OSLog
import UmbraErrorsDomains
import CoreErrors
import ErrorHandlingInterfaces

/// Example class demonstrating best practices for error handling with the new system
public class ErrorHandlingExamples {
  /// Logger for this class
  private let logger=Logger(subsystem: "com.umbracorp.UmbraCore", category: "ErrorExamples")

  /// Demonstrates creating and throwing a simple error
  /// - Parameter shouldFail: Whether the operation should fail
  /// - Throws: SecurityError if shouldFail is true
  public func demonstrateSimpleErrorHandling(shouldFail: Bool) throws {
    if shouldFail {
      // Create a security error with source information automatically captured
      throw UmbraErrorsDomains.SecurityError(code: .accessError)
    }
  }

  /// Demonstrates error handling with context and underlying errors
  /// - Parameter data: Data to encrypt
  public func demonstrateContextAndCauseHandling(data: Data) throws {
    do {
      // Validate inputs
      if data.isEmpty {
        // Create an error with additional context
        let context = ErrorContext(
          source: "EncryptionService",
          operation: "encryption",
          details: "Data length: \(data.count)"
        )
        
        // Create and throw the error with context
        throw UmbraErrorsDomains.SecurityError(
          code: .encryptionFailed,
          description: "Cannot encrypt empty data"
        ).with(context: context)
      }

      // Simulate an encryption operation that might fail
      if arc4random_uniform(2) == 0 {
        throw UmbraErrorsDomains.SecurityError(code: .encryptionFailed)
      }

      logger.info("Encryption successful")
    } catch {
      logger.error("Encryption failed: \(error.localizedDescription)")
      throw error
    }
  }

  /// Demonstrates using Result type for error handling
  /// - Parameters:
  ///   - data: The data to encrypt
  ///   - key: The encryption key
  /// - Returns: Result containing encrypted data or an error
  public func demonstrateResultType(data: Data, key: String) -> Result<Data, Error> {
    // Validate input
    guard !key.isEmpty else {
      return .failure(UmbraErrorsDomains.SecurityError(code: .invalidKey))
    }

    // Simulate encryption with possible error
    let errorProbability = arc4random_uniform(4)
    switch errorProbability {
      case 0:
        return .failure(UmbraErrorsDomains.SecurityError(code: .encryptionFailed))
      case 1:
        return .failure(UmbraErrorsDomains.SecurityError(code: .invalidKey))
      default:
        // Success case
        let encryptedData = Data(data.reversed())
        return .success(encryptedData)
    }
  }

  /// Demonstrates error mapping between different error types
  /// - Parameter error: The error to map
  /// - Returns: The mapped error
  public func demonstrateErrorMapping(_ error: Error) -> Error {
    // For example purposes, we'll just return the original error
    // In a real implementation, you would use error registry and mapping
    return error
  }

  /// Shows how to use defer for resource cleanup
  /// - Parameter resource: A resource identifier
  /// - Throws: SecurityError if there's a problem with the resource
  public func demonstrateDeferredCleanup(resource: String) throws {
    // Simulate resource acquisition
    logger.info("Acquiring resource: \(resource)")

    // Use defer for cleanup that should happen regardless of errors
    defer {
      // This code runs when the function exits, whether normally or due to error
      logger.info("Releasing resource: \(resource)")
    }

    // Simulate an operation that might fail
    if resource.isEmpty {
      logger.error("Invalid resource name")
      throw UmbraErrorsDomains.SecurityError(code: .accessError)
    }

    // Normal operation
    logger.info("Successfully used resource: \(resource)")
  }
}

/// Helper extension on SecurityError to simplify creating errors with context
extension UmbraErrorsDomains.SecurityError {
  /// Adds context to this error
  /// - Parameter context: The context to add
  /// - Returns: The error with context
  func with(context: ErrorContext) -> UmbraErrorsDomains.SecurityError {
    // In a real implementation, this would store the context with the error
    // For this example, we just return self
    return self
  }
}
