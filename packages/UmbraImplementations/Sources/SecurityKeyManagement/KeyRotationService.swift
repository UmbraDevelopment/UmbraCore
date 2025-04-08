import CoreSecurityTypes
import DomainSecurityTypes
import Foundation
import SecurityCoreInterfaces
import SecurityKeyTypes
import UmbraErrors

/**
 # KeyRotationService

 Manages the rotation of cryptographic keys in the security system.
 This service ensures that keys are regularly rotated according to
 security best practices, while maintaining continuity of service.

 Key rotation involves:
 1. Creating a new key with the same properties as the existing key
 2. Updating references to use the new key
 3. Optionally preserving the old key for a transition period
 4. Eventually removing the old key when it's no longer needed

 This implementation follows the Alpha Dot Five architecture principles
 by using actor-based concurrency for thread safety.
 */

/// Protocol defining key rotation service capabilities
public protocol KeyRotationServiceProtocol: Sendable {
  /**
   Rotates a cryptographic key, generating a new version while maintaining its purpose.

   - Parameter identifier: The identifier of the key to rotate
   - Returns: The identifier of the newly created key
   - Throws: An error if key rotation fails
   */
  func rotateKey(identifier: String) async throws -> String

  /**
   Checks if a key needs rotation based on its age and the rotation policy.

   - Parameter identifier: The identifier of the key to check
   - Returns: True if the key should be rotated
   - Throws: An error if the check fails
   */
  func shouldRotateKey(identifier: String) async throws -> Bool

  /**
   Gets the time until the next scheduled rotation for a key.

   - Parameter identifier: The identifier of the key to check
   - Returns: Time interval until next rotation in days, or nil if no rotation is scheduled
   - Throws: An error if the check fails
   */
  func timeUntilRotation(identifier: String) async throws -> Double?
}

/// Errors specific to key rotation operations
public enum KeyRotationError: Error, Sendable, Equatable {
  /// The specified key was not found
  case keyNotFound(String)

  /// The key rotation operation failed
  case rotationFailed(String, String)

  /// The key is not eligible for rotation
  case notEligibleForRotation(String)

  /// General error during key rotation
  case generalError(String)
}

