/**
 # UmbraCore Key Lifecycle Management

 This file provides functionality for managing the lifecycle of cryptographic keys
 in the UmbraCore security framework, including rotation, expiration, and retirement.

 ## Responsibilities

 * Key rotation (generating new keys and retiring old ones)
 * Key expiration management
 * Key versioning
 * Key usage tracking

 ## Security Considerations

 * Regular key rotation helps limit the impact of potential key compromise
 * Properly retiring old keys prevents their use after they should be retired
 * Key usage tracking helps identify potential key misuse
 * Versioning ensures that the correct key is used for each operation
 */

import ErrorHandlingDomains
import Foundation
import SecurityProtocolsCore
import UmbraCoreTypes

/// Provides key lifecycle management functionality
///
/// KeyLifecycle is responsible for managing the lifecycle of cryptographic keys,
/// including rotation, expiration, and retirement. It ensures that keys are
/// properly managed throughout their lifetime.
final class KeyLifecycle {
  // MARK: - Types

  /// Configuration for key rotation
  struct RotationConfig {
    /// The identifier of the key to rotate
    let keyIdentifier: String

    /// The new identifier to use for the rotated key
    let newIdentifier: String

    /// Whether to preserve the old key (true) or delete it (false)
    let preserveOldKey: Bool

    /// Creates a new rotation configuration
    init(
      keyIdentifier: String,
      newIdentifier: String,
      preserveOldKey: Bool=true
    ) {
      self.keyIdentifier=keyIdentifier
      self.newIdentifier=newIdentifier
      self.preserveOldKey=preserveOldKey
    }
  }

  // MARK: - Properties

  /// The key store for retrieving and storing keys
  private let keyStore: KeyStore

  /// The key generator for creating new keys
  private let keyGenerator: KeyGenerator

  // MARK: - Initialisation

  /// Creates a new KeyLifecycle manager
  /// - Parameters:
  ///   - keyStore: The key store to use
  ///   - keyGenerator: The key generator to use
  init(keyStore: KeyStore, keyGenerator: KeyGenerator) {
    self.keyStore=keyStore
    self.keyGenerator=keyGenerator
  }

  // MARK: - Key Lifecycle Operations

  /// Rotate a key, generating a new one and optionally retiring the old one
  /// - Parameters:
  ///   - config: The rotation configuration
  ///   - keyType: The type of key to generate
  ///   - bits: The size of the new key in bits
  ///   - purpose: The purpose of the key
  /// - Returns: Success if the key was rotated, failure otherwise
  func rotateKey(
    config: RotationConfig,
    keyType: KeyType,
    bits: Int,
    purpose: KeyPurpose
  ) -> Result<Void, UmbraErrors.Security.Protocols> {
    // First, check if the old key exists
    let retrieveResult=keyStore.retrieveKey(withIdentifier: config.keyIdentifier)

    switch retrieveResult {
      case .success:
        // Generate a new key
        let generateResult=keyGenerator.generateKey(bits: bits, keyType: keyType, purpose: purpose)

        switch generateResult {
          case let .success(newKey):
            // Store the new key
            let storeResult=keyStore.storeKey(
              newKey,
              withIdentifier: config.newIdentifier
            )

            switch storeResult {
              case .success:
                // If we're not preserving the old key, delete it
                if !config.preserveOldKey {
                  _=keyStore.deleteKey(withIdentifier: config.keyIdentifier)
                }
                return .success(())

              case let .failure(error):
                return .failure(error)
            }

          case let .failure(error):
            // Convert UmbraErrors.Security.Protocols to UmbraErrors.Security.Protocols
            return .failure(.serviceError("Failed to generate new key: \(error)"))
        }

      case let .failure(error):
        return .failure(error)
    }
  }

  /// Delete a key that is no longer needed
  /// - Parameter identifier: The identifier of the key to delete
  /// - Returns: Success if the key was deleted, failure otherwise
  func retireKey(
    withIdentifier identifier: String
  ) -> Result<Void, UmbraErrors.Security.Protocols> {
    keyStore.deleteKey(withIdentifier: identifier)
  }
}
