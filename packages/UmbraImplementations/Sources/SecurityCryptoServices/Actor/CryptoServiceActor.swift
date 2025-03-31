import CoreSecurityTypes
import DomainSecurityTypes
import Foundation
import LoggingInterfaces
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

  /// Configuration options for cryptographic operations
  private var defaultConfig: SecurityConfigDTO

  // MARK: - Initialisation

  /**
   Initialises a new crypto service actor with the specified provider type.

   - Parameters:
      - providerType: The type of security provider to use
      - logger: Logger for recording operations
   */
  public init(providerType: SecurityProviderType?=nil, logger: LoggingProtocol) {
    self.logger=logger

    // Create provider based on specified type or best available
    do {
      if let providerType {
        provider=try SecurityProviderFactory.createProvider(type: providerType)
      } else {
        provider=try SecurityProviderFactory.createBestAvailableProvider()
      }

      // Create default configuration for this provider
      defaultConfig=SecurityConfigDTO.aesEncryption(providerType: provider.providerType)

      Task {
        await logger.info(
          "Initialised CryptoServiceActor with provider: \(self.provider.providerType.rawValue)",
          metadata: nil
        )
      }
    } catch {
      // Fall back to basic provider if there's an issue
      provider=SecurityProviderFactory.createDefaultProvider()
      defaultConfig=SecurityConfigDTO.aesEncryption(providerType: .basic)

      Task {
        await logger.warning(
          "Failed to create requested provider, falling back to basic provider: \(error.localizedDescription)",
          metadata: nil
        )
      }
    }
  }

  /**
   Changes the active security provider.

   - Parameter type: The provider type to switch to
   - Returns: True if the provider was successfully changed, false otherwise
   */
  public func setProvider(_ type: SecurityProviderType) -> Bool {
    do {
      let newProvider=try SecurityProviderFactory.createProvider(type: type)
      provider=newProvider
      defaultConfig=SecurityConfigDTO.aesEncryption(providerType: type)

      Task {
        await logger.info("Changed security provider to: \(type.rawValue)", metadata: nil)
      }
      return true
    } catch {
      Task {
        await logger.error(
          "Failed to change security provider: \(error.localizedDescription)",
          metadata: nil
        )
      }
      return false
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
    config: SecurityConfigDTO?=nil
  ) async throws -> SecureBytes {
    let dataBytes=data.extractUnderlyingData()
    let keyBytes=key.extractUnderlyingData()

    // Generate IV using the provider
    let iv: Data
    do {
      iv=try provider.generateIV(size: 16)
    } catch {
      await logger.error("Failed to generate IV: \(error.localizedDescription)", metadata: nil)
      throw SecurityProtocolError
        .cryptographicError("Failed to generate IV: \(error.localizedDescription)")
    }

    // Use provided config or default
    let operationConfig=config ?? defaultConfig

    // Encrypt data
    do {
      let encryptedData=try provider.encrypt(
        plaintext: dataBytes,
        key: keyBytes,
        iv: iv,
        config: operationConfig
      )

      // Prepend IV to encrypted data for later decryption
      var result=Data(capacity: iv.count + encryptedData.count)
      result.append(iv)
      result.append(encryptedData)

      return SecureBytes(data: result)
    } catch {
      await logger.error("Encryption failed: \(error.localizedDescription)", metadata: nil)

      if let secError=error as? SecurityProtocolError {
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
    config: SecurityConfigDTO?=nil
  ) async throws -> SecureBytes {
    let dataBytes=data.extractUnderlyingData()
    let keyBytes=key.extractUnderlyingData()

    // Validate minimum length (IV + at least some ciphertext)
    guard dataBytes.count > 16 else {
      await logger.error("Encrypted data too short, must include IV", metadata: nil)
      throw SecurityProtocolError.invalidInput("Encrypted data too short, must include IV")
    }

    // Extract IV and ciphertext
    let iv=dataBytes.prefix(16)
    let ciphertext=dataBytes.dropFirst(16)

    // Use provided config or default
    let operationConfig=config ?? defaultConfig

    // Decrypt data
    do {
      let decryptedData=try provider.decrypt(
        ciphertext: ciphertext,
        key: keyBytes,
        iv: Data(iv),
        config: operationConfig
      )

      return SecureBytes(data: decryptedData)
    } catch {
      await logger.error("Decryption failed: \(error.localizedDescription)", metadata: nil)

      if let secError=error as? SecurityProtocolError {
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
    config: SecurityConfigDTO?=nil
  ) async throws -> SecureBytes {
    // Use provided config or default
    let operationConfig=config ?? defaultConfig

    do {
      let keyData=try provider.generateKey(size: size, config: operationConfig)
      return SecureBytes(data: keyData)
    } catch {
      await logger.error("Key generation failed: \(error.localizedDescription)", metadata: nil)

      if let secError=error as? SecurityProtocolError {
        throw secError
      } else {
        throw SecurityProtocolError
          .cryptographicError("Key generation failed: \(error.localizedDescription)")
      }
    }
  }

  // MARK: - Hashing Operations

  /**
   Creates a cryptographic hash of the input data.

   - Parameters:
      - data: The data to hash
      - algorithm: Hash algorithm to use (SHA256, SHA384, SHA512)
   - Returns: Hash value wrapped in SecureBytes
   - Throws: SecurityProtocolError if hashing fails
   */
  public func hash(
    data: SecureBytes,
    algorithm: String="SHA256"
  ) async throws -> SecureBytes {
    let dataBytes=data.extractUnderlyingData()

    do {
      let hashData=try provider.hash(data: dataBytes, algorithm: algorithm)
      return SecureBytes(data: hashData)
    } catch {
      await logger.error("Hashing failed: \(error.localizedDescription)", metadata: nil)

      if let secError=error as? SecurityProtocolError {
        throw secError
      } else {
        throw SecurityProtocolError
          .cryptographicError("Hashing failed: \(error.localizedDescription)")
      }
    }
  }

  /**
   Verifies that a hash matches the expected value.

   - Parameters:
      - hash: The hash to verify
      - expected: The expected hash value
   - Returns: True if the hashes match, false otherwise
   */
  public func verifyHash(_ hash: SecureBytes, matches expected: SecureBytes) -> Bool {
    hash == expected
  }

  // MARK: - Parallel Processing

  /**
   Encrypts multiple data items in parallel using task groups.

   - Parameters:
      - dataItems: Array of data items to encrypt
      - key: The encryption key to use for all items
      - config: Optional configuration override
   - Returns: Array of encrypted data items in the same order
   - Throws: SecurityProtocolError if any encryption operation fails
   */
  public func encryptBatch(
    dataItems: [SecureBytes],
    using key: SecureBytes,
    config: SecurityConfigDTO?=nil
  ) async throws -> [SecureBytes] {
    try await withThrowingTaskGroup(of: (Int, SecureBytes).self) { group in
      // Add each encryption task to the group
      for (index, data) in dataItems.enumerated() {
        group.addTask {
          let encryptedData=try await self.encrypt(data: data, using: key, config: config)
          return (index, encryptedData)
        }
      }

      // Collect results and maintain original order
      var results=[(Int, SecureBytes)]()
      for try await result in group {
        results.append(result)
      }

      return results.sorted { $0.0 < $1.0 }.map(\.1)
    }
  }

  /**
   Decrypts multiple data items in parallel using task groups.

   - Parameters:
      - dataItems: Array of encrypted data items to decrypt
      - key: The decryption key to use for all items
      - config: Optional configuration override
   - Returns: Array of decrypted data items in the same order
   - Throws: SecurityProtocolError if any decryption operation fails
   */
  public func decryptBatch(
    dataItems: [SecureBytes],
    using key: SecureBytes,
    config: SecurityConfigDTO?=nil
  ) async throws -> [SecureBytes] {
    try await withThrowingTaskGroup(of: (Int, SecureBytes).self) { group in
      // Add each decryption task to the group
      for (index, data) in dataItems.enumerated() {
        group.addTask {
          let decryptedData=try await self.decrypt(data: data, using: key, config: config)
          return (index, decryptedData)
        }
      }

      // Collect results and maintain original order
      var results=[(Int, SecureBytes)]()
      for try await result in group {
        results.append(result)
      }

      return results.sorted { $0.0 < $1.0 }.map(\.1)
    }
  }
}
