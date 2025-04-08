import Foundation

/**
 Security level for file system operations.

 Defines the security level to apply to file system operations,
 from standard to highly restricted access.
 */
public enum SecurityLevel: String, Sendable, Equatable, Hashable, CaseIterable {
  /// Standard security level for normal operations
  case standard

  /// Elevated security for sensitive operations
  case elevated

  /// High security for critical operations
  case high

  /// Restricted security for highly sensitive operations
  case restricted
}

/**
 Security options for file system operations.

 This struct encapsulates security-related settings for file system operations,
 providing consistent configuration for access controls and permissions.
 */
public struct SecurityOptions: Equatable, Sendable, Hashable {
  /// The security level for operations
  public let level: SecurityLevel

  /// Whether to preserve permissions during copy/move operations
  public let preservePermissions: Bool

  /// Whether to enforce sandboxing (restrict operations to specific directories)
  public let enforceSandboxing: Bool

  /// Whether to allow operations on symbolic links
  public let allowSymlinks: Bool

  /**
   Initialises security options for file system operations.

   - Parameters:
      - level: The security level for operations
      - preservePermissions: Whether to preserve permissions during copy/move operations
      - enforceSandboxing: Whether to restrict operations to specific directories
      - allowSymlinks: Whether to allow operations on symbolic links
   */
  public init(
    level: SecurityLevel = .standard,
    preservePermissions: Bool=true,
    enforceSandboxing: Bool=true,
    allowSymlinks: Bool=false
  ) {
    self.level=level
    self.preservePermissions=preservePermissions
    self.enforceSandboxing=enforceSandboxing
    self.allowSymlinks=allowSymlinks
  }
}
