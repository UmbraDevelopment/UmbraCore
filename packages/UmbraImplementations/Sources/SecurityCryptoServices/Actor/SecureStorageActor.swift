import CoreSecurityTypes
import DomainSecurityTypes
import Foundation
import LoggingInterfaces
import SecurityCoreInterfaces
import SecurityUtils

/**
 # SecureStorageActor

 A Swift actor that provides thread-safe access to secure storage operations
 for cryptographic keys and sensitive data.

 This actor manages the secure storage, retrieval, and rotation of cryptographic
 keys and other sensitive material. It uses the configured security provider for
 encryption/decryption of stored data.

 ## Usage

 ```swift
 // Create the actor with a specific provider type
 let secureStorage = SecureStorageActor(providerType: .apple, logger: logger)

 // Store and retrieve keys securely
 try await secureStorage.storeKey(key, withIdentifier: "master-key")
 let retrievedKey = try await secureStorage.retrieveKey(withIdentifier: "master-key")
 ```

 ## Thread Safety

 All methods are automatically thread-safe due to Swift's actor isolation rules.
 Mutable state is properly contained within the actor and cannot be accessed from
 outside except through the defined async interfaces.
 */
public actor SecureStorageActor {
  // MARK: - Properties

  /// The underlying crypto service for encryption/decryption
  private let cryptoService: CryptoServiceActor

  /// Logger for recording operations
  private let logger: LoggingProtocol

  /// In-memory cache of recently used keys (identifier -> key)
  private var keyCache: [String: [UInt8]] = [:]

  /// Storage location for encrypted keys
  private let storageURL: URL

  // MARK: - Initialisation

  /**
   Initialises a new secure storage actor.

   - Parameters:
      - providerType: The type of security provider to use
      - storageURL: Custom URL for key storage (defaults to app support directory)
      - logger: Logger for recording operations
   */
  public init(
    providerType: SecurityProviderType?=nil,
    storageURL: URL?=nil,
    logger: LoggingProtocol
  ) {
    self.logger=logger
    cryptoService=CryptoServiceActor(providerType: providerType, logger: logger)

    // Set up storage location
    if let customURL=storageURL {
      self.storageURL=customURL
    } else {
      // Default to app support directory
      let fileManager=FileManager.default
      let appSupportURL=fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)
        .first!
      self.storageURL=appSupportURL.appendingPathComponent("UmbraSecureStorage", isDirectory: true)
    }

    // Ensure storage directory exists
    try? FileManager.default.createDirectory(
      at: self.storageURL,
      withIntermediateDirectories: true,
      attributes: nil
    )

    Task {
      await logger.info(
        "Initialised SecureStorageActor with storage at: \(self.storageURL.path)",
        metadata: nil
      )
    }
  }

  // MARK: - Key Storage Operations

  /**
   Stores a cryptographic key securely.

   The key is encrypted using a master key before being written to storage.
   Memory protection is used to ensure sensitive key material is properly
   zeroed after use.

   - Parameters:
      - key: The key to store
      - identifier: Unique identifier for the key
      - overwrite: Whether to overwrite an existing key with the same identifier
   - Throws: SecurityProtocolError if storage fails
   */
  public func storeKey(
    _ key: [UInt8],
    withIdentifier identifier: String,
    overwrite: Bool=false
  ) async throws {
    // Check if key exists and we're not overwriting
    let keyURL=storageURL.appendingPathComponent("\(identifier).key")
    if FileManager.default.fileExists(atPath: keyURL.path) && !overwrite {
      await logger.warning(
        "Key with identifier '\(identifier)' already exists and overwrite is false",
        metadata: nil
      )
      throw SecurityProtocolError.invalidInput("Key with identifier '\(identifier)' already exists")
    }

    do {
      // Generate or retrieve master key for wrapping
      let masterKey = try await getMasterKey()
      
      // Use memory protection to handle the sensitive key data
      try await MemoryProtection.withSecureTemporaryData(key) { secureKey in
        // Encrypt the key
        let encryptedKey = try await self.cryptoService.encrypt(data: secureKey, using: masterKey)
        
        // Write to storage
        try Data(encryptedKey).write(to: keyURL)
        
        // Update cache - create a copy to store in cache
        self.keyCache[identifier] = [UInt8](secureKey)
      }

      await logger.info("Successfully stored key with identifier: \(identifier)", metadata: nil)
    } catch {
      await logger.error("Failed to store key: \(error.localizedDescription)", metadata: nil)

      if let secError=error as? SecurityProtocolError {
        throw secError
      } else {
        throw SecurityProtocolError
          .cryptographicError("Failed to store key: \(error.localizedDescription)")
      }
    }
  }

  /**
   Retrieves a cryptographic key from secure storage.

   The key is decrypted using the master key after being read from storage.
   Memory protection utilities are used to ensure secure handling of the key.

   - Parameter identifier: The unique identifier of the key to retrieve
   - Returns: The retrieved key
   - Throws: SecurityProtocolError if retrieval fails
   */
  public func retrieveKey(withIdentifier identifier: String) async throws -> [UInt8] {
    // Check cache first
    if let cachedKey=keyCache[identifier] {
      // Return a copy of the cached key through secure memory handling
      return MemoryProtection.secureDataCopy(cachedKey)
    }

    // Construct key URL
    let keyURL=storageURL.appendingPathComponent("\(identifier).key")

    // Check if key exists
    guard FileManager.default.fileExists(atPath: keyURL.path) else {
      await logger.error("Key with identifier '\(identifier)' not found", metadata: nil)
      throw SecurityProtocolError.invalidInput("Key with identifier '\(identifier)' not found")
    }

    do {
      // Read encrypted key from storage
      let encryptedData=try Data(contentsOf: keyURL)
      let encryptedKey=[UInt8](encryptedData)

      // Retrieve master key for unwrapping
      let masterKey=try await getMasterKey()

      // Decrypt the key with memory protection
      let key = try await cryptoService.decrypt(data: encryptedKey, using: masterKey)

      // Update cache with a secured copy
      keyCache[identifier] = MemoryProtection.secureDataCopy(key)

      await logger.info("Successfully retrieved key with identifier: \(identifier)", metadata: nil)
      return key
    } catch {
      await logger.error("Failed to retrieve key: \(error.localizedDescription)", metadata: nil)

      if let secError=error as? SecurityProtocolError {
        throw secError
      } else {
        throw SecurityProtocolError
          .cryptographicError("Failed to retrieve key: \(error.localizedDescription)")
      }
    }
  }

  /**
   Deletes a key from secure storage.

   - Parameter identifier: The unique identifier of the key to delete
   - Returns: True if the key was successfully deleted, false otherwise
   */
  public func deleteKey(withIdentifier identifier: String) async -> Bool {
    // Construct key URL
    let keyURL=storageURL.appendingPathComponent("\(identifier).key")

    // Check if key exists
    guard FileManager.default.fileExists(atPath: keyURL.path) else {
      await logger.warning("Key with identifier '\(identifier)' not found for deletion", metadata: nil)
      return false
    }

    do {
      // Remove from file system
      try FileManager.default.removeItem(at: keyURL)

      // Securely remove from cache if it exists
      if let _ = keyCache[identifier] {
        // Use memory protection to zero the memory before removing
        MemoryProtection.securelyZeroData(&keyCache[identifier]!)
        keyCache.removeValue(forKey: identifier)
      }

      await logger.info("Successfully deleted key with identifier: \(identifier)", metadata: nil)
      return true
    } catch {
      await logger.error(
        "Failed to delete key '\(identifier)': \(error.localizedDescription)",
        metadata: nil
      )
      return false
    }
  }

  /**
   Rotates a key, generating a new key and re-encrypting data secured with the old key.
   
   Uses memory protection to ensure secure handling of key material throughout
   the rotation process.

   - Parameters:
      - identifier: The identifier of the key to rotate
      - bitLength: Optional bit length for the new key
      - dataToReencrypt: Optional data items encrypted with the old key that need re-encryption
   - Returns: Optional array of re-encrypted data items if provided
   - Throws: SecurityProtocolError if rotation fails
   */
  public func rotateKey(
    withIdentifier identifier: String,
    bitLength: Int=256,
    dataToReencrypt: [[UInt8]]?=nil
  ) async throws -> [[UInt8]]? {
    // Retrieve the old key first
    let oldKey = try await retrieveKey(withIdentifier: identifier)
    
    // Generate a new key
    let newKey = try await cryptoService.generateKey(bitLength: bitLength)
    
    // Use memory protection for the key rotation process
    return try await MemoryProtection.withSecureTemporaryBatch([oldKey, newKey]) { protectedKeys in
      let protectedOldKey = protectedKeys[0]
      let protectedNewKey = protectedKeys[1]
      
      // Store the new key with the same identifier (overwriting the old one)
      try await self.storeKey(protectedNewKey, withIdentifier: identifier, overwrite: true)
      
      // If there are data items to re-encrypt, do that
      if let dataItems = dataToReencrypt {
        // Decrypt with old key
        let decryptedItems = try await self.cryptoService.decryptBatch(
          dataItems: dataItems,
          using: protectedOldKey
        )
        
        // Use memory protection for handling the decrypted sensitive data
        let reencryptedItems = try await MemoryProtection.withSecureTemporaryBatch(decryptedItems) { protectedItems in
          // Re-encrypt with new key
          return try await self.cryptoService.encryptBatch(
            dataItems: protectedItems,
            using: protectedNewKey
          )
        }
        
        await self.logger.info(
          "Successfully rotated key '\(identifier)' and re-encrypted \(dataItems.count) data items",
          metadata: nil
        )
        
        return reencryptedItems
      } else {
        await self.logger.info("Successfully rotated key '\(identifier)'", metadata: nil)
        return nil
      }
    }
  }

  // MARK: - Private Implementation

  /**
   Retrieves or generates the master key used for securing other keys.

   This is a high-security operation as the master key protects all other keys.
   Memory protection utilities are used to ensure secure handling of the master key.

   - Returns: The master key
   - Throws: SecurityProtocolError if master key operations fail
   */
  private func getMasterKey() async throws -> [UInt8] {
    let masterKeyIdentifier = "umbra.master.key"
    let masterKeyURL = storageURL.appendingPathComponent("\(masterKeyIdentifier).key")

    // If master key doesn't exist, generate it
    if !FileManager.default.fileExists(atPath: masterKeyURL.path) {
      do {
        // Generate a strong master key with memory protection
        let masterKey = try await cryptoService.generateKey(bitLength: 256)
        
        return try await MemoryProtection.withSecureTemporaryData(masterKey) { protectedMasterKey in
          // Derive a wrapping key from system and user information
          let wrappingKey = try await self.deriveWrappingKey()
          
          // Use memory protection for the wrapping key
          return try await MemoryProtection.withSecureTemporaryData(wrappingKey) { protectedWrappingKey in
            // Encrypt the master key with the wrapping key
            let encryptedMasterKey = try await self.cryptoService.encrypt(
              data: protectedMasterKey,
              using: protectedWrappingKey
            )
            
            // Write encrypted master key to storage
            try Data(encryptedMasterKey).write(to: masterKeyURL)
            
            await self.logger.info("Generated and stored new master key", metadata: nil)
            
            // Return a copy of the master key
            return [UInt8](protectedMasterKey)
          }
        }
      } catch {
        await logger.error(
          "Failed to generate master key: \(error.localizedDescription)",
          metadata: nil
        )
        
        if let secError=error as? SecurityProtocolError {
          throw secError
        } else {
          throw SecurityProtocolError
            .cryptographicError("Failed to generate master key: \(error.localizedDescription)")
        }
      }
    }

    // If master key exists, load and decrypt it
    do {
      // Read encrypted master key
      let encryptedData=try Data(contentsOf: masterKeyURL)
      let encryptedMasterKey=[UInt8](encryptedData)

      // Derive the wrapping key with memory protection
      let wrappingKey = try await deriveWrappingKey()
      
      return try await MemoryProtection.withSecureTemporaryData(wrappingKey) { protectedWrappingKey in
        // Decrypt the master key
        let masterKey = try await self.cryptoService.decrypt(
          data: encryptedMasterKey,
          using: protectedWrappingKey
        )
        
        // Return a copy of the master key
        return masterKey
      }
    } catch {
      await logger.error(
        "Failed to retrieve master key: \(error.localizedDescription)",
        metadata: nil
      )
      
      if let secError=error as? SecurityProtocolError {
        throw secError
      } else {
        throw SecurityProtocolError
          .cryptographicError("Failed to retrieve master key: \(error.localizedDescription)")
      }
    }
  }

  /**
   Derives a wrapping key from system and device-specific information.

   This key is used to protect the master key and is derived from secure
   hardware and system information to bind it to the device.

   - Returns: The derived wrapping key
   - Throws: SecurityProtocolError if key derivation fails
   */
  private func deriveWrappingKey() async throws -> [UInt8] {
    // Implementation-specific key derivation - this would use hardware info
    // For this example, we generate a key through the crypto service
    // In a real implementation, this would use secure enclaves and derivation
    return try await cryptoService.generateKey(bitLength: 256)
  }

  /**
   Clears all cached keys from memory.

   This should be called when the application is backgrounded or when
   the user explicitly logs out to prevent sensitive data from remaining in memory.
   */
  public func clearKeyCache() {
    // Securely zero all cached keys before removing them
    for (identifier, _) in keyCache {
      MemoryProtection.securelyZeroData(&keyCache[identifier]!)
    }
    keyCache.removeAll()
    
    // Log the cache clearing operation
    Task {
      await logger.info("Cleared key cache", metadata: nil)
    }
  }

  /**
   Deinitializes the actor, ensuring all sensitive data is cleared.
   */
  deinit {
    // Ensure all cached keys are securely zeroed
    clearKeyCache()
  }
}
