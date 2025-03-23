import Foundation
import XPCProtocolsCore

/// UmbraCore provides the foundational types and protocols for the Umbra security framework.
public enum UmbraCore {
  /// The current version of the UmbraCore framework
  public static let version="1.0.0"

  /// Configuration options for the UmbraCore framework
  public struct Configuration {
    /// Whether to use verbose logging
    public var verboseLogging: Bool

    /// The default security level for cryptographic operations
    public var defaultSecurityLevel: XPCProtocolTypeDefs.SecurityLevel

    public init(
      verboseLogging: Bool=false,
      defaultSecurityLevel: XPCProtocolTypeDefs.SecurityLevel = .standard
    ) {
      self.verboseLogging=verboseLogging
      self.defaultSecurityLevel=defaultSecurityLevel
    }
  }

  /// Security levels for cryptographic operations
  /// @deprecated This will be replaced by XPCProtocolTypeDefs.SecurityLevel in a future version.
  /// New code should use XPCProtocolTypeDefs.SecurityLevel directly.
  @available(
    *,
    deprecated,
    message: "This will be replaced by XPCProtocolTypeDefs.SecurityLevel in a future version. Use XPCProtocolTypeDefs.SecurityLevel directly."
  )
  @frozen
  public enum SecurityLevel: Sendable {
    /// High security - suitable for sensitive data
    case high
    /// Medium security - balanced between security and performance
    case medium
    /// Low security - suitable for non-sensitive data or testing
    case low

    /// Recommended key length in bits for this security level
    public var recommendedKeyLength: Int {
      switch self {
        case .high: 256
        case .medium: 192
        case .low: 128
      }
    }

    /// Convert to XPCProtocolTypeDefs.SecurityLevel
    public func toXPCProtocol() -> XPCProtocolTypeDefs.SecurityLevel {
      switch self {
        case .high: .high
        case .medium: .standard
        case .low: .standard // No direct mapping to lower security
      }
    }

    /// Create from XPCProtocolTypeDefs.SecurityLevel
    public static func from(xpcLevel level: XPCProtocolTypeDefs.SecurityLevel) -> SecurityLevel {
      switch level {
        case .maximum, .high: return .high
        case .standard: return .medium
        @unknown default: return .medium // Default to medium security for future cases
      }
    }

    /// Recommended number of PBKDF2 iterations for this security level
    public var recommendedPBKDF2Iterations: Int {
      switch self {
        case .high: 310_000
        case .medium: 200_000
        case .low: 100_000
      }
    }
  }
}

/// Represents an error that can occur in the UmbraCore framework
public protocol UmbraError: LocalizedError {
  /// The error domain
  var domain: String { get }

  /// Whether this error is recoverable
  var isRecoverable: Bool { get }

  /// Additional error context, if any
  var context: [String: Any] { get }
}
