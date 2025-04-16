import CoreSecurityTypes
import Foundation

/// This file maintains backward compatibility with the SecurityProviderType from CoreSecurityTypes.
///
/// In the Alpha Dot Five architecture, we explicitly use SecurityProviderType instead of the
/// legacy CryptoServiceType. This file maps between the two for transitional purposes.
///
/// Developers must explicitly choose which implementation to use based on their
/// requirements, rather than rely on automatic selection. Each type provides different
/// features, compatibility, and security characteristics.
///
/// ## Implementation Types
///
/// - `basic`: Default implementation using AES encryption, for general use cases.
///
/// - `ring`: Implementation using Ring cryptography library.
///   Features cross-platform compatibility and works in any environment.
///
/// - `appleCryptoKit`: Apple-native implementation using CryptoKit.
///   Optimised specifically for Apple platforms with hardware acceleration.
///
/// - `platform`: Platform-specific implementation that selects the best
///   provider for the current platform.
@available(*, deprecated, message: "Use SecurityProviderType directly instead")
public enum CryptoServiceType: String, Sendable {
  /// Default implementation using AES for general use
  case standard

  /// Cross-platform implementation using Ring
  case crossPlatform

  /// Apple-specific implementation using CryptoKit
  case applePlatform

  /// Custom implementation
  case custom

  /// Hardware Security Module
  case hardwareSecurity

  /// Converts to the equivalent SecurityProviderType
  public var securityProviderType: SecurityProviderType {
    switch self {
      case .standard:
        .basic
      case .crossPlatform:
        .ring
      case .applePlatform:
        .appleCryptoKit
      case .custom:
        .custom
      case .hardwareSecurity:
        .hsm
    }
  }

  /// Converts from SecurityProviderType
  ///
  /// - Parameter providerType: The provider type to convert
  /// - Returns: The equivalent CryptoServiceType
  public static func from(providerType: SecurityProviderType) -> CryptoServiceType {
    switch providerType {
      case .basic:
        return .standard
      case .ring:
        return .crossPlatform
      case .appleCryptoKit:
        return .applePlatform
      case .custom:
        return .custom
      case .cryptoKit:
        return .applePlatform  // CryptoKit is Apple platform specific
      case .system:
        return .standard       // System cryptography maps to standard implementation
      case .hsm:
        return .hardwareSecurity // Hardware Security Module
      case .platform:
        return .applePlatform  // Platform cryptography on Apple devices
    }
  }

  /// Determines if the implementation is available on the current platform
  public var isAvailableOnCurrentPlatform: Bool {
    switch self {
      case .standard:
        // Standard implementation is available everywhere
        return true
      case .crossPlatform:
        // Cross-platform implementation is available everywhere
        return true
      case .applePlatform:
        // Apple implementation is only available on Apple platforms
        #if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
          return true
        #else
          return false
        #endif
      case .custom:
        // Custom implementation requires explicit availability check
        return false
      case .hardwareSecurity:
        // Hardware Security Module availability is unknown
        return false
    }
  }
}
