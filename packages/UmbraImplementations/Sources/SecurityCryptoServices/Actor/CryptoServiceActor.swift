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
   - Returns: Encrypted data as a byte array
   - Throws: SecurityProtocolError if encryption fails
   */
  public func encrypt(
    data: [UInt8],
    using key: [UInt8],
    config: SecurityConfigDTO?=nil
  ) async throws -> [UInt8] {
    let dataBytes=Data(data)
    let keyBytes=Data(key)

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

      return [UInt8](result)
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
   - Returns: Decrypted data as a byte array
   - Throws: SecurityProtocolError if decryption fails
   */
  public func decrypt(
    data: [UInt8],
    using key: [UInt8],
    config: SecurityConfigDTO?=nil
  ) async throws -> [UInt8] {
    let dataBytes=Data(data)
    let keyBytes=Data(key)

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
        iv: iv,
        config: operationConfig
      )

      return [UInt8](decryptedData)
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

  /**
   Generates a cryptographic key of the specified strength.

   - Parameters:
      - bitLength: The key length in bits
      - config: Optional configuration override
   - Returns: Generated key as a byte array
   - Throws: SecurityProtocolError if key generation fails
   */
  public func generateKey(
    bitLength: Int=256,
    config: SecurityConfigDTO?=nil
  ) async throws -> [UInt8] {
    // Calculate byte length from bit length
    let byteLength=(bitLength + 7) / 8

    // Use provided config or default
    let operationConfig=config ?? defaultConfig

    do {
      let keyData=try provider.generateKey(size: byteLength, config: operationConfig)
      return [UInt8](keyData)
    } catch {
      await logger.error(
        "Key generation failed: \(error.localizedDescription)",
        metadata: nil
      )

      if let secError=error as? SecurityProtocolError {
        throw secError
      } else {
        throw SecurityProtocolError
          .cryptographicError("Key generation failed: \(error.localizedDescription)")
      }
    }
  }

  /**
   Computes a cryptographic hash of the provided data.

   - Parameters:
      - data: Data to hash
      - algorithm: Hash algorithm to use
   - Returns: Hash value as a byte array
   - Throws: SecurityProtocolError if hashing fails
   */
  public func hash(
    data: [UInt8],
    algorithm: HashAlgorithm = .sha256
  ) async throws -> [UInt8] {
    do {
      let hashData=try provider.hash(data: Data(data), algorithm: algorithm)
      return [UInt8](hashData)
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
   Verifies that a hash matches the expected value using constant-time comparison.

   - Parameters:
      - hash: The hash to verify
      - expected: The expected hash value
   - Returns: True if the hashes match, false otherwise
   */
  public func verifyHash(_ hash: [UInt8], matches expected: [UInt8]) -> Bool {
    // Using secure comparison to prevent timing attacks
    guard hash.count == expected.count else {
      return false
    }

    var result: UInt8=0
    for i in 0..<hash.count {
      result |= hash[i] ^ expected[i]
    }
    return result == 0
  }

  /**
   Encrypts multiple data items in parallel using task groups.

   - Parameters:
      - dataItems: Array of data items to encrypt
      - key: The encryption key
      - config: Optional configuration override
   - Returns: Array of encrypted data items
   - Throws: SecurityProtocolError if encryption fails
   */
  public func encryptBatch(
    dataItems: [[UInt8]],
    using key: [UInt8],
    config: SecurityConfigDTO?=nil
  ) async throws -> [[UInt8]] {
    try await withThrowingTaskGroup(of: (Int, [UInt8]).self) { group in
      // Add tasks for each item
      for (index, item) in dataItems.enumerated() {
        group.addTask {
          let encrypted=try await self.encrypt(data: item, using: key, config: config)
          return (index, encrypted)
        }
      }

      // Collect results maintaining original order
      var results=[(Int, [UInt8])]()
      for try await result in group {
        results.append(result)
      }

      // Sort by original index and return just the encrypted data
      return results.sorted(by: { $0.0 < $1.0 }).map(\.1)
    }
  }

  /**
   Decrypts multiple data items in parallel using task groups.

   - Parameters:
      - dataItems: Array of encrypted data items to decrypt
      - key: The decryption key
      - config: Optional configuration override
   - Returns: Array of decrypted data items
   - Throws: SecurityProtocolError if decryption fails
   */
  public func decryptBatch(
    dataItems: [[UInt8]],
    using key: [UInt8],
    config: SecurityConfigDTO?=nil
  ) async throws -> [[UInt8]] {
    try await withThrowingTaskGroup(of: (Int, [UInt8]).self) { group in
      // Add tasks for each item
      for (index, item) in dataItems.enumerated() {
        group.addTask {
          let decrypted=try await self.decrypt(data: item, using: key, config: config)
          return (index, decrypted)
        }
      }

      // Collect results maintaining original order
      var results=[(Int, [UInt8])]()
      for try await result in group {
        results.append(result)
      }

      // Sort by original index and return just the decrypted data
      return results.sorted(by: { $0.0 < $1.0 }).map(\.1)
    }
  }
}