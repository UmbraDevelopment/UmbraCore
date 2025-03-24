


import UmbraErrors
import UmbraErrorsCore
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
  /// - Throws: UmbraErrors.Security.Core if the check fails
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

/// Adapter class to convert between SecurityProviderProtocol and SecurityProviderBase
public final class SecurityProviderBaseAdapter: SecurityProviderBase {
  private let provider: any SecurityProviderProtocol

  /// Initialise with a security provider
  /// - Parameter provider: The provider to adapt
  public init(provider: any SecurityProviderProtocol) {
    self.provider=provider
  }

  public static var protocolIdentifier: String {
    "com.umbra.security.provider.base.adapter"
  }

  public func isAvailable() async -> Result<Bool, UmbraErrors.XPC.SecurityError> {
    do {
      let available=try await provider.isAvailable()
      return .success(available)
    } catch {
      if let securityError=error as? UmbraErrors.Security.Core {
        // Convert core error to protocol error
        if let protocolError=securityError.toProtocolError() {
          return .failure(protocolError)
        }
      }
      // Default mapping for other errors
      return .failure(.internalError(description: error.localizedDescription))
    }
  }

  public func getVersion() async -> String {
    await provider.getVersion()
  }
}
