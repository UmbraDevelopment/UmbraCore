/**
 # FoundationCryptoAdapter

 This adapter provides integration between UmbraCore's security interfaces and
 Foundation's cryptographic functionality. It allows Foundation-based applications
 to use UmbraCore security services with minimal integration effort.

 ## Responsibilities

 * Adapt UmbraCore security interfaces to Foundation types and patterns
 * Convert between Foundation data types and UmbraCore secure types
 * Handle error translation between systems
 * Provide convenience methods for common Foundation-based security operations
 */

import Foundation
import SecurityCoreInterfaces
import SecurityCoreTypes
import SecurityInterfaces
import SecurityProviders
import SecurityTypes
import SecurityUtils
import UmbraErrors

/// Adapter that integrates UmbraCore's security interfaces with Foundation
public final class FoundationCryptoAdapter: Sendable {
  // MARK: - Properties

  /// The underlying application security provider
  private let securityProvider: ApplicationSecurityProviderProtocol

  // MARK: - Initialisation

  /// Create a new adapter with the specified security provider
  /// - Parameter securityProvider: The application security provider to adapt
  public init(securityProvider: ApplicationSecurityProviderProtocol = ApplicationSecurityProviderService()) {
    self.securityProvider = securityProvider
  }

  // MARK: - Public API

  /// Encrypt data using the provided key
  /// - Parameters:
  ///   - data: Data to encrypt
  ///   - key: Key to use for encryption
  /// - Returns: Encrypted data
  public func encrypt(_ data: Data, using key: Data) async throws -> Data {
    let secureData = data.toSecureBytes()
    let secureKey = key.toSecureBytes()

    // Use defer to ensure secure data is zeroed after use
    defer {
      var keyCopy = secureKey
      MemoryProtection.secureZero(&keyCopy)
    }

    // Store the key with a unique identifier for this operation
    let keyID = UUID().uuidString
    try await securityProvider.keyManager.storeKey(secureKey, withIdentifier: keyID)
    
    // Create encryption configuration
    let encryptionConfig = EncryptionConfig(
      keyID: keyID,
      algorithm: .aes256GCM
    )
    
    // Perform encryption
    do {
      let result = try await securityProvider.encrypt(
        data: data,
        with: encryptionConfig
      )
      
      return result.encryptedData
    } catch {
      throw CryptoError.encryptionFailed(
        error.localizedDescription,
        context: CryptoErrorContext(
          operation: "encrypt",
          details: ["dataSize": "\(data.count)", "keySize": "\(key.count)"]
        )
      )
    }
  }

  /// Decrypt data using the provided key
  /// - Parameters:
  ///   - data: Data to decrypt
  ///   - key: Key to use for decryption
  /// - Returns: Decrypted data
  public func decrypt(_ data: Data, using key: Data) async throws -> Data {
    let secureData = data.toSecureBytes()
    let secureKey = key.toSecureBytes()

    // Use defer to ensure secure data is zeroed after use
    defer {
      var keyCopy = secureKey
      MemoryProtection.secureZero(&keyCopy)
    }

    // Store the key with a unique identifier for this operation
    let keyID = UUID().uuidString
    try await securityProvider.keyManager.storeKey(secureKey, withIdentifier: keyID)
    
    // Create decryption configuration
    let decryptionConfig = EncryptionConfig(
      keyID: keyID,
      algorithm: .aes256GCM
    )
    
    // Perform decryption
    do {
      let result = try await securityProvider.decrypt(
        data: data,
        with: decryptionConfig
      )
      
      return result.decryptedData
    } catch {
      throw CryptoError.decryptionFailed(
        error.localizedDescription,
        context: CryptoErrorContext(
          operation: "decrypt",
          details: ["dataSize": "\(data.count)", "keySize": "\(key.count)"]
        )
      )
    }
  }

  /// Generate a random key of the specified size
  /// - Parameter size: Size of the key in bytes
  /// - Returns: The generated key
  public func generateKey(size: Int = 32) async throws -> Data {
    let keyConfig = KeyGenerationConfig(
      keyType: .encryption,
      keySize: size * 8
    )
    
    do {
      let result = try await securityProvider.generateKey(with: keyConfig)
      
      if let keyData = result.key {
        return keyData
      } else {
        // If key wasn't directly returned but stored with an ID, retrieve it
        let key = try await securityProvider.keyManager.retrieveKey(withIdentifier: result.keyID)
        return key.extractUnderlyingData()
      }
    } catch {
      throw CryptoError.keyGenerationFailed(
        error.localizedDescription,
        context: CryptoErrorContext(
          operation: "generateKey",
          details: ["keySize": "\(size * 8)"]
        )
      )
    }
  }

  /// Generate a hash of the provided data
  /// - Parameters:
  ///   - data: Data to hash
  ///   - algorithm: Hash algorithm to use (default: SHA-256)
  /// - Returns: The hash value
  public func hash(_ data: Data, using algorithm: HashAlgorithm = .sha256) async throws -> Data {
    let hashConfig = HashConfig(algorithm: algorithm)
    
    do {
      let result = try await securityProvider.hash(data: data, with: hashConfig)
      return result.hashValue
    } catch {
      throw CryptoError.hashingFailed(
        error.localizedDescription,
        context: CryptoErrorContext(
          operation: "hash",
          details: ["algorithm": "\(algorithm)", "dataSize": "\(data.count)"]
        )
      )
    }
  }
}

/// Errors specific to cryptographic operations
public enum CryptoError: Error, LocalizedError {
  case encryptionFailed(String, context: CryptoErrorContext)
  case decryptionFailed(String, context: CryptoErrorContext)
  case keyGenerationFailed(String, context: CryptoErrorContext)
  case hashingFailed(String, context: CryptoErrorContext)
  
  public var errorDescription: String? {
    switch self {
    case let .encryptionFailed(message, _):
      return "Encryption failed: \(message)"
    case let .decryptionFailed(message, _):
      return "Decryption failed: \(message)"
    case let .keyGenerationFailed(message, _):
      return "Key generation failed: \(message)"
    case let .hashingFailed(message, _):
      return "Hashing failed: \(message)"
    }
  }
}

/// Context information for crypto errors
public struct CryptoErrorContext: Sendable {
  public let operation: String
  public let details: [String: String]

  public init(operation: String, details: [String: String] = [:]) {
    self.operation = operation
    self.details = details
  }
}
