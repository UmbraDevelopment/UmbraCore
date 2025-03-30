import Foundation
import LoggingInterfaces
import SecurityCoreInterfaces
import SecurityCoreTypes
import SecurityTypes

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
  private var keyCache: [String: SecureBytes]=[:]

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

   - Parameters:
      - key: The key to store
      - identifier: Unique identifier for the key
      - overwrite: Whether to overwrite an existing key with the same identifier
   - Throws: SecurityProtocolError if storage fails
   */
  public func storeKey(
    _ key: SecureBytes,
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
      let masterKey=try await getMasterKey()

      // Encrypt the key
      let encryptedKey=try await cryptoService.encrypt(data: key, using: masterKey)

      // Write to storage
      try encryptedKey.extractUnderlyingData().write(to: keyURL)

      // Update cache
      keyCache[identifier]=key

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

   - Parameter identifier: The unique identifier of the key to retrieve
   - Returns: The retrieved key
   - Throws: SecurityProtocolError if retrieval fails
   */
  public func retrieveKey(withIdentifier identifier: String) async throws -> SecureBytes {
    // Check cache first
    if let cachedKey=keyCache[identifier] {
      return cachedKey
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
      let encryptedKey=SecureBytes(data: encryptedData)

      // Retrieve master key for unwrapping
      let masterKey=try await getMasterKey()

      // Decrypt the key
      let key=try await cryptoService.decrypt(data: encryptedKey, using: masterKey)

      // Update cache
      keyCache[identifier]=key

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
   - Throws: SecurityProtocolError if deletion fails
   */
  public func deleteKey(withIdentifier identifier: String) async throws {
    // Remove from cache
    keyCache.removeValue(forKey: identifier)

    // Construct key URL
    let keyURL=storageURL.appendingPathComponent("\(identifier).key")

    // Check if key exists
    guard FileManager.default.fileExists(atPath: keyURL.path) else {
      await logger.warning(
        "Key with identifier '\(identifier)' not found for deletion",
        metadata: nil
      )
      return
    }

    do {
      // Delete the file
      try FileManager.default.removeItem(at: keyURL)
      await logger.info("Successfully deleted key with identifier: \(identifier)", metadata: nil)
    } catch {
      await logger.error("Failed to delete key: \(error.localizedDescription)", metadata: nil)
      throw SecurityProtocolError
        .cryptographicError("Failed to delete key: \(error.localizedDescription)")
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
    newKeySize size: Int=256,
    dataToReencrypt: [SecureBytes]?=nil
  ) async throws -> [SecureBytes]? {
    // Retrieve the old key
    let oldKey=try await retrieveKey(withIdentifier: identifier)

    // Generate a new key
    let newKey=try await cryptoService.generateKey(size: size)

    // Store the new key, overwriting the old one
    try await storeKey(newKey, withIdentifier: identifier, overwrite: true)

    // Re-encrypt data if provided
    if let dataItems=dataToReencrypt {
      // Decrypt with old key
      let decryptedItems=try await cryptoService.decryptBatch(dataItems: dataItems, using: oldKey)

      // Re-encrypt with new key
      let reencryptedItems=try await cryptoService.encryptBatch(
        dataItems: decryptedItems,
        using: newKey
      )

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
   Gets or generates the master key used for wrapping other keys.

   - Returns: The master key
   - Throws: SecurityProtocolError if key retrieval or generation fails
   */
  private func getMasterKey() async throws -> SecureBytes {
    let masterKeyIdentifier="umbra.master.key"
    let masterKeyURL=storageURL.appendingPathComponent("\(masterKeyIdentifier).key")

    // If master key doesn't exist, generate it
    if !FileManager.default.fileExists(atPath: masterKeyURL.path) {
      await logger.info("Generating new master key", metadata: nil)

      // Generate a strong key
      let masterKey=try await cryptoService.generateKey(size: 256)

      // Derive a wrapping key from device-specific information
      let wrappingKey=try await deriveWrappingKey()

      // Encrypt the master key with the wrapping key
      let encryptedMasterKey=try await cryptoService.encrypt(data: masterKey, using: wrappingKey)

      // Write to storage
      try encryptedMasterKey.extractUnderlyingData().write(to: masterKeyURL)

      return masterKey
    }

    // Read existing master key
    do {
      let encryptedData=try Data(contentsOf: masterKeyURL)
      let encryptedMasterKey=SecureBytes(data: encryptedData)

      // Derive the wrapping key
      let wrappingKey=try await deriveWrappingKey()

      // Decrypt the master key
      let masterKey=try await cryptoService.decrypt(data: encryptedMasterKey, using: wrappingKey)

      return masterKey
    } catch {
      await logger.error(
        "Failed to retrieve master key: \(error.localizedDescription)",
        metadata: nil
      )
      throw SecurityProtocolError
        .cryptographicError("Failed to retrieve master key: \(error.localizedDescription)")
    }
  }

  /**
   Derives a wrapping key from device-specific information.

   This key is used to protect the master key and is derived from
   hardware-specific information where possible.

   - Returns: A device-specific wrapping key
   - Throws: SecurityProtocolError if key derivation fails
   */
  private func deriveWrappingKey() async throws -> SecureBytes {
    // Create a device identifier that's stable across app launches
    var deviceIdentifiers=[String]()

    // Add stable device identifiers (replace with actual implementation)
    deviceIdentifiers.append(Bundle.main.bundleIdentifier ?? "com.umbra.core")

    #if os(macOS)
      // Add macOS-specific identifiers
      if let serialNumber=getSerialNumber() {
        deviceIdentifiers.append(serialNumber)
      }
    #endif

    // Join and hash the identifiers to create a stable seed
    let identifierString=deviceIdentifiers.joined(separator: "|")
    let identifierData=identifierString.data(using: .utf8)!
    let identifierBytes=SecureBytes(data: identifierData)

    // Hash multiple times to strengthen
    let hash1=try await cryptoService.hash(data: identifierBytes, algorithm: "SHA256")
    let hash2=try await cryptoService.hash(data: hash1, algorithm: "SHA512")

    // Use the resulting hash as our wrapping key
    return hash2
  }

  #if os(macOS)
    /**
     Retrieves the Mac serial number for device identification.

     - Returns: Serial number as a string, or nil if not available
     */
    private func getSerialNumber() -> String? {
      // This is a placeholder - actual implementation would use IOKit
      // to retrieve the hardware serial in a secure way
      nil
    }
  #endif
}
