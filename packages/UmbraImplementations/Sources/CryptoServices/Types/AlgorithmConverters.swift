import CoreSecurityTypes
import Foundation

/**
 # Algorithm Converters

 This file provides conversion utilities between algorithm types in different modules
 to handle namespace conflicts and maintain proper type safety.
 */

/// Extension to convert CryptoServices.EncryptionAlgorithm to CoreSecurityTypes.EncryptionAlgorithm
extension EncryptionAlgorithm {
  /// Convert to CoreSecurityTypes.EncryptionAlgorithm
  func toCoreSecurityType() -> CoreSecurityTypes.EncryptionAlgorithm {
    switch self {
      case .aes256CBC:
        .aes256CBC
      case .aes256GCM:
        .aes256GCM
    }
  }

  /// Create from CoreSecurityTypes.EncryptionAlgorithm
  static func from(coreType: CoreSecurityTypes.EncryptionAlgorithm) -> EncryptionAlgorithm {
    switch coreType {
      case .aes256CBC:
        .aes256CBC
      case .aes256GCM:
        .aes256GCM
      case .chacha20Poly1305:
        // Default to a supported algorithm since we don't have chacha20Poly1305
        .aes256GCM
    }
  }
}
