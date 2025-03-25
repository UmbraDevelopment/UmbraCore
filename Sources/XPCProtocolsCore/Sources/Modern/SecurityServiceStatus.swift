import Foundation

/// Represents the status of a security service
/// Used for health checks and monitoring
public struct SecurityServiceStatus: Sendable, Equatable, Hashable {
  /// Current operational status of the service
  public let status: String

  /// Version of the service
  public let version: String

  /// Additional information about the service
  public let info: [String: String]

  /// Create a new security service status
  /// - Parameters:
  ///   - status: The current status (e.g., "active", "degraded", "offline")
  ///   - version: The service version
  ///   - info: Additional service information
  public init(status: String, version: String, info: [String: String]) {
    self.status=status
    self.version=version
    self.info=info
  }

  // Required for Equatable/Hashable
  public static func == (lhs: SecurityServiceStatus, rhs: SecurityServiceStatus) -> Bool {
    lhs.status == rhs.status &&
      lhs.version == rhs.version &&
      lhs.info == rhs.info
  }

  // Required for Hashable
  public func hash(into hasher: inout Hasher) {
    hasher.combine(status)
    hasher.combine(version)
    // Now we can hash the info dictionary since it contains only Hashable types
    for (key, value) in info {
      hasher.combine(key)
      hasher.combine(value)
    }
  }
}
