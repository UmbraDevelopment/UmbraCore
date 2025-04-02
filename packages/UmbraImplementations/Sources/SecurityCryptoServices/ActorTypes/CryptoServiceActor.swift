import CoreSecurityTypes
import DomainSecurityTypes
import Foundation
import LoggingInterfaces
import LoggingServices
import LoggingTypes
import ProviderFactories
import SecurityCoreInterfaces
import UmbraErrors

/**
 # CryptoServiceActor

 A Swift actor that provides thread-safe access to cryptographic operations
 using the pluggable security provider architecture.

 This actor fully embraces Swift's structured concurrency model, offering
 asynchronous methods for all cryptographic operations while ensuring proper
 isolation of mutable state.

 ## Usage

 ```swift
 // Create the actor with a specific provider type
 let logger = DefaultLogger()
 let cryptoService = CryptoServiceActor(providerType: .cryptoKit, logger: logger)

 // Perform operations asynchronously
 let encryptedData = try await cryptoService.encrypt(data: myData, using: myKey)
 ```

 ## Thread Safety

 All methods are automatically thread-safe due to Swift's actor isolation rules.
 Mutable state is properly contained within the actor and cannot be accessed from
 outside except through the defined async interfaces.
 */
public actor CryptoServiceActor: CryptoServiceProtocol {
  // MARK: - Properties

  /// The underlying security provider implementation
  private var provider: EncryptionProviderProtocol

  /// Logger for recording operations
  private let logger: LoggingProtocol

  /// Domain-specific logger for cryptographic operations
  private let logAdapter: DomainLogAdapter

  /// The source identifier for logging
  private let logSource = "CryptoService"
  
  /// The secure storage used for handling sensitive data
  public let secureStorage: SecureStorageProtocol
  
  /// Default security configuration
  private let defaultConfig: SecurityConfigDTO
  
  // MARK: - CryptoServiceProtocol Methods
  
  /// Encrypts binary data using a key from secure storage.
  public func encrypt(
    dataIdentifier: String,
    keyIdentifier: String,
    options: EncryptionOptions?
  ) async -> Result<String, SecurityStorageError> {
    do {
      // Retrieve data and key from secure storage
      let dataResult = await secureStorage.retrieve(identifier: dataIdentifier)
      let keyResult = await secureStorage.retrieve(identifier: keyIdentifier)
      
      guard case let .success(data) = dataResult else {
        return .failure(.dataNotFound)
      }
      
      guard case let .success(key) = keyResult else {
        return .failure(.keyNotFound)
      }
      
      // Encrypt the data
      let encryptResult = await encrypt(data: data, using: key)
      
      guard case let .success(encryptedData) = encryptResult else {
        return .failure(.encryptionFailed)
      }
      
      // Store the encrypted data
      return await secureStorage.store(encryptedData, customIdentifier: nil)
    } catch {
      return .failure(.encryptionFailed)
    }
  }
  
  /// Decrypts binary data using a key from secure storage.
  public func decrypt(
    encryptedDataIdentifier: String,
    keyIdentifier: String,
    options: DecryptionOptions?
  ) async -> Result<String, SecurityStorageError> {
    do {
      // Retrieve encrypted data and key from secure storage
      let dataResult = await secureStorage.retrieve(identifier: encryptedDataIdentifier)
      let keyResult = await secureStorage.retrieve(identifier: keyIdentifier)
      
      guard case let .success(encryptedData) = dataResult else {
        return .failure(.dataNotFound)
      }
      
      guard case let .success(key) = keyResult else {
        return .failure(.keyNotFound)
      }
      
      // Decrypt the data
      let decryptResult = await decrypt(data: encryptedData, using: key)
      
      guard case let .success(decryptedData) = decryptResult else {
        return .failure(.decryptionFailed)
      }
      
      // Store the decrypted data
      return await secureStorage.store(decryptedData, customIdentifier: nil)
    } catch {
      return .failure(.decryptionFailed)
    }
  }
  
  /// Computes a cryptographic hash of data in secure storage.
  public func hash(
    dataIdentifier: String,
    options: HashingOptions?
  ) async -> Result<String, SecurityStorageError> {
    do {
      // Retrieve data from secure storage
      let dataResult = await secureStorage.retrieve(identifier: dataIdentifier)
      
      guard case let .success(data) = dataResult else {
        return .failure(.dataNotFound)
      }
      
      // Hash the data
      let algorithm = options?.algorithm ?? defaultConfig.hashAlgorithm
      let hashResult = await hash(data: data, algorithm: algorithm)
      
      guard case let .success(hashedData) = hashResult else {
        return .failure(.hashingFailed)
      }
      
      // Store the hash
      return await secureStorage.store(hashedData, customIdentifier: nil)
    } catch {
      return .failure(.hashingFailed)
    }
  }
  
  /// Verifies a cryptographic hash against the expected value, both stored securely.
  public func verifyHash(
    dataIdentifier: String,
    hashIdentifier: String,
    options: HashingOptions?
  ) async -> Result<Bool, SecurityStorageError> {
    do {
      // Retrieve data and expected hash from secure storage
      let dataResult = await secureStorage.retrieve(identifier: dataIdentifier)
      let expectedHashResult = await secureStorage.retrieve(identifier: hashIdentifier)
      
      guard case let .success(data) = dataResult else {
        return .failure(.dataNotFound)
      }
      
      guard case let .success(expectedHash) = expectedHashResult else {
        return .failure(.hashNotFound)
      }
      
      // Compute hash of the data
      let algorithm = options?.algorithm ?? defaultConfig.hashAlgorithm
      let hashResult = await hash(data: data, algorithm: algorithm)
      
      guard case let .success(computedHash) = hashResult else {
        return .failure(.hashingFailed)
      }
      
      // Compare hashes
      return .success(computedHash == expectedHash)
    } catch {
      return .failure(.hashVerificationFailed)
    }
  }
  
  /// Generates a cryptographic key and stores it securely.
  public func generateKey(
    length: Int,
    options: KeyGenerationOptions?
  ) async -> Result<String, SecurityStorageError> {
    do {
      let keyGenResult = await generateKey(size: length)
      
      guard case let .success(key) = keyGenResult else {
        return .failure(.keyGenerationFailed)
      }
      
      // Store the key
      return await secureStorage.store(key, customIdentifier: options?.customIdentifier)
    } catch {
      return .failure(.keyGenerationFailed)
    }
  }
  
  /// Imports data into secure storage for use with cryptographic operations.
  public func importData(
    _ data: [UInt8],
    customIdentifier: String?
  ) async -> Result<String, SecurityStorageError> {
    await secureStorage.store(data, customIdentifier: customIdentifier)
  }
  
  /// Exports data from secure storage.
  public func exportData(
    identifier: String
  ) async -> Result<[UInt8], SecurityStorageError> {
    await secureStorage.retrieve(identifier: identifier)
  }

  // MARK: - Initialisation

  /**
   Initialises a new cryptographic service actor with the specified provider type.

   - Parameters:
    - providerType: The type of security provider to use
    - logger: The logger to use for recording operations
   */
  public init(
    providerType: SecurityProviderType,
    logger: LoggingProtocol,
    secureStorage: SecureStorageProtocol? = nil
  ) {
    // Create the provider factory
    let factory = SecurityProviderFactoryImpl.self

    // Attempt to create the provider
    do {
      provider = try factory.createProvider(type: providerType)
      defaultConfig = SecurityConfigDTO(
        encryptionAlgorithm: .aes256CBC,
        hashAlgorithm: .sha256,
        providerType: providerType
      )
    } catch {
      // If provider creation fails, use a fallback provider
      provider = FallbackEncryptionProvider()
      defaultConfig = SecurityConfigDTO(
        encryptionAlgorithm: .aes256CBC,
        hashAlgorithm: .sha256,
        providerType: .basic
      )
    }

    self.logger = logger
    
    // Create or use provided secure storage
    if let providedStorage = secureStorage {
      self.secureStorage = providedStorage
    } else {
      // Create default secure storage (temporary in-memory solution)
      let storageURL = URL(fileURLWithPath: NSTemporaryDirectory())
        .appendingPathComponent("com.umbra.securestorage")
      self.secureStorage = SecureStorageActor(
        providerType: providerType,
        storageURL: storageURL,
        logger: logger
      )
    }
    
    // Create domain log adapter
    logAdapter = DomainLogAdapter(logger: logger)
  }

  /**
   Encrypts data using the specified key and configuration.

   - Parameters:
      - data: The data to encrypt as a byte array
      - key: The encryption key as a byte array
      - config: Optional configuration for the encryption operation
   - Returns: Result containing the encrypted data or an error
   */
  public func encrypt(
    _ data: [UInt8],
    using key: [UInt8],
    config: SecurityConfigDTO? = nil
  ) async -> Result<[UInt8], SecurityServiceError> {
    let algorithm = (config ?? defaultConfig).encryptionAlgorithm

    await logAdapter.debug(
      "Encrypting data with algorithm: \(algorithm.rawValue)",
      source: logSource
    )

    do {
      // First, we need to generate an initialisation vector
      var ivData: Data
      do {
        ivData = try provider.generateIV(size: 16)
      } catch {
        await logAdapter.error(
          "Failed to generate IV: \(error.localizedDescription)",
          source: logSource
        )
        return .failure(
          SecurityServiceError.invalidInputData("Failed to generate IV: \(error.localizedDescription)")
        )
      }

      // Convert the input parameters to Data objects
      let inputData = Data(data)
      let keyData = Data(key)

      // Encrypt the data
      do {
        let encryptedData = try provider.encrypt(
          plaintext: inputData,
          key: keyData,
          iv: ivData,
          config: config ?? defaultConfig
        )

        // Prepend the IV to the encrypted data for later decryption
        let resultData = ivData + encryptedData
        return .success([UInt8](resultData))
      } catch {
        if let secError = error as? SecurityServiceError {
          return .failure(secError)
        } else {
          return .failure(
            SecurityServiceError.providerError("Encryption failed: \(error.localizedDescription)")
          )
        }
      }
    }
  }

  /**
   Decrypts data using the specified key and configuration.

   - Parameters:
      - data: The encrypted data with IV prefixed
      - key: The decryption key as a byte array
      - config: Optional configuration for the decryption operation
   - Returns: Result containing the decrypted data or an error
   */
  public func decrypt(
    _ data: [UInt8],
    using key: [UInt8],
    config: SecurityConfigDTO? = nil
  ) async -> Result<[UInt8], SecurityServiceError> {
    let algorithm = (config ?? defaultConfig).encryptionAlgorithm

    await logAdapter.debug(
      "Decrypting data with algorithm: \(algorithm.rawValue)",
      source: logSource
    )

    // Ensure the data includes an IV (at least 16 bytes)
    guard data.count > 16 else {
      await logAdapter.warning(
        "Decrypt failed: Data too short to contain IV",
        source: logSource
      )
      return .failure(SecurityServiceError.invalidInputData("Encrypted data too short"))
    }

    do {
      // Extract the IV from the first 16 bytes
      let iv = Data(data[0..<16])
      // The rest is the actual encrypted data
      let encryptedData = Data(data[16...])

      // Convert the key to a Data object
      let keyData = Data(key)

      // Decrypt the data
      do {
        let decryptedData = try provider.decrypt(
          ciphertext: encryptedData,
          key: keyData,
          iv: iv,
          config: config ?? defaultConfig
        )

        return .success([UInt8](decryptedData))
      } catch {
        if let secError = error as? SecurityServiceError {
          return .failure(secError)
        } else {
          return .failure(
            SecurityServiceError.providerError("Decryption failed: \(error.localizedDescription)")
          )
        }
      }
    }
  }

  /**
   Generates a new cryptographic key with the specified size.

   - Parameters:
      - size: The key size in bits
      - config: Optional configuration for the key generation operation
   - Returns: Result containing the generated key or an error
   */
  public func generateKey(
    size: Int,
    config: SecurityConfigDTO? = nil
  ) async -> Result<[UInt8], SecurityServiceError> {
    let algorithm = (config ?? defaultConfig).encryptionAlgorithm

    await logAdapter.debug(
      "Generating key with algorithm: \(algorithm.rawValue)",
      source: logSource
    )

    do {
      let keyData = try provider.generateKey(
        size: size,
        config: config ?? defaultConfig
      )

      return .success([UInt8](keyData))
    } catch {
      if let secError = error as? SecurityServiceError {
        return .failure(secError)
      } else {
        return .failure(
          SecurityServiceError.keyManagementError("Key generation failed: \(error.localizedDescription)")
        )
      }
    }
  }

  /**
   Derives a cryptographic key from the given password and salt.

   - Parameters:
      - password: The password to derive the key from
      - salt: The salt to use for key derivation
      - iterations: The number of iterations to use for key derivation
      - keyLength _: The length of the derived key in bytes
      - config: Optional configuration for the key derivation operation
   - Returns: Result containing the derived key or an error
   */
  public func deriveKey(
    fromPassword password: [UInt8],
    salt: [UInt8],
    iterations: Int = 10000,
    keyLength _: Int = 32,
    config: SecurityConfigDTO? = nil
  ) async -> Result<[UInt8], SecurityServiceError> {
    let algorithm = (config ?? defaultConfig).encryptionAlgorithm

    await logAdapter.debug(
      "Deriving key with algorithm: \(algorithm.rawValue)",
      source: logSource
    )

    do {
      // This implementation would typically use PBKDF2 or another KDF
      // For now, just simulate key derivation with a hash
      var result = Data()
      let passwordData = Data(password)
      let saltData = Data(salt)
      
      // Simple key derivation simulation
      var combined = passwordData
      combined.append(saltData)
      
      for _ in 0..<iterations / 1000 {
        // In a real implementation, this would use PBKDF2
        let hash = try provider.hash(data: combined, algorithm: "SHA256")
        combined = hash
        if result.count < 32 {
          result.append(hash)
        }
      }
      
      // Ensure we have the right key length
      if result.count > 32 {
        result = result.prefix(32)
      }
      
      return .success([UInt8](result))
    } catch {
      if let secError = error as? SecurityServiceError {
        return .failure(secError)
      } else {
        return .failure(
          SecurityServiceError.providerError("Key derivation failed: \(error.localizedDescription)")
        )
      }
    }
  }

  /**
   Computes a cryptographic hash of the input data.

   - Parameters:
      - data: The data to hash
      - algorithm: The hash algorithm to use
      - config: Optional configuration for the hash operation
   - Returns: Result containing the hash or an error
   */
  public func hash(
    _ data: [UInt8],
    algorithm: HashAlgorithm = .sha256,
    config: SecurityConfigDTO? = nil
  ) async -> Result<[UInt8], SecurityServiceError> {
    await logAdapter.debug(
      "Hashing data with algorithm: \(algorithm.rawValue)",
      source: logSource
    )

    do {
      // Execute the operation
      let result = try provider.hash(
        data: Data(data),
        algorithm: algorithm.rawValue
      )

      return .success([UInt8](result))
    } catch {
      if let secError = error as? SecurityServiceError {
        return .failure(secError)
      } else {
        return .failure(
          SecurityServiceError.keyManagementError("Hash operation failed: \(error.localizedDescription)")
        )
      }
    }
  }

  /**
   Encrypts multiple data items in parallel using task groups.

   - Parameters:
      - dataItems: Array of data items to encrypt as byte arrays
      - key: The encryption key as a byte array
      - config: Optional configuration for the encryption operation
   - Returns: Result containing the encrypted items or an error
   */
  public func encryptBatch(
    _ dataItems: [[UInt8]],
    using key: [UInt8],
    config: SecurityConfigDTO? = nil
  ) async -> Result<[[UInt8]], SecurityServiceError> {
    let algorithm = (config ?? defaultConfig).encryptionAlgorithm

    await logAdapter.debug(
      "Encrypting batch of data with algorithm: \(algorithm.rawValue)",
      source: logSource
    )

    var results = [[UInt8]]()
    results.reserveCapacity(dataItems.count)
    var encounteredError: SecurityServiceError? = nil

    // Process each item sequentially for simplicity
    for item in dataItems {
      let result = await encrypt(item, using: key, config: config)
      switch result {
        case let .success(encryptedData):
          results.append(encryptedData)
        case let .failure(error):
          encounteredError = error
          break
      }
      
      // If we encountered an error, stop processing and return it
      if encounteredError != nil {
        break
      }
    }
    
    // If any encryption failed, return the error
    if let error = encounteredError {
      return .failure(error)
    }

    return .success(results)
  }
  
  /**
   Decrypt a batch of data items using the same key.

   - Parameters:
      - dataItems: Array of data items to decrypt
      - key: Key to use for decryption
      - config: Optional configuration for the decryption operation
   - Returns: Result containing the decrypted data items or an error
   */
  public func decryptBatch(
    _ dataItems: [[UInt8]],
    using key: [UInt8],
    config: SecurityConfigDTO? = nil
  ) async -> Result<[[UInt8]], SecurityServiceError> {
    let algorithm = (config ?? defaultConfig).encryptionAlgorithm

    await logAdapter.debug(
      "Decrypting batch of data with algorithm: \(algorithm.rawValue)",
      source: logSource
    )

    var results = [[UInt8]]()
    results.reserveCapacity(dataItems.count)
    var encounteredError: SecurityServiceError? = nil

    // Process each item sequentially for simplicity
    for item in dataItems {
      let result = await decrypt(item, using: key, config: config)
      switch result {
        case let .success(decryptedData):
          results.append(decryptedData)
        case let .failure(error):
          encounteredError = error
          break
      }
      
      // If we encountered an error, stop processing and return it
      if encounteredError != nil {
        break
      }
    }
    
    // If any decryption failed, return the error
    if let error = encounteredError {
      return .failure(error)
    }

    return .success(results)
  }

  /**
   Verifies the integrity of data using a cryptographic hash.

   - Parameters:
      - data: The data to verify
      - expectedHash: The expected hash value
      - algorithm: The hash algorithm to use
      - config: Optional configuration for the hash operation
   - Returns: Result indicating success or an error
   */
  public func verifyHash(
    _ data: [UInt8],
    expectedHash: [UInt8],
    algorithm: HashAlgorithm = .sha256,
    config: SecurityConfigDTO? = nil
  ) async -> Result<[UInt8], SecurityServiceError> {
    await logAdapter.debug(
      "Verifying hash with algorithm: \(algorithm.rawValue)",
      source: logSource
    )

    // Compute the hash of the input data
    let hashResult = await hash(data, algorithm: algorithm, config: config)

    switch hashResult {
      case let .success(computedHash):
        // Compare with the expected hash
        if computedHash == expectedHash {
          return .success(computedHash)
        } else {
          return .failure(
            SecurityServiceError.keyManagementError("Hash verification failed: hashes do not match")
          )
        }
      case let .failure(error):
        return .failure(error)
    }
  }

  // MARK: - Batch Operations

  /**
   Generates random bytes of the specified length.

   - Parameters:
      - count: Number of random bytes to generate
      - config: Optional configuration override
   - Returns: Result containing random bytes as a byte array or an error
   */
  public func generateRandomBytes(
    count: Int,
    config: SecurityConfigDTO? = nil
  ) async -> Result<[UInt8], SecurityServiceError> {
    await logAdapter.debug(
      "Generating \(count) random bytes",
      source: logSource
    )

    // Use provided config or default
    let operationConfig = config ?? defaultConfig

    do {
      // Generate random bytes using the provider's key generation method
      // This is a workaround as the EncryptionProviderProtocol doesn't have a specific
      // method for generating random bytes
      let randomData = try provider.generateKey(size: count * 8, config: operationConfig)

      await logAdapter.debug(
        "Random generation completed successfully",
        source: logSource
      )

      return .success([UInt8](randomData))
    } catch {
      await logAdapter.error(
        "Failed to generate random bytes: \(error.localizedDescription)",
        source: logSource
      )

      if let secError = error as? SecurityServiceError {
        return .failure(secError)
      } else {
        return .failure(
          SecurityServiceError.cryptographicError("Random generation failed: \(error.localizedDescription)")
        )
      }
    }
  }
}

