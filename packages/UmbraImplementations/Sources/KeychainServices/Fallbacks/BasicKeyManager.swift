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
      await logger.debug("Retrieved key with identifier: \(identifier)", metadata: nil, source: "BasicKeyManager")
      return .success(key)
    } else {
      await logger.error("Failed to retrieve key with identifier: \(identifier)", metadata: nil, source: "BasicKeyManager")
      return .failure(.keyManagementError("Key not found: \(identifier)"))
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
    await logger.debug("Stored key with identifier: \(identifier)", metadata: nil, source: "BasicKeyManager")
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
      await logger.debug("Deleted key with identifier: \(identifier)", metadata: nil, source: "BasicKeyManager")
      return .success(())
    } else {
      await logger.error("Failed to delete key with identifier: \(identifier)", metadata: nil, source: "BasicKeyManager")
      return .failure(.keyManagementError("Key not found: \(identifier)"))
    }
  }

  /**
   Generate a new cryptographic key of the specified type.

   - Parameter type: The type of key to generate
   - Returns: A result containing the generated key or an error
   */
  public func generateKey(ofType type: KeyType) async throws -> SecureBytes {
    // This is a very basic implementation that would not be secure in production
    await logger
      .warning("Using BasicKeyManager to generate a key - this is not secure for production use", metadata: nil, source: "BasicKeyManager")

    var keyData: [UInt8]

    switch type {
      case .aes128:
        keyData=[UInt8](repeating: 0, count: 16)
      case .aes256:
        keyData=[UInt8](repeating: 0, count: 32)
      case .rsaPrivate:
        keyData=[UInt8](repeating: 0, count: 256)
      case .rsaPublic:
        keyData=[UInt8](repeating: 0, count: 128)
      case .hmac:
        keyData=[UInt8](repeating: 0, count: 32)
    }

    // Fill with random data
    for i in 0..<keyData.count {
      keyData[i]=UInt8.random(in: 0...255)
    }

    return SecureBytes(data: Data(keyData))
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
    let newKey = SecureBytes(data: Data((0..<32).map { _ in UInt8.random(in: 0...255) }))
    
    // Store the new key with the same identifier
    let storeResult = await storeKey(newKey, withIdentifier: identifier)
    
    switch storeResult {
    case .success:
      // If there's data to re-encrypt, we would do it here.
      // For this simple implementation, we just return the data unchanged
      return .success((newKey: newKey, reencryptedData: dataToReencrypt))
    case .failure(let error):
      return .failure(error)
    }
  }
  
  /**
   Lists all available key identifiers.
   
   - Returns: An array of key identifiers or an error
   */
  public func listKeyIdentifiers() async -> Result<[String], SecurityProtocolError> {
    return .success(Array(keyStore.keys))
  }
}
