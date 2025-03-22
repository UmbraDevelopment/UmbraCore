import Foundation
import KeyManagementTypes

/// Core service types namespace
/// This file contains common type definitions used in service implementations
@available(*, deprecated, message: "Use CoreServicesTypes directly")
public enum CoreServices {
  /// Represents the current state of a service
  /// @deprecated Use ServiceState directly instead
  @available(*, deprecated, message: "Use ServiceState directly instead")
  public enum LegacyServiceState: Equatable, Sendable {
    /// Service is running and healthy
    case healthy
    /// Service is running but experiencing performance issues
    case degraded(reason: String)
    /// Service is not available
    case unavailable(reason: String)
    /// Service is starting up
    case starting
    /// Service is shutting down
    case shuttingDown
    /// Service is in maintenance mode
    case maintenance
  }
}

// Add extensions for Codable, CustomStringConvertible, etc.
extension CoreServices.LegacyServiceState: CustomStringConvertible {
  public var description: String {
    switch self {
      case .healthy:
        "Healthy"
      case let .degraded(reason):
        "Degraded: \(reason)"
      case let .unavailable(reason):
        "Unavailable: \(reason)"
      case .starting:
        "Starting"
      case .shuttingDown:
        "Shutting Down"
      case .maintenance:
        "Maintenance"
    }
  }
}

extension CoreServices.LegacyServiceState: Codable {
  private enum CodingKeys: String, CodingKey {
    case type
    case reason
  }

  public init(from decoder: Decoder) throws {
    let container=try decoder.container(keyedBy: CodingKeys.self)
    let type=try container.decode(String.self, forKey: .type)

    switch type {
      case "healthy":
        self = .healthy
      case "degraded":
        let reason=try container.decode(String.self, forKey: .reason)
        self = .degraded(reason: reason)
      case "unavailable":
        let reason=try container.decode(String.self, forKey: .reason)
        self = .unavailable(reason: reason)
      case "starting":
        self = .starting
      case "shuttingDown":
        self = .shuttingDown
      case "maintenance":
        self = .maintenance
      default:
        throw DecodingError.dataCorrupted(
          DecodingError.Context(
            codingPath: container.codingPath,
            debugDescription: "Unknown service state type: \(type)"
          )
        )
    }
  }

  public func encode(to encoder: Encoder) throws {
    var container=encoder.container(keyedBy: CodingKeys.self)

    switch self {
      case .healthy:
        try container.encode("healthy", forKey: .type)
      case let .degraded(reason):
        try container.encode("degraded", forKey: .type)
        try container.encode(reason, forKey: .reason)
      case let .unavailable(reason):
        try container.encode("unavailable", forKey: .type)
        try container.encode(reason, forKey: .reason)
      case .starting:
        try container.encode("starting", forKey: .type)
      case .shuttingDown:
        try container.encode("shuttingDown", forKey: .type)
      case .maintenance:
        try container.encode("maintenance", forKey: .type)
    }
  }
}

/// Conversion helpers for legacy service state
@available(*, deprecated, message: "Use ServiceState directly instead")
extension CoreServices.LegacyServiceState {
  /// Convert to external service state
  public func toStandardServiceState() -> ServiceState {
    switch self {
      case .healthy:
        .ready
      case .degraded:
        .running
      case .unavailable:
        .error
      case .starting:
        .initializing
      case .shuttingDown:
        .shuttingDown
      case .maintenance:
        .suspended
    }
  }
}

// For backwards compatibility, provide a direct typealias
@available(*, deprecated, message: "Use ServiceState directly")
public typealias CoreServicesTypesServiceState=CoreServices.LegacyServiceState

/// Namespace for core services types
/// This replaces the deprecated CoreServices enum
public enum CoreServicesTypes {
  // This enum is intentionally empty as all types are defined at module level
  // It serves as a namespace for documentation purposes
}
