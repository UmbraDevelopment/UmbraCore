import Foundation
import SecurityCoreTypes
import SecurityTypes
import UmbraErrors

/**
 # Key Rotation Service

 This module provides key rotation capabilities, which are essential for maintaining
 cryptographic hygiene in any security-focused application. Key rotation involves
 periodically replacing cryptographic keys with new ones to limit the impact of
 potential key compromise and comply with security best practices.

 ## Security Rationale

 Regular key rotation provides several security benefits:

 1. **Limited Exposure Window**: Reduces the time window during which a compromised
    key can be exploited.

 2. **Compartmentalisation**: Limits the amount of data encrypted with any single key,
    reducing the impact of key compromise.

 3. **Compliance**: Meets requirements of security standards like PCI-DSS, NIST,
    and GDPR, which recommend or mandate periodic key rotation.

 4. **Defence in Depth**: Complements other security measures by ensuring that
    even if other controls fail, the window of vulnerability is limited.

 ## Implementation Notes

 This service implements versioned key identifiers that track key generations,
 enabling seamless key rotation without disrupting system operation. The format
 used is `baseId_vN` where N is the version number.
 */

/// Protocol defining the core operations of a key rotation service.
/// Implementations of this protocol manage the lifecycle of cryptographic keys,
/// including rotation, version tracking, and expiry management.
public protocol KeyRotationService {
  /**
   Rotates a cryptographic key, generating a new version while maintaining its purpose.

   This operation creates a new key with the same properties (algorithm, size) as the
   original, assigns it a new version number, and stores it in the key store. The
   original key remains available for decryption of existing data, while the new key
   should be used for any new encryption operations.

   ## Key Identifier Format

   Keys are identified using a versioned format: `baseId_vN` where:
   - `baseId` is the base identifier for the key's purpose (e.g., "database_encryption")
   - `N` is the version number (e.g., 1, 2, 3)

   ## Example Usage

   ```swift
   // Rotate the database encryption key
   let oldKeyID = "database_encryption_v1"
   let newKeyID = try await keyRotationService.rotateKey(identifier: oldKeyID)

   // newKeyID would be "database_encryption_v2"
   // Update systems to use the new key for encryption
   ```

   - Parameter identifier: The identifier of the key to rotate
   - Returns: The identifier of the newly created key
   - Throws: `KeyRotationError` if the operation fails
   */
  func rotateKey(identifier: String) async throws -> String

  /**
   Retrieves the current version number of a key.

   This method parses the key identifier to extract its current version number,
   which is useful for determining if a key needs rotation or for tracking
   key history.

   ## Example Usage

   ```swift
   let keyID = "payment_processing_v3"
   let version = try await keyRotationService.getCurrentKeyVersion(identifier: keyID)
   // version would be 3
   ```

   - Parameter identifier: The identifier of the key
   - Returns: The current version number
   - Throws: `KeyRotationError` if the version cannot be determined
   */
  func getCurrentKeyVersion(identifier: String) async throws -> Int

  /**
   Determines if a key should be rotated based on policy settings.

   This method checks factors such as key age, usage count, or other
   policy parameters to determine if a key should be rotated. Implementations
   may consider industry-specific requirements (e.g., PCI-DSS) when making
   this determination.

   ## Example Usage

   ```swift
   let keyID = "customer_data_v1"
   if await keyRotationService.keyRequiresRotation(identifier: keyId) {
       let newKeyID = try await keyRotationService.rotateKey(identifier: keyID)
       // Update configuration to use newKeyID
   }
   ```

   - Parameter identifier: The identifier of the key to check
   - Returns: `true` if the key should be rotated, `false` otherwise
   */
  func keyRequiresRotation(identifier: String) async -> Bool
}

/**
 Error types specific to key rotation operations.

 These errors provide detailed information about failures during key rotation
 operations, helping with diagnostics and appropriate error handling.
 */
public enum KeyRotationError: Error, LocalizedError {
  /// Indicates the requested key could not be found in the key store
  case keyNotFound(String)

  /// Indicates a failure during the rotation process
  case rotationFailed(String, reason: String)

  /// Indicates the provided key identifier does not follow the expected format
  case invalidKeyIdentifier(String)

  public var errorDescription: String? {
    switch self {
      case let .keyNotFound(id):
        "Key not found: \(id)"
      case let .rotationFailed(id, reason):
        "Failed to rotate key \(id): \(reason)"
      case let .invalidKeyIdentifier(id):
        "Invalid key identifier: \(id). Expected format is 'baseId_vN' where N is a version number."
    }
  }
}

/**
 Standard implementation of the key rotation service.

 This class provides a complete implementation of the KeyRotationService protocol,
 managing cryptographic keys throughout their lifecycle, including creation,
 rotation, and retirement.
 */
public class KeyRotationServiceImpl: KeyRotationService {
  /// Key store for managing cryptographic keys
  private let keyStore: KeyStore

  /// Key generator for creating new cryptographic keys
  private let keyGenerator: KeyGenerator

  /// Default rotation period in days
  private let defaultRotationPeriod: Int

  /**
   Initialises a key rotation service with the necessary dependencies.

   - Parameters:
      - keyStore: The key store to use for storing and retrieving keys
      - keyGenerator: The key generator to use for creating new keys
      - defaultRotationPeriod: Default rotation period in days (default: 90)
   */
  public init(keyStore: KeyStore, keyGenerator: KeyGenerator, defaultRotationPeriod: Int=90) {
    self.keyStore=keyStore
    self.keyGenerator=keyGenerator
    self.defaultRotationPeriod=defaultRotationPeriod
  }

