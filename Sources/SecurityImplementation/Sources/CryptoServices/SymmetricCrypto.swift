/**
 # UmbraCore Symmetric Cryptography Service

 This file provides symmetric encryption capabilities for the UmbraCore security framework.
 It implements the symmetric encryption portions of the CryptoServiceProtocol and provides
 AES-GCM encryption with appropriate security measures.

 ## Security Considerations

 * Symmetric encryption uses AES-GCM with 256-bit keys, which is considered strong by
   current standards.
 * Memory safety is implemented via SecureBytes containers which provide basic memory
   protections.
 * The implementation doesn't currently include mitigations for timing attacks or other
   side-channel vulnerabilities.
 */

import CoreErrors
import ErrorHandlingDomains
import Foundation
import SecurityProtocolsCore
import UmbraCoreTypes

/// Provides symmetric encryption operations to the CryptoService.
///
/// This struct offers methods for encrypting and decrypting data using symmetric
/// cryptographic algorithms, with both basic and advanced configuration options.
public struct SymmetricCrypto: Sendable {
  // MARK: - Initialisation

  /// Creates a new instance of SymmetricCrypto.
  public init() {
    // No initialisation needed - stateless service
  }

  // MARK: - Public API

  /// Encrypts data using the specified key.
  /// - Parameters:
  ///   - data: The data to encrypt.
  ///   - key: The encryption key (should be 256 bits / 32 bytes).
  /// - Returns: Encrypted data or error if encryption fails.
  ///
  /// This function uses AES-GCM with a random IV. The IV is prepended to the
  /// encrypted data in the returned SecureBytes object (first 12 bytes).
  ///
  /// The format of the returned data is: [IV (12 bytes)][Encrypted data with authentication tag]
  public func encrypt(
    data: SecureBytes,
    using key: SecureBytes
  ) async -> Result<SecureBytes, UmbraErrors.Security.Protocols> {
    do {
      // Generate a random IV
      let iv=CryptoWrapper.generateRandomIVSecure()

      // Encrypt the data with AES-GCM
      let encryptedData=try CryptoWrapper.aesEncrypt(data: data, key: key, iv: iv)

      // Prepend the IV to the encrypted data
      let result=SecureBytes.combine(iv, encryptedData)

      return .success(result)
    } catch {
      return .failure(.encryptionFailed(
        reason: "Symmetric encryption failed: \(error.localizedDescription)"
      ))
    }
  }

  /// Decrypts data using the specified key.
  /// - Parameters:
  ///   - data: The encrypted data (should include the IV as first 12 bytes).
  ///   - key: The decryption key (should be 256 bits / 32 bytes).
  /// - Returns: Decrypted data or error if decryption fails.
  ///
  /// This function expects the input data to be in the format produced by the encrypt function:
  /// [IV (12 bytes)][Encrypted data with authentication tag]
  public func decrypt(
    data: SecureBytes,
    using key: SecureBytes
  ) async -> Result<SecureBytes, UmbraErrors.Security.Protocols> {
    do {
      // Ensure data is long enough to contain the IV
      guard data.count > 12 else {
        return .failure(.invalidInput(reason: "Encrypted data too short"))
      }

      // Extract the IV and ciphertext
      let splitResult=try data.split(at: 12)
      let iv=splitResult.0
      let encryptedData=splitResult.1

      // Decrypt the data
      let decryptedData=try CryptoWrapper.aesDecrypt(data: encryptedData, key: key, iv: iv)

      return .success(decryptedData)
    } catch {
      return .failure(.decryptionFailed(
        reason: "Symmetric decryption failed: \(error.localizedDescription)"
      ))
    }
  }

  /// Encrypt data using a symmetric key with advanced configuration.
  /// - Parameters:
  ///   - data: Data to encrypt.
  ///   - key: Symmetric key for encryption.
  ///   - config: Configuration options.
  /// - Returns: Result containing encrypted data or error.
  public func encryptSymmetric(
    data: SecureBytes,
    key: SecureBytes,
    config: SecurityConfigDTO
  ) async -> Result<SecureBytes, UmbraErrors.Security.Protocols> {
    do {
      // Use IV from config or generate a random one
      let iv=config.initializationVector ?? CryptoWrapper.generateRandomIVSecure()

      // Encrypt the data with the provided or random IV
      let encryptedData=try CryptoWrapper.aesEncrypt(data: data, key: key, iv: iv)

      // If IV was not in config, we need to prepend it to the result
      let result=config.initializationVector != nil ?
        encryptedData :
        SecureBytes.combine(iv, encryptedData)

      return .success(result)
    } catch {
      return .failure(.encryptionFailed(
        reason: "Symmetric encryption with config failed: \(error.localizedDescription)"
      ))
    }
  }

  /// Decrypt data using a symmetric key with advanced configuration.
  /// - Parameters:
  ///   - data: Data to decrypt.
  ///   - key: Symmetric key for decryption.
  ///   - config: Configuration options.
  /// - Returns: Result containing decrypted data or error.
  public func decryptSymmetric(
    data: SecureBytes,
    key: SecureBytes,
    config: SecurityConfigDTO
  ) async -> Result<SecureBytes, UmbraErrors.Security.Protocols> {
    do {
      let iv: SecureBytes
      let dataToDecrypt: SecureBytes

      if let providedIv=config.initializationVector {
        // If IV is provided in config, use it
        iv=providedIv
        dataToDecrypt=data
      } else {
        // Extract IV from data (first 12 bytes)
        guard data.count > 12 else {
          return .failure(.invalidInput(reason: "Encrypted data too short"))
        }

        let splitResult=try data.split(at: 12)
        iv=splitResult.0
        dataToDecrypt=splitResult.1
      }

      // Decrypt the data
      let decryptedData=try CryptoWrapper.aesDecrypt(data: dataToDecrypt, key: key, iv: iv)

      return .success(decryptedData)
    } catch {
      return .failure(.decryptionFailed(
        reason: "Symmetric decryption with config failed: \(error.localizedDescription)"
      ))
    }
  }
}
