import Foundation
import UmbraErrorsCore

/// DTO for crypto errors
public struct CryptoErrorDTO: Error, Hashable, Equatable, Sendable {
  /// The type of crypto error
  public enum CryptoErrorType: String, Hashable, Equatable, Sendable {
    /// Invalid key length
    case invalidKeyLength="INVALID_KEY_LENGTH"
    /// Invalid parameters
    case invalidParameters="INVALID_PARAMETERS"
    /// Operation failed
    case operationFailed="OPERATION_FAILED"
    /// Algorithm not supported
    case algorithmNotSupported="ALGORITHM_NOT_SUPPORTED"
    /// Key generation failed
    case keyGenerationFailed="KEY_GENERATION_FAILED"
    /// Encryption failed
    case encryptionFailed="ENCRYPTION_FAILED"
    /// Decryption failed
    case decryptionFailed="DECRYPTION_FAILED"
    /// Signature verification failed
    case signatureVerificationFailed="SIGNATURE_VERIFICATION_FAILED"
    /// Certificate validation failed
    case certificateValidationFailed="CERTIFICATE_VALIDATION_FAILED"
    /// Unknown crypto error
    case unknown="UNKNOWN"
  }

  /// The type of crypto error
  public let type: CryptoErrorType

  /// Human-readable description of the error
  public let description: String

  /// Additional context information about the error
  public let context: ErrorContext

  /// The underlying error, if any
  public let underlyingError: Error?

  /// Creates a new CryptoErrorDTO
  /// - Parameters:
  ///   - type: The type of crypto error
  ///   - description: Human-readable description
  ///   - context: Additional context information
  ///   - underlyingError: The underlying error
  public init(
    type: CryptoErrorType,
    description: String,
    context: ErrorContext=ErrorContext(),
    underlyingError: Error?=nil
  ) {
    self.type=type
    self.description=description
    self.context=context
    self.underlyingError=underlyingError
  }

  /// Creates a new CryptoErrorDTO with dictionary context
  /// - Parameters:
  ///   - type: The type of crypto error
  ///   - description: Human-readable description
  ///   - contextDict: Additional context information as dictionary
  ///   - underlyingError: The underlying error
  public init(
    type: CryptoErrorType,
    description: String,
    contextDict: [String: Any]=[:],
    underlyingError: Error?=nil
  ) {
    self.type=type
    self.description=description
    context=ErrorContext(contextDict)
    self.underlyingError=underlyingError
  }

  /// Creates a CryptoErrorDTO from a generic error
  /// - Parameter error: The source error
  /// - Returns: A CryptoErrorDTO
  public static func from(_ error: Error) -> CryptoErrorDTO {
    if let cryptoError=error as? CryptoErrorDTO {
      return cryptoError
    }

    return CryptoErrorDTO(
      type: .unknown,
      description: "\(error)",
      context: ErrorContext(),
      underlyingError: error
    )
  }

  // MARK: - Hashable & Equatable

  public func hash(into hasher: inout Hasher) {
    hasher.combine(type)
    hasher.combine(description)
    // Not hashing context or underlyingError as they may not be Hashable
  }

  public static func == (lhs: CryptoErrorDTO, rhs: CryptoErrorDTO) -> Bool {
    lhs.type == rhs.type &&
      lhs.description == rhs.description
    // Not comparing context or underlyingError for equality
  }
}