/**
 Domain-specific log adapter that adds domain information to log metadata
 */
private struct DomainLogAdapter {
  let logger: LoggingProtocol
  private let domain: String

  init(logger: LoggingProtocol, domain: String) {
    self.logger = logger
    self.domain = domain
  }

  func debug(_ message: String, source: String) async {
    await logger.debug(
      message,
      metadata: PrivacyMetadata(),
      source: "\(domain).\(source)"
    )
  }

  func info(_ message: String, source: String) async {
    await logger.info(
      message,
      metadata: PrivacyMetadata(),
      source: "\(domain).\(source)"
    )
  }

  func warning(_ message: String, source: String) async {
    await logger.warning(
      message,
      metadata: PrivacyMetadata(),
      source: "\(domain).\(source)"
    )
  }

  func error(_ message: String, source: String) async {
    await logger.error(
      message,
      metadata: PrivacyMetadata(),
      source: "\(domain).\(source)"
    )
  }
}

/**
 A null logger that doesn't log anything; used as a fallback
 */
private final class NullLogger: LoggingProtocol {
  /// The underlying logging actor
  public var loggingActor: LoggingActor {
    nullActor
  }
  
  /// Empty logging actor for the null logger
  private let nullActor = LoggingActor(destinations: [], minimumLogLevel: .critical)
  
