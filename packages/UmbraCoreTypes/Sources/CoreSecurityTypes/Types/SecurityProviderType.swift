import Foundation

/**
 Defines the supported security provider types in the security subsystem.

 This enumeration allows components to specify which underlying security
 implementation should be used for cryptographic operations. The choice of provider
 is typically determined during service initialisation (e.g., via dependency injection)
 based on platform requirements, performance needs, or desired compatibility.

 This enumeration supports the three primary backend strategies:
 - Restic: Uses basic or system provider
 - RingFFI: Uses Ring Crypto provider
 - AppleCK: Uses Apple CryptoKit provider

 This enumeration follows the architecture pattern for type-safe
 representation of domain concepts within the Alpha Dot Five architecture.
 */
public enum SecurityProviderType: String, Sendable, Codable, Equatable, CaseIterable {
  /// Apple CryptoKit provider for native performance and integration on Apple platforms (macOS,
  /// iOS, etc.).
  case cryptoKit = "CryptoKit"
  
  /// Alias for cryptoKit to align with BuildConfig naming
  case appleCryptoKit = "AppleCryptoKit"

  /// Ring Crypto provider using Rust FFI for cross-platform cryptographic compatibility.
  case ring = "Ring"

  /// Basic AES implementation, potentially for fallback or environments where other providers are
  /// unavailable.
  case basic = "Basic"

  /// System-provided security services (e.g., Keychain access where applicable). Specific
  /// functionality depends on the OS.
  case system = "System"

  /// Hardware Security Module (HSM) provider, intended for interaction with dedicated hardware
  /// security devices.
  case hsm = "HSM"
  
  /// Platform-specific optimised provider
  case platform = "Platform"
  
  /// Custom provider implementation
  case custom = "Custom"

  /// Returns a human-readable description of the provider
  public var localizedDescription: String {
    switch self {
      case .cryptoKit, .appleCryptoKit:
        "Apple CryptoKit"
      case .ring:
        "Ring Crypto"
      case .basic:
        "Basic Provider"
      case .system:
        "System Provider"
      case .hsm:
        "Hardware Security Module"
      case .platform:
        "Platform-Optimised Provider"
      case .custom:
        "Custom Provider"
    }
  }

  /// Returns whether the provider is available on the current platform
  public var isAvailable: Bool {
    switch self {
      case .cryptoKit, .appleCryptoKit:
        #if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
          return true
        #else
          return false
        #endif
      case .ring:
        // Ring should be available on all platforms with FFI support
        return true
      case .basic:
        // Basic provider is always available
        return true
      case .system:
        // System provider depends on platform specifics
        #if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
          return true
        #else
          return false
        #endif
      case .hsm:
        // HSM availability requires runtime check
        return false // Default to false, should be checked at runtime
      case .platform, .custom:
        // These are abstract types that need to be resolved to concrete types
        return true
    }
  }
  
  /// Whether this provider supports operation in a sandboxed environment
  public var supportsSandbox: Bool {
    switch self {
      case .cryptoKit, .appleCryptoKit:
        return true
      case .system:
        #if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
          return true
        #else
          return false
        #endif
      case .ring, .basic, .hsm, .platform, .custom:
        return false
    }
  }
  
  /// Whether this provider has cross-platform compatibility
  public var isCrossPlatform: Bool {
    switch self {
      case .ring, .basic:
        return true
      case .cryptoKit, .appleCryptoKit, .system, .hsm, .platform, .custom:
        return false
    }
  }
  
  /// Maps this provider type to the corresponding backend strategy
  public var correspondingBackendStrategy: String {
    switch self {
      case .cryptoKit, .appleCryptoKit:
        return "appleCK"
      case .ring:
        return "ringFFI"
      case .basic, .system, .platform, .custom, .hsm:
        return "restic"
    }
  }
}
