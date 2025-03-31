import Foundation

/**
 Defines the supported security provider types in the security subsystem.

 This enumeration follows the architecture pattern for type-safe
 representation of domain concepts.
 */
public enum SecurityProviderType: String, Sendable, Codable, Equatable, CaseIterable {
  /// Apple CryptoKit provider for Apple platforms
  case cryptoKit="CryptoKit"

  /// Ring Crypto provider for cross-platform compatibility
  case ring="Ring"

  /// Basic AES implementation for fallback
  case basic="Basic"

  /// System-provided security services
  case system="System"

  /// Hardware Security Module provider
  case hsm="HSM"

  /// Returns a human-readable description of the provider
  public var localizedDescription: String {
    switch self {
      case .cryptoKit:
        "Apple CryptoKit"
      case .ring:
        "Ring Crypto"
      case .basic:
        "Basic Provider"
      case .system:
        "System Provider"
      case .hsm:
        "Hardware Security Module"
    }
  }

  /// Returns whether the provider is available on the current platform
  public var isAvailable: Bool {
    switch self {
      case .cryptoKit:
        #if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
          return true
        #else
          return false
        #endif
      case .ring, .basic:
        return true
      case .system:
        #if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
          return true
        #else
          return false
        #endif
      case .hsm:
        // HSM support would need to be determined at runtime
        return false
    }
  }
}
