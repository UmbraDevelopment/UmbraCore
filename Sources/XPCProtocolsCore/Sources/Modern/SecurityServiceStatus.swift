import Foundation

/// Represents the status of a security service
/// Used for health checks and monitoring
public struct SecurityServiceStatus: Sendable, Equatable, Hashable {
  /// Current operational status of the service
  public let status: String

  /// Version of the service
  public let version: String

  /// Additional information about the service
  public let info: [String: Any]

  /// Create a new security service status
  /// - Parameters:
  ///   - status: The current status (e.g., "active", "degraded", "offline")
  ///   - version: The service version
  ///   - info: Additional service information
  public init(status: String, version: String, info: [String: Any]) {
    self.status=status
    self.version=version
    self.info=info
  }

  // Required for Equatable/Hashable due to info containing Any
  public static func == (lhs: SecurityServiceStatus, rhs: SecurityServiceStatus) -> Bool {
    lhs.status == rhs.status &&
      lhs.version == rhs.version
  }

  // Required for Hashable due to info containing Any
  public func hash(into hasher: inout Hasher) {
    hasher.combine(status)
    hasher.combine(version)
  }
}
