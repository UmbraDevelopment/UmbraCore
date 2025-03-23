import CoreErrors
import ErrorHandlingDomains
import SecurityInterfacesProtocols
import UmbraCoreTypes
import XPCProtocolsCore

/// Base protocol for security providers
/// This protocol is designed to be Foundation-free and serve as a base for more specific security
/// provider protocols

public protocol SecurityProviderBase: Sendable {
  /// Protocol identifier - used for protocol negotiation
  static var protocolIdentifier: String { get }

  /// Test if the security provider is available
  /// - Returns: True if the provider is available, false otherwise
  /// - Throws: SecurityError if the check fails
  func isAvailable() async -> Result<Bool, CoreErrors.XPCErrors.SecurityError>
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
  public func isAvailable() async -> Result<Bool, CoreErrors.XPCErrors.SecurityError> {
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

  public init(provider: any SecurityProviderProtocol) {
    self.provider=provider
  }

  public static var protocolIdentifier: String {
    "com.umbra.security.provider.base.adapter"
  }

  public func isAvailable() async -> Result<Bool, CoreErrors.XPCErrors.SecurityError> {
    // This is a simple implementation that assumes the provider is available
    // In a real implementation, you might want to perform some checks
    .success(true)
  }

  public func getVersion() async -> String {
    // This is a simple implementation that returns a fixed version
    // In a real implementation, you might want to get the version from the provider
    "1.0.0"
  }
}
