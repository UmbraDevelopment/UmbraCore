import Foundation
import UmbraErrorsCore

/// DTO for repository errors
public struct RepositoryErrorDTO: Error, Hashable, Equatable, Sendable {
  /// The type of repository error
  public enum RepositoryErrorType: String, Hashable, Equatable, Sendable {
    /// Item not found
    case notFound="NOT_FOUND"
    /// Repository not found
    case repositoryNotFound="REPOSITORY_NOT_FOUND"
    /// Repository is locked
    case locked="LOCKED"
    /// Repository is not accessible
    case notAccessible="NOT_ACCESSIBLE"
    /// Invalid repository configuration
    case invalidConfiguration="INVALID_CONFIGURATION"
    /// Conflict in repository operation
    case conflict="CONFLICT"
    /// Authentication failed
    case authenticationFailed="AUTHENTICATION_FAILED"
    /// Authorisation failed
    case authorisationFailed="AUTHORISATION_FAILED"
    /// Operation timeout
    case timeout="TIMEOUT"
    /// General failure
    case generalFailure="GENERAL_FAILURE"
    /// Unknown repository error
    case unknown="UNKNOWN"
  }

  /// The type of repository error
  public let type: RepositoryErrorType

  /// Human-readable description of the error
  public let description: String

  /// Additional context information about the error
  public let context: UmbraErrorsCore.ErrorContext

  /// The underlying error, if any
  public let underlyingError: Error?

  /// Creates a new RepositoryErrorDTO
  /// - Parameters:
  ///   - type: The type of repository error
  ///   - description: Human-readable description
  ///   - context: Additional context information
  ///   - underlyingError: The underlying error
  public init(
    type: RepositoryErrorType,
    description: String,
    context: UmbraErrorsCore.ErrorContext=UmbraErrorsCore.ErrorContext(),
    underlyingError: Error?=nil
  ) {
    self.type=type
    self.description=description
    self.context=context
    self.underlyingError=underlyingError
  }

  /// Creates a new RepositoryErrorDTO with dictionary context
  /// - Parameters:
  ///   - type: The type of repository error
  ///   - description: Human-readable description
  ///   - contextDict: Additional context information as dictionary
  ///   - underlyingError: The underlying error
  public init(
    type: RepositoryErrorType,
    description: String,
    contextDict: [String: Any]=[:],
    underlyingError: Error?=nil
  ) {
    self.type=type
    self.description=description
    context=UmbraErrorsCore.ErrorContext(contextDict)
    self.underlyingError=underlyingError
  }

  /// Creates a RepositoryErrorDTO from a generic error
  /// - Parameter error: The source error
  /// - Returns: A RepositoryErrorDTO
  public static func from(_ error: Error) -> RepositoryErrorDTO {
    if let repositoryError=error as? RepositoryErrorDTO {
      return repositoryError
    }

    return RepositoryErrorDTO(
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

  public static func == (lhs: RepositoryErrorDTO, rhs: RepositoryErrorDTO) -> Bool {
    lhs.type == rhs.type &&
      lhs.description == rhs.description
    // Not comparing context or underlyingError for equality
  }
}
