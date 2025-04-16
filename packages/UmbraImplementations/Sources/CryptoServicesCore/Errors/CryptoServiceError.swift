import CoreSecurityTypes
import Foundation
import SecurityCoreInterfaces

/// CryptoServiceError
///
/// Specialised error type for cryptographic service operations.
///
/// This type provides detailed, context-rich errors for cryptographic operations
/// with specific categories and metadata to help with debugging and error handling.
public struct CryptoServiceError: Error, Equatable, Hashable, Sendable {
  /// Main category of the error
  public let category: ErrorCategory

  /// Specific operation that caused the error
  public let operation: String

  /// Detailed message explaining the error
  public let message: String

  /// Optional underlying error that caused this error
  public let underlyingError: Error?

  /// Additional metadata for debugging purposes
  public let metadata: [String: String]

  /// Initialises a new cryptographic service error.
  ///
  /// - Parameters:
  ///   - category: The error category
  ///   - operation: The operation that caused the error
  ///   - message: Detailed error message
  ///   - underlyingError: Optional underlying error
  ///   - metadata: Additional metadata for debugging
  public init(
    category: ErrorCategory,
    operation: String,
    message: String,
    underlyingError: Error?=nil,
    metadata: [String: String]=[:]
  ) {
    self.category=category
    self.operation=operation
    self.message=message
    self.underlyingError=underlyingError
    self.metadata=metadata
  }

  /// Creates a user-friendly error message.
  ///
  /// - Returns: A message suitable for displaying to users
  public func userFriendlyMessage() -> String {
    switch category {
      case .invalidInput:
        "The operation could not be completed because the input was invalid."
      case .permissionDenied:
        "The operation could not be completed because permission was denied."
      case .keyManagement:
        "A problem occurred while managing cryptographic keys."
      case .dataCorruption:
        "The cryptographic data appears to be corrupted or tampered with."
      case .algorithmFailure:
        "The cryptographic algorithm failed to complete the operation."
      case .resourceUnavailable:
        "A required resource was not available to complete the operation."
      case .unsupportedOperation:
        "This operation is not supported by the current cryptographic implementation."
      case .securityViolation:
        "A security violation was detected during the operation."
      case .providerSpecific:
        "A provider-specific error occurred during the operation."
      case .hardwareFailure:
        "A hardware security component failed during the operation."
      case .internalError:
        "An internal error occurred in the cryptographic service."
    }
  }

  /// Technical details about the error for developers.
  ///
  /// - Returns: A detailed technical message with debugging information
  public func technicalDetails() -> String {
    var details="""
      CryptoServiceError:
      - Category: \(category)
      - Operation: \(operation)
      - Message: \(message)
      """

    if !metadata.isEmpty {
      details += "\n- Metadata:"
      for (key, value) in metadata.sorted(by: { $0.key < $1.key }) {
        details += "\n  - \(key): \(value)"
      }
    }

    if let underlyingError {
      details += "\n- Underlying error: \(String(describing: underlyingError))"
    }

    return details
  }

  /// Maps this error to the appropriate SecurityStorageError
  ///
  /// - Returns: The equivalent SecurityCoreInterfaces.SecurityStorageError
  public func asSecurityStorageError() -> SecurityCoreInterfaces.SecurityStorageError {
    switch category {
      case .invalidInput:
        .invalidInput(message)
      case .permissionDenied:
        .operationFailed("Access denied: \(message)")
      case .keyManagement:
        .keyNotFound
      case .dataCorruption:
        .operationFailed("Data corrupted: \(message)")
      case .algorithmFailure:
        .operationFailed("Algorithm failure: \(message)")
      case .resourceUnavailable:
        .storageUnavailable
      case .unsupportedOperation:
        .unsupportedOperation
      case .securityViolation:
        .operationFailed("Security violation: \(message)")
      case .providerSpecific:
        .operationFailed("Provider error: \(message)")
      case .hardwareFailure:
        .operationFailed("Hardware failure: \(message)")
      case .internalError:
        .operationFailed("Internal error: \(message)")
    }
  }

