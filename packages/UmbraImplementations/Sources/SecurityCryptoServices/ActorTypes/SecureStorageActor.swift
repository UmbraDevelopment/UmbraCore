import CoreSecurityTypes
import DomainSecurityTypes
import Foundation
import LoggingInterfaces
import SecurityCoreInterfaces

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
    providerType: SecurityProviderType? = nil,
    storageURL: URL? = nil,
    logger: LoggingProtocol
  ) {
    self.logger = logger
    cryptoService = CryptoServiceActor(providerType: providerType, logger: logger)

    // Set up storage location
    if let customURL = storageURL {
      self.storageURL = customURL
    } else {
      // Default to app support directory
      let fileManager = FileManager.default
      let appSupportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)
        .first!
      self.storageURL = appSupportURL.appendingPathComponent("UmbraSecureStorage", isDirectory: true)
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

   - Parameters:
      - key: The key to store as a byte array
      - identifier: Unique identifier for the key
      - overwrite: Whether to overwrite an existing key with the same identifier
   - Throws: SecurityProtocolError if storage fails
   */
  public func storeKey(
    _ key: [UInt8],
    withIdentifier identifier: String,
    overwrite: Bool = false
  ) async throws {
    // Check if key exists and we're not overwriting
    let keyURL = storageURL.appendingPathComponent("\(identifier).key")
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

      // Encrypt the key
      let encryptResult = await cryptoService.encrypt(data: key, using: masterKey)
      
      guard case let .success(encryptedKey) = encryptResult else {
        if case let .failure(error) = encryptResult {
          throw error
        } else {
          throw SecurityProtocolError.cryptographicError("Encryption failed with unknown error")
        }
      }

      // Write to storage
      try Data(encryptedKey).write(to: keyURL)

      // Update cache
      keyCache[identifier] = key

      await logger.info("Successfully stored key with identifier: \(identifier)", metadata: nil)
    } catch {
      await logger.error("Failed to store key: \(error.localizedDescription)", metadata: nil)

      if let secError = error as? SecurityProtocolError {
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

   - Parameter identifier: The unique identifier of the key to retrieve
   - Returns: The retrieved key as a byte array
   - Throws: SecurityProtocolError if retrieval fails
   */
  public func retrieveKey(withIdentifier identifier: String) async throws -> [UInt8] {
    // Check cache first
    if let cachedKey = keyCache[identifier] {
      return cachedKey
    }

    // Construct key URL
    let keyURL = storageURL.appendingPathComponent("\(identifier).key")

    // Check if key exists
    guard FileManager.default.fileExists(atPath: keyURL.path) else {
      await logger.error("Key with identifier '\(identifier)' not found", metadata: nil)
      throw SecurityProtocolError.invalidInput("Key with identifier '\(identifier)' not found")
    }

    do {
      // Read encrypted key from storage
      let encryptedData = try Data(contentsOf: keyURL)
      let encryptedKey = [UInt8](encryptedData)

      // Retrieve master key for unwrapping
      let masterKey = try await getMasterKey()

      // Decrypt the key
      let decryptResult = await cryptoService.decrypt(data: encryptedKey, using: masterKey)
      
      guard case let .success(key) = decryptResult else {
        if case let .failure(error) = decryptResult {
          throw error
        } else {
          throw SecurityProtocolError.cryptographicError("Decryption failed with unknown error")
        }
      }

      // Update cache
      keyCache[identifier] = key

      await logger.info("Successfully retrieved key with identifier: \(identifier)", metadata: nil)
      return key
    } catch {
      await logger.error("Failed to retrieve key: \(error.localizedDescription)", metadata: nil)

      if let secError = error as? SecurityProtocolError {
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
   - Throws: SecurityProtocolError if deletion fails
   */
  public func deleteKey(withIdentifier identifier: String) async throws {
    let keyURL = storageURL.appendingPathComponent("\(identifier).key")

    // Check if key exists
    guard FileManager.default.fileExists(atPath: keyURL.path) else {
      await logger.error("Key with identifier '\(identifier)' not found", metadata: nil)
      throw SecurityProtocolError.invalidInput("Key with identifier '\(identifier)' not found")
    }

    do {
      // Remove from disk
      try FileManager.default.removeItem(at: keyURL)

      // Remove from cache
      keyCache[identifier] = nil

      await logger.info("Successfully deleted key with identifier: \(identifier)", metadata: nil)
    } catch {
      await logger.error("Failed to delete key: \(error.localizedDescription)", metadata: nil)
      throw SecurityProtocolError
        .invalidInput("Failed to delete key: \(error.localizedDescription)")
    }
  }

  /**
   Lists all available key identifiers.

   - Returns: Array of key identifiers
   - Throws: SecurityProtocolError if listing fails
   */
  public func listKeyIdentifiers() async throws -> [String] {
    do {
      let fileManager = FileManager.default
      let fileURLs = try fileManager.contentsOfDirectory(
        at: storageURL,
        includingPropertiesForKeys: nil,
        options: [.skipsHiddenFiles]
      )

      let keyIdentifiers = fileURLs
        .filter { $0.pathExtension == "key" }
        .map { $0.deletingPathExtension().lastPathComponent }

      return keyIdentifiers
    } catch {
      await logger.error("Failed to list key identifiers: \(error.localizedDescription)", metadata: nil)
      throw SecurityProtocolError
        .invalidInput("Failed to list key identifiers: \(error.localizedDescription)")
    }
  }

  /**
   Rotates a key by generating a new key and re-encrypting any data secured with the old key.

   - Parameters:
      - identifier: The unique identifier of the key to rotate
      - size: Size in bits for the new key
      - dataToReencrypt: Optional data items to re-encrypt with the new key
   - Returns: Array of re-encrypted data items if provided
   - Throws: SecurityProtocolError if rotation fails
   */
  public func rotateKey(
    withIdentifier identifier: String,
    newKeySize size: Int = 256,
    dataToReencrypt: [[UInt8]]? = nil
  ) async throws -> [[UInt8]]? {
    // Retrieve the old key
    let oldKey = try await retrieveKey(withIdentifier: identifier)

    // Generate a new key
    let newKeyResult = await cryptoService.generateKey(size: size)
    
    guard case let .success(newKey) = newKeyResult else {
      if case let .failure(error) = newKeyResult {
        throw error
      } else {
        throw SecurityProtocolError.cryptographicError("Key generation failed with unknown error")
      }
    }

    // Store the new key, overwriting the old one
    try await storeKey(newKey, withIdentifier: identifier, overwrite: true)

    // Re-encrypt data if provided
    if let dataItems = dataToReencrypt {
      // Decrypt with old key
      let decryptResults = await cryptoService.decryptBatch(dataItems: dataItems, using: oldKey)
      
      guard case let .success(decryptedItems) = decryptResults else {
        if case let .failure(error) = decryptResults {
          throw error
        } else {
          throw SecurityProtocolError.cryptographicError("Decryption failed with unknown error")
        }
      }

      // Re-encrypt with new key
      let encryptResults = await cryptoService.encryptBatch(
        dataItems: decryptedItems,
        using: newKey
      )
      
      guard case let .success(reencryptedItems) = encryptResults else {
        if case let .failure(error) = encryptResults {
          throw error
        } else {
          throw SecurityProtocolError.cryptographicError("Encryption failed with unknown error")
        }
      }

      await logger.info(
        "Successfully rotated key and re-encrypted \(dataItems.count) data items",
        metadata: nil
      )
      return reencryptedItems
    }

    await logger.info("Successfully rotated key with identifier: \(identifier)", metadata: nil)
    return nil
  }

  // MARK: - Private Helpers

  /**
   Gets or generates the master key used for encrypting/decrypting other keys.

   - Returns: Master key as a byte array
   - Throws: SecurityProtocolError if key retrieval fails
   */
  private func getMasterKey() async throws -> [UInt8] {
    let masterKeyIdentifier = "umbra.master.key"
    let masterKeyURL = storageURL.appendingPathComponent("\(masterKeyIdentifier).key")

    // If master key doesn't exist, generate it
    if !FileManager.default.fileExists(atPath: masterKeyURL.path) {
      await logger.info("Master key does not exist, generating new one", metadata: nil)
      
      // Generate a new master key (32 bytes = 256 bits, suitable for AES-256)
      let randomResult = await cryptoService.generateRandomBytes(count: 32)
      
      guard case let .success(masterKeyBytes) = randomResult else {
        if case let .failure(error) = randomResult {
          throw error
        } else {
          throw SecurityProtocolError.cryptographicError("Random generation failed with unknown error")
        }
      }

      // Derive a wrapping key from device-specific factors
      // In a real implementation, this would use secure enclave or keychain
      let wrappingKeyResult = await cryptoService.deriveKey(
        fromPassword: "device-specific-salt",
        salt: [0x55, 0x4D, 0x42, 0x52, 0x41], // "UMBRA" in hex
        iterations: 10000
      )
      
      guard case let .success(wrappingKey) = wrappingKeyResult else {
        if case let .failure(error) = wrappingKeyResult {
          throw error
        } else {
          throw SecurityProtocolError.cryptographicError("Key derivation failed with unknown error")
        }
      }

      // Encrypt the master key with the wrapping key
      let encryptResult = await cryptoService.encrypt(data: masterKeyBytes, using: wrappingKey)
      
      guard case let .success(encryptedMasterKey) = encryptResult else {
        if case let .failure(error) = encryptResult {
          throw error
        } else {
          throw SecurityProtocolError.cryptographicError("Encryption failed with unknown error")
        }
      }

      // Save the encrypted master key
      try Data(encryptedMasterKey).write(to: masterKeyURL)
      
      // Return the unencrypted master key for immediate use
      return masterKeyBytes
    } else {
      // Master key exists, load and decrypt it
      let encryptedData = try Data(contentsOf: masterKeyURL)
      let encryptedMasterKey = [UInt8](encryptedData)

      // Derive the same wrapping key
      let wrappingKeyResult = await cryptoService.deriveKey(
        fromPassword: "device-specific-salt",
        salt: [0x55, 0x4D, 0x42, 0x52, 0x41], // "UMBRA" in hex
        iterations: 10000
      )
      
      guard case let .success(wrappingKey) = wrappingKeyResult else {
        if case let .failure(error) = wrappingKeyResult {
          throw error
        } else {
          throw SecurityProtocolError.cryptographicError("Key derivation failed with unknown error")
        }
      }

      // Decrypt the master key
      let decryptResult = await cryptoService.decrypt(data: encryptedMasterKey, using: wrappingKey)
      
      guard case let .success(masterKey) = decryptResult else {
        if case let .failure(error) = decryptResult {
          throw error
        } else {
          throw SecurityProtocolError.cryptographicError("Decryption failed with unknown error")
        }
      }

      return masterKey
    }
  }
}
