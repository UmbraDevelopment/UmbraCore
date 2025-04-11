import Foundation
import SecurityInterfaces

/**
 # BasicCryptoOperationTypes

 Type definitions required for cryptographic operations in the BasicSecurityProvider.

 This provides compatibility types that bridge between different parts of the
 cryptographic architecture while maintaining clear boundaries between modules.
 */

/**
 Represents a cryptographic operation type.

 Each operation corresponds to a specific cryptographic function
 performed by the security provider.
 */
public enum SecureOperationType: String, Sendable, Equatable {
  /// Encryption operation
  case encrypt

  /// Decryption operation
  case decrypt

  /// Hash operation
  case hash

  /// Hash verification operation
  case verify

  /// Key generation operation
  case generateKey
}

/**
 Protocol for cryptographic material that can be safely used in concurrent contexts.

 This protocol is implemented by types that represent cryptographic keys,
 certificates, and other sensitive materials.
 */
public protocol SendableCryptoMaterial: Sendable, Equatable {}

/**
 Basic implementation of cryptographic material using Foundation.Data.

 This provides a simple way to use Data as SendableCryptoMaterial.
 */
extension Data: SendableCryptoMaterial {}
