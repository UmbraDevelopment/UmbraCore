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
extension ServiceState: CustomStringConvertible {
  public var description: String {
    switch self {
      case .ready, .running:
        "Healthy"
      case .error:
        "Unavailable: Error"
      case .initializing:
        "Starting"
      case .shuttingDown:
        "Shutting Down"
      case .suspended:
        "Maintenance"
      case .uninitialized:
        "Uninitialized"
      case .shutdown:
        "Shut Down"
    }
  }
}

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

// For backwards compatibility, provide a direct typealias
@available(*, deprecated, message: "Use ServiceState directly")
public typealias CoreServicesTypesServiceState=CoreServices.LegacyServiceState

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
