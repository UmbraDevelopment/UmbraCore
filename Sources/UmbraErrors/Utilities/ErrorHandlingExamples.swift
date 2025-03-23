import ErrorHandlingDomains
import Foundation
import OSLog

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
      throw SecurityError.accessError(message: "Access denied to secure resource")
    }
  }

  /// Demonstrates error handling with context and underlying errors
  /// - Parameter data: Data to encrypt
  /// - Returns: Encrypted data
  /// - Throws: SecurityError with context if encryption fails
  public func demonstrateContextualErrorHandling(data: Data) throws -> Data {
    do {
      // Simulate encryption operation
      if data.isEmpty {
        // Create an error with additional context
        let context=ErrorContext().adding(key: "dataLength", value: data.count)
          .adding(key: "operation", value: "encryption")

        throw SecurityError.encryptionFailed(
          message: "Cannot encrypt empty data",
          // Include context with the error
          cause: NSError(domain: "com.example", code: -1, userInfo: nil)
        ).with(context: context)
      }

      // Simulate successful encryption
      return Data(data.reversed())
    } catch {
      // Log the error with privacy controls
      logger.error("Encryption failed: \(error, privacy: .private)")
      throw error
    }
  }

  /// Demonstrates using Result type with the error system
  /// - Parameter key: Key identifier
  /// - Returns: Result containing either the key data or an error
  public func demonstrateResultType(key: String) -> Result<Data, SecurityError> {
    // Validate input
    guard !key.isEmpty else {
      return .failure(SecurityError.invalidKey(message: "Key cannot be empty"))
    }

    // Simulate key retrieval
    if key == "master" {
      return .failure(
        SecurityError.unauthorisedAccess(
          message: "Attempted to access master key",
          file: #file,
          line: #line,
          function: #function
        )
      )
    }

    // Success case
    return .success(Data(key.utf8))
  }

  /// Demonstrates error mapping between different error domains
  /// - Parameter error: An error from any domain
  /// - Returns: A mapped security error if applicable
  public func demonstrateErrorMapping(_ error: Error) -> Error {
    // Register mappers if not already registered
    registerSecurityErrorMappers()

    // Use the ErrorRegistry to map the error
    if let securityError=error.mapped(to: SecurityError.self) {
      // We successfully mapped to our new SecurityError type
      return securityError
    } else if let legacyError=error.mapped(to: CoreErrors.SecurityError.self) {
      // We mapped to the legacy SecurityError type
      // Now map it to our enhanced type
      let enhancedError=securityErrorMapper.mapReverse(legacyError)

      // Add context information during mapping
      return enhancedError.with(
        context: ErrorContext.withMessage("Mapped from legacy error")
      )
    }

    // If we can't map it, wrap the error
    return ErrorFactory.wrapError(
      error,
      domain: SecurityErrorDomain.domain,
      code: SecurityErrorDomain.secureStorageFailure.rawValue,
      description: "Unknown error occurred in security operation"
    )
  }

  /// Demonstrates proper error recovery techniques
  /// - Parameter operation: Closure that may throw an error
  /// - Returns: The result of the operation or a default value on error
  public func demonstrateErrorRecovery<T>(
    _ operation: () throws -> T,
    default defaultValue: T
  ) -> T {
    do {
      return try operation()
    } catch let error as SecurityError where error.errorCode == .decryptionFailed {
      // Handle specific security errors
      logger.warning("Decryption failed, using default value: \(error.errorDescription)")
      return defaultValue
    } catch {
      // Handle any other errors
      logger.error("Operation failed: \(error.localizedDescription)")
      return defaultValue
    }
  }

  /// Demonstrates deferred cleanup with errors
  /// - Parameter resource: Resource identifier
  /// - Throws: SecurityError if the operation fails
  public func demonstrateDeferredCleanup(resource: String) throws {
    // Simulate resource acquisition
    logger.info("Acquiring resource: \(resource)")

    // Use defer for cleanup that should happen regardless of errors
    defer {
      logger.info("Releasing resource: \(resource)")
    }

    // Operation that might fail
    if resource.contains("restricted") {
      throw SecurityError.unauthorisedAccess(
        message: "Cannot access restricted resource: \(resource)"
      )
    }

    // Normal operation
    logger.info("Successfully used resource: \(resource)")
  }

  /// Extension on SecurityError to add convenience initializers
  extension SecurityError {
    /// Creates an unauthorised access error
    fileprivate static func unauthorisedAccess(
      message: String?=nil,
      file: String=#file,
      line: Int=#line,
      function: String=#function
    ) -> SecurityError {
      makeError(
        SecurityError(
          code: .unauthorisedAccess,
          description: message
        ),
        file: file,
        line: line,
        function: function
      )
    }
  }
}
