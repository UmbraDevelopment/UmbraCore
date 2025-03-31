import Foundation
import LoggingInterfaces
import SecurityCoreInterfaces
import SecurityCoreTypes
import SecurityTypes
import UmbraErrors

/**
 # BasicKeyManager

 A simplified key manager implementation that provides minimal functionality
 for situations where the full key manager cannot be loaded. This implementation
 should only be used as a fallback during initialisation or for testing.

 For production use, always use the proper KeyManagementProtocol implementation
 from SecurityKeyManagement.
 */

/// Basic key types supported by the BasicKeyManager
public enum KeyType {
  case aes128
  case aes256
  case rsaPrivate
  case rsaPublic
  case hmac
}

/// Error types specific to key management operations
public enum KeyManagementError: Error, Equatable {
  /// The requested key was not found
  case keyNotFound(identifier: String)
  /// Failed to generate a key
  case keyGenerationFailed(reason: String)
  /// Failed to store a key
  case keyStorageFailed(reason: String)
  /// Invalid key format
  case invalidKeyFormat(reason: String)
}

public final class BasicKeyManager: KeyManagementProtocol, @unchecked Sendable {
  /// In-memory storage for keys
  private var keyStore: [String: SecureBytes]=[:]

  /// Logger for operations
  private let logger: LoggingProtocol

  /**
   Initialise a new basic key manager with the specified logger.

   - Parameter logger: Logger for recording operations
   */
  public init(logger: LoggingProtocol?=nil) {
    self.logger=logger ?? DefaultLogger()
  }

  /**
   Retrieve a cryptographic key with the specified identifier.

   - Parameter identifier: The identifier of the key to retrieve
   - Returns: A result containing the key or an error
   */
  public func retrieveKey(withIdentifier identifier: String) async
  -> Result<SecureBytes, SecurityProtocolError> {
    if let key=keyStore[identifier] {
      await logger.debug(
        "Retrieved key with identifier: \(identifier)",
        metadata: nil,
        source: "BasicKeyManager"
      )
      return .success(key)
    } else {
      await logger.error(
        "Failed to retrieve key with identifier: \(identifier)",
        metadata: nil,
        source: "BasicKeyManager"
      )
      return .failure(.keyNotFound(identifier: identifier))
    }
  }

  /**
   Store a cryptographic key with the specified identifier.

   - Parameters:
      - key: The key to store
      - identifier: The identifier to associate with the key
   - Returns: A result indicating success or an error
   */
  public func storeKey(
    _ key: SecureBytes,
    withIdentifier identifier: String
  ) async -> Result<Void, SecurityProtocolError> {
    keyStore[identifier]=key
    await logger.debug(
      "Stored key with identifier: \(identifier)",
      metadata: nil,
      source: "BasicKeyManager"
    )
    return .success(())
  }

  /**
   Delete a cryptographic key with the specified identifier.

   - Parameter identifier: The identifier of the key to delete
   - Returns: A result indicating success or an error
   */
  public func deleteKey(withIdentifier identifier: String) async
  -> Result<Void, SecurityProtocolError> {
    if keyStore.removeValue(forKey: identifier) != nil {
      await logger.debug(
        "Deleted key with identifier: \(identifier)",
        metadata: nil,
        source: "BasicKeyManager"
      )
      return .success(())
    } else {
      await logger.error(
        "Failed to delete key with identifier: \(identifier)",
        metadata: nil,
        source: "BasicKeyManager"
      )
      return .failure(.keyNotFound(identifier: identifier))
    }
  }

  /**
   Generate a cryptographic key with the specified configuration.

   - Parameter config: The configuration for generating the key
   - Returns: The result of the key generation operation
   - Throws: Error if key generation fails
   */
  public func generateKey(with config: KeyGenerationConfig) async throws -> KeyGenerationResult {
    await logger.warning(
      "Using BasicKeyManager to generate a key with configuration - this is not secure for production",
      metadata: nil,
      source: "BasicKeyManager"
    )

    // Generate a key based on the specified algorithm
    let keySize=switch config.algorithm {
      case .aes256:
        256
      case .ecdsaP256:
        256
      case .ecdsaP384:
        384
      case .ed25519:
        256
    }

    let keyBytes=try await generateRandomBytes(count: keySize / 8)
    let key=SecureBytes(Data(keyBytes))

    // Generate a unique identifier
    let keyIdentifier=UUID().uuidString

    // Store the key with the identifier
    let storeResult=await storeKey(key, withIdentifier: keyIdentifier)

    if case let .failure(error)=storeResult {
      throw error
    }

    // Return the key generation result
    return KeyGenerationResult(
      keyIdentifier: keyIdentifier,
      algorithm: config.algorithm,
      metadata: config.metadata
    )
  }

