// CryptoKit removed - cryptography will be handled in ResticBar
import CoreErrors
import CryptoTypes
import Foundation

/// Service for performing cryptographic operations
/// This is a placeholder implementation that will be replaced by ResticBar
/// @deprecated This will be replaced by CryptoTypes.CryptoService in a future version.
/// New code should use CryptoTypes.CryptoService instead.
@available(
  *,
  deprecated,
  message: "This will be replaced by CryptoTypes.CryptoService in a future version. Use CryptoTypes.CryptoService protocol instead."
)
public actor CryptoService {
  /// Shared instance of the crypto service
  public static let shared=CryptoService()

  private init() {}

  /// Generate a new symmetric key
  /// - Parameters:
  ///   - algorithm: The algorithm to use for key generation
  ///   - keySize: The size of the key in bits
  /// - Returns: The generated key data
  public func generateSymmetricKey(algorithm _: String, keySize _: Int) throws -> Data {
    // Placeholder implementation - will be replaced by ResticBar
    throw NSError(domain: "CryptoService", code: -1, userInfo: [
      NSLocalizedDescriptionKey: "Cryptography functionality has been moved to ResticBar"
    ])
  }

  /// Encrypt data using a symmetric key
  /// - Parameters:
  ///   - data: Data to encrypt
  ///   - key: Key to use for encryption
  /// - Returns: Encrypted data
  public func encrypt(_: Data, using _: Data) throws -> Data {
    // Placeholder implementation - will be replaced by ResticBar
    throw NSError(domain: "CryptoService", code: -1, userInfo: [
      NSLocalizedDescriptionKey: "Cryptography functionality has been moved to ResticBar"
    ])
  }

  /// Decrypt data using a symmetric key
  /// - Parameters:
  ///   - data: Data to decrypt
  ///   - key: Key to use for decryption
  /// - Returns: Decrypted data
  public func decrypt(_: Data, using _: Data) throws -> Data {
    // Placeholder implementation - will be replaced by ResticBar
    throw NSError(domain: "CryptoService", code: -1, userInfo: [
      NSLocalizedDescriptionKey: "Cryptography functionality has been moved to ResticBar"
    ])
  }
}

/// Errors that can occur during cryptographic operations
/// @deprecated This will be replaced by CoreErrors.CryptoError in a future version.
/// New code should use CoreErrors.CryptoError directly.
@available(
  *,
  deprecated,
  message: "This will be replaced by CoreErrors.CryptoError in a future version. Use CoreErrors.CryptoError directly."
)