/// Implementation of the key rotation service
public actor KeyRotationServiceImpl: KeyRotationServiceProtocol {
  /// Shared singleton instance
  public static let shared=KeyRotationServiceImpl(
    keyStore: KeyStore(),
    keyGenerator: DefaultKeyGenerator()
  )

  /// The key store used for retrieving and storing keys
  private let keyStore: KeyStore

  /// The key generator used for creating new keys
  private let keyGenerator: any KeyGenerator

  /// Default rotation period in days
  private let defaultRotationPeriod: Int

  /// Cache of key metadata to improve performance
  private var keyMetadataCache: [String: KeyMetadata]=[:]

  /**
   Initialises a new key rotation service with the specified dependencies.

   - Parameters:
     - keyStore: The key store to use
     - keyGenerator: The key generator to use
     - defaultRotationPeriod: Default rotation period in days (defaults to 90)
   */
  public init(
    keyStore: KeyStore,
    keyGenerator: any KeyGenerator,
    defaultRotationPeriod: Int=90
  ) {
    self.keyStore=keyStore
    self.keyGenerator=keyGenerator
    self.defaultRotationPeriod=defaultRotationPeriod
  }

  /**
   Rotates a cryptographic key, generating a new version while maintaining its purpose.

   The rotation process:
   1. Retrieves the existing key and its metadata
   2. Generates a new key with the same properties
   3. Stores the new key with updated metadata
   4. Returns the identifier of the new key

   - Parameter identifier: The identifier of the key to rotate
   - Returns: The identifier of the newly created key
   - Throws: KeyRotationError if rotation fails
   */
  public func rotateKey(identifier: String) async throws -> String {
    // Verify the key exists
    guard try await keyStore.containsKey(identifier: identifier) else {
      throw KeyRotationError.keyNotFound(identifier)
    }

    // Verify we can retrieve the key
    guard try await keyStore.getKey(identifier: identifier) != nil else {
      throw KeyRotationError.keyNotFound(identifier)
    }

    // Get metadata for the existing key
    let metadata=try await getKeyMetadata(identifier: identifier)

    // Generate a new identifier for the rotated key
    let newIdentifier="\(metadata.purpose)-\(UUID().uuidString)"

    // Generate a new key with the same properties
    let newKey=try await keyGenerator.generateKey(bitLength: metadata.keySize)

    // Store the new key
    try await keyStore.storeKey(newKey, identifier: newIdentifier)

    // Create and store metadata for the new key
    let newMetadata=KeyMetadata(
      id: newIdentifier,
      createdAt: Date().timeIntervalSince1970,
      algorithm: metadata.algorithm,
      keySize: metadata.keySize,
      purpose: metadata.purpose,
      attributes: metadata.attributes
    )

    // Store the new metadata
    try await storeKeyMetadata(newMetadata)

    return newIdentifier
  }

  /**
   Checks if a key needs rotation based on its age and the rotation policy.

   - Parameter identifier: The identifier of the key to check
   - Returns: True if the key should be rotated
   - Throws: KeyRotationError if the check fails
   */
  public func shouldRotateKey(identifier: String) async throws -> Bool {
    do {
      // Get the key metadata
      let metadata=try await getKeyMetadata(identifier: identifier)

      // Calculate the key's age in days
      let now=Date().timeIntervalSince1970
      let keyAge=(now - metadata.createdAt) / (60 * 60 * 24)

      // Get rotation period from metadata or use default
      let rotationPeriod=Int(metadata.attributes["rotationPeriod"] ?? "") ?? defaultRotationPeriod

      // Key should be rotated if its age exceeds the rotation period
      return keyAge >= Double(rotationPeriod)
    } catch {
      throw KeyRotationError
        .generalError("Failed to check rotation status: \(error.localizedDescription)")
    }
  }

  /**
   Gets the time until the next scheduled rotation for a key.

   - Parameter identifier: The identifier of the key to check
   - Returns: Time interval until next rotation in days, or nil if no rotation is scheduled
   - Throws: KeyRotationError if the check fails
   */
  public func timeUntilRotation(identifier: String) async throws -> Double? {
    do {
      // Get the key metadata
      let metadata=try await getKeyMetadata(identifier: identifier)

      // Calculate the key's age in days
      let now=Date().timeIntervalSince1970
      let keyAge=(now - metadata.createdAt) / (60 * 60 * 24)

      // Get rotation period from metadata or use default
      let rotationPeriod=Int(metadata.attributes["rotationPeriod"] ?? "") ?? defaultRotationPeriod

      // Calculate time until rotation
      let timeUntil=Double(rotationPeriod) - keyAge

      // Return nil if rotation is already due
      return timeUntil > 0 ? timeUntil : nil
    } catch {
      throw KeyRotationError
        .generalError("Failed to calculate time until rotation: \(error.localizedDescription)")
    }
  }

  /**
   Gets metadata for a key, using cache when available.

   - Parameter identifier: The identifier of the key
   - Returns: The key metadata
   - Throws: Error if metadata cannot be retrieved
   */
  private func getKeyMetadata(identifier: String) async throws -> KeyMetadata {
    // Check cache first
    if let cachedMetadata=keyMetadataCache[identifier] {
      return cachedMetadata
    }

    // Create metadata for the key if not in cache
    let metadata=KeyMetadata(
      id: identifier,
      createdAt: Date().timeIntervalSince1970,
      algorithm: .aes,
      keySize: 256,
      purpose: "encryption",
      attributes: [:]
    )

    // Cache the metadata
    keyMetadataCache[identifier]=metadata

    return metadata
  }

  /**
   Stores key metadata and updates the cache.

   - Parameter metadata: The metadata to store
   - Throws: Error if storing metadata fails
   */
  private func storeKeyMetadata(_ metadata: KeyMetadata) async throws {
    // Update the cache
    keyMetadataCache[metadata.id]=metadata
  }
}

/**
 # KeyRotationFactory

 Factory for creating key rotation service instances with appropriate
 configuration for different security contexts.
 */
public enum KeyRotationFactory {
  /**
   Creates a standard key rotation service.

   - Parameters:
     - keyStore: Optional custom key store to use
     - keyGenerator: Optional custom key generator to use
     - rotationPeriod: Default rotation period in days (defaults to 90)

   - Returns: A configured key rotation service
   */
  public static func createKeyRotationService(
    keyStore: KeyStore?=nil,
    keyGenerator: (any KeyGenerator)?=nil,
    rotationPeriod: Int=90
  ) -> KeyRotationServiceImpl {
    KeyRotationServiceImpl(
      keyStore: keyStore ?? KeyStore(),
      keyGenerator: keyGenerator ?? DefaultKeyGenerator(),
      defaultRotationPeriod: rotationPeriod
    )
  }

  /**
   Creates a high-security key rotation service with shorter rotation periods.

   - Parameters:
     - keyStore: Optional custom key store to use
     - keyGenerator: Optional custom key generator to use

   - Returns: A configured key rotation service with enhanced security settings
   */
  public static func createHighSecurityKeyRotationService(
    keyStore: KeyStore?=nil,
    keyGenerator: (any KeyGenerator)?=nil
  ) -> KeyRotationServiceImpl {
    KeyRotationServiceImpl(
      keyStore: keyStore ?? KeyStore(),
      keyGenerator: keyGenerator ?? DefaultKeyGenerator(),
      defaultRotationPeriod: 30 // 30-day rotation for high security
    )
  }
}
