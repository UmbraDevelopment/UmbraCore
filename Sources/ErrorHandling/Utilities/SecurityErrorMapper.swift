import Foundation

// Local type declarations to replace imports
// These replace the removed ErrorHandling and ErrorHandlingDomains imports

/// Error domain namespace
public enum ErrorDomain {
  /// Security domain
  public static let security="Security"
  /// Crypto domain
  public static let crypto="Crypto"
  /// Application domain
  public static let application="Application"
}

/// Error context protocol
public protocol ErrorContext {
  /// Domain of the error
  var domain: String { get }
  /// Code of the error
  var code: Int { get }
  /// Description of the error
  var description: String { get }
}

/// Base error context implementation
public struct BaseErrorContext: ErrorContext {
  /// Domain of the error
  public let domain: String
  /// Code of the error
  public let code: Int
  /// Description of the error
  public let description: String

  /// Initialise with domain, code and description
  public init(domain: String, code: Int, description: String) {
    self.domain=domain
    self.code=code
    self.description=description
  }
}

/// A utility class for mapping security errors between different domains
public class LegacySecurityErrorMapper {
  /// Initialiser for the LegacySecurityErrorMapper
  public init() {}

  /// Maps an external error to a security core error
  /// - Parameter error: The external error to map
  /// - Returns: A mapped security core error, or nil if mapping is not possible
  public func mapToCoreError(_ error: Error) -> UmbraErrors.GeneralSecurity.Core? {
    // Check if the error is already a security error
    if let securityError=error as? UmbraErrors.GeneralSecurity.Core {
      return securityError
    }

    // Extract error information from the external error
    let nsError=error as NSError
    let domain=nsError.domain
    let code=nsError.code

    // Map common error patterns to security core errors

    // Authentication errors
    if domain == "com.auth.error" || domain.contains("authentication") {
      return .invalidInput(reason: "Authentication failed: \(nsError.localizedDescription)")
    }

    // Encryption/decryption errors
    if domain.contains("crypto") || domain.contains("encryption") {
      if code == -1 {
        return .encryptionFailed(
          reason: "Encryption operation failed: \(nsError.localizedDescription)"
        )
      } else if code == -2 {
        return .decryptionFailed(
          reason: "Decryption operation failed: \(nsError.localizedDescription)"
        )
      } else if code == -3 {
        return .keyGenerationFailed(
          reason: "Key generation failed: \(nsError.localizedDescription)"
        )
      }
    }

    // Timeout errors
    if domain.contains("timeout") || nsError.localizedDescription.contains("timed out") {
      return .timeout(operation: "Security operation")
    }

    // Hash verification errors
    if domain.contains("hash") || domain.contains("verification") {
      return .hashVerificationFailed(
        reason: "Hash verification failed: \(nsError.localizedDescription)"
      )
    }

    // Default to internal error if no specific mapping is found
    return .internalError("Unmapped external error: \(nsError.localizedDescription)")
  }

  /// Maps a security core error to a generic error
  /// - Parameter error: The security core error to map
  /// - Returns: A generic error representation
  public func mapToGenericError(
    _ error: UmbraErrors.GeneralSecurity
      .Core
  ) -> ErrorHandlingInterfaces.UmbraError {
    let source=ErrorHandlingInterfaces.ErrorSource(
      file: #file,
      line: #line,
      function: #function
    )

    let context=ErrorHandlingInterfaces.ErrorContext(
      source: "SecurityModule",
      operation: "SecurityOperation",
      details: "Mapped from security core error"
    )

    // Create a generic error with appropriate details
    return SecurityGenericError(
      domain: "Security",
      code: String(describing: error),
      message: getErrorMessage(from: error),
      details: [:],
      source: source,
      underlyingError: error,
      context: context
    )
  }

  /// Extracts a user-friendly message from a security core error
  /// - Parameter error: The security core error
  /// - Returns: A user-friendly error message
  private func getErrorMessage(from error: UmbraErrors.GeneralSecurity.Core) -> String {
    switch error {
      case let .encryptionFailed(reason):
        return "Encryption failed: \(reason)"
      case let .decryptionFailed(reason):
        return "Decryption failed: \(reason)"
      case let .keyGenerationFailed(reason):
        return "Key generation failed: \(reason)"
      case let .invalidKey(reason):
        return "Invalid key: \(reason)"
      case let .hashVerificationFailed(reason):
        return "Hash verification failed: \(reason)"
      case let .randomGenerationFailed(reason):
        return "Random generation failed: \(reason)"
      case let .invalidInput(reason):
        return "Invalid input: \(reason)"
      case let .storageOperationFailed(reason):
        return "Storage operation failed: \(reason)"
      case let .timeout(operation):
        return "Operation timed out: \(operation)"
      case let .serviceError(code, reason):
        return "Service error \(code): \(reason)"
      case let .internalError(message):
        return "Internal error: \(message)"
      case let .notImplemented(feature):
        return "Not implemented: \(feature)"
      @unknown default:
        return "Unknown security error: \(error)"
    }
  }
}

/// A generic error implementation that conforms to UmbraError
private struct SecurityGenericError: ErrorHandlingInterfaces.UmbraError, Sendable {
  let domain: String
  let code: String
  let message: String
  let details: [String: String]
  let source: ErrorHandlingInterfaces.ErrorSource?
  var underlyingError: Error?
  var context: ErrorHandlingInterfaces.ErrorContext

  /// Initialiser with all properties
  init(
    domain: String,
    code: String,
    message: String,
    details: [String: String],
    source: ErrorHandlingInterfaces.ErrorSource?,
    underlyingError: Error?,
    context: ErrorHandlingInterfaces.ErrorContext
  ) {
    self.domain=domain
    self.code=code
    self.message=message
    self.details=details
    self.source=source
    self.underlyingError=underlyingError
    self.context=context
  }

  /// Conform to CustomStringConvertible
  var description: String {
    message
  }

  /// A user-friendly error message (required by UmbraError)
  var errorDescription: String {
    message
  }

  /// Create a new instance with additional context
  func with(context: ErrorHandlingInterfaces.ErrorContext) -> Self {
    var newError=self
    newError.context=context
    return newError
  }

  /// Create a new instance with an underlying error
  func with(underlyingError: Error) -> Self {
    var newError=self
    newError.underlyingError=underlyingError
    return newError
  }

  /// Create a new instance with source information
  func with(source: ErrorHandlingInterfaces.ErrorSource) -> Self {
    SecurityGenericError(
      domain: domain,
      code: code,
      message: message,
      details: details,
      source: source,
      underlyingError: underlyingError,
      context: context
    )
  }
}