  /// Equality implementation for Equatable conformance.
  ///
  /// Note: This implementation ignores the underlying error since Error doesn't conform to
  /// Equatable.
  ///
  /// - Parameters:
  ///   - lhs: Left-hand side error
  ///   - rhs: Right-hand side error
  /// - Returns: Whether the errors are equivalent
  public static func == (lhs: CryptoServiceError, rhs: CryptoServiceError) -> Bool {
    lhs.category == rhs.category &&
      lhs.operation == rhs.operation &&
      lhs.message == rhs.message &&
      lhs.metadata == rhs.metadata
  }

  /// Hashable implementation.
  ///
  /// - Parameter hasher: The hasher to use
  public func hash(into hasher: inout Hasher) {
    hasher.combine(category)
    hasher.combine(operation)
    hasher.combine(message)
    hasher.combine(metadata)
  }

  /// Creates an input validation error.
  ///
  /// - Parameters:
  ///   - operation: The operation that detected the invalid input
  ///   - message: Detailed error message
  ///   - metadata: Additional metadata for debugging
  /// - Returns: A configured CryptoServiceError
  public static func invalidInput(
    operation: String,
    message: String,
    metadata: [String: String]=[:]
  ) -> CryptoServiceError {
    CryptoServiceError(
      category: .invalidInput,
      operation: operation,
      message: message,
      metadata: metadata
    )
  }

  /// Creates a permission denied error.
  ///
  /// - Parameters:
  ///   - operation: The operation that was denied
  ///   - message: Detailed error message
  ///   - metadata: Additional metadata for debugging
  /// - Returns: A configured CryptoServiceError
  public static func permissionDenied(
    operation: String,
    message: String,
    metadata: [String: String]=[:]
  ) -> CryptoServiceError {
    CryptoServiceError(
      category: .permissionDenied,
      operation: operation,
      message: message,
      metadata: metadata
    )
  }

  /// Creates a key management error.
  ///
  /// - Parameters:
  ///   - operation: The key management operation that failed
  ///   - message: Detailed error message
  ///   - metadata: Additional metadata for debugging
  /// - Returns: A configured CryptoServiceError
  public static func keyManagement(
    operation: String,
    message: String,
    metadata: [String: String]=[:]
  ) -> CryptoServiceError {
    CryptoServiceError(
      category: .keyManagement,
      operation: operation,
      message: message,
      metadata: metadata
    )
  }

  /// Creates a data corruption error.
  ///
  /// - Parameters:
  ///   - operation: The operation that detected corruption
  ///   - message: Detailed error message
  ///   - metadata: Additional metadata for debugging
  /// - Returns: A configured CryptoServiceError
  public static func dataCorruption(
    operation: String,
    message: String,
    metadata: [String: String]=[:]
  ) -> CryptoServiceError {
    CryptoServiceError(
      category: .dataCorruption,
      operation: operation,
      message: message,
      metadata: metadata
    )
  }

  /// Creates an algorithm failure error.
  ///
  /// - Parameters:
  ///   - operation: The operation where the algorithm failed
  ///   - message: Detailed error message
  ///   - underlyingError: Optional underlying error
  ///   - metadata: Additional metadata for debugging
  /// - Returns: A configured CryptoServiceError
  public static func algorithmFailure(
    operation: String,
    message: String,
    underlyingError: Error?=nil,
    metadata: [String: String]=[:]
  ) -> CryptoServiceError {
    CryptoServiceError(
      category: .algorithmFailure,
      operation: operation,
      message: message,
      underlyingError: underlyingError,
      metadata: metadata
    )
  }

  /// Creates a resource unavailable error.
  ///
  /// - Parameters:
  ///   - operation: The operation requiring the resource
  ///   - message: Detailed error message
  ///   - metadata: Additional metadata for debugging
  /// - Returns: A configured CryptoServiceError
  public static func resourceUnavailable(
    operation: String,
    message: String,
    metadata: [String: String]=[:]
  ) -> CryptoServiceError {
    CryptoServiceError(
      category: .resourceUnavailable,
      operation: operation,
      message: message,
      metadata: metadata
    )
  }

