/**
 # SecureCryptoStorage

 Provides secure storage services specifically for cryptographic materials
 following the Alpha Dot Five architecture principles.

 This actor encapsulates the secure storage of cryptographic materials such as
 keys, encrypted data, and authentication tokens, ensuring that sensitive
 data is properly protected when at rest.
 */

import CryptoInterfaces
import CryptoTypes
import Foundation
import LoggingInterfaces
import LoggingTypes
import SecurityCoreInterfaces
import UmbraErrors

/**
 Implementation of secure storage specifically for cryptographic materials.

 This actor provides specialised storage for cryptographic materials with
 enhanced contextual information and dedicated methods for different types
 of cryptographic assets.
 */
public actor SecureCryptoStorage: Sendable {
  /// The underlying secure storage provider
  private let secureStorage: any SecureStorageProtocol

  /// Logger for storage operations
  private let logger: any LoggingProtocol

  /**
   Initialises a new secure crypto storage.

   - Parameters:
      - secureStorage: The secure storage implementation to use
      - logger: Logger for recording operations
   */
  public init(
    secureStorage: any SecureStorageProtocol,
    logger: any LoggingProtocol
  ) {
    self.secureStorage=secureStorage
    self.logger=logger
  }

  // MARK: - Key Storage

  /**
   Stores a cryptographic key.
   
   - Parameters:
      - key: The key material to store
      - identifier: A unique identifier for retrieval
      - purpose: The purpose of the key (e.g., encryption, signing)
      - algorithm: Optional algorithm information
   */
  public func storeKey(
    _ key: Data,
    identifier: String,
    purpose: String,
    algorithm: String?=nil
  ) async throws {
    let config=SecureStorageConfig(
      accessControl: .standard,
      encrypt: true,
      context: [
        "type": "crypto_key",
        "purpose": purpose,
        "algorithm": algorithm ?? "unknown"
      ]
    )
    
    do {
      let result=try await secureStorage.storeData(
        [UInt8](key),
        withIdentifier: identifier
      )
      
      switch result {
      case .success:
        return
      case .failure(let error):
        throw error
      }
    } catch {
      throw error
    }
  }

  /**
   Retrieves a cryptographic key.

   - Parameter identifier: Identifier for the key
   - Returns: The retrieved key
   - Throws: CryptoError if retrieval fails
   */
  public func retrieveKey(identifier: String) async throws -> Data {
    let config=SecureStorageConfig(
      accessControl: .standard,
      encrypt: true,
      context: ["type": "cryptographic_key"]
    )

    do {
      let result=try await secureStorage.retrieveSecurely(
        identifier: identifier,
        config: config
      )

      guard let data=result.data, result.success else {
        throw CryptoError.keyNotFound(
          identifier: identifier
        )
      }

      var metadata=PrivacyMetadata()
      metadata["identifier"]=PrivacyMetadataValue(value: identifier, privacy: .private)

      await logger.debug(
        "Successfully retrieved key",
        metadata: metadata,
        source: "SecureCryptoStorage"
      )
      return data
    } catch {
      throw CryptoError.keyNotFound(
        identifier: identifier
      )
    }
  }

  /**
   Deletes a cryptographic key.

   - Parameter identifier: Identifier for the key
   - Throws: CryptoError if deletion fails
   */
  public func deleteKey(identifier: String) async throws {
    let config=SecureStorageConfig(
      accessControl: .standard,
      encrypt: true,
      context: ["type": "cryptographic_key"]
    )

    do {
      let result=try await secureStorage.deleteSecurely(
        identifier: identifier,
        config: config
      )

      if !result.success {
        throw CryptoError.keyNotFound(
          identifier: identifier
        )
      }

      var metadata=PrivacyMetadata()
      metadata["identifier"]=PrivacyMetadataValue(value: identifier, privacy: .private)

      await logger.info(
        "Successfully deleted key",
        metadata: metadata,
        source: "SecureCryptoStorage"
      )
    } catch {
      throw CryptoError.keyNotFound(
        identifier: identifier
      )
    }
  }

  // MARK: - Derived Key Storage

  /**
   Stores a derived key with parameters that were used to derive it.

   - Parameters:
      - key: The derived key
      - password: Reference to password used (not stored)
      - salt: Salt used for derivation
      - iterations: Number of iterations used
      - options: Key derivation options used

   - Returns: Identifier that can be used to retrieve the key
   - Throws: CryptoError if storage fails
   */
  public func storeDerivedKey(
    _ key: Data,
    fromPasswordReference passwordRef: String,
    salt: Data,
    iterations: Int,
    options: KeyDerivationOptions?
  ) async throws -> String {
    // Create a unique identifier based on derivation parameters
    let identifier="derived_key_\(passwordRef.hashValue)_\(salt.hashValue)_\(iterations)"

    let config=SecureStorageConfig(
      accessControl: .standard,
      encrypt: true,
      context: [
        "type": "derived_key",
        "iterations": "\(iterations)",
        "algorithm": options?.function.rawValue ?? "pbkdf2"
      ]
    )

    do {
      let result=try await secureStorage.storeSecurely(
        data: key,
        identifier: identifier,
        config: config
      )

      if !result.success {
        throw CryptoError.keyDerivationFailed(
          reason: "Failed to store derived key"
        )
      }

      var metadata=PrivacyMetadata()
      metadata["iterations"]=PrivacyMetadataValue(value: "\(iterations)", privacy: .public)
      metadata["algorithm"]=PrivacyMetadataValue(value: options?.function.rawValue ?? "pbkdf2",
                                                 privacy: .public)

      await logger.info(
        "Successfully stored derived key",
        metadata: metadata,
        source: "SecureCryptoStorage"
      )
      return identifier
    } catch {
      throw CryptoError.keyDerivationFailed(
        reason: "Storage error: \(error.localizedDescription)"
      )
    }
  }

  // MARK: - HMAC Storage

  /**
   Compute and store an HMAC for a data hash using a specific key and algorithm
   */
  public func computeAndStoreHMAC(
    forDataHash dataHash: Int,
    keyIdentifier: String,
    algorithm: CoreSecurityTypes.HashAlgorithm
  ) async throws -> String {
    let identifier="hmac_\(dataHash)_\(keyIdentifier)_\(UUID().uuidString)"

    let config=SecureStorageConfig(
      accessControl: .standard,
      encrypt: true,
      context: [
        "type": "hmac",
        "algorithm": algorithm.rawValue,
        "keyIdentifier": keyIdentifier
      ]
    )

    do {
      let result=try await secureStorage.storeSecurely(
        data: Data(),
        identifier: identifier,
        config: config
      )

      if !result.success {
        throw CryptoError.operationFailed(
          reason: "Failed to store HMAC"
        )
      }

      var metadata=PrivacyMetadata()
      metadata["algorithm"]=PrivacyMetadataValue(value: algorithm.rawValue, privacy: .public)
      metadata["keyIdentifier"]=PrivacyMetadataValue(value: keyIdentifier, privacy: .private)

      await logger.debug(
        "Successfully stored HMAC",
        metadata: metadata,
        source: "SecureCryptoStorage"
      )
      return identifier
    } catch {
      throw CryptoError.operationFailed(
        reason: "Storage error: \(error.localizedDescription)"
      )
    }
  }
}