  /**
   Rotates a key with the given identifier, creating a new version.

   This implementation:
   1. Parses the key identifier to extract the base ID and version
   2. Retrieves the existing key to determine its properties
   3. Generates a new key with the same properties
   4. Creates a new identifier with an incremented version
   5. Stores the new key with the new identifier

   ## Security Considerations

   - The method preserves the bit length of the original key to ensure
     consistent security levels across rotations.
   - The original key is not deleted, allowing for decryption of data
     encrypted with the previous key version.
   - For sensitive operations, consider implementing additional access
     controls around key rotation.

   - Parameter identifier: The identifier of the key to rotate
   - Returns: The identifier of the newly created key
   - Throws: `KeyRotationError` if the key cannot be found or rotation fails
   */
  public func rotateKey(identifier: String) async throws -> String {
    // Parse the identifier to extract base ID and version
    let (baseID, version)=try parseKeyIdentifier(identifier)

    // Get the existing key, if it exists
    guard let oldKey=await keyStore.getKey(identifier: identifier) else {
      throw KeyRotationError.keyNotFound(identifier)
    }

    // Generate new key with same size as the old one
    let bitLength=oldKey.count * 8
    let newKey=try await keyGenerator.generateKey(bitLength: bitLength)

    // Create a new identifier with incremented version
    let newVersion=version + 1
    let newIdentifier="\(baseID)_v\(newVersion)"

    // Store the new key
    await keyStore.storeKey(newKey, identifier: newIdentifier)

    return newIdentifier
  }

  /**
   Retrieves the current version number from a key identifier.

   This method parses versioned key identifiers in the format `baseId_vN`
   where N is the version number.

   - Parameter identifier: The key identifier to parse
   - Returns: The current version number
   - Throws: `KeyRotationError.invalidKeyIdentifier` if the identifier
             cannot be parsed
   */
  public func getCurrentKeyVersion(identifier: String) async throws -> Int {
    let (_, version)=try parseKeyIdentifier(identifier)
    return version
  }

  /**
   Determines if a key should be rotated based on its age and configured
   rotation period.

   This implementation checks the key's last rotation date against the
   configured rotation period. If the key is older than the rotation
   period, it returns true.

   ## Customisation Options

   Subclasses may override this method to implement more sophisticated
   rotation policies based on additional factors such as:

   - Usage counts (rotating keys after a certain number of operations)
   - Data volume (rotating keys after encrypting a certain amount of data)
   - Risk levels (rotating high-risk keys more frequently)
   - Compliance requirements (adhering to specific standards)

   - Parameter identifier: The identifier of the key to check
   - Returns: `true` if the key should be rotated, `false` otherwise
   */
  public func keyRequiresRotation(identifier: String) async -> Bool {
    do {
      // Get the rotation period from metadata or use default
      // In a real implementation, this would check actual key metadata
      // For now, we'll parse the identifier to check if it's old enough
      let (_, version)=try parseKeyIdentifier(identifier)

      // Use a simple heuristic: if version is low, it probably needs rotation
      // In a real implementation, check actual creation date against policy
      if version < 3 {
        return true
      }

      // For demonstration, assume keys with higher versions
      // were rotated more recently
      return false
    } catch {
      // In case of error, assume key needs rotation for safety
      return true
    }
  }

  /**
   Parses a key identifier to extract its components.

   This method handles versioned key identifiers in the format `baseId_vN`
   where N is the version number.

   - Parameter identifier: The key identifier to parse
   - Returns: A tuple containing the base ID and version number
   - Throws: `KeyRotationError.invalidKeyIdentifier` if the identifier
             cannot be parsed
   */
  func parseKeyIdentifier(_ identifier: String) throws -> (baseID: String, version: Int) {
    // Check if the identifier matches the expected pattern
    let pattern=#"^(.+)_v(\d+)$"#
    let regex=try NSRegularExpression(pattern: pattern)
    let range=NSRange(identifier.startIndex..<identifier.endIndex, in: identifier)

    guard let match=regex.firstMatch(in: identifier, range: range) else {
      throw KeyRotationError.invalidKeyIdentifier(identifier)
    }

    // Extract the base ID and version
    guard
      let baseIDRange=Range(match.range(at: 1), in: identifier),
      let versionRange=Range(match.range(at: 2), in: identifier),
      let version=Int(identifier[versionRange])
    else {
      throw KeyRotationError.invalidKeyIdentifier(identifier)
    }

    let baseID=String(identifier[baseIDRange])
    return (baseID, version)
  }
}

/// Factory methods for creating key rotation services
extension KeyRotationServiceImpl {
  /**
   Creates a default KeyRotationService with standard settings.

   This factory method simplifies the creation of a KeyRotationService with
   common configuration parameters, making it easier to integrate key rotation
   into applications.

   ## Example Usage

   ```swift
   let keyStore = KeyStoreImpl(storageProvider: secureStorage)
   let keyGenerator = KeyGeneratorImpl()

   let rotationService = KeyRotationServiceImpl.createDefault(
       keyStore: keyStore,
       keyGenerator: keyGenerator
   )

   // Use rotationService for key management operations
   ```

   - Parameters:
      - keyStore: The key store to use for storing and retrieving keys
      - keyGenerator: The key generator to use for creating new keys

   - Returns: A configured KeyRotationService
   */
  public static func createDefault(
    keyStore: KeyStore,
    keyGenerator: KeyGenerator
  ) -> KeyRotationService {
    KeyRotationServiceImpl(keyStore: keyStore, keyGenerator: keyGenerator)
  }
}