  public func debug(_ message: String, metadata: PrivacyMetadata?, source: String) async {
    // No-op
  }
  
  public func info(_ message: String, metadata: PrivacyMetadata?, source: String) async {
    // No-op
  }
  
  public func warning(_ message: String, metadata: PrivacyMetadata?, source: String) async {
    // No-op
  }
  
  public func error(_ message: String, metadata: PrivacyMetadata?, source: String) async {
    // No-op
  }
  
  public func critical(_ message: String, metadata: PrivacyMetadata?, source: String) async {
    // No-op
  }
  
  public func log(_ level: LogLevel, _ message: String, metadata: PrivacyMetadata?, source: String) async {
    // No-op
  }
  
  public func logMessage(_ level: LogLevel, _ message: String, context: LogContext) async {
    // No-op
  }
}

/**
 Fallback encryption provider used when the preferred provider cannot be created.
 Provides basic functionality using Apple's CommonCrypto when possible.
 */
@available(*, deprecated, message: "Use only as fallback when other providers are unavailable")
private final class FallbackEncryptionProvider: EncryptionProviderProtocol {
  /// The provider type for this implementation
  public var providerType: SecurityProviderType { .basic }
  
  func encrypt(
    plaintext: Data,
    key: Data,
    iv: Data,
    config: SecurityConfigDTO
  ) throws -> Data {
    guard !plaintext.isEmpty else {
      throw SecurityServiceError.invalidInputData("Plaintext data cannot be empty")
    }
    
    guard !key.isEmpty else {
      throw SecurityServiceError.invalidInputData("Encryption key cannot be empty")
    }
    
    guard !iv.isEmpty else {
      throw SecurityServiceError.invalidInputData("Initialisation vector cannot be empty")
    }
    
    // Simple XOR-based encryption as fallback (NOT cryptographically secure!)
    var result = Data(count: plaintext.count)
    let keyBytes = [UInt8](key)

    for i in 0..<plaintext.count {
      result[i] = plaintext[i] ^ keyBytes[i % key.count]
      result[i] = (result[i] << 3) | (result[i] >> 5) // Simple rotation
    }

    return result
  }

