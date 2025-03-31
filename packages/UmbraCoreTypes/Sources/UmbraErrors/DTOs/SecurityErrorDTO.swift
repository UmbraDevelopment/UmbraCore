import Foundation
import UmbraErrorsCore

/// A Data Transfer Object specifically for security-related errors
/// This helps break circular dependencies between security error modules
public struct SecurityErrorDTO: Sendable {
  /// The specific security error type
  public enum SecurityErrorType: String, Equatable, Hashable, Sendable, Codable {
    case authentication
    case authorisation
    case encryption
    case decryption
    case keyManagement
    case certificateValidation
    case invalidSignature
    case untrustedSource
    case secureChannelFailure
    case integrityViolation
    case unknown
  }

  /// The type of security error
  public let type: SecurityErrorType

  /// Human-readable description of the error
  public let description: String

  /// Additional contextual information
  public let context: [String: String]

  /// Underlying error if available
  /// Note: This property is excluded from Hashable and Equatable conformance
  public let underlyingError: Error?

  /// Creates a new SecurityErrorDTO
  /// - Parameters:
  ///   - type: The type of security error
  ///   - description: Human-readable description of the error
  ///   - context: Additional contextual information
  ///   - underlyingError: Underlying error if available
  public init(
    type: SecurityErrorType,
    description: String,
    context: [String: String]=[:],
    underlyingError: Error?=nil
  ) {
    self.type=type
    self.description=description
    self.context=context
    self.underlyingError=underlyingError
  }

  /// Convert to a generic ErrorDTO
  /// - Returns: An ErrorDTO representing this security error
  public func toErrorDTO() -> ErrorDTO {
    ErrorDTO(
      identifier: "security.\(type.rawValue)",
      domain: "security",
      description: description,
      contextData: context
    )
  }
}

// MARK: - Error Conformance

extension SecurityErrorDTO: Error {
  public var localizedDescription: String {
    description
  }
}

// MARK: - Hashable & Equatable

extension SecurityErrorDTO: Hashable, Equatable {
  public func hash(into hasher: inout Hasher) {
    // Exclude underlyingError because Error doesn't conform to Hashable
    hasher.combine(type)
    hasher.combine(description)
    hasher.combine(context)
  }

  public static func == (lhs: SecurityErrorDTO, rhs: SecurityErrorDTO) -> Bool {
    // Exclude underlyingError because Error doesn't conform to Equatable
    lhs.type == rhs.type &&
      lhs.description == rhs.description &&
      lhs.context == rhs.context
  }
}

// MARK: - Codable

extension SecurityErrorDTO: Codable {
  private enum CodingKeys: String, CodingKey {
    case type
    case description
    case context
  }

  public init(from decoder: Decoder) throws {
    let container=try decoder.container(keyedBy: CodingKeys.self)
    type=try container.decode(SecurityErrorType.self, forKey: .type)
    description=try container.decode(String.self, forKey: .description)
    context=try container.decode([String: String].self, forKey: .context)
    underlyingError=nil
  }

  public func encode(to encoder: Encoder) throws {
    var container=encoder.container(keyedBy: CodingKeys.self)
    try container.encode(type, forKey: .type)
    try container.encode(description, forKey: .description)
    try container.encode(context, forKey: .context)
  }
}
