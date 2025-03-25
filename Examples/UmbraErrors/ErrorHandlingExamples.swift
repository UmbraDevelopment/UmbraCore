import ErrorHandlingDomains
import Foundation
import OSLog
import UmbraErrors
import UmbraErrorsCore

// Define our own SecurityError for the examples
public struct SecurityError: UmbraError, Sendable {
  public let domain: String = "Security"
  public let errorCode: SecurityErrorCode
  public let description: String?
  public var errorDescription: String { description ?? errorCode.defaultDescription }
  public var code: String { String(errorCode.rawValue) }
  public var source: ErrorSource?
  public var underlyingError: Error?
  public var context: ErrorContext
  
  public enum SecurityErrorCode: Int, Sendable, CaseIterable {
    case unauthorisedAccess = 1000
    case encryptionFailed = 1001
    case decryptionFailed = 1002
    case invalidKey = 1003
    case accessError = 1004
    
    var defaultDescription: String {
      switch self {
      case .unauthorisedAccess:
        return "Unauthorised access to secure resource"
      case .encryptionFailed:
        return "Failed to encrypt data"
      case .decryptionFailed:
        return "Failed to decrypt data"
      case .invalidKey:
        return "Invalid key provided"
      case .accessError:
        return "Access denied to secure resource"
      }
    }
  }
  
  public init(
    code: SecurityErrorCode,
    description: String? = nil,
    source: ErrorSource? = nil,
    underlyingError: Error? = nil,
    context: ErrorContext = ErrorContext()
  ) {
    self.errorCode = code
    self.description = description
    self.source = source
    self.underlyingError = underlyingError
    self.context = context
  }
  
  public func with(context: ErrorContext) -> SecurityError {
    var copy = self
    copy.context = context
    return copy
  }
  
  public func with(underlyingError: Error) -> SecurityError {
    var copy = self
    copy.underlyingError = underlyingError
    return copy
  }
  
  public func with(source: ErrorSource) -> SecurityError {
    var copy = self
    copy.source = source
    return copy
  }
  
  // Factory methods
  public static func unauthorisedAccess(
    message: String? = nil,
    cause: Error? = nil,
    file: String = #file,
    line: Int = #line,
    function: String = #function
  ) -> SecurityError {
    SecurityError(
      code: .unauthorisedAccess,
      description: message,
      source: ErrorSource(file: file, line: line, function: function),
      underlyingError: cause
    )
  }
  
  public static func encryptionFailed(
    message: String? = nil,
    cause: Error? = nil,
    file: String = #file,
    line: Int = #line,
    function: String = #function
  ) -> SecurityError {
    SecurityError(
      code: .encryptionFailed,
      description: message,
      source: ErrorSource(file: file, line: line, function: function),
      underlyingError: cause
    )
  }
  
  public static func invalidKey(
    message: String? = nil,
    file: String = #file,
    line: Int = #line,
    function: String = #function
  ) -> SecurityError {
    SecurityError(
      code: .invalidKey,
      description: message,
      source: ErrorSource(file: file, line: line, function: function)
    )
  }
  
  public static func accessError(
    message: String? = nil,
    file: String = #file,
    line: Int = #line,
    function: String = #function
  ) -> SecurityError {
    SecurityError(
      code: .accessError,
      description: message,
      source: ErrorSource(file: file, line: line, function: function)
    )
  }
}

/// Example class demonstrating best practices for error handling with the new system
public class ErrorHandlingExamples {
  /// Logger for this class
  private let logger = Logger(subsystem: "com.umbracorp.UmbraCore", category: "ErrorExamples")

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
        var contextInfo = ErrorContext()
        contextInfo = contextInfo.adding(key: "dataLength", value: data.count)
                                 .adding(key: "operation", value: "encryption")
        
        let error = SecurityError.encryptionFailed(
          message: "Cannot encrypt empty data",
          cause: NSError(domain: "com.example", code: -1, userInfo: nil)
        ).with(context: contextInfo)
        
        throw error
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
        SecurityError.unauthorisedAccess(message: "Attempted to access master key")
      )
    }

    // Success case
    return .success(Data(key.utf8))
  }

  /// Demonstrates error mapping between different error domains
  /// - Parameter error: An error from any domain
  /// - Returns: A mapped security error if applicable
  public func demonstrateErrorMapping(_ error: Error) -> Error {
    // Example of simple error handling - just return the error
    if let securityError = error as? SecurityError {
      return securityError
    }
    
    // In a real implementation, you would use proper error mapping
    return SecurityError.accessError(
      message: "Error mapped from: \(String(describing: error))"
    )
  }

  /// Demonstrates using the defer statement for resource cleanup
  /// - Parameter resource: Resource identifier to simulate acquisition
  /// - Throws: SecurityError if resource access is denied
  public func demonstrateDeferredCleanup(resource: String) throws {
    // Simulate resource acquisition
    logger.info("Acquiring resource: \(resource)")

    // Use defer for cleanup that should happen regardless of errors
    defer {
      logger.info("Releasing resource: \(resource)")
    }

    // Simulate conditional failure
    if resource.contains("restricted") {
      throw SecurityError.unauthorisedAccess(message: "Cannot access restricted resource")
    }

    // Normal operation
    logger.info("Successfully used resource: \(resource)")
  }
}
