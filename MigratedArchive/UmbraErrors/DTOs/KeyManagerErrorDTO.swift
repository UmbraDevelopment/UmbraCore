import Foundation
import UmbraErrorsCore

/// DTO for key manager errors
public struct KeyManagerErrorDTO: Error, Hashable, Equatable, Sendable {
  /// The type of key manager error
  public enum KeyManagerErrorType: String, Hashable, Equatable, Sendable {
    /// Key not found
    case keyNotFound="KEY_NOT_FOUND"
    /// Invalid key format
    case invalidKeyFormat="INVALID_KEY_FORMAT"
    /// Key generation failed
    case keyGenerationFailed="KEY_GENERATION_FAILED"
    /// Key storage failed
    case keyStorageFailed="KEY_STORAGE_FAILED"
    /// Key deletion failed
    case keyDeletionFailed="KEY_DELETION_FAILED"
    /// Key retrieval failed
    case keyRetrievalFailed="KEY_RETRIEVAL_FAILED"
    /// Access denied
    case accessDenied="ACCESS_DENIED"
    /// General failure
    case generalFailure="GENERAL_FAILURE"
    /// Unknown key manager error
    case unknown="UNKNOWN"
  }

  /// The type of key manager error
  public let type: KeyManagerErrorType

  /// Human-readable description of the error
  public let description: String

  /// Additional context information about the error
  public let context: UmbraErrorsCore.ErrorContext

  /// The underlying error, if any
  public let underlyingError: Error?

  /// Creates a new KeyManagerErrorDTO
  /// - Parameters:
  ///   - type: The type of key manager error
  ///   - description: Human-readable description
  ///   - context: Additional context information
  ///   - underlyingError: The underlying error
  public init(
    type: KeyManagerErrorType,
    description: String,
    context: UmbraErrorsCore.ErrorContext=UmbraErrorsCore.ErrorContext(),
    underlyingError: Error?=nil
  ) {
    self.type=type
    self.description=description
    self.context=context
    self.underlyingError=underlyingError
  }

  /// Creates a new KeyManagerErrorDTO with dictionary context
  /// - Parameters:
  ///   - type: The type of key manager error
  ///   - description: Human-readable description
  ///   - contextDict: Additional context information as dictionary
  ///   - underlyingError: The underlying error
  public init(
    type: KeyManagerErrorType,
    description: String,
    contextDict: [String: Any]=[:],
    underlyingError: Error?=nil
  ) {
    self.type=type
    self.description=description
    context=UmbraErrorsCore.ErrorContext(contextDict)
    self.underlyingError=underlyingError
  }

  /// Creates a KeyManagerErrorDTO from a generic error
  /// - Parameter error: The source error
  /// - Returns: A KeyManagerErrorDTO
  public static func from(_ error: Error) -> KeyManagerErrorDTO {
    if let keyManagerError=error as? KeyManagerErrorDTO {
      return keyManagerError
    }

    return KeyManagerErrorDTO(
      type: .unknown,
      description: "\(error)",
      context: UmbraErrorsCore.ErrorContext(),
      underlyingError: error
    )
  }

  // MARK: - Hashable & Equatable

  public func hash(into hasher: inout Hasher) {
    hasher.combine(type)
    hasher.combine(description)
    // Not hashing context or underlyingError as they may not be Hashable
  }

  public static func == (lhs: KeyManagerErrorDTO, rhs: KeyManagerErrorDTO) -> Bool {
    lhs.type == rhs.type &&
      lhs.description == rhs.description
    // Not comparing context or underlyingError for equality
  }
}
