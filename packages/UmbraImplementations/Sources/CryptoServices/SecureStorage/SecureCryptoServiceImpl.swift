/**
 # EnhancedSecureCryptoServiceImpl

 A fully secure implementation of CryptoServiceProtocol that follows the Alpha Dot Five
 architecture principles, integrating native actor-based SecureStorage for all
 cryptographic materials.

 This implementation ensures all sensitive data is properly stored, retrieved, and
 managed through secure channels with appropriate privacy protections.
 */

import CryptoInterfaces
import CryptoTypes
import Foundation
import LoggingInterfaces
import LoggingTypes
import SecurityCoreInterfaces
import UmbraErrors

/**
 A secure implementation of CryptoServiceProtocol using actor-based SecureStorage
 for all cryptographic operations.
 */
public actor EnhancedSecureCryptoServiceImpl: CryptoServiceProtocol {
  /// The wrapped crypto service implementation
  private let wrapped: CryptoServiceProtocol

  /// Secure storage specifically for cryptographic materials
  private let secureCryptoStorage: SecureCryptoStorage
  
  /// Storage adapter for protocol compliance
  private let storageAdapter: SecureStorageAdapter

  /// Secure storage protocol implementation for storing and retrieving data
  public var secureStorage: any SecureStorageProtocol {
    return storageAdapter
  }

  /// Logger for recording operations with proper privacy controls
  private let logger: LoggingProtocol

  /**
   Initialises a new secure crypto service.

   - Parameters:
      - wrapped: The base crypto service implementation
      - storage: Secure storage for cryptographic materials
      - logger: Logger for recording operations
   */
  public init(
    wrapped: CryptoServiceProtocol,
    storage: SecureCryptoStorage,
    logger: LoggingProtocol
  ) {
    self.wrapped = wrapped
    self.secureCryptoStorage = storage
    self.logger = logger
    self.storageAdapter = SecureStorageAdapter(storage: storage, logger: logger)
  }

  /**
   Encrypts data using the provided key and initialisation vector.

   - Parameters:
      - data: Data to encrypt
      - key: Encryption key
      - iv: Initialisation vector
      - cryptoOptions: Optional configuration

   - Returns: Encrypted data
   - Throws: CryptoError if encryption fails
   */
  public func encrypt(
    _ data: Data,
    using key: Data,
    iv: Data,
    cryptoOptions: CryptoOptions?
  ) async throws -> Data {
    // For small payloads, first try to get the key from secure storage
    var keyToUse = key
    if key.count < 64 && key.count > 16 {
      // This might be a key identifier rather than the actual key
      do {
        let keyString = String(data: key, encoding: .utf8) ?? ""
        keyToUse = try await secureCryptoStorage.retrieveKey(identifier: keyString)

        var metadata = PrivacyMetadata()
        metadata["algorithm"] = PrivacyMetadataValue(value: cryptoOptions?.algorithm.rawValue ?? "default", privacy: .public)
        metadata["keyId"] = PrivacyMetadataValue(value: keyString, privacy: .private)

        await logger.debug(
          "Retrieved encryption key from secure storage",
          metadata: metadata,
          source: "SecureCryptoService"
        )
      } catch {
        // Not a key identifier, use the key directly
        keyToUse = key
      }
    }

    // Use the wrapped implementation for encryption
    let encryptedData = try await wrapped.encrypt(
      data,
      using: keyToUse,
      iv: iv,
      cryptoOptions: cryptoOptions
    )

    var metadata = PrivacyMetadata()
    metadata["algorithm"] = PrivacyMetadataValue(value: cryptoOptions?.algorithm.rawValue ?? "default", privacy: .public)
    metadata["dataSize"] = PrivacyMetadataValue(value: "\(data.count)", privacy: .public)

    await logger.debug(
      "Successfully encrypted data",
      metadata: metadata,
      source: "SecureCryptoService"
    )

    return encryptedData
  }

  /**
   Decrypts data using the provided key and initialisation vector.

   - Parameters:
      - data: Data to decrypt
      - key: Decryption key
      - iv: Initialisation vector
      - cryptoOptions: Optional configuration

   - Returns: Decrypted data
   - Throws: CryptoError if decryption fails
   */
  public func decrypt(
    _ data: Data,
    using key: Data,
    iv: Data,
    cryptoOptions: CryptoOptions?
  ) async throws -> Data {
    // For small payloads, first try to get the key from secure storage
    var keyToUse = key
    if key.count < 64 && key.count > 16 {
      // This might be a key identifier rather than the actual key
      do {
        let keyString = String(data: key, encoding: .utf8) ?? ""
        keyToUse = try await secureCryptoStorage.retrieveKey(identifier: keyString)

        var metadata = PrivacyMetadata()
        metadata["algorithm"] = PrivacyMetadataValue(value: cryptoOptions?.algorithm.rawValue ?? "default", privacy: .public)
        metadata["keyId"] = PrivacyMetadataValue(value: keyString, privacy: .private)

        await logger.debug(
          "Retrieved decryption key from secure storage",
          metadata: metadata,
          source: "SecureCryptoService"
        )
      } catch {
        // Not a key identifier, use the key directly
        keyToUse = key
      }
    }

    // Use the wrapped implementation for decryption
    let decryptedData = try await wrapped.decrypt(
      data,
      using: keyToUse,
      iv: iv,
      cryptoOptions: cryptoOptions
    )

    var metadata = PrivacyMetadata()
    metadata["algorithm"] = PrivacyMetadataValue(value: cryptoOptions?.algorithm.rawValue ?? "default", privacy: .public)
    metadata["dataSize"] = PrivacyMetadataValue(value: "\(data.count)", privacy: .public)

    await logger.debug(
      "Successfully decrypted data",
      metadata: metadata,
      source: "SecureCryptoService"
    )

    return decryptedData
  }

  /**
   Derives a key from a password, salt, and iterations.

   - Parameters:
      - password: Password to derive key from
      - salt: Salt data to use in derivation
      - iterations: Number of iterations
      - derivationOptions: Optional configuration

   - Returns: Derived key or its identifier
   - Throws: CryptoError if derivation fails
   */
  public func deriveKey(
    from password: String,
    salt: Data,
    iterations: Int,
    derivationOptions: KeyDerivationOptions?
  ) async throws -> Data {
    // Generate the key using the wrapped implementation
    let derivedKey = try await wrapped.deriveKey(
      from: password,
      salt: salt,
      iterations: iterations,
      derivationOptions: derivationOptions
    )

    // Store the key securely without storing the password
    let passwordReference = String(password.hashValue)
    let identifier = try await secureCryptoStorage.storeDerivedKey(
      derivedKey,
      fromPasswordReference: passwordReference,
      salt: salt,
      iterations: iterations,
      options: derivationOptions
    )

    var metadata = PrivacyMetadata()
    metadata["iterations"] = PrivacyMetadataValue(value: "\(iterations)", privacy: .public)
    metadata["algorithm"] = PrivacyMetadataValue(value: derivationOptions?.function.rawValue ?? "pbkdf2", privacy: .public)
    metadata["identifier"] = PrivacyMetadataValue(value: identifier, privacy: .private)

    await logger.info(
      "Successfully derived and stored key",
      metadata: metadata,
      source: "SecureCryptoService"
    )

    // Return the identifier instead of the key
    return identifier.data(using: .utf8) ?? derivedKey
  }

  /**
   Generates a cryptographic key of the specified length.

   - Parameters:
      - length: Length of the key in bytes
      - keyOptions: Optional configuration

   - Returns: Generated key or its identifier
   - Throws: CryptoError if key generation fails
   */
  public func generateKey(
    length: Int,
    keyOptions: KeyGenerationOptions?
  ) async throws -> Data {
    // Generate the key using the wrapped implementation
    let generatedKey = try await wrapped.generateKey(
      length: length,
      keyOptions: keyOptions
    )

    // Store the key securely
    let identifier = "generated_key_\(UUID().uuidString)"
    try await secureCryptoStorage.storeKey(
      generatedKey,
      identifier: identifier,
      purpose: keyOptions?.purpose ?? .encryption
    )

    var metadata = PrivacyMetadata()
    metadata["length"] = PrivacyMetadataValue(value: "\(length)", privacy: .public)
    metadata["purpose"] = PrivacyMetadataValue(value: keyOptions?.purpose.rawValue ?? "encryption", privacy: .public)
    metadata["identifier"] = PrivacyMetadataValue(value: identifier, privacy: .private)

    await logger.info(
      "Successfully generated and stored key",
      metadata: metadata,
      source: "SecureCryptoService"
    )

    // Return the identifier instead of the key
    return identifier.data(using: .utf8) ?? generatedKey
  }

  /**
   Generates an HMAC for the provided data using the specified key.

   - Parameters:
      - data: Data to authenticate
      - key: Key to use for HMAC
      - hmacOptions: Optional configuration

   - Returns: Generated HMAC
   - Throws: CryptoError if HMAC generation fails
   */
  public func generateHMAC(
    for data: Data,
    using key: Data,
    hmacOptions: HMACOptions?
  ) async throws -> Data {
    // For small payloads, first try to get the key from secure storage
    var keyToUse = key
    if key.count < 64 && key.count > 16 {
      // This might be a key identifier rather than the actual key
      do {
        let keyString = String(data: key, encoding: .utf8) ?? ""
        keyToUse = try await secureCryptoStorage.retrieveKey(identifier: keyString)

        var metadata = PrivacyMetadata()
        metadata["algorithm"] = PrivacyMetadataValue(value: hmacOptions?.algorithm.rawValue ?? "sha256", privacy: .public)
        metadata["keyId"] = PrivacyMetadataValue(value: keyString, privacy: .private)

        await logger.debug(
          "Retrieved HMAC key from secure storage",
          metadata: metadata,
          source: "SecureCryptoService"
        )
      } catch {
        // Not a key identifier, use the key directly
        keyToUse = key
      }
    }

    // Generate the HMAC using the wrapped implementation
    let hmac = try await wrapped.generateHMAC(
      for: data,
      using: keyToUse,
      hmacOptions: hmacOptions
    )

    // Store the HMAC securely
    let keyIdentifier = String(data: key, encoding: .utf8) ?? "direct_key"
    let hmacIdentifier = try await secureCryptoStorage.storeHMAC(
      hmac,
      forDataHash: data.hashValue,
      keyIdentifier: keyIdentifier,
      algorithm: hmacOptions?.algorithm ?? .sha256
    )

    var metadata = PrivacyMetadata()
    metadata["algorithm"] = PrivacyMetadataValue(value: hmacOptions?.algorithm.rawValue ?? "sha256", privacy: .public)
    metadata["hmacId"] = PrivacyMetadataValue(value: hmacIdentifier, privacy: .private)
    metadata["dataSize"] = PrivacyMetadataValue(value: "\(data.count)", privacy: .public)

    await logger.debug(
      "Successfully generated and stored HMAC",
      metadata: metadata,
      source: "SecureCryptoService"
    )

    return hmac
  }

  /**
   Encrypt data from secure storage using a key from secure storage.
   - Parameters:
      - dataIdentifier: Identifier of the data to encrypt.
      - keyIdentifier: Identifier of the key to use for encryption.
      - options: Optional encryption options.
   - Returns: Identifier of the encrypted data or an error.
  */
  public func encrypt(
    dataIdentifier: String,
    keyIdentifier: String,
    options: SecurityCoreInterfaces.EncryptionOptions?
  ) async -> Result<String, SecurityStorageError> {
    // Log the encryption operation with privacy protections
    var metadata = PrivacyMetadata()
    metadata.add(key: "operation", value: "encrypt", privacyLevel: .public)
    metadata.add(key: "dataIdentifier", value: dataIdentifier, privacyLevel: .private)
    metadata.add(key: "keyIdentifier", value: keyIdentifier, privacyLevel: .private)

    await logger.debug("Starting encryption operation", metadata: metadata, source: "SecureCryptoService")

    // Retrieve data from secure storage
    let dataResult = await secureStorage.retrieveData(withIdentifier: dataIdentifier)

    guard case .success(let data) = dataResult else {
      if case .failure(let error) = dataResult {
        await logger.error("Failed to retrieve data for encryption: \(error.localizedDescription)",
                          metadata: metadata,
                          source: "SecureCryptoService")
        return .failure(error)
      }
      return .failure(.dataNotFound)
    }

    // Retrieve key from secure storage
    let keyResult = await secureStorage.retrieveData(withIdentifier: keyIdentifier)

    guard case .success(let keyData) = keyResult else {
      if case .failure(let error) = keyResult {
        await logger.error("Failed to retrieve key for encryption: \(error.localizedDescription)",
                          metadata: metadata,
                          source: "SecureCryptoService")
        return .failure(error)
      }
      return .failure(.keyNotFound)
    }

    // Forward the operation to the wrapped implementation
    let result = await wrapped.encrypt(
      dataIdentifier: dataIdentifier,
      keyIdentifier: keyIdentifier,
      options: options
    )

    // Log the result
    switch result {
    case .success(let identifier):
      var resultMetadata = metadata
      resultMetadata.add(key: "resultIdentifier", value: identifier, privacyLevel: .private)
      await logger.info("Encryption completed successfully",
                        metadata: resultMetadata,
                        source: "SecureCryptoService")
    case .failure(let error):
      await logger.error("Encryption failed: \(error.localizedDescription)",
                        metadata: metadata,
                        source: "SecureCryptoService")
    }

    return result
  }

  /**
   Decrypt data from secure storage using a key from secure storage.
   - Parameters:
      - encryptedDataIdentifier: Identifier of the encrypted data.
      - keyIdentifier: Identifier of the key to use for decryption.
      - options: Optional decryption options.
   - Returns: Identifier of the decrypted data or an error.
  */
  public func decrypt(
    encryptedDataIdentifier: String,
    keyIdentifier: String,
    options: SecurityCoreInterfaces.DecryptionOptions?
  ) async -> Result<String, SecurityStorageError> {
    // Log the decryption operation with privacy protections
    var metadata = PrivacyMetadata()
    metadata.add(key: "operation", value: "decrypt", privacyLevel: .public)
    metadata.add(key: "encryptedDataIdentifier", value: encryptedDataIdentifier, privacyLevel: .private)
    metadata.add(key: "keyIdentifier", value: keyIdentifier, privacyLevel: .private)

    await logger.debug("Starting decryption operation", metadata: metadata, source: "SecureCryptoService")

    // Forward the operation to the wrapped implementation
    let result = await wrapped.decrypt(
      encryptedDataIdentifier: encryptedDataIdentifier,
      keyIdentifier: keyIdentifier,
      options: options
    )

    // Log the result
    switch result {
    case .success(let identifier):
      var resultMetadata = metadata
      resultMetadata.add(key: "resultIdentifier", value: identifier, privacyLevel: .private)
      await logger.info("Decryption completed successfully",
                        metadata: resultMetadata,
                        source: "SecureCryptoService")
    case .failure(let error):
      await logger.error("Decryption failed: \(error.localizedDescription)",
                        metadata: metadata,
                        source: "SecureCryptoService")
    }

    return result
  }

  /**
   Hash data from secure storage.
   - Parameters:
      - dataIdentifier: Identifier of the data to hash.
      - options: Optional hashing options.
   - Returns: Identifier of the generated hash or an error.
  */
  public func hash(
    dataIdentifier: String,
    options: SecurityCoreInterfaces.HashingOptions?
  ) async -> Result<String, SecurityStorageError> {
    // Log the hash operation with privacy protections
    var metadata = PrivacyMetadata()
    metadata.add(key: "operation", value: "hash", privacyLevel: .public)
    metadata.add(key: "dataIdentifier", value: dataIdentifier, privacyLevel: .private)

    await logger.debug("Starting hash operation", metadata: metadata, source: "SecureCryptoService")

    // Forward the operation to the wrapped implementation
    let result = await wrapped.hash(
      dataIdentifier: dataIdentifier,
      options: options
    )

    // Log the result
    switch result {
    case .success(let identifier):
      var resultMetadata = metadata
      resultMetadata.add(key: "resultIdentifier", value: identifier, privacyLevel: .private)
      await logger.info("Hash operation completed successfully",
                        metadata: resultMetadata,
                        source: "SecureCryptoService")
    case .failure(let error):
      await logger.error("Hash operation failed: \(error.localizedDescription)",
                        metadata: metadata,
                        source: "SecureCryptoService")
    }

    return result
  }

  /**
   Verify a hash against data from secure storage.
   - Parameters:
      - dataIdentifier: Identifier of the data to verify.
      - hashIdentifier: Identifier of the hash to compare against.
      - options: Optional hashing options.
   - Returns: Whether the hash matches the data or an error.
  */
  public func verifyHash(
    dataIdentifier: String,
    hashIdentifier: String,
    options: SecurityCoreInterfaces.HashingOptions?
  ) async -> Result<Bool, SecurityStorageError> {
    // Log the verification operation with privacy protections
    var metadata = PrivacyMetadata()
    metadata.add(key: "operation", value: "verifyHash", privacyLevel: .public)
    metadata.add(key: "dataIdentifier", value: dataIdentifier, privacyLevel: .private)
    metadata.add(key: "hashIdentifier", value: hashIdentifier, privacyLevel: .private)

    await logger.debug("Starting hash verification", metadata: metadata, source: "SecureCryptoService")

    // Forward the operation to the wrapped implementation
    let result = await wrapped.verifyHash(
      dataIdentifier: dataIdentifier,
      hashIdentifier: hashIdentifier,
      options: options
    )

    // Log the result
    switch result {
    case .success(let verified):
      var resultMetadata = metadata
      resultMetadata.add(key: "verified", value: String(verified), privacyLevel: .public)
      let status = verified ? "verified" : "failed verification"
      await logger.info("Hash verification completed: \(status)",
                        metadata: resultMetadata,
                        source: "SecureCryptoService")
    case .failure(let error):
      await logger.error("Hash verification failed: \(error.localizedDescription)",
                        metadata: metadata,
                        source: "SecureCryptoService")
    }

    return result
  }

  /**
   Generate a cryptographic key.
   - Parameters:
      - length: Length of the key in bytes.
      - options: Optional key generation options.
   - Returns: Identifier of the generated key or an error.
  */
  public func generateKey(
    length: Int,
    options: SecurityCoreInterfaces.KeyGenerationOptions?
  ) async -> Result<String, SecurityStorageError> {
    // Log the key generation operation with privacy protections
    var metadata = PrivacyMetadata()
    metadata.add(key: "operation", value: "generateKey", privacyLevel: .public)
    metadata.add(key: "keyLength", value: String(length), privacyLevel: .public)

    await logger.debug("Starting key generation", metadata: metadata, source: "SecureCryptoService")

    // Forward the operation to the wrapped implementation
    let result = await wrapped.generateKey(
      length: length,
      options: options
    )

    // Log the result
    switch result {
    case .success(let identifier):
      var resultMetadata = metadata
      resultMetadata.add(key: "keyIdentifier", value: identifier, privacyLevel: .private)
      await logger.info("Key generation completed successfully",
                        metadata: resultMetadata,
                        source: "SecureCryptoService")
    case .failure(let error):
      await logger.error("Key generation failed: \(error.localizedDescription)",
                        metadata: metadata,
                        source: "SecureCryptoService")
    }

    return result
  }

  /**
   Import raw data into secure storage.
   - Parameters:
      - data: Raw data to import.
      - customIdentifier: Optional custom identifier for the data.
   - Returns: Identifier of the stored data or an error.
  */
  public func importData(
    _ data: [UInt8],
    customIdentifier: String?
  ) async -> Result<String, SecurityStorageError> {
    // Log the import operation with privacy protections
    var metadata = PrivacyMetadata()
    metadata.add(key: "operation", value: "importData", privacyLevel: .public)
    metadata.add(key: "dataSize", value: String(data.count), privacyLevel: .public)

    if let customIdentifier = customIdentifier {
      metadata.add(key: "customIdentifier", value: customIdentifier, privacyLevel: .private)
    }

    await logger.debug("Starting data import", metadata: metadata, source: "SecureCryptoService")

    // Forward the operation to the wrapped implementation
    let result = await wrapped.importData(
      data,
      customIdentifier: customIdentifier
    )

    // Log the result
    switch result {
    case .success(let identifier):
      var resultMetadata = metadata
      resultMetadata.add(key: "resultIdentifier", value: identifier, privacyLevel: .private)
      await logger.info("Data import completed successfully",
                        metadata: resultMetadata,
                        source: "SecureCryptoService")
    case .failure(let error):
      await logger.error("Data import failed: \(error.localizedDescription)",
                        metadata: metadata,
                        source: "SecureCryptoService")
    }

    return result
  }

  /**
   Export data from secure storage.
   - Parameter identifier: Identifier of the data to export.
   - Returns: The raw data or an error.
   - Warning: Use with caution as this exposes sensitive material.
  */
  public func exportData(
    identifier: String
  ) async -> Result<[UInt8], SecurityStorageError> {
    // Log the export operation with privacy protections
    var metadata = PrivacyMetadata()
    metadata.add(key: "operation", value: "exportData", privacyLevel: .public)
    metadata.add(key: "identifier", value: identifier, privacyLevel: .private)

    await logger.debug("Starting data export", metadata: metadata, source: "SecureCryptoService")

    // Log warning about data exposure
    await logger.warning(
      "Exporting data from secure storage exposes sensitive material",
      metadata: metadata,
      source: "SecureCryptoService"
    )

    // Forward the operation to the wrapped implementation
    let result = await wrapped.exportData(
      identifier: identifier
    )

    // Log the result
    switch result {
    case .success(let data):
      var resultMetadata = metadata
      resultMetadata.add(key: "dataSize", value: String(data.count), privacyLevel: .public)
      await logger.info("Data export completed successfully",
                        metadata: resultMetadata,
                        source: "SecureCryptoService")
    case .failure(let error):
      await logger.error("Data export failed: \(error.localizedDescription)",
                        metadata: metadata,
                        source: "SecureCryptoService")
    }

    return result
  }
}
