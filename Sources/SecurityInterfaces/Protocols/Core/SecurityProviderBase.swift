import UmbraCoreTypes
import UmbraErrors
import UmbraErrorsCore

/// Base protocol for security providers
/// This protocol is designed to be Foundation-free and serve as a base for more specific security
/// provider protocols
public protocol SecurityProviderBase: Sendable {
  /// Protocol identifier - used for protocol negotiation
  static var protocolIdentifier: String { get }

  /// Test if the security provider is available
  /// - Returns: True if the provider is available, false otherwise
  func isAvailable() async -> Result<Bool, UmbraErrors.XPC.SecurityError>

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
  public func isAvailable() async -> Result<Bool, UmbraErrors.XPC.SecurityError> {
    .success(true)
  }

  /// Default version string
  public func getVersion() async -> String {
    "1.0.0"
  }
}
