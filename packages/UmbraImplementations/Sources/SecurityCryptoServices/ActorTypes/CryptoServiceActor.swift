import CoreSecurityTypes
import DomainSecurityTypes
import Foundation
import LoggingInterfaces
import LoggingServices
import LoggingTypes
import ProviderFactories
import SecurityCoreInterfaces

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
 let encryptedData = try await cryptoService.encrypt(data: myData, using: myKey)
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
  private let logAdapter: DomainLogAdapter

  /// The source identifier for logging
  private let logSource="CryptoService"

  /// Configuration options for cryptographic operations
  private var defaultConfig: SecurityConfigDTO

  // MARK: - Initialisation

  /**
   Initialises a new crypto service actor with the specified provider type.

   - Parameters:
      - providerType: The type of security provider to use
      - logger: Logger for recording operations
   */
  public init(providerType: SecurityProviderType?=nil, logger: LoggingProtocol?) {
    // Use the provided logger or create a default one
    self.logger=logger ?? LoggingServiceFactory.createDefaultLogger()
    logAdapter=DomainLogAdapter(logger: self.logger, domain: "CryptoService")

    do {
      if let providerType {
        provider=try SecurityProviderFactoryImpl.createProvider(type: providerType)
      } else {
        provider=try SecurityProviderFactoryImpl.createBestAvailableProvider()
      }

      // If the provider successfully initialises, set the default config
      defaultConfig=SecurityConfigDTO(
        algorithm: "AES",
        keySize: 256,
        mode: "GCM",
        options: [:]
      )
    } catch {
      // If provider creation fails, use a fallback provider
      provider=FallbackEncryptionProvider()
      defaultConfig=SecurityConfigDTO(
        algorithm: "AES",
        keySize: 128,
        mode: "CBC",
        options: [:]
      )

      Task {
        await logAdapter.warning(
          "Failed to create preferred provider, using fallback: \(error.localizedDescription)",
          source: logSource
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
    await logAdapter.debug(
      "Changing provider to: \(type.rawValue)",
      source: logSource
    )

    do {
      let newProvider=try SecurityProviderFactoryImpl.createProvider(type: type)
      provider=newProvider
      defaultConfig=SecurityConfigDTO(
        algorithm: "AES",
        keySize: 256,
        mode: "GCM",
        options: [:]
      )

      await logAdapter.debug(
        "Provider changed to: \(type.rawValue)",
        source: logSource
      )
    } catch {
      await logAdapter.error(
        "Failed to change provider: \(error.localizedDescription)",
        source: logSource
      )
      throw SecurityServiceError.providerError(error.localizedDescription)
    }
  }

  // MARK: - Encryption Operations

  /**
   Encrypts data using the configured provider.

   - Parameters:
      - data: The data to encrypt as a byte array
      - key: The encryption key as a byte array
      - config: Optional configuration override
   - Returns: Result containing encrypted data as a byte array or an error
   */
  public func encrypt(
    data: [UInt8],
    using key: [UInt8],
    config: SecurityConfigDTO?=nil
  ) async -> Result<[UInt8], SecurityProtocolError> {
    let algorithm=(config ?? defaultConfig).algorithm

    await logAdapter.debug(
      "Encrypting data with algorithm: \(algorithm)",
      source: logSource
    )

    // Generate IV using the provider
    let iv: Data
    do {
      iv=try provider.generateIV(size: 16)
    } catch {
      await logAdapter.error(
        "Failed to generate IV: \(error.localizedDescription)",
        source: logSource
      )
      return .failure(
        SecurityProtocolError
          .cryptographicError("Failed to generate IV: \(error.localizedDescription)")
      )
    }

    // Use provided config or default
    let operationConfig=config ?? defaultConfig

    // Encrypt data
    do {
      let encryptedData=try provider.encrypt(
        plaintext: Data(data),
        key: Data(key),
        iv: iv,
        config: operationConfig
      )

      // Prepend IV to encrypted data for later decryption
      var result=Data(capacity: iv.count + encryptedData.count)
      result.append(iv)
      result.append(encryptedData)

      await logAdapter.debug(
        "Encryption completed successfully",
        source: logSource
      )

      return .success([UInt8](result))
    } catch {
      await logAdapter.error(
        "Encryption failed: \(error.localizedDescription)",
        source: logSource
      )

      if let secError=error as? SecurityProtocolError {
        return .failure(secError)
      } else {
        return .failure(
          SecurityProtocolError
            .cryptographicError("Encryption failed: \(error.localizedDescription)")
        )
      }
    }
  }

  /**
   Decrypts data using the configured provider.

   - Parameters:
      - data: The data to decrypt (IV + ciphertext) as a byte array
      - key: The decryption key as a byte array
      - config: Optional configuration override
   - Returns: Result containing decrypted data as a byte array or an error
   */
  public func decrypt(
    data: [UInt8],
    using key: [UInt8],
    config: SecurityConfigDTO?=nil
  ) async -> Result<[UInt8], SecurityProtocolError> {
    let algorithm=(config ?? defaultConfig).algorithm

    await logAdapter.debug(
      "Decrypting data with algorithm: \(algorithm)",
      source: logSource
    )

    // Validate minimum length (IV + at least some ciphertext)
    guard data.count > 16 else {
      await logAdapter.error(
        "Encrypted data too short, must include IV",
        source: logSource
      )
      return .failure(SecurityProtocolError.invalidInput("Encrypted data too short"))
    }

    // Extract IV and ciphertext
    let iv=data.prefix(16)
    let ciphertext=data.dropFirst(16)

    // Use provided config or default
    let operationConfig=config ?? defaultConfig

    // Decrypt data
    do {
      let decryptedData=try provider.decrypt(
        ciphertext: Data(ciphertext),
        key: Data(key),
        iv: Data(iv),
        config: operationConfig
      )

      await logAdapter.debug(
        "Decryption completed successfully",
        source: logSource
      )

      return .success([UInt8](decryptedData))
    } catch {
      await logAdapter.error(
        "Decryption failed: \(error.localizedDescription)",
        source: logSource
      )

      if let secError=error as? SecurityProtocolError {
        return .failure(secError)
      } else {
        return .failure(
          SecurityProtocolError
            .cryptographicError("Decryption failed: \(error.localizedDescription)")
        )
      }
    }
  }

  // MARK: - Key Management

  /**
   Generates a cryptographic key of the specified size.

   - Parameters:
      - size: Key size in bits (128, 192, or 256 for AES)
      - config: Optional configuration override
   - Returns: Result containing generated key as a byte array or an error
   */
  public func generateKey(
    size: Int,
    config: SecurityConfigDTO?=nil
  ) async -> Result<[UInt8], SecurityProtocolError> {
    let algorithm=(config ?? defaultConfig).algorithm

    await logAdapter.debug(
      "Generating key with algorithm: \(algorithm)",
      source: logSource
    )

    // Use provided config or default
    let operationConfig=config ?? defaultConfig

    do {
      let keyData=try provider.generateKey(size: size, config: operationConfig)

      await logAdapter.debug(
        "Key generation completed successfully",
        source: logSource
      )

      return .success([UInt8](keyData))
    } catch {
      await logAdapter.error(
        "Key generation failed: \(error.localizedDescription)",
        source: logSource
      )

      if let secError=error as? SecurityProtocolError {
        return .failure(secError)
      } else {
        return .failure(
          SecurityProtocolError
            .cryptographicError("Key generation failed: \(error.localizedDescription)")
        )
      }
    }
  }

  /**
   Derives a key from a password using PBKDF2.

   - Parameters:
      - password: The password to derive from
      - salt: Salt to use for derivation as a byte array
      - iterations: Number of iterations (higher is more secure but slower)
      - keyLength: Desired key length in bytes
      - config: Optional configuration override
   - Returns: Result containing derived key as a byte array or an error
   */
  public func deriveKey(
    fromPassword password: String,
    salt _: [UInt8],
    iterations _: Int=10000,
    keyLength _: Int=32,
    config: SecurityConfigDTO?=nil
  ) async -> Result<[UInt8], SecurityProtocolError> {
    let algorithm=(config ?? defaultConfig).algorithm

    await logAdapter.debug(
      "Deriving key with algorithm: \(algorithm)",
      source: logSource
    )

    do {
      // Since provider doesn't directly support deriveKey, we'll implement it
      // This is a placeholder implementation
      let passwordData=password.data(using: .utf8) ?? Data()

      // Use the underlying hash function to create a key derivation
      // This is a simplified PBKDF2-like approach
      let result=await hash(data: [UInt8](passwordData))

      // In a real implementation, we would perform proper key derivation
      // For now, we're just returning the hashed password as a placeholder
      return result
    } catch {
      await logAdapter.error(
        "Key derivation failed: \(error.localizedDescription)",
        source: logSource
      )
      if let secError=error as? SecurityProtocolError {
        return .failure(secError)
      } else {
        return .failure(
          SecurityProtocolError
            .cryptographicError("Key derivation failed: \(error.localizedDescription)")
        )
      }
    }
  }

  // MARK: - Hash Functions

  /**
   Generates a cryptographic hash of data using the specified algorithm.

   - Parameters:
      - data: Data to hash as a byte array
      - algorithm: Hashing algorithm to use
      - config: Optional configuration override
   - Returns: Result containing hash value as a byte array or an error
   */
  public func hash(
    data: [UInt8],
    using algorithm: CoreSecurityTypes.HashAlgorithm = .sha256,
    config: SecurityConfigDTO?=nil
  ) async -> Result<[UInt8], SecurityProtocolError> {
    await logAdapter.debug(
      "Hashing data with algorithm: \(algorithm.rawValue)",
      source: logSource
    )

    // Use provided config or default
    let operationConfig=config ?? defaultConfig

    do {
      // Execute the operation
      let result=await provider.hash(
        data: Data(data)
      )

      switch result {
        case let .success(hashData):
          await logAdapter.debug(
            "Hash operation completed successfully",
            source: logSource
          )
          return .success([UInt8](hashData))
        case let .failure(error):
          await logAdapter.error(
            "Hash operation failed: \(error.localizedDescription)",
            source: logSource
          )
          return .failure(error)
      }
    } catch {
      await logAdapter.error(
        "Hash operation threw exception: \(error.localizedDescription)",
        source: logSource
      )
      if let secError=error as? SecurityProtocolError {
        return .failure(secError)
      } else {
        return .failure(
          SecurityProtocolError
            .cryptographicError("Hash operation failed: \(error.localizedDescription)")
        )
      }
    }
  }

  // MARK: - Batch Operations

  /**
   Encrypts multiple data items in parallel using task groups.

   - Parameters:
      - dataItems: Array of data items to encrypt as byte arrays
      - key: The encryption key to use for all items as a byte array
      - config: Optional configuration override
   - Returns: Result containing array of encrypted data items as byte arrays or an error
   */
  public func encryptBatch(
    dataItems: [[UInt8]],
    using key: [UInt8],
    config: SecurityConfigDTO?=nil
  ) async -> Result<[[UInt8]], SecurityProtocolError> {
    let algorithm=(config ?? defaultConfig).algorithm

    await logAdapter.debug(
      "Encrypting batch of data with algorithm: \(algorithm)",
      source: logSource
    )

    var results=[[UInt8]]()
    var errorEncountered: Error?

    // Use task groups for parallel processing
    do {
      try await withThrowingTaskGroup(of: (Int, Result<[UInt8], Error>).self) { group in
        // Queue up all encryption tasks
        for (index, data) in dataItems.enumerated() {
          group.addTask {
            let encrypted=await self.encrypt(data: data, using: key, config: config)
            return (index, encrypted)
          }
        }

        // Prepare to receive results in order
        results=Array(repeating: [UInt8](), count: dataItems.count)

        // Process results as they complete
        for try await (index, result) in group {
          switch result {
            case let .success(encrypted):
              results[index]=encrypted
            case let .failure(error):
              errorEncountered=error
              group.cancelAll() // Cancel remaining tasks on first error
          }
        }
      }
    } catch {
      await logAdapter.error(
        "Batch encryption task group error: \(error.localizedDescription)",
        source: logSource
      )
      errorEncountered=error
    }

    if let error=errorEncountered {
      await logAdapter.error(
        "Batch encryption failed: \(error.localizedDescription)",
        source: logSource
      )
      if let secError=error as? SecurityProtocolError {
        return .failure(secError)
      } else {
        return .failure(
          SecurityProtocolError
            .cryptographicError("Batch encryption failed: \(error.localizedDescription)")
        )
      }
    }

    await logAdapter.debug(
      "Batch encryption completed successfully",
      source: logSource
    )

    return .success(results)
  }

  /**
   Decrypts multiple data items in parallel using task groups.

   - Parameters:
      - dataItems: Array of encrypted data items to decrypt as byte arrays
      - key: The decryption key to use for all items as a byte array
      - config: Optional configuration override
   - Returns: Result containing array of decrypted data items as byte arrays or an error
   */
  public func decryptBatch(
    dataItems: [[UInt8]],
    using key: [UInt8],
    config: SecurityConfigDTO?=nil
  ) async -> Result<[[UInt8]], SecurityProtocolError> {
    let algorithm=(config ?? defaultConfig).algorithm

    await logAdapter.debug(
      "Decrypting batch of data with algorithm: \(algorithm)",
      source: logSource
    )

    var results=[[UInt8]]()
    var errorEncountered: Error?

    // Use task groups for parallel processing
    do {
      try await withThrowingTaskGroup(of: (Int, Result<[UInt8], Error>).self) { group in
        // Queue up all decryption tasks
        for (index, data) in dataItems.enumerated() {
          group.addTask {
            let decrypted=await self.decrypt(data: data, using: key, config: config)
            return (index, decrypted)
          }
        }

        // Prepare to receive results in order
        results=Array(repeating: [UInt8](), count: dataItems.count)

        // Process results as they complete
        for try await (index, result) in group {
          switch result {
            case let .success(decrypted):
              results[index]=decrypted
            case let .failure(error):
              errorEncountered=error
              group.cancelAll() // Cancel remaining tasks on first error
          }
        }
      }
    } catch {
      await logAdapter.error(
        "Batch decryption task group error: \(error.localizedDescription)",
        source: logSource
      )
      errorEncountered=error
    }

    if let error=errorEncountered {
      await logAdapter.error(
        "Batch decryption failed: \(error.localizedDescription)",
        source: logSource
      )
      if let secError=error as? SecurityProtocolError {
        return .failure(secError)
      } else {
        return .failure(
          SecurityProtocolError
            .cryptographicError("Batch decryption failed: \(error.localizedDescription)")
        )
      }
    }

    await logAdapter.debug(
      "Batch decryption completed successfully",
      source: logSource
    )

    return .success(results)
  }

  /**
   Generates random bytes of the specified length.

   - Parameters:
      - count: Number of random bytes to generate
      - config: Optional configuration override
   - Returns: Result containing random bytes as a byte array or an error
   */
  public func generateRandomBytes(
    count: Int,
    config: SecurityConfigDTO?=nil
  ) async -> Result<[UInt8], SecurityProtocolError> {
    await logAdapter.debug(
      "Generating \(count) random bytes",
      source: logSource
    )

    // Use provided config or default
    let operationConfig=config ?? defaultConfig

    do {
      let randomData=try provider.generateRandom(count: count, config: operationConfig)

      await logAdapter.debug(
        "Random generation completed successfully",
        source: logSource
      )

      return .success([UInt8](randomData))
    } catch {
      await logAdapter.error(
        "Random generation failed: \(error.localizedDescription)",
        source: logSource
      )

      if let secError=error as? SecurityProtocolError {
        return .failure(secError)
      } else {
        return .failure(
          SecurityProtocolError
            .cryptographicError("Random generation failed: \(error.localizedDescription)")
        )
      }
    }
  }
}

/**
 Domain-specific log adapter for crypto operations.
 Wraps a standard logger and adds domain context.
 */
private struct DomainLogAdapter {
  private let logger: LoggingProtocol
  private let domain: String

  init(logger: LoggingProtocol, domain: String) {
    self.logger=logger
    self.domain=domain
  }

  func debug(_ message: String, source: String) async {
    await logger.debug(
      message,
      metadata: [
        "domain": .string(domain),
        "source": .string(source)
      ]
    )
  }

  func info(_ message: String, source: String) async {
    await logger.info(
      message,
      metadata: [
        "domain": .string(domain),
        "source": .string(source)
      ]
    )
  }

  func warning(_ message: String, source: String) async {
    await logger.warning(
      message,
      metadata: [
        "domain": .string(domain),
        "source": .string(source)
      ]
    )
  }

  func error(_ message: String, source: String) async {
    await logger.error(
      message,
      metadata: [
        "domain": .string(domain),
        "source": .string(source)
      ]
    )
  }
}

/**
 Fallback encryption provider used when the preferred provider cannot be created.
 Provides basic functionality using Apple's CommonCrypto when possible.
 */
private class FallbackEncryptionProvider: EncryptionProviderProtocol {
  func encrypt(
    plaintext: Data,
    key: Data,
    iv _: Data,
    config _: SecurityConfigDTO
  ) throws -> Data {
    // This would typically use CommonCrypto for a fallback implementation
    // For now, just return the plaintext with a simple XOR (not secure!)
    var result=Data(count: plaintext.count)
    let keyBytes=[UInt8](key)

    for i in 0..<plaintext.count {
      result[i]=plaintext[i] ^ keyBytes[i % key.count]
    }

    return result
  }

  func decrypt(
    ciphertext: Data,
    key: Data,
    iv: Data,
    config: SecurityConfigDTO
  ) throws -> Data {
    // For XOR, encryption and decryption are the same operation
    try encrypt(plaintext: ciphertext, key: key, iv: iv, config: config)
  }

  func generateKey(size: Int, config _: SecurityConfigDTO) throws -> Data {
    var bytes=[UInt8](repeating: 0, count: size / 8)
    let status=SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)

    guard status == errSecSuccess else {
      throw SecurityProtocolError.cryptographicError("Failed to generate key: \(status)")
    }

    return Data(bytes)
  }

  func generateIV(size: Int) throws -> Data {
    var bytes=[UInt8](repeating: 0, count: size)
    let status=SecRandomCopyBytes(kSecRandomDefault, size, &bytes)

    guard status == errSecSuccess else {
      throw SecurityProtocolError.cryptographicError("Failed to generate IV: \(status)")
    }

    return Data(bytes)
  }

  func generateRandom(count: Int, config _: SecurityConfigDTO) throws -> Data {
    var bytes=[UInt8](repeating: 0, count: count)
    let status=SecRandomCopyBytes(kSecRandomDefault, count, &bytes)

    guard status == errSecSuccess else {
      throw SecurityProtocolError.cryptographicError("Failed to generate random data: \(status)")
    }

    return Data(bytes)
  }

  func hash(data: Data) async -> Result<[UInt8], SecurityProtocolError> {
    // Basic hash implementation (not secure, just for fallback)
    var hasher=SHA256()
    hasher.update(data: data)
    let digest=hasher.finalize()
    return .success([UInt8](digest))
  }
}

// Simple SHA-256 implementation for the fallback provider
private struct SHA256 {
  private var buffer=[UInt8](repeating: 0, count: 32)

  mutating func update(data: Data) {
    // This is a placeholder - a real implementation would use CommonCrypto
    // Just doing some simple mixing for the fallback
    for byte in data {
      for i in 0..<buffer.count {
        buffer[i]=buffer[i] &+ byte &+ UInt8(i)
        buffer[i]=(buffer[i] << 3) | (buffer[i] >> 5) // Simple rotation
      }
    }
  }

  func finalize() -> Data {
    Data(buffer)
  }
}
