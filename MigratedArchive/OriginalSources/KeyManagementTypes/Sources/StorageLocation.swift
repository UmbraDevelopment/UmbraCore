/// Represents where a cryptographic key is stored
///
/// This is the canonical implementation of StorageLocation used across the UmbraCore framework.
/// It defines the standardised locations where cryptographic keys can be stored.
@frozen
public enum StorageLocation: String, Sendable, Codable, Equatable, Hashable {
  /// Key is stored in the Secure Enclave
  case secureEnclave

  /// Key is stored in the keychain
  case keychain

  /// Key is stored in memory
  case memory
}

// MARK: - CoreServicesTypesNoFoundation Conversions

extension StorageLocation {
  /// Convert to CoreServicesTypesNoFoundation.StorageLocation
  /// - Returns: The equivalent CoreServicesTypesNoFoundation.StorageLocation
  public func toCoreServicesNoFoundation() -> Any {
    // This is a type-erased conversion to avoid direct import
    // The actual type is CoreServicesTypesNoFoundation.StorageLocation
    switch self {
      case .secureEnclave: "secureEnclave"
      case .keychain: "keychain"
      case .memory: "memory"
    }
  }

  /// Create from CoreServicesTypesNoFoundation.StorageLocation
  /// - Parameter coreServicesNoFoundation: The CoreServicesTypesNoFoundation.StorageLocation to
  /// convert from
  /// - Returns: The equivalent canonical StorageLocation
  public static func fromCoreServicesNoFoundation(_ coreServicesNoFoundation: Any)
  -> StorageLocation {
    // This is a type-erased conversion to avoid direct import
    // The actual type is CoreServicesTypesNoFoundation.StorageLocation
    let rawValue=String(describing: coreServicesNoFoundation)
    switch rawValue {
      case "secureEnclave": return .secureEnclave
      case "keychain": return .keychain
      case "memory": return .memory
      default: fatalError("Unknown storage location: \(rawValue)")
    }
  }
}
