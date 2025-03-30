import Foundation

/**
 # SecurityProviderType

 Defines the available security provider implementations in UmbraCore.

 This enumeration allows developers to select between different security
 implementations based on their requirements for platform support,
 performance, and feature set.
 */
public enum SecurityProviderType: String, Sendable, Codable, CaseIterable {
  /// Basic security provider using AES-CBC (fallback option)
  case basic

  /// Cross-platform security using Ring FFI (Rust crypto library)
  case ring

  /// Native Apple platform security using CryptoKit
  case apple

  /**
   Returns the default provider type for the current platform.

   On Apple platforms, this will prefer the CryptoKit implementation
   when available, falling back to other options as necessary.
   */
  public static var defaultProvider: SecurityProviderType {
    #if canImport(CryptoKit) && !DEBUG_FORCE_BASIC_PROVIDER
      return .apple
    #elseif canImport(RingCrypto) && !DEBUG_FORCE_BASIC_PROVIDER
      return .ring
    #else
      return .basic
    #endif
  }

  /// Human-readable description of the provider
  public var description: String {
    switch self {
      case .basic:
        "Basic AES-CBC Security Provider"
      case .ring:
        "Ring FFI Security Provider"
      case .apple:
        "Apple CryptoKit Security Provider"
    }
  }
}
