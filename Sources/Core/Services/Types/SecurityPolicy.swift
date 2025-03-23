import Foundation
import KeyManagementTypes

/// Represents a security policy that defines access control requirements
public struct SecurityPolicy: Sendable, Equatable {
  /// Required authentication level
  public let requiredAuthentication: AuthenticationLevel

  /// Required storage location
  public let requiredStorageLocation: KeyManagementTypes.StorageLocation?

  /// Required key status
  public let requiredKeyStatus: KeyManagementTypes.KeyStatus

  /// Authentication levels supported by the policy
  public enum AuthenticationLevel: Int, Sendable, Equatable, Comparable {
    /// No authentication required
    case none=0
    /// Basic authentication (e.g., password)
    case basic=1
    /// Two-factor authentication
    case twoFactor=2
    /// Biometric authentication
    case biometric=3

    public static func < (lhs: AuthenticationLevel, rhs: AuthenticationLevel) -> Bool {
      lhs.rawValue < rhs.rawValue
    }
  }

  /// Creates a new security policy
  /// - Parameters:
  ///   - requiredAuthentication: Required authentication level
  ///   - requiredStorageLocation: Required storage location, if any
  ///   - requiredKeyStatus: Required key status
  public init(
    requiredAuthentication: AuthenticationLevel = .none,
    requiredStorageLocation: KeyManagementTypes.StorageLocation?=nil,
    requiredKeyStatus: KeyManagementTypes.KeyStatus = .active
  ) {
    self.requiredAuthentication=requiredAuthentication
    self.requiredStorageLocation=requiredStorageLocation
    self.requiredKeyStatus=requiredKeyStatus
  }

  public static func == (lhs: SecurityPolicy, rhs: SecurityPolicy) -> Bool {
    lhs.requiredAuthentication == rhs.requiredAuthentication &&
      lhs.requiredStorageLocation == rhs.requiredStorageLocation &&
      lhs.requiredKeyStatus == rhs.requiredKeyStatus
  }
}
