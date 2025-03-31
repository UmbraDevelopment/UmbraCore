import Foundation

import UmbraErrorsCore

/// Domain identifier for key manager errors
public enum KeyManagerErrorDomain: String, CaseIterable, Sendable {
  /// Domain identifier
  public static let domain="KeyManager"

  // Error codes within the key manager domain
  case keyNotFound="KEY_NOT_FOUND"
  case invalidKeyFormat="INVALID_KEY_FORMAT"
  case keyGenerationFailed="KEY_GENERATION_FAILED"
  case keyStorageFailed="KEY_STORAGE_FAILED"
  case keyDeletionFailed="KEY_DELETION_FAILED"
  case keyRetrievalFailed="KEY_RETRIEVAL_FAILED"
  case accessDenied="ACCESS_DENIED"
  case generalFailure="GENERAL_FAILURE"
}

/// Enhanced implementation of a KeyManagerError
public struct KeyManagerError: UmbraError {
  /// Domain identifier
  public let domain: String=KeyManagerErrorDomain.domain

  /// The type of key manager error
  public enum ErrorType: Sendable, Equatable {
    /// Key not found
    case keyNotFound
    /// Invalid key format
    case invalidKeyFormat
    /// Key generation failed
    case keyGenerationFailed
    /// Key storage failed
    case keyStorageFailed
    /// Key deletion failed
    case keyDeletionFailed
    /// Key retrieval failed
    case keyRetrievalFailed
    /// Access denied
    case accessDenied
    /// General failure
    case generalFailure
  }

  /// The specific error type
  public let type: ErrorType

  /// Error code used for serialisation and identification
  public let code: String

  /// Human-readable description of the error
  public let description: String

  /// Additional context information about the error
  public let context: ErrorContext

  /// The underlying error, if any
  public let underlyingError: Error?

  /// Source information about where the error occurred
  public let source: ErrorSource?

  /// Human-readable description of the error (UmbraError protocol requirement)
  public var errorDescription: String {
    if let details=context.typedValue(for: "details") as String?, !details.isEmpty {
      return "\(description): \(details)"
    }
    return description
  }

  /// Creates a formatted description of the error
  public var localizedDescription: String {
    if let details=context.typedValue(for: "details") as String?, !details.isEmpty {
      return "\(description): \(details)"
    }
    return description
  }

  /// Creates a new KeyManagerError
  /// - Parameters:
  ///   - type: The error type
  ///   - code: The error code
  ///   - description: Human-readable description
  ///   - context: Additional context information
  ///   - underlyingError: Optional underlying error
  ///   - source: Optional source information
  public init(
    type: ErrorType,
    code: String,
    description: String,
    context: ErrorContext=ErrorContext(),
    underlyingError: Error?=nil,
    source: ErrorSource?=nil
  ) {
    self.type=type
    self.code=code
    self.description=description
    self.context=context
    self.underlyingError=underlyingError
    self.source=source
  }

  /// Creates a new instance of the error with additional context
  public func with(context: ErrorContext) -> KeyManagerError {
    KeyManagerError(
      type: type,
      code: code,
      description: description,
      context: context,
      underlyingError: underlyingError,
      source: source
    )
  }

  /// Creates a new instance of the error with a specified underlying error
  public func with(underlyingError: Error) -> KeyManagerError {
    KeyManagerError(
      type: type,
      code: code,
      description: description,
      context: context,
      underlyingError: underlyingError,
      source: source
    )
  }

  /// Creates a new instance of the error with source information
  public func with(source: ErrorSource) -> KeyManagerError {
    KeyManagerError(
      type: type,
      code: code,
      description: description,
      context: context,
      underlyingError: underlyingError,
      source: source
    )
  }
}

/// Convenience functions for creating specific key manager errors
extension KeyManagerError {
  /// Creates a key not found error
  /// - Parameters:
  ///   - keyId: The ID of the key that was not found
  ///   - context: Additional context information
  ///   - underlyingError: Optional underlying error
  /// - Returns: A fully configured KeyManagerError
  public static func keyNotFound(
    keyID: String,
    context: [String: Any]=[:],
    underlyingError: Error?=nil
  ) -> KeyManagerError {
    var contextDict=context
    contextDict["keyId"]=keyID
    contextDict["details"]="Key with ID '\(keyID)' was not found"

    let errorContext=ErrorContext(contextDict)

    return KeyManagerError(
      type: .keyNotFound,
      code: KeyManagerErrorDomain.keyNotFound.rawValue,
      description: "Key not found",
      context: errorContext,
      underlyingError: underlyingError
    )
  }

  /// Creates an invalid key format error
  /// - Parameters:
  ///   - format: The expected format
  ///   - context: Additional context information
  ///   - underlyingError: Optional underlying error
  /// - Returns: A fully configured KeyManagerError
  public static func invalidKeyFormat(
    format: String,
    context: [String: Any]=[:],
    underlyingError: Error?=nil
  ) -> KeyManagerError {
    var contextDict=context
    contextDict["format"]=format
    contextDict["details"]="Key format '\(format)' is invalid"

    let errorContext=ErrorContext(contextDict)

    return KeyManagerError(
      type: .invalidKeyFormat,
      code: KeyManagerErrorDomain.invalidKeyFormat.rawValue,
      description: "Invalid key format",
      context: errorContext,
      underlyingError: underlyingError
    )
  }

