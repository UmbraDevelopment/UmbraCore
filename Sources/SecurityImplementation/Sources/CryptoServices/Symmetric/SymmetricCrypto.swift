/**
 # UmbraCore Symmetric Cryptography Service

 This file provides implementation of symmetric cryptographic operations
 for the UmbraCore security framework, including AES encryption and decryption.

 ## Responsibilities

 * Symmetric key encryption and decryption
 * Support for various AES modes (GCM, CBC, etc.)
 * Parameter validation and secure operation
 * Initialisation vector generation
 */

import CryptoSwiftFoundationIndependent
import ErrorHandlingDomains
import Foundation
import SecurityProtocolsCore
import UmbraCoreTypes

/// Service for symmetric cryptographic operations
final class SymmetricCrypto: Sendable {
  // MARK: - Initialisation

  /// Creates a new symmetric cryptography service
  init() {
    // Initialize any resources needed
  }

  // MARK: - Public Methods

  /// Encrypt data using a symmetric key
  /// - Parameters:
  ///   - data: Data to encrypt
  ///   - key: Encryption key
  ///   - algorithm: Encryption algorithm to use (e.g., "AES-GCM")
  ///   - iv: Optional initialisation vector
  /// - Returns: Result of the encryption operation
  func encryptData(
    data: SecureBytes,
    key: SecureBytes,
    algorithm: String,
    iv initialIV: SecureBytes?
  ) async -> SecurityResultDTO {
    // Validate inputs
    guard !data.isEmpty else {
      return SecurityResultDTO(
        success: false,
        error: UmbraErrors.Security.Protocols.invalidInput("Cannot encrypt empty data")
      )
    }

    guard !key.isEmpty else {
      return SecurityResultDTO(
        success: false,
        error: UmbraErrors.Security.Protocols.invalidInput("Encryption key cannot be empty")
      )
    }

    // Validate key size based on algorithm
    if algorithm == "AES-GCM" {
      // AES-256 requires a 32-byte key
      guard key.count == 32 else {
        return SecurityResultDTO(
          success: false,
          error: UmbraErrors.Security.Protocols
            .invalidInput("AES-256-GCM requires a 32-byte key, but got \(key.count) bytes"),
          errorDetails: "AES-256-GCM requires a 32-byte key, but got \(key.count) bytes"
        )
      }
    }

    // Use CryptoWrapper for real encryption
    do {
      // Generate IV if not provided
      let iv=initialIV ?? CryptoWrapper.generateRandomIVSecure()

      // Encrypt data using the CryptoWrapper
      // For AES-GCM, the IV is typically 12 bytes and is used for nonce
      if algorithm == "AES-GCM" {
        let encryptedData=try CryptoWrapper.encryptAES_GCM(
          data: data,
          key: key,
          iv: iv
        )

        // Combine IV and encrypted data for proper decryption later
        // Format: IV + EncryptedData
        let combinedData=SecureBytes.combine(iv, encryptedData)

        return SecurityResultDTO(data: combinedData)
      } else {
        // Unsupported algorithm
        return SecurityResultDTO(
          success: false,
          error: UmbraErrors.Security.Protocols
            .unsupportedOperation(name: "Encryption algorithm \(algorithm)")
        )
      }
    } catch {
      return SecurityResultDTO(
        success: false,
        error: UmbraErrors.Security.Protocols
          .encryptionFailed("Encryption failed: \(error.localizedDescription)")
      )
    }
  }

  /// Decrypt data using a symmetric key
  /// - Parameters:
  ///   - data: Data to decrypt
  ///   - key: Decryption key
  ///   - algorithm: Decryption algorithm to use (e.g., "AES-GCM")
  ///   - iv: Optional initialisation vector
  /// - Returns: Result of the decryption operation
  func decryptData(
    data: SecureBytes,
    key: SecureBytes,
    algorithm: String,
    iv explicitIV: SecureBytes?
  ) async -> SecurityResultDTO {
    // Validate inputs
    guard !data.isEmpty else {
      return SecurityResultDTO(
        success: false,
        error: UmbraErrors.Security.Protocols.invalidInput("Cannot decrypt empty data")
      )
    }

    guard !key.isEmpty else {
      return SecurityResultDTO(
        success: false,
        error: UmbraErrors.Security.Protocols.invalidInput("Decryption key cannot be empty")
      )
    }

    // Validate key size based on algorithm
    if algorithm == "AES-GCM" {
      // AES-256 requires a 32-byte key
      guard key.count == 32 else {
        return SecurityResultDTO(
          success: false,
          error: UmbraErrors.Security.Protocols
            .invalidInput("AES-256-GCM requires a 32-byte key, but got \(key.count) bytes"),
          errorDetails: "AES-256-GCM requires a 32-byte key, but got \(key.count) bytes"
        )
      }
    }

    do {
      // For AES-GCM decryption
      if algorithm == "AES-GCM" {
        // If we have explicit IV, use it and the data as is
        if let iv=explicitIV {
          let decryptedData=try CryptoWrapper.decryptAES_GCM(
            data: data,
            key: key,
            iv: iv
          )
          return SecurityResultDTO(data: decryptedData)
        }
        // Otherwise, extract IV from the combined data
        else if data.count > 12 { // Minimum size for IV + any data
          // Extract IV (first 12 bytes) and encrypted data
          let iv=data[0..<12]
          let encryptedData=data[12..<data.count]

          // Decrypt using the extracted IV
          let decryptedData=try CryptoWrapper.decryptAES_GCM(
            data: encryptedData,
            key: key,
            iv: iv
          )
          return SecurityResultDTO(data: decryptedData)
        } else {
          return SecurityResultDTO(
            success: false,
            error: UmbraErrors.Security.Protocols
              .invalidFormat(reason: "Data too short to contain IV and encrypted content")
          )
        }
      } else {
        // Unsupported algorithm
        return SecurityResultDTO(
          success: false,
          error: UmbraErrors.Security.Protocols
            .unsupportedOperation(name: "Decryption algorithm \(algorithm)")
        )
      }
    } catch {
      return SecurityResultDTO(
        success: false,
        error: UmbraErrors.Security.Protocols
          .invalidFormat(reason: "Unable to decrypt data: invalid format")
      )
    }
  }

  /// Generate an initialisation vector appropriate for the specified algorithm
  /// - Parameter algorithm: The encryption algorithm
  /// - Returns: A randomly generated IV or nil if the algorithm doesn't need one
  func generateIV(for algorithm: String) -> SecureBytes? {
    // Determine the appropriate IV size based on the algorithm
    var ivSize: Int

    if algorithm.starts(with: "AES-GCM") {
      ivSize=12 // 96 bits for GCM mode
    } else if algorithm.starts(with: "AES-CBC") || algorithm.starts(with: "AES-CTR") {
      ivSize=16 // 128 bits for CBC and CTR modes
    } else {
      // No IV needed or unknown algorithm
      return nil
    }

    // Use CryptoWrapper to generate random IV
    return CryptoWrapper.generateRandomIVSecure(size: ivSize)
  }
}
