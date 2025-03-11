import KeyManagementTypes

/// Represents where a cryptographic key is stored
///
/// - Important: This type is deprecated. Please use `KeyManagementTypes.StorageLocation` instead.
///
/// The canonical implementation is available in the KeyManagementTypes module and provides
/// a standardised representation used across the UmbraCore framework.
@frozen
@available(*, deprecated, message: "Please use KeyManagementTypes.StorageLocation instead")
public enum StorageLocation: String, Sendable, Codable {
  /// Key is stored in the Secure Enclave
  case secureEnclave
  /// Key is stored in the keychain
  case keychain
  /// Key is stored in memory
  case memory

  /// Convert to the canonical StorageLocation type
  /// - Returns: The equivalent canonical StorageLocation
  public func toCanonical() -> KeyManagementTypes.StorageLocation {
    // Use the raw conversion method
    switch self {
      case .secureEnclave: .secureEnclave
      case .keychain: .keychain
      case .memory: .memory
    }
  }

  /// Create from the canonical StorageLocation type
  /// - Parameter canonical: The canonical StorageLocation to convert from
  /// - Returns: The equivalent legacy StorageLocation
  public static func from(canonical: KeyManagementTypes.StorageLocation) -> StorageLocation {
    // Use the raw conversion method
    switch canonical {
      case .secureEnclave: .secureEnclave
      case .keychain: .keychain
      case .memory: .memory
    }
  }
}
