// Standard modules
import Foundation

/// Errors that can occur during repository operations.
public enum RepositoryError: LocalizedError, Equatable, Sendable, Codable {
  /// The repository was not found at the specified location.
  case notFound(identifier: String)

  /// The repository was not found during an operation.
  case repositoryNotFound(_ message: String)

  /// The repository is locked and cannot be accessed.
  case locked(reason: String)

  /// The repository cannot be accessed due to permissions or other issues.
  case notAccessible(reason: String)

  /// The repository configuration is invalid.
  case invalidConfiguration(reason: String)

  /// An operation on the repository failed.
  case operationFailed(reason: String)

  /// Repository maintenance operation failed.
  case maintenanceFailed(reason: String)

  /// Repository validation failed.
  case validationFailed(reason: String)

  /// Repository health check failed.
  case healthCheckFailed(reason: String)

  /// The error description.
  public var errorDescription: String? {
    switch self {
      case let .notFound(identifier):
        "Repository not found: \(identifier)"
      case let .repositoryNotFound(message):
        message
      case let .locked(reason):
        "Repository is locked: \(reason)"
      case let .notAccessible(reason):
        "Repository is not accessible: \(reason)"
      case let .invalidConfiguration(reason):
        "Invalid repository configuration: \(reason)"
      case let .operationFailed(reason):
        "Repository operation failed: \(reason)"
      case let .maintenanceFailed(reason):
        "Repository maintenance failed: \(reason)"
      case let .validationFailed(reason):
        "Repository validation failed: \(reason)"
      case let .healthCheckFailed(reason):
        "Repository health check failed: \(reason)"
    }
  }

  public var failureReason: String? {
    switch self {
      case let .locked(reason),
           let .notAccessible(reason),
           let .invalidConfiguration(reason),
           let .operationFailed(reason),
           let .maintenanceFailed(reason),
           let .validationFailed(reason),
           let .healthCheckFailed(reason):
        reason
      case let .notFound(identifier):
        identifier
      case let .repositoryNotFound(message):
        message
    }
  }

  public var recoverySuggestion: String? {
    switch self {
      case .notFound:
        "Check the repository identifier and try again"
      case .repositoryNotFound:
        "Check the repository identifier and try again"
      case .locked:
        "Wait for other operations to complete or force unlock if necessary"
      case .notAccessible:
        "Check repository permissions and network connectivity"
      case .invalidConfiguration:
        "Check repository configuration settings"
      case .operationFailed:
        "Retry the operation or check logs for more details"
      case .maintenanceFailed:
        "Retry the maintenance operation or check logs for more details"
      case .validationFailed:
        "Check repository configuration and data for errors"
      case .healthCheckFailed:
        "Check repository configuration and data for errors"
    }
  }

  // MARK: - Codable

  private enum CodingKeys: String, CodingKey {
    case type
    case identifier
    case message
    case reason
  }

  public func encode(to encoder: Encoder) throws {
    var container=encoder.container(keyedBy: CodingKeys.self)
    switch self {
      case let .notFound(identifier):
        try container.encode("notFound", forKey: .type)
        try container.encode(identifier, forKey: .identifier)
      case let .repositoryNotFound(message):
        try container.encode("repositoryNotFound", forKey: .type)
        try container.encode(message, forKey: .message)
      case let .locked(reason):
        try container.encode("locked", forKey: .type)
        try container.encode(reason, forKey: .reason)
      case let .notAccessible(reason):
        try container.encode("notAccessible", forKey: .type)
        try container.encode(reason, forKey: .reason)
      case let .invalidConfiguration(reason):
        try container.encode("invalidConfiguration", forKey: .type)
        try container.encode(reason, forKey: .reason)
      case let .operationFailed(reason):
        try container.encode("operationFailed", forKey: .type)
        try container.encode(reason, forKey: .reason)
      case let .maintenanceFailed(reason):
        try container.encode("maintenanceFailed", forKey: .type)
        try container.encode(reason, forKey: .reason)
      case let .validationFailed(reason):
        try container.encode("validationFailed", forKey: .type)
        try container.encode(reason, forKey: .reason)
      case let .healthCheckFailed(reason):
        try container.encode("healthCheckFailed", forKey: .type)
        try container.encode(reason, forKey: .reason)
    }
  }

  @preconcurrency
  @available(*, deprecated, message: "Will need to be refactored for Swift 6")
  public init(from decoder: Decoder) throws {
    let container=try decoder.container(keyedBy: CodingKeys.self)
    let type=try container.decode(String.self, forKey: .type)
    switch type {
      case "notFound":
        let identifier=try container.decode(String.self, forKey: .identifier)
        self = .notFound(identifier: identifier)
      case "repositoryNotFound":
        let message=try container.decode(String.self, forKey: .message)
        self = .repositoryNotFound(message)
      case "locked":
        let reason=try container.decode(String.self, forKey: .reason)
        self = .locked(reason: reason)
      case "notAccessible":
        let reason=try container.decode(String.self, forKey: .reason)
        self = .notAccessible(reason: reason)
      case "invalidConfiguration":
        let reason=try container.decode(String.self, forKey: .reason)
        self = .invalidConfiguration(reason: reason)
      case "operationFailed":
        let reason=try container.decode(String.self, forKey: .reason)
        self = .operationFailed(reason: reason)
      case "maintenanceFailed":
        let reason=try container.decode(String.self, forKey: .reason)
        self = .maintenanceFailed(reason: reason)
      case "validationFailed":
        let reason=try container.decode(String.self, forKey: .reason)
        self = .validationFailed(reason: reason)
      case "healthCheckFailed":
        let reason=try container.decode(String.self, forKey: .reason)
        self = .healthCheckFailed(reason: reason)
      default:
        throw DecodingError.dataCorruptedError(
          forKey: .type,
          in: container,
          debugDescription: "Invalid repository error type: \(type)"
        )
    }
  }
}
