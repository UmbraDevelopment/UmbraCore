import Foundation
import LoggingInterfaces
import LoggingTypes
import ProviderFactories
import SecurityCoreInterfaces
import SecurityCoreTypes
import SecurityTypes
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
 let cryptoService = CryptoServiceActor(providerType: .apple, logger: logger)

 // Perform operations asynchronously
 let encryptedData = try await cryptoService.encrypt(data: secureData, using: secureKey)
 ```

 ## Thread Safety

 All methods are automatically thread-safe due to Swift's actor isolation rules.
 Mutable state is properly contained within the actor and cannot be accessed from
 outside except through the defined async interfaces.
 */
public actor CryptoServiceActor {
  // MARK: - Properties

  /// The underlying security provider implementation
  private var provider: EncryptionProviderProtocol

  /// Logger for recording operations
  private let logger: LoggingProtocol
  
  /// Domain-specific logger for cryptographic operations
  private let cryptoLogger: CryptoLogger

  /// Configuration options for cryptographic operations
  private var defaultConfig: SecurityConfigDTO

  // MARK: - Initialisation

  /**
   Initialises a new crypto service actor with the specified provider type.

   - Parameters:
      - providerType: The type of security provider to use
      - logger: Logger for recording operations
   */
  public init(providerType: SecurityProviderType? = nil, logger: LoggingProtocol) {
    self.logger = logger ?? DefaultLogger()
    self.cryptoLogger = CryptoLogger(logger: logger)

    do {
      if let providerType {
        provider = try SecurityProviderFactoryImpl.createProvider(type: providerType)
      } else {
        provider = try SecurityProviderFactoryImpl.createBestAvailableProvider()
      }

      // If the provider successfully initialises, set the default config
      if let providerType {
        defaultConfig = SecurityConfigDTO.aesEncryption(providerType: providerType)
      } else {
        defaultConfig = SecurityConfigDTO.aesEncryption(providerType: .basic)
      }

      Task {
        var context = LogMetadataDTOCollection()
        context.addPublic(key: "provider", value: self.provider.providerType.rawValue)
        context.addPublic(key: "algorithm", value: "AES")
        
        await cryptoLogger.logOperationSuccess(
            operation: "initialize",
            algorithm: "AES",
            additionalContext: context,
            message: "Initialised CryptoServiceActor with provider: \(self.provider.providerType.rawValue)"
        )
      }
    } catch {
      // Fall back to basic provider if there's an issue
      provider = SecurityProviderFactoryImpl.createDefaultProvider()
      defaultConfig = SecurityConfigDTO.aesEncryption(providerType: .basic)

      // Log the error but don't crash
      Task {
        await cryptoLogger.logOperationError(
            operation: "initialize",
            error: error,
            algorithm: "AES",
            additionalContext: {
                var context = LogMetadataDTOCollection()
                context.addPublic(key: "fallback", value: "basic")
                return context
            }(),
            message: "Failed to initialise security provider. Using basic provider instead."
        )
      }
    }
  }

  /**
   Changes the active security provider.

   - Parameter type: The provider type to switch to
   - Returns: True if the provider was successfully changed, false otherwise
   */
  public func setProviderType(_ type: SecurityProviderType) async throws {
    await cryptoLogger.logOperationStart(
        operation: "change_provider",
        additionalContext: {
            var context = LogMetadataDTOCollection()
            context.addPublic(key: "provider", value: type.rawValue)
            return context
        }()
    )
    
    do {
      let newProvider = try SecurityProviderFactoryImpl.createProvider(type: type)
      provider = newProvider
      defaultConfig = SecurityConfigDTO.aesEncryption(providerType: type)
      
      await cryptoLogger.logOperationSuccess(
          operation: "change_provider",
          additionalContext: {
              var context = LogMetadataDTOCollection()
              context.addPublic(key: "provider", value: type.rawValue)
              return context
          }(),
          message: "Security provider changed to: \(type)"
      )
    } catch {
      await cryptoLogger.logOperationError(
          operation: "change_provider",
          error: error,
          additionalContext: {
              var context = LogMetadataDTOCollection()
              context.addPublic(key: "provider", value: type.rawValue)
              return context
          }(),
          message: "Failed to change security provider"
      )
      throw SecurityServiceError.providerError(error.localizedDescription)
    }
  }

  // MARK: - Encryption Operations

  /**
   Encrypts data using the configured provider.

   - Parameters:
      - data: The data to encrypt
      - key: The encryption key
      - config: Optional configuration override
   - Returns: Encrypted data wrapped in SecureBytes
   - Throws: SecurityProtocolError if encryption fails
   */
  public func encrypt(
    data: SecureBytes,
    using key: SecureBytes,
    config: SecurityConfigDTO? = nil
  ) async throws -> SecureBytes {
    let algorithm = (config ?? defaultConfig).algorithm
    
    await cryptoLogger.logOperationStart(
        operation: "encrypt",
        algorithm: algorithm
    )
    
    let dataBytes = data.extractUnderlyingData()
    let keyBytes = key.extractUnderlyingData()

    // Generate IV using the provider
    let iv: Data
    do {
      iv = try provider.generateIV(size: 16)
    } catch {
      await cryptoLogger.logOperationError(
          operation: "generate_iv",
          error: error,
          algorithm: algorithm,
          message: "Failed to generate IV"
      )
      throw SecurityProtocolError
        .cryptographicError("Failed to generate IV: \(error.localizedDescription)")
    }

    // Use provided config or default
    let operationConfig = config ?? defaultConfig

    // Encrypt data
    do {
      let encryptedData = try provider.encrypt(
        plaintext: dataBytes,
        key: keyBytes,
        iv: iv,
        config: operationConfig
      )

      // Prepend IV to encrypted data for later decryption
      var result = Data(capacity: iv.count + encryptedData.count)
      result.append(iv)
      result.append(encryptedData)

      await cryptoLogger.logOperationSuccess(
          operation: "encrypt",
          algorithm: algorithm,
          additionalContext: {
              var context = LogMetadataDTOCollection()
              context.addPublic(key: "dataSize", value: String(dataBytes.count))
              context.addPublic(key: "resultSize", value: String(result.count))
              return context
          }()
      )
      
      return SecureBytes(data: result)
    } catch {
      await cryptoLogger.logOperationError(
          operation: "encrypt",
          error: error,
          algorithm: algorithm,
          additionalContext: {
              var context = LogMetadataDTOCollection()
              context.addPublic(key: "dataSize", value: String(dataBytes.count))
              return context
          }()
      )

      if let secError = error as? SecurityProtocolError {
        throw secError
      } else {
        throw SecurityProtocolError
          .cryptographicError("Encryption failed: \(error.localizedDescription)")
      }
    }
  }

  /**
   Decrypts data using the configured provider.

   - Parameters:
      - data: The data to decrypt (IV + ciphertext)
      - key: The decryption key
      - config: Optional configuration override
   - Returns: Decrypted data wrapped in SecureBytes
   - Throws: SecurityProtocolError if decryption fails
   */
  public func decrypt(
    data: SecureBytes,
    using key: SecureBytes,
    config: SecurityConfigDTO? = nil
  ) async throws -> SecureBytes {
    let algorithm = (config ?? defaultConfig).algorithm
    
    await cryptoLogger.logOperationStart(
        operation: "decrypt",
        algorithm: algorithm
    )
    
    let dataBytes = data.extractUnderlyingData()
    let keyBytes = key.extractUnderlyingData()

    // Validate minimum length (IV + at least some ciphertext)
    guard dataBytes.count > 16 else {
      await cryptoLogger.logOperationError(
          operation: "decrypt",
          error: SecurityProtocolError.invalidInput("Encrypted data too short"),
          algorithm: algorithm,
          additionalContext: {
              var context = LogMetadataDTOCollection()
              context.addPublic(key: "dataSize", value: String(dataBytes.count))
              return context
          }()
      )
      throw SecurityProtocolError.invalidInput("Encrypted data too short, must include IV")
    }

    // Extract IV and ciphertext
    let iv = dataBytes.prefix(16)
    let ciphertext = dataBytes.dropFirst(16)

    // Use provided config or default
    let operationConfig = config ?? defaultConfig

    // Decrypt data
    do {
      let decryptedData = try provider.decrypt(
        ciphertext: ciphertext,
        key: keyBytes,
        iv: Data(iv),
        config: operationConfig
      )

      await cryptoLogger.logOperationSuccess(
          operation: "decrypt",
          algorithm: algorithm,
          additionalContext: {
              var context = LogMetadataDTOCollection()
              context.addPublic(key: "ciphertextSize", value: String(ciphertext.count))
              context.addPublic(key: "plaintextSize", value: String(decryptedData.count))
              return context
          }()
      )
      
      return SecureBytes(data: decryptedData)
    } catch {
      await cryptoLogger.logOperationError(
          operation: "decrypt",
          error: error,
          algorithm: algorithm,
          additionalContext: {
              var context = LogMetadataDTOCollection()
              context.addPublic(key: "ciphertextSize", value: String(ciphertext.count))
              return context
          }()
      )

      if let secError = error as? SecurityProtocolError {
        throw secError
      } else {
        throw SecurityProtocolError
          .cryptographicError("Decryption failed: \(error.localizedDescription)")
      }
    }
  }

  // MARK: - Key Management

  /**
   Generates a cryptographic key of the specified size.

   - Parameters:
      - size: Key size in bits (128, 192, or 256 for AES)
      - config: Optional configuration override
   - Returns: Generated key wrapped in SecureBytes
   - Throws: SecurityProtocolError if key generation fails
   */
  public func generateKey(
    size: Int,
    config: SecurityConfigDTO? = nil
  ) async throws -> SecureBytes {
    let algorithm = (config ?? defaultConfig).algorithm
    
    await cryptoLogger.logOperationStart(
        operation: "generate_key",
        algorithm: algorithm,
        additionalContext: {
            var context = LogMetadataDTOCollection()
            context.addPublic(key: "keySize", value: String(size))
            return context
        }()
    )
    
    // Use provided config or default
    let operationConfig = config ?? defaultConfig

    do {
      let keyData = try provider.generateKey(size: size, config: operationConfig)
      
      await cryptoLogger.logOperationSuccess(
          operation: "generate_key",
          algorithm: algorithm,
          additionalContext: {
              var context = LogMetadataDTOCollection()
              context.addPublic(key: "keySize", value: String(size))
              return context
          }()
      )
      
      return SecureBytes(data: keyData)
    } catch {
      await cryptoLogger.logOperationError(
          operation: "generate_key",
          error: error,
          algorithm: algorithm,
          additionalContext: {
              var context = LogMetadataDTOCollection()
              context.addPublic(key: "keySize", value: String(size))
              return context
          }()
      )

      if let secError = error as? SecurityProtocolError {
        throw secError
      } else {
        throw SecurityProtocolError
          .cryptographicError("Key generation failed: \(error.localizedDescription)")
      }
    }
  }

  /**
   Derives a key from a password using PBKDF2.

   - Parameters:
      - password: The password to derive from
      - salt: Salt to use for derivation
      - iterations: Number of iterations (higher is more secure but slower)
      - keyLength: Desired key length in bytes
      - config: Optional configuration override
   - Returns: Derived key wrapped in SecureBytes
   - Throws: SecurityProtocolError if key derivation fails
   */
  public func deriveKey(
    fromPassword password: String,
    salt: Data,
    iterations: Int = 10000,
    keyLength: Int = 32,
    config: SecurityConfigDTO? = nil
  ) async throws -> SecureBytes {
    let algorithm = "PBKDF2"
    
    await cryptoLogger.logOperationStart(
        operation: "derive_key",
        algorithm: algorithm,
        additionalContext: {
            var context = LogMetadataDTOCollection()
            context.addPublic(key: "iterations", value: String(iterations))
            context.addPublic(key: "keyLength", value: String(keyLength))
            context.addPublic(key: "saltLength", value: String(salt.count))
            return context
        }()
    )
    
    // Use provided config or default
    let operationConfig = config ?? defaultConfig

    do {
      let keyData = try provider.deriveKey(
        fromPassword: password,
        salt: salt,
        iterations: iterations,
        keyLength: keyLength,
        config: operationConfig
      )
      
      await cryptoLogger.logOperationSuccess(
          operation: "derive_key",
          algorithm: algorithm,
          additionalContext: {
              var context = LogMetadataDTOCollection()
              context.addPublic(key: "iterations", value: String(iterations))
              context.addPublic(key: "keyLength", value: String(keyLength))
              return context
          }()
      )
      
      return SecureBytes(data: keyData)
    } catch {
      await cryptoLogger.logOperationError(
          operation: "derive_key",
          error: error,
          algorithm: algorithm,
          additionalContext: {
              var context = LogMetadataDTOCollection()
              context.addPublic(key: "iterations", value: String(iterations))
              context.addPublic(key: "keyLength", value: String(keyLength))
              return context
          }()
      )

      if let secError = error as? SecurityProtocolError {
        throw secError
      } else {
        throw SecurityProtocolError
          .cryptographicError("Key derivation failed: \(error.localizedDescription)")
      }
    }
  }

  // MARK: - Hash Functions

  /**
   Generates a cryptographic hash of data using the specified algorithm.

   - Parameters:
      - data: Data to hash
      - algorithm: Hashing algorithm to use
      - config: Optional configuration override
   - Returns: Hash value as SecureBytes
   - Throws: SecurityProtocolError if hashing fails
   */
  public func hash(
    data: SecureBytes,
    using algorithm: HashAlgorithm = .sha256,
    config: SecurityConfigDTO? = nil
  ) async throws -> SecureBytes {
    await cryptoLogger.logOperationStart(
        operation: "hash",
        algorithm: algorithm.rawValue,
        additionalContext: {
            var context = LogMetadataDTOCollection()
            context.addPublic(key: "dataSize", value: String(data.count))
            return context
        }()
    )
    
    let dataBytes = data.extractUnderlyingData()

    // Use provided config or default
    let operationConfig = config ?? defaultConfig

    do {
      let hashValue = try provider.hash(
        data: dataBytes,
        algorithm: algorithm,
        config: operationConfig
      )
      
      await cryptoLogger.logOperationSuccess(
          operation: "hash",
          algorithm: algorithm.rawValue,
          additionalContext: {
              var context = LogMetadataDTOCollection()
              context.addPublic(key: "dataSize", value: String(data.count))
              context.addPublic(key: "hashSize", value: String(hashValue.count))
              return context
          }()
      )
      
      return SecureBytes(data: hashValue)
    } catch {
      await cryptoLogger.logOperationError(
          operation: "hash",
          error: error,
          algorithm: algorithm.rawValue,
          additionalContext: {
              var context = LogMetadataDTOCollection()
              context.addPublic(key: "dataSize", value: String(data.count))
              return context
          }()
      )

      if let secError = error as? SecurityProtocolError {
        throw secError
      } else {
        throw SecurityProtocolError.cryptographicError("Hashing failed: \(error.localizedDescription)")
      }
    }
  }

  // MARK: - Batch Operations

  /**
   Encrypts multiple data items in parallel using task groups.

   - Parameters:
      - dataItems: Array of data items to encrypt
      - key: The encryption key to use for all items
      - config: Optional configuration override
   - Returns: Array of encrypted data items
   - Throws: SecurityProtocolError if any encryption fails
   */
  public func encryptBatch(
    dataItems: [SecureBytes],
    using key: SecureBytes,
    config: SecurityConfigDTO? = nil
  ) async throws -> [SecureBytes] {
    let algorithm = (config ?? defaultConfig).algorithm
    
    await cryptoLogger.logOperationStart(
        operation: "encrypt_batch",
        algorithm: algorithm,
        additionalContext: {
            var context = LogMetadataDTOCollection()
            context.addPublic(key: "itemCount", value: String(dataItems.count))
            return context
        }()
    )
    
    var results = [SecureBytes]()
    var errorEncountered: Error?

    // Use task groups for parallel processing
    try await withThrowingTaskGroup(of: (Int, Result<SecureBytes, Error>).self) { group in
      // Queue up all encryption tasks
      for (index, data) in dataItems.enumerated() {
        group.addTask {
          do {
            let encrypted = try await self.encrypt(data: data, using: key, config: config)
            return (index, .success(encrypted))
          } catch {
            return (index, .failure(error))
          }
        }
      }

      // Prepare to receive results in order
      results = Array(repeating: SecureBytes(), count: dataItems.count)

      // Process results as they complete
      for try await (index, result) in group {
        switch result {
        case let .success(encrypted):
          results[index] = encrypted
        case let .failure(error):
          errorEncountered = error
          group.cancelAll() // Cancel remaining tasks on first error
          break
        }
      }
    }

    if let error = errorEncountered {
      await cryptoLogger.logOperationError(
          operation: "encrypt_batch",
          error: error,
          algorithm: algorithm,
          additionalContext: {
              var context = LogMetadataDTOCollection()
              context.addPublic(key: "itemCount", value: String(dataItems.count))
              return context
          }()
      )
      throw error
    }

    await cryptoLogger.logOperationSuccess(
        operation: "encrypt_batch",
        algorithm: algorithm,
        additionalContext: {
            var context = LogMetadataDTOCollection()
            context.addPublic(key: "itemCount", value: String(dataItems.count))
            context.addPublic(key: "successCount", value: String(results.count))
            return context
        }()
    )
    
    return results
  }

  /**
   Decrypts multiple data items in parallel using task groups.

   - Parameters:
      - dataItems: Array of encrypted data items to decrypt
      - key: The decryption key to use for all items
      - config: Optional configuration override
   - Returns: Array of decrypted data items
   - Throws: SecurityProtocolError if any decryption fails
   */
  public func decryptBatch(
    dataItems: [SecureBytes],
    using key: SecureBytes,
    config: SecurityConfigDTO? = nil
  ) async throws -> [SecureBytes] {
    let algorithm = (config ?? defaultConfig).algorithm
    
    await cryptoLogger.logOperationStart(
        operation: "decrypt_batch",
        algorithm: algorithm,
        additionalContext: {
            var context = LogMetadataDTOCollection()
            context.addPublic(key: "itemCount", value: String(dataItems.count))
            return context
        }()
    )
    
    var results = [SecureBytes]()
    var errorEncountered: Error?

    // Use task groups for parallel processing
    try await withThrowingTaskGroup(of: (Int, Result<SecureBytes, Error>).self) { group in
      // Queue up all decryption tasks
      for (index, data) in dataItems.enumerated() {
        group.addTask {
          do {
            let decrypted = try await self.decrypt(data: data, using: key, config: config)
            return (index, .success(decrypted))
          } catch {
            return (index, .failure(error))
          }
        }
      }

      // Prepare to receive results in order
      results = Array(repeating: SecureBytes(), count: dataItems.count)

      // Process results as they complete
      for try await (index, result) in group {
        switch result {
        case let .success(decrypted):
          results[index] = decrypted
        case let .failure(error):
          errorEncountered = error
          group.cancelAll() // Cancel remaining tasks on first error
          break
        }
      }
    }

    if let error = errorEncountered {
      await cryptoLogger.logOperationError(
          operation: "decrypt_batch",
          error: error,
          algorithm: algorithm,
          additionalContext: {
              var context = LogMetadataDTOCollection()
              context.addPublic(key: "itemCount", value: String(dataItems.count))
              return context
          }()
      )
      throw error
    }

    await cryptoLogger.logOperationSuccess(
        operation: "decrypt_batch",
        algorithm: algorithm,
        additionalContext: {
            var context = LogMetadataDTOCollection()
            context.addPublic(key: "itemCount", value: String(dataItems.count))
            context.addPublic(key: "successCount", value: String(results.count))
            return context
        }()
    )
    
    return results
  }
}