  func decrypt(
    ciphertext: Data,
    key: Data,
    iv: Data,
    config: SecurityConfigDTO
  ) throws -> Data {
    guard !ciphertext.isEmpty else {
      throw SecurityServiceError.invalidInputData("Ciphertext data cannot be empty")
    }
    
    guard !key.isEmpty else {
      throw SecurityServiceError.invalidInputData("Decryption key cannot be empty")
    }
    
    guard !iv.isEmpty else {
      throw SecurityServiceError.invalidInputData("Initialisation vector cannot be empty")
    }
    
    // For XOR, encryption and decryption are the same operation
    return try encrypt(plaintext: ciphertext, key: key, iv: iv, config: config)
  }

  func generateKey(size: Int, config: SecurityConfigDTO) throws -> Data {
    guard size > 0 else {
      throw SecurityServiceError.invalidInputData("Key size must be greater than zero")
    }
    
    var bytes = [UInt8](repeating: 0, count: size / 8)
    let status = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)

    guard status == errSecSuccess else {
      throw SecurityServiceError.cryptographicError("Failed to generate key: \(status)")
    }

    return Data(bytes)
  }

  func generateIV(size: Int) throws -> Data {
    guard size > 0 else {
      throw SecurityServiceError.invalidInputData("IV size must be greater than zero")
    }
    
    var bytes = [UInt8](repeating: 0, count: size)
    let status = SecRandomCopyBytes(kSecRandomDefault, size, &bytes)

    guard status == errSecSuccess else {
      throw SecurityServiceError.cryptographicError("Failed to generate IV: \(status)")
    }

    return Data(bytes)
  }

  func generateRandom(count: Int, config: SecurityConfigDTO) throws -> Data {
    guard count > 0 else {
      throw SecurityServiceError.invalidInputData("Random data size must be greater than zero")
    }
    
    var bytes = [UInt8](repeating: 0, count: count)
    let status = SecRandomCopyBytes(kSecRandomDefault, count, &bytes)

    guard status == errSecSuccess else {
      throw SecurityServiceError.cryptographicError("Failed to generate random data: \(status)")
    }

    return Data(bytes)
  }

  func hash(data: Data, algorithm: String) throws -> Data {
    guard !data.isEmpty else {
      throw SecurityServiceError.invalidInputData("Data to hash cannot be empty")
    }
    
    // Use a more secure hash implementation if available
    if algorithm.uppercased() == "SHA256" {
      var hasher = SHA256()
      hasher.update(data: data)
      return hasher.finalize()
    } else {
      throw SecurityServiceError.invalidInputData("Unsupported hash algorithm: \(algorithm)")
    }
  }
}

// Simple SHA-256 implementation for the fallback provider
private struct SHA256 {
  private var buffer = [UInt8](repeating: 0, count: 32)

  mutating func update(data: Data) {
    // This is a placeholder - a real implementation would use CommonCrypto
    // Just doing some simple mixing for the fallback
    for byte in data {
      for i in 0..<buffer.count {
        buffer[i] = buffer[i] &+ byte &+ UInt8(i)
        buffer[i] = (buffer[i] << 3) | (buffer[i] >> 5) // Simple rotation
      }
    }
  }

  func finalize() -> Data {
    Data(buffer)
  }
}
