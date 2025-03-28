import Foundation
import SecurityTypes
import UmbraErrors

/// Base protocol for security providers
/// This protocol is designed to be Foundation-free and serve as a base for more specific security
/// provider protocols
public protocol SecurityProviderBase: Sendable {
  /// Protocol identifier - used for protocol negotiation
  static var protocolIdentifier: String { get }

  /// Test if the security provider is available
  /// - Returns: True if the provider is available, false otherwise
  /// - Throws: SecurityError if the check fails
  func isAvailable() async -> Result<Bool, SecurityErrorDTO>

  /// Get the provider's version information
  /// - Returns: Version string
  func getVersion() async -> String
}

/// Default implementation for SecurityProviderBase
extension SecurityProviderBase {
  /// Default protocol identifier
  public static var protocolIdentifier: String {
    "com.umbra.security.provider.base"
  }

  /// Default implementation that assumes the provider is available
  public func isAvailable() async -> Result<Bool, SecurityErrorDTO> {
    .success(true)
  }

  /// Default version string
  public func getVersion() async -> String {
    "1.0.0"
  }
}

/// Adapter class to convert between SecurityProviderProtocol and SecurityProviderBase
public final class SecurityProviderBaseAdapter: SecurityProviderBase {
  private let provider: any SecurityProviderProtocol

  /// Initialise with a security provider
  /// - Parameter provider: The provider to adapt
  public init(provider: any SecurityProviderProtocol) {
    self.provider=provider
  }

  public static var protocolIdentifier: String {
    "com.umbra.security.provider.adapter"
  }

  public func isAvailable() async -> Result<Bool, SecurityErrorDTO> {
    // Simply return success as the underlying provider is assumed to be available
    .success(true)
  }

  public func getVersion() async -> String {
    // Return adapter version only since the provider doesn't have getVersion
    "adapter.1.0"
  }
}