  /// Creates an unsupported operation error.
  ///
  /// - Parameters:
  ///   - operation: The unsupported operation
  ///   - message: Detailed error message
  ///   - metadata: Additional metadata for debugging
  /// - Returns: A configured CryptoServiceError
  public static func unsupportedOperation(
    operation: String,
    message: String,
    metadata: [String: String]=[:]
  ) -> CryptoServiceError {
    CryptoServiceError(
      category: .unsupportedOperation,
      operation: operation,
      message: message,
      metadata: metadata
    )
  }

  /// Creates a security violation error.
  ///
  /// - Parameters:
  ///   - operation: The operation where the violation was detected
  ///   - message: Detailed error message
  ///   - metadata: Additional metadata for debugging
  /// - Returns: A configured CryptoServiceError
  public static func securityViolation(
    operation: String,
    message: String,
    metadata: [String: String]=[:]
  ) -> CryptoServiceError {
    CryptoServiceError(
      category: .securityViolation,
      operation: operation,
      message: message,
      metadata: metadata
    )
  }

  /// Creates a provider-specific error.
  ///
  /// - Parameters:
  ///   - provider: The provider name
  ///   - operation: The operation that failed
  ///   - message: Detailed error message
  ///   - underlyingError: Optional underlying error
  ///   - metadata: Additional metadata for debugging
  /// - Returns: A configured CryptoServiceError
  public static func providerSpecific(
    provider: String,
    operation: String,
    message: String,
    underlyingError: Error?=nil,
    metadata: [String: String]=[:]
  ) -> CryptoServiceError {
    var updatedMetadata=metadata
    updatedMetadata["provider"]=provider

    return CryptoServiceError(
      category: .providerSpecific,
      operation: operation,
      message: message,
      underlyingError: underlyingError,
      metadata: updatedMetadata
    )
  }

  /// Creates a hardware failure error.
  ///
  /// - Parameters:
  ///   - operation: The operation that encountered hardware failure
  ///   - message: Detailed error message
  ///   - metadata: Additional metadata for debugging
  /// - Returns: A configured CryptoServiceError
  public static func hardwareFailure(
    operation: String,
    message: String,
    metadata: [String: String]=[:]
  ) -> CryptoServiceError {
    CryptoServiceError(
      category: .hardwareFailure,
      operation: operation,
      message: message,
      metadata: metadata
    )
  }

  /// Creates an internal error.
  ///
  /// - Parameters:
  ///   - operation: The operation with the internal error
  ///   - message: Detailed error message
  ///   - underlyingError: Optional underlying error
  ///   - metadata: Additional metadata for debugging
  /// - Returns: A configured CryptoServiceError
  public static func internalError(
    operation: String,
    message: String,
    underlyingError: Error?=nil,
    metadata: [String: String]=[:]
  ) -> CryptoServiceError {
    CryptoServiceError(
      category: .internalError,
      operation: operation,
      message: message,
      underlyingError: underlyingError,
      metadata: metadata
    )
  }

  /// Main categories of cryptographic errors
  public enum ErrorCategory: String, Equatable, Hashable, Sendable, CaseIterable {
    /// Invalid input parameters
    case invalidInput

    /// Permission or access denied
    case permissionDenied

    /// Key creation, storage, or retrieval issues
    case keyManagement

    /// Data appears to be corrupted or tampered with
    case dataCorruption

    /// Failure in cryptographic algorithm execution
    case algorithmFailure

    /// Required resource is unavailable
    case resourceUnavailable

    /// Operation not supported by this implementation
    case unsupportedOperation

    /// Security violation detected
    case securityViolation

    /// Provider-specific error
    case providerSpecific

    /// Hardware security component failure
    case hardwareFailure

    /// Internal implementation error
    case internalError
  }
}
