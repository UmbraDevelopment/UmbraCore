import Foundation
import KeyManagementTypes

/// Represents where a cryptographic key is stored
///
/// - Important: This type is deprecated. Please use the canonical
/// `KeyManagementTypes.StorageLocation` instead.
///
/// The canonical implementation is available in the KeyManagementTypes module and provides
/// a standardised representation used across the UmbraCore framework.
/// Extension to provide conversion to/from the raw representation
/// This will be used by KeyManagementTypes module through type extension
@available(
  *,
  deprecated,
  message: "Please use the canonical KeyManagementTypes.StorageLocation instead"
)
// Removed public enum StorageLocation definition in favor of using
// KeyManagementTypes.StorageLocation directly

// MARK: - Raw Conversion Extension (for KeyManagementTypes)

extension KeyManagementTypes.StorageLocation {
  /// The raw representation that matches the canonical type's raw locations
  public enum RawRepresentation: String, Codable, Equatable {
    case secureEnclave
    case keychain
    case memory
  }

  /// Convert to a raw representation that can be used by KeyManagementTypes
  /// - Returns: The raw representation
  public func toRawRepresentation() -> RawRepresentation {
    switch self {
      case .secureEnclave: .secureEnclave
      case .keychain: .keychain
      case .memory: .memory
    }
  }

  /// Create from a raw representation coming from KeyManagementTypes
  /// - Parameter rawRepresentation: The raw representation to convert from
  /// - Returns: The equivalent canonical StorageLocation
  public static func from(rawRepresentation: RawRepresentation) -> KeyManagementTypes
  .StorageLocation {
    switch rawRepresentation {
      case .secureEnclave: KeyManagementTypes.StorageLocation.secureEnclave
      case .keychain: KeyManagementTypes.StorageLocation.keychain
      case .memory: KeyManagementTypes.StorageLocation.memory
    }
  }
}
