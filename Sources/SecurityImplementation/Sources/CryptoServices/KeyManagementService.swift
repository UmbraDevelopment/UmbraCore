/**
 # UmbraCore Key Management Service

 This file provides key generation and management capabilities for the UmbraCore security
 framework. It implements the key management portions of the CryptoServiceProtocol and provides
 secure methods for generating cryptographic keys and random data.

 ## Security Considerations

 * Keys are generated using cryptographically secure random number generators.
 * Keys are stored in SecureBytes containers which provide basic memory protections.
 * Care should be taken to properly dispose of keys when they are no longer needed.
 */

import CoreErrors
import ErrorHandlingDomains
import Foundation
import SecurityProtocolsCore
import UmbraCoreTypes

/// Provides key management operations to the CryptoService.
///
/// This struct implements methods for generating and deriving cryptographic keys
/// and producing secure random data for use throughout the security framework.
public struct KeyManagementService: Sendable {
  // MARK: - Initialisation

  /// Creates a new instance of KeyManagementService.
  public init() {
    // No initialisation needed - stateless service
  }

  // MARK: - Public API

  /// Generates a cryptographic key suitable for encryption/decryption operations.
  /// - Returns: A new cryptographic key as `SecureBytes` or an error.
  public func generateKey() async -> Result<SecureBytes, UmbraErrors.Security.Protocols> {
    // Generate a random 256-bit (32-byte) key
    let key=CryptoWrapper.generateRandomKeySecure()
    return .success(key)
  }

  /// Generate cryptographically secure random data.
  /// - Parameter length: The length of random data to generate in bytes.
  /// - Returns: Result containing random data or error.
  public func generateRandomData(
    length: Int
  ) async -> Result<SecureBytes, UmbraErrors.Security.Protocols> {
    // Input validation
    guard length > 0 else {
      return .failure(.invalidInput(reason: "Random data length must be greater than zero"))
    }

    guard length <= 1024 * 1024 else {
      return .failure(.invalidInput(
        reason: "Random data length exceeds maximum allowed (1MB)"
      ))
    }

    // Generate random data
    var randomBytes=[UInt8](repeating: 0, count: length)
    let status=SecRandomCopyBytes(kSecRandomDefault, length, &randomBytes)

    if status == errSecSuccess {
      return .success(SecureBytes(bytes: randomBytes))
    } else {
      return .failure(.randomGenerationFailed(reason: "Failed to generate random data"))
    }
  }

  /// Derives a key from a password using a secure key derivation function.
  /// - Parameters:
  ///   - password: The password to derive the key from.
  ///   - salt: Salt value to use in the derivation process.
  ///   - iterations: Number of iterations to use in the derivation.
  ///   - keyLength: Length of the derived key in bytes.
  /// - Returns: The derived key or an error.
  public func deriveKey(
    from password: SecureBytes,
    salt: SecureBytes,
    iterations: Int=10000,
    keyLength: Int=32
  ) async -> Result<SecureBytes, UmbraErrors.Security.Protocols> {
    // Input validation
    guard !password.isEmpty, !salt.isEmpty else {
      return .failure(.invalidInput(reason: "Password or salt is empty"))
    }

    guard iterations >= 1000 else {
      return .failure(.invalidInput(
        reason: "Iteration count too low, minimum 1000 required"
      ))
    }

    guard keyLength >= 16, keyLength <= 64 else {
      return .failure(.invalidInput(
        reason: "Key length must be between 16 and 64 bytes"
      ))
    }

    do {
      // Use PBKDF2 via CryptoWrapper
      let derivedKey=try CryptoWrapper.deriveKey(
        password: password,
        salt: salt,
        iterations: iterations,
        keyLength: keyLength
      )

      return .success(derivedKey)
    } catch {
      return .failure(.internalError(
        "Key derivation failed: \(error.localizedDescription)"
      ))
    }
  }
}
