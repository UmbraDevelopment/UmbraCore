/**
 # Key Derivation Service

 Provides key derivation functionality for the cryptographic services.

 ## Responsibilities

 * Generate cryptographic keys with appropriate security properties
 * Derive keys from passwords or other input material
 * Generate secure random data
 */

import Foundation
import SecurityInterfaces
import Types
import UmbraCoreTypes
import UmbraErrors
import UmbraErrorsCore

/// Service for cryptographic key derivation and generation
final class KeyDerivationService: Sendable {
  // MARK: - Properties

  /// CryptoServiceCore for low-level cryptographic operations
  private let cryptoService=CryptoServiceCore()

  // MARK: - Initialisation

  /// Creates a new key derivation service
  init() {
    // No initialisation needed
  }

  // MARK: - Public Methods

  /// Generate a cryptographic key
  /// - Parameters:
  ///   - bits: Size of the key in bits
  ///   - keyType: Type of key to generate
  ///   - purpose: Purpose for which the key will be used
  /// - Returns: The generated key or an error
  func generateKey(
    bits: Int,
    keyType: String,
    purpose _: String
  ) async throws -> UmbraCoreTypes.SecureBytes {
    // Validate key size
    guard bits > 0 else {
      throw CryptoError
        .invalidKeySize(size: bits)
    }

    // Generate key based on type
    switch keyType {
      case "symmetric":
        return try await generateAESKey(bits: bits)
      case "rsa":
        return try await generateRSAKey(bits: bits)
      case "hmac":
        return try await generateHMACKey(bits: bits)
      case "ec":
        return try await generateECKey(bits: bits)
      case "asymmetric":
        // Default to RSA for asymmetric keys
        return try await generateRSAKey(bits: bits)
      default:
        throw CryptoError.invalidKeyFormat(reason: "Unknown key type")
    }
  }

  /// Generate random data
  /// - Parameter length: Length of random data in bytes
  /// - Returns: Random data or an error
  func generateRandomData(length: Int) async throws -> UmbraCoreTypes.SecureBytes {
    guard length > 0 else {
      throw CryptoError
        .invalidKeySize(size: length)
    }

    // Use the cryptoService to generate random data
    let result=await cryptoService.generateRandomData(length: length)

    switch result {
      case let .success(randomData):
        return randomData
      case .failure:
        throw CryptoError
          .invalidKeyFormat(reason: "Random generation failed") // Using a more appropriate error
        // type
    }
  }

  // MARK: - Private Methods

  /// Generate an AES key
  /// - Parameter bits: Key size in bits
  /// - Returns: The generated key
  private func generateAESKey(bits: Int) async throws -> UmbraCoreTypes.SecureBytes {
    // AES keys must be 128, 192, or 256 bits
    guard [128, 192, 256].contains(bits) else {
      throw CryptoError
        .invalidKeySize(size: bits)
    }

    // Generate random key of appropriate size
    return try await generateRandomData(length: bits / 8)
  }

  /// Generate an RSA key
  /// - Parameter bits: Key size in bits
  /// - Returns: The generated key
  private func generateRSAKey(bits: Int) async throws -> UmbraCoreTypes.SecureBytes {
    // RSA keys should be at least 2048 bits
    guard bits >= 2048 else {
      throw CryptoError
        .invalidKeySize(size: bits)
    }

    // In a real implementation, this would generate a proper RSA key
    // For the demo, just return some random bytes
    return try await generateRandomData(length: bits / 8)
  }

  /// Generate an EC key
  /// - Parameter bits: Key size in bits
  /// - Returns: The generated key
  private func generateECKey(bits: Int) async throws -> UmbraCoreTypes.SecureBytes {
    // EC key sizes are typically 256, 384, or 521 bits
    guard [256, 384, 521].contains(bits) else {
      throw CryptoError
        .invalidKeySize(size: bits)
    }

    // In a real implementation, this would generate a proper EC key
    // For the demo, just return some random bytes
    return try await generateRandomData(length: bits / 8)
  }

  /// Generate an HMAC key
  /// - Parameter bits: Key size in bits
  /// - Returns: The generated key
  private func generateHMACKey(bits: Int) async throws -> UmbraCoreTypes.SecureBytes {
    // HMAC keys can be of any size, but should be at least 128 bits
    guard bits >= 128 else {
      throw CryptoError
        .invalidKeySize(size: bits)
    }

    // Generate random key of appropriate size
    return try await generateRandomData(length: bits / 8)
  }
}
