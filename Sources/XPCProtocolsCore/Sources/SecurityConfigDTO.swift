import Foundation
import UmbraCoreTypes

/// Security configuration for XPC operations
///
/// This DTO provides configuration parameters for security operations
/// performed through XPC services.
public struct SecurityConfigDTO: Sendable, Codable, Equatable {
  /// Operation timeout in seconds
  public let timeoutSeconds: Double

  /// Security level for the operation
  public let securityLevel: SecurityLevel

  /// Additional configuration parameters
  public let parameters: [String: String]

  /// Create a new security configuration
  /// - Parameters:
  ///   - timeoutSeconds: Operation timeout in seconds
  ///   - securityLevel: Security level for the operation
  ///   - parameters: Additional configuration parameters
  public init(
    timeoutSeconds: Double=30.0,
    securityLevel: SecurityLevel = .standard,
    parameters: [String: String]=[:]
  ) {
    self.timeoutSeconds=timeoutSeconds
    self.securityLevel=securityLevel
    self.parameters=parameters
  }

  /// Security level for operations
  public enum SecurityLevel: String, Sendable, Codable, Equatable, CaseIterable {
    /// Minimal security (for non-sensitive operations)
    case minimal

    /// Standard security (default for most operations)
    case standard

    /// High security (for sensitive operations)
    case high

    /// Maximum security (for critical operations)
    case maximum
  }
}
