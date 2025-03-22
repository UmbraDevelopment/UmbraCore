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
        return .ready
      case .degraded:
        return .running
      case .unavailable:
        return .error
      case .starting:
        return .initializing
      case .shuttingDown:
        return .shuttingDown
      case .maintenance:
        return .suspended
    }
  }
}

// For backwards compatibility, provide a direct typealias
@available(*, deprecated, message: "Use ServiceState directly")
public typealias CoreServicesTypesServiceState=CoreServices.LegacyServiceState

/**
 * MIGRATION GUIDE:
 * 
 * This migration guide explains how to properly handle ServiceState references:
 * 
 * 1. PREFERRED: Import CoreServicesTypes directly and use ServiceState
 *    Example:
 *    ```swift
 *    import CoreServicesTypes
 *    
 *    func example() {
 *      let state: ServiceState = .running
 *    }
 *    ```
 *
 * 2. TEMPORARY: If maintaining existing code patterns, continue using
 *    CoreServicesTypes.ServiceState but add appropriate deprecation
 *    warnings
 *
 * The CoreServicesTypes.ServiceState reference will be removed in
 * a future version. Please migrate code to use the direct type.
 */

/// This namespace is maintained for backwards compatibility only.
/// New code should directly import CoreServicesTypes and use those types.
@available(*, deprecated, message: "Import CoreServicesTypes module directly instead")
public enum CoreServicesTypes {}