  /// Creates a key generation failed error
  /// - Parameters:
  ///   - reason: The reason key generation failed
  ///   - context: Additional context information
  ///   - underlyingError: Optional underlying error
  /// - Returns: A fully configured KeyManagerError
  public static func keyGenerationFailed(
    reason: String,
    context: [String: Any]=[:],
    underlyingError: Error?=nil
  ) -> KeyManagerError {
    var contextDict=context
    contextDict["reason"]=reason
    contextDict["details"]="Key generation failed: \(reason)"

    let errorContext=ErrorContext(contextDict)

    return KeyManagerError(
      type: .keyGenerationFailed,
      code: KeyManagerErrorDomain.keyGenerationFailed.rawValue,
      description: "Key generation failed",
      context: errorContext,
      underlyingError: underlyingError
    )
  }

  /// Creates a key storage failed error
  /// - Parameters:
  ///   - keyId: The ID of the key that failed to store
  ///   - reason: The reason key storage failed
  ///   - context: Additional context information
  ///   - underlyingError: Optional underlying error
  /// - Returns: A fully configured KeyManagerError
  public static func keyStorageFailed(
    keyID: String,
    reason: String,
    context: [String: Any]=[:],
    underlyingError: Error?=nil
  ) -> KeyManagerError {
    var contextDict=context
    contextDict["keyId"]=keyID
    contextDict["reason"]=reason
    contextDict["details"]="Failed to store key '\(keyID)': \(reason)"

    let errorContext=ErrorContext(contextDict)

    return KeyManagerError(
      type: .keyStorageFailed,
      code: KeyManagerErrorDomain.keyStorageFailed.rawValue,
      description: "Key storage failed",
      context: errorContext,
      underlyingError: underlyingError
    )
  }

  /// Creates a key deletion failed error
  /// - Parameters:
  ///   - keyId: The ID of the key that failed to delete
  ///   - reason: The reason key deletion failed
  ///   - context: Additional context information
  ///   - underlyingError: Optional underlying error
  /// - Returns: A fully configured KeyManagerError
  public static func keyDeletionFailed(
    keyID: String,
    reason: String,
    context: [String: Any]=[:],
    underlyingError: Error?=nil
  ) -> KeyManagerError {
    var contextDict=context
    contextDict["keyId"]=keyID
    contextDict["reason"]=reason
    contextDict["details"]="Failed to delete key '\(keyID)': \(reason)"

    let errorContext=ErrorContext(contextDict)

    return KeyManagerError(
      type: .keyDeletionFailed,
      code: KeyManagerErrorDomain.keyDeletionFailed.rawValue,
      description: "Key deletion failed",
      context: errorContext,
      underlyingError: underlyingError
    )
  }

  /// Creates a key retrieval failed error
  /// - Parameters:
  ///   - keyId: The ID of the key that failed to retrieve
  ///   - reason: The reason key retrieval failed
  ///   - context: Additional context information
  ///   - underlyingError: Optional underlying error
  /// - Returns: A fully configured KeyManagerError
  public static func keyRetrievalFailed(
    keyID: String,
    reason: String,
    context: [String: Any]=[:],
    underlyingError: Error?=nil
  ) -> KeyManagerError {
    var contextDict=context
    contextDict["keyId"]=keyID
    contextDict["reason"]=reason
    contextDict["details"]="Failed to retrieve key '\(keyID)': \(reason)"

    let errorContext=ErrorContext(contextDict)

    return KeyManagerError(
      type: .keyRetrievalFailed,
      code: KeyManagerErrorDomain.keyRetrievalFailed.rawValue,
      description: "Key retrieval failed",
      context: errorContext,
      underlyingError: underlyingError
    )
  }

  /// Creates an access denied error
  /// - Parameters:
  ///   - operation: The operation that was denied
  ///   - reason: The reason access was denied
  ///   - context: Additional context information
  ///   - underlyingError: Optional underlying error
  /// - Returns: A fully configured KeyManagerError
  public static func accessDenied(
    operation: String,
    reason: String,
    context: [String: Any]=[:],
    underlyingError: Error?=nil
  ) -> KeyManagerError {
    var contextDict=context
    contextDict["operation"]=operation
    contextDict["reason"]=reason
    contextDict["details"]="Access denied for operation '\(operation)': \(reason)"

    let errorContext=ErrorContext(contextDict)

    return KeyManagerError(
      type: .accessDenied,
      code: KeyManagerErrorDomain.accessDenied.rawValue,
      description: "Access denied",
      context: errorContext,
      underlyingError: underlyingError
    )
  }

  /// Creates a general error
  /// - Parameters:
  ///   - description: Human-readable description
  ///   - context: Additional context information
  ///   - underlyingError: Optional underlying error
  /// - Returns: A fully configured KeyManagerError
  public static func generalFailure(
    description: String,
    context: [String: Any]=[:],
    underlyingError: Error?=nil
  ) -> KeyManagerError {
    var contextDict=context
    contextDict["details"]=description

    let errorContext=ErrorContext(contextDict)

    return KeyManagerError(
      type: .generalFailure,
      code: KeyManagerErrorDomain.generalFailure.rawValue,
      description: description,
      context: errorContext,
      underlyingError: underlyingError
    )
  }
}