  /**
   Generate a new cryptographic key of the specified type.

   - Parameter type: The type of key to generate
   - Returns: A result containing the generated key or an error
   */
  public func generateKey(ofType type: KeyType) async throws -> SecureBytes {
    // This is a very basic implementation that would not be secure in production
    await logger
      .warning(
        "Using BasicKeyManager to generate a key - this is not secure for production use",
        metadata: nil,
        source: "BasicKeyManager"
      )

    var keyData=switch type {
      case .aes128:
        [UInt8](repeating: 0, count: 16)
      case .aes256:
        [UInt8](repeating: 0, count: 32)
      case .rsaPrivate:
        [UInt8](repeating: 0, count: 256)
      case .rsaPublic:
        [UInt8](repeating: 0, count: 128)
      case .hmac:
        [UInt8](repeating: 0, count: 32)
    }

    // Fill with random data
    for i in 0..<keyData.count {
      keyData[i]=UInt8.random(in: 0...255)
    }

    return SecureBytes(Data(keyData))
  }

  /**
   Generate random bytes securely.

   - Parameter count: Number of bytes to generate
   - Returns: Data containing the random bytes
   - Throws: Error if secure random generation fails
   */
  private func generateRandomBytes(count: Int) async throws -> Data {
    var bytes=[UInt8](repeating: 0, count: count)
    let status=SecRandomCopyBytes(kSecRandomDefault, count, &bytes)

    guard status == errSecSuccess else {
      throw SecurityProtocolError
        .keyNotFound(identifier: "Failed to generate secure random bytes: \(status)")
    }

    return Data(bytes)
  }

  /**
   Rotates a key with the specified identifier and optionally re-encrypts data.

   - Parameters:
     - identifier: The identifier of the key to rotate
     - dataToReencrypt: Optional data to re-encrypt with the new key
   - Returns: A result containing the new key and re-encrypted data, or an error
   */
  public func rotateKey(
    withIdentifier identifier: String,
    dataToReencrypt: SecureBytes?
  ) async -> Result<(newKey: SecureBytes, reencryptedData: SecureBytes?), SecurityProtocolError> {
    await logger.warning(
      "Using BasicKeyManager to rotate a key - this is not secure for production use",
      metadata: nil,
      source: "BasicKeyManager"
    )

    // Create a new random key
    let newKey=SecureBytes(Data((0..<32).map { _ in UInt8.random(in: 0...255) }))

    // Store the new key with the same identifier
    let storeResult=await storeKey(newKey, withIdentifier: identifier)

    switch storeResult {
      case .success:
        // If there's data to re-encrypt, we would do it here.
        // For this simple implementation, we just return the data unchanged
        return .success((newKey: newKey, reencryptedData: dataToReencrypt))
      case let .failure(error):
        return .failure(error)
    }
  }

  /**
   Lists all available key identifiers.

   - Returns: An array of key identifiers or an error
   */
  public func listKeyIdentifiers() async -> Result<[String], SecurityProtocolError> {
    .success(Array(keyStore.keys))
  }

  /**
   Resets a key by generating a new one and replacing the old one with the same identifier.

   - Parameter identifier: The identifier of the key to reset
   - Returns: Result indicating success or failure with error
   */
  public func resetKey(withIdentifier identifier: String) async -> Result<Void, Error> {
    await logger.info(
      "Resetting key with identifier \(identifier)",
      metadata: nil,
      source: "BasicKeyManager"
    )

    guard keyStore[identifier] != nil else {
      return .failure(KeyManagementError.keyNotFound(identifier: identifier))
    }

    // Create a new random key
    let newKey=SecureBytes(Data((0..<32).map { _ in UInt8.random(in: 0...255) }))

    // Store the new key with the same identifier
    keyStore[identifier]=newKey

    return .success(())
  }
}
