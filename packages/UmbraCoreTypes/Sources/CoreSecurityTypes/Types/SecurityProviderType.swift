import Foundation

/**
 Defines the supported security provider types in the security subsystem.

 This enumeration allows components to specify which underlying security
 implementation should be used for cryptographic operations. The choice of provider
 is typically determined during service initialisation (e.g., via dependency injection)
 based on platform requirements, performance needs, or desired compatibility.

 This enumeration follows the architecture pattern for type-safe
 representation of domain concepts.
 */
public enum SecurityProviderType: String, Sendable, Codable, Equatable, CaseIterable {
  /// Apple CryptoKit provider for native performance and integration on Apple platforms (macOS,
  /// iOS, etc.).
  case cryptoKit="CryptoKit"

  /// Ring Crypto provider using Rust FFI for cross-platform cryptographic compatibility.
  case ring="Ring"

  /// Basic AES implementation, potentially for fallback or environments where other providers are
  /// unavailable.
  case basic="Basic"

  /// System-provided security services (e.g., Keychain access where applicable). Specific
  /// functionality depends on the OS.
  case system="System"

  /// Hardware Security Module (HSM) provider, intended for interaction with dedicated hardware
  /// security devices.
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
