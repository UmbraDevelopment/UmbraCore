import CoreSecurityTypes
import CryptoInterfaces
import CryptoServicesApple
import CryptoServicesCore
import CryptoServicesStandard
import CryptoServicesXfn
import DomainSecurityTypes
import Foundation
import LoggingInterfaces
import SecurityCoreInterfaces
import UmbraErrors

/**
 # SecurityProviderFactoryImpl

 Factory for creating security provider implementations based on specified provider types.

 This factory follows the Alpha Dot Five architecture pattern for structured dependency creation,
 ensuring that appropriate security providers are instantiated based on platform capabilities,
 available libraries, and configuration requirements.

 ## Usage

 ```swift
 // Create a specific provider
 let provider = try SecurityProviderFactoryImpl.createProvider(type: .cryptoKit)

 // Or let the factory select the best available
 let provider = try SecurityProviderFactoryImpl.createBestAvailableProvider()
 ```

 ## Provider Selection

 The factory will automatically select providers based on:
 1. The requested provider type
 2. Platform availability (e.g., CryptoKit on Apple platforms)
 3. Security requirements

 If a requested provider is unavailable, it will fall back to the next best option.
 */
public enum SecurityProviderFactoryImpl {
  /**
   Creates a security provider of the specified type.

   - Parameter type: The type of security provider to create
   - Returns: A fully configured provider implementation
   - Throws: SecurityServiceError if the provider is not available on this platform
   */
  public static func createProvider(type: SecurityProviderType) throws
  -> EncryptionProviderProtocol {
    switch type {
      case .cryptoKit:
        #if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
          return try CryptoKitProvider()
        #else
          throw SecurityServiceError.providerError("CryptoKit is not available on this platform")
        #endif
      case .ring:
        return try RingProvider()
      case .basic:
        // Use StandardSecurityProvider as a more secure alternative to the deprecated
        // FallbackEncryptionProvider
        return StandardSecurityProvider()
      case .system:
        #if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
          return try SystemSecurityProvider()
        #else
          throw SecurityServiceError
            .providerError("System provider is not available on this platform")
        #endif
      case .hsm:
        if HSMProvider.isAvailable() {
          return try HSMProvider()
        } else {
          throw SecurityServiceError.providerError("HSM provider is not available")
        }
    }
  }

  /**
   Creates the best available security provider based on the current platform.

   This method tries to create providers in order of preference (most secure to least secure),
   falling back to simpler providers if more secure ones are not available.

   - Returns: The best available provider
   - Throws: SecurityServiceError if no providers are available
   */
  public static func createBestAvailableProvider() throws -> EncryptionProviderProtocol {
    // Try providers in order of preference
    let providerTypes: [SecurityProviderType]=[
      .cryptoKit,
      .ring,
      .system,
      .basic
    ]

    // Try each provider in sequence
    var lastError: Error?
    for providerType in providerTypes {
      do {
        return try createProvider(type: providerType)
      } catch {
        lastError=error
        // Continue to next provider
      }
    }

    throw SecurityServiceError.providerError(
      "No security providers available: \(lastError?.localizedDescription ?? "Unknown error")"
    )
  }

  /**
   Creates a default provider for non-critical operations.

   This is useful for operations that don't require the highest security level
   but need basic encryption capabilities.

   - Returns: A default encryption provider
   */
  public static func createDefaultProvider() -> EncryptionProviderProtocol {
    // Try to create providers in order of security preference
    let providerTypes: [SecurityProviderType]=[
      .cryptoKit,
      .ring,
      .system
    ]

    // Try each provider in sequence before falling back to basic
    for providerType in providerTypes {
      do {
        return try createProvider(type: providerType)
      } catch {
        // Continue to next provider
        continue
      }
    }

    // Use StandardSecurityProvider instead of the deprecated FallbackEncryptionProvider
    return StandardSecurityProvider()
  }
}

// MARK: - Provider Implementations

/**
 Apple CryptoKit-based encryption provider.

 This provider delegates to CryptoServicesApple for high-performance,
 secure cryptographic operations with hardware acceleration when available.
 */
private final class CryptoKitProvider: EncryptionProviderProtocol {
  public var providerType: SecurityProviderType { .cryptoKit }

  // The CryptoServiceProtocol instance from CryptoServicesApple
  private let cryptoService: CryptoServiceProtocol

  // Secure storage for cryptographic operations
  private let secureStorage: SecureStorageProtocol

  // Logger for secure operations
  private let logger: LoggingProtocol?

  init() throws {
    // Create a dedicated secure storage instance for this provider
    secureStorage=TemporarySecureStorage()
    logger=nil

    // Create the Apple-native cryptographic service
    cryptoService=try Task {
      await CryptoServiceRegistry.createService(
        type: .apple,
        secureStorage: secureStorage,
        logger: logger
      )
    }.value
  }

  public func encrypt(
    plaintext: Data,
    key: Data,
    iv: Data,
    config: SecurityConfigDTO
  ) throws -> Data {
    // Store the data and key in secure storage
    let dataID=UUID().uuidString
    let keyID=UUID().uuidString

    // Convert async operations to synchronous for compatibility
    let dataStoreResult=try Task {
      await cryptoService.storeData(data: plaintext, identifier: dataID)
    }.value

    guard case .success=dataStoreResult else {
      throw SecurityServiceError.providerError("Failed to store plaintext data for encryption")
    }

    let keyStoreResult=try Task {
      await cryptoService.storeData(data: key, identifier: keyID)
    }.value

    guard case .success=keyStoreResult else {
      throw SecurityServiceError.providerError("Failed to store key for encryption")
    }

    // Create encryption options with the IV
    let options=EncryptionOptions(
      algorithm: config.encryptionAlgorithm.rawValue,
      mode: "GCM",
      padding: "NoPadding",
      iv: iv,
      aad: nil
    )

    // Perform the encryption operation
    let encryptResult=try Task {
      await cryptoService.encrypt(
        dataIdentifier: dataID,
        keyIdentifier: keyID,
        options: options
      )
    }.value

    // Retrieve the encrypted data
    switch encryptResult {
      case let .success(encryptedID):
        let retrieveResult=try Task {
          await cryptoService.retrieveData(identifier: encryptedID)
        }.value

        switch retrieveResult {
          case let .success(encryptedData):
            return encryptedData
          case .failure:
            throw SecurityServiceError.providerError("Failed to retrieve encrypted data")
        }

      case .failure:
        throw SecurityServiceError.providerError("Encryption operation failed")
    }
  }

  public func decrypt(
    ciphertext: Data,
    key: Data,
    iv: Data,
    config: SecurityConfigDTO
  ) throws -> Data {
    // Store the data and key in secure storage
    let dataID=UUID().uuidString
    let keyID=UUID().uuidString

    // Convert async operations to synchronous for compatibility
    let dataStoreResult=try Task {
      await cryptoService.storeData(data: ciphertext, identifier: dataID)
    }.value

    guard case .success=dataStoreResult else {
      throw SecurityServiceError.providerError("Failed to store ciphertext data for decryption")
    }

    let keyStoreResult=try Task {
      await cryptoService.storeData(data: key, identifier: keyID)
    }.value

    guard case .success=keyStoreResult else {
      throw SecurityServiceError.providerError("Failed to store key for decryption")
    }

    // Create decryption options with the IV
    let options=DecryptionOptions(
      algorithm: config.encryptionAlgorithm.rawValue,
      mode: "GCM",
      padding: "NoPadding",
      iv: iv,
      aad: nil
    )

    // Perform the decryption operation
    let decryptResult=try Task {
      await cryptoService.decrypt(
        encryptedDataIdentifier: dataID,
        keyIdentifier: keyID,
        options: options
      )
    }.value

    // Retrieve the decrypted data
    switch decryptResult {
      case let .success(decryptedID):
        let retrieveResult=try Task {
          await cryptoService.retrieveData(identifier: decryptedID)
        }.value

        switch retrieveResult {
          case let .success(decryptedData):
            return decryptedData
          case .failure:
            throw SecurityServiceError.providerError("Failed to retrieve decrypted data")
        }

      case .failure:
        throw SecurityServiceError.providerError("Decryption operation failed")
    }
  }

  public func generateKey(size: Int, config: SecurityConfigDTO) throws -> Data {
    // Create key generation options
    let options=KeyGenerationOptions(
      algorithm: config.encryptionAlgorithm.rawValue,
      keyUsage: "encryption",
      metadata: ["keySize": "\(size)"]
    )

    // Perform the key generation operation
    let generateResult=try Task {
      await cryptoService.generateKey(
        length: size / 8, // Convert bits to bytes
        options: options
      )
    }.value

    // Retrieve the generated key
    switch generateResult {
      case let .success(keyID):
        let retrieveResult=try Task {
          await cryptoService.retrieveData(identifier: keyID)
        }.value

        switch retrieveResult {
          case let .success(keyData):
            return keyData
          case .failure:
            throw SecurityServiceError.providerError("Failed to retrieve generated key")
        }

      case .failure:
        throw SecurityServiceError.providerError("Key generation failed")
    }
  }

  public func generateIV(size: Int) throws -> Data {
    // Delegate to crypto service for random bytes generation
    let generateResult=try Task {
      // We'll need to import the key first, then export it
      let randomID=UUID().uuidString
      let randomBytes=Array(repeating: UInt8(0), count: size)
      let importResult=await cryptoService.importData(randomBytes, customIdentifier: randomID)

      guard case .success=importResult else {
        return Result<Data, SecurityStorageError>
          .failure(.storageError("Failed to create random bytes"))
      }

      // Now generate random bytes by storing and retrieving
      let options=KeyGenerationOptions(
        algorithm: "AES",
        keyUsage: "iv",
        metadata: ["size": "\(size)"]
      )

      let keyResult=await cryptoService.generateKey(length: size, options: options)

      switch keyResult {
        case let .success(keyID):
          let dataResult=await cryptoService.retrieveData(identifier: keyID)
          return dataResult
        case let .failure(error):
          return Result<Data, SecurityStorageError>.failure(error)
      }
    }.value

    switch generateResult {
      case let .success(ivData):
        return ivData
      case .failure:
        throw SecurityServiceError.providerError("Failed to generate IV")
    }
  }

  public func hash(data: Data, algorithm: String) throws -> Data {
    // Store the data in secure storage
    let dataID=UUID().uuidString

    // Convert async operations to synchronous for compatibility
    let dataStoreResult=try Task {
      await cryptoService.storeData(data: data, identifier: dataID)
    }.value

    guard case .success=dataStoreResult else {
      throw SecurityServiceError.providerError("Failed to store data for hashing")
    }

    // Create hashing options
    let options=HashingOptions(
      algorithm: algorithm,
      metadata: nil
    )

    // Perform the hashing operation
    let hashResult=try Task {
      await cryptoService.hash(
        dataIdentifier: dataID,
        options: options
      )
    }.value

    // Retrieve the hash result
    switch hashResult {
      case let .success(hashID):
        let retrieveResult=try Task {
          await cryptoService.retrieveData(identifier: hashID)
        }.value

        switch retrieveResult {
          case let .success(hashData):
            return hashData
          case .failure:
            throw SecurityServiceError.providerError("Failed to retrieve hash data")
        }

      case .failure:
        throw SecurityServiceError.providerError("Hashing operation failed")
    }
  }
}

/**
 Ring cryptography library provider.

 This provider delegates to CryptoServicesXfn for cross-platform
 compatibility while maintaining high security standards.
 */
private final class RingProvider: EncryptionProviderProtocol {
  public var providerType: SecurityProviderType { .ring }

  // The CryptoServiceProtocol instance from CryptoServicesXfn
  private let cryptoService: CryptoServiceProtocol

  // Secure storage for cryptographic operations
  private let secureStorage: SecureStorageProtocol

  // Logger for secure operations
  private let logger: LoggingProtocol?

  init() throws {
    // Create a dedicated secure storage instance for this provider
    secureStorage=TemporarySecureStorage()
    logger=nil

    // Create the Ring-based cryptographic service
    cryptoService=try Task {
      await CryptoServiceRegistry.createService(
        type: .xfn,
        secureStorage: secureStorage,
        logger: logger
      )
    }.value
  }

  public func encrypt(
    plaintext: Data,
    key: Data,
    iv: Data,
    config: SecurityConfigDTO
  ) throws -> Data {
    // Store the data and key in secure storage
    let dataID=UUID().uuidString
    let keyID=UUID().uuidString

    // Convert async operations to synchronous for compatibility
    let dataStoreResult=try Task {
      await cryptoService.storeData(data: plaintext, identifier: dataID)
    }.value

    guard case .success=dataStoreResult else {
      throw SecurityServiceError.providerError("Failed to store plaintext data for encryption")
    }

    let keyStoreResult=try Task {
      await cryptoService.storeData(data: key, identifier: keyID)
    }.value

    guard case .success=keyStoreResult else {
      throw SecurityServiceError.providerError("Failed to store key for encryption")
    }

    // Create encryption options with the IV
    let options=EncryptionOptions(
      algorithm: config.encryptionAlgorithm.rawValue,
      mode: "GCM",
      padding: "NoPadding",
      iv: iv,
      aad: nil
    )

    // Perform the encryption operation
    let encryptResult=try Task {
      await cryptoService.encrypt(
        dataIdentifier: dataID,
        keyIdentifier: keyID,
        options: options
      )
    }.value

    // Retrieve the encrypted data
    switch encryptResult {
      case let .success(encryptedID):
        let retrieveResult=try Task {
          await cryptoService.retrieveData(identifier: encryptedID)
        }.value

        switch retrieveResult {
          case let .success(encryptedData):
            return encryptedData
          case .failure:
            throw SecurityServiceError.providerError("Failed to retrieve encrypted data")
        }

      case .failure:
        throw SecurityServiceError.providerError("Encryption operation failed")
    }
  }

  public func decrypt(
    ciphertext: Data,
    key: Data,
    iv: Data,
    config: SecurityConfigDTO
  ) throws -> Data {
    // Store the data and key in secure storage
    let dataID=UUID().uuidString
    let keyID=UUID().uuidString

    // Convert async operations to synchronous for compatibility
    let dataStoreResult=try Task {
      await cryptoService.storeData(data: ciphertext, identifier: dataID)
    }.value

    guard case .success=dataStoreResult else {
      throw SecurityServiceError.providerError("Failed to store ciphertext data for decryption")
    }

    let keyStoreResult=try Task {
      await cryptoService.storeData(data: key, identifier: keyID)
    }.value

    guard case .success=keyStoreResult else {
      throw SecurityServiceError.providerError("Failed to store key for decryption")
    }

    // Create decryption options with the IV
    let options=DecryptionOptions(
      algorithm: config.encryptionAlgorithm.rawValue,
      mode: "GCM",
      padding: "NoPadding",
      iv: iv,
      aad: nil
    )

    // Perform the decryption operation
    let decryptResult=try Task {
      await cryptoService.decrypt(
        encryptedDataIdentifier: dataID,
        keyIdentifier: keyID,
        options: options
      )
    }.value

    // Retrieve the decrypted data
    switch decryptResult {
      case let .success(decryptedID):
        let retrieveResult=try Task {
          await cryptoService.retrieveData(identifier: decryptedID)
        }.value

        switch retrieveResult {
          case let .success(decryptedData):
            return decryptedData
          case .failure:
            throw SecurityServiceError.providerError("Failed to retrieve decrypted data")
        }

      case .failure:
        throw SecurityServiceError.providerError("Decryption operation failed")
    }
  }

  public func generateKey(size: Int, config: SecurityConfigDTO) throws -> Data {
    // Create key generation options
    let options=KeyGenerationOptions(
      algorithm: config.encryptionAlgorithm.rawValue,
      keyUsage: "encryption",
      metadata: ["keySize": "\(size)"]
    )

    // Perform the key generation operation
    let generateResult=try Task {
      await cryptoService.generateKey(
        length: size / 8, // Convert bits to bytes
        options: options
      )
    }.value

    // Retrieve the generated key
    switch generateResult {
      case let .success(keyID):
        let retrieveResult=try Task {
          await cryptoService.retrieveData(identifier: keyID)
        }.value

        switch retrieveResult {
          case let .success(keyData):
            return keyData
          case .failure:
            throw SecurityServiceError.providerError("Failed to retrieve generated key")
        }

      case .failure:
        throw SecurityServiceError.providerError("Key generation failed")
    }
  }

  public func generateIV(size: Int) throws -> Data {
    // Delegate to crypto service for random bytes generation
    let generateResult=try Task {
      // Generate key with IV usage
      let options=KeyGenerationOptions(
        algorithm: "AES",
        keyUsage: "iv",
        metadata: ["size": "\(size)"]
      )

      let keyResult=await cryptoService.generateKey(length: size, options: options)

      switch keyResult {
        case let .success(keyID):
          let dataResult=await cryptoService.retrieveData(identifier: keyID)
          return dataResult
        case let .failure(error):
          return Result<Data, SecurityStorageError>.failure(error)
      }
    }.value

    switch generateResult {
      case let .success(ivData):
        return ivData
      case .failure:
        throw SecurityServiceError.providerError("Failed to generate IV")
    }
  }

  public func hash(data: Data, algorithm: String) throws -> Data {
    // Store the data in secure storage
    let dataID=UUID().uuidString

    // Convert async operations to synchronous for compatibility
    let dataStoreResult=try Task {
      await cryptoService.storeData(data: data, identifier: dataID)
    }.value

    guard case .success=dataStoreResult else {
      throw SecurityServiceError.providerError("Failed to store data for hashing")
    }

    // Create hashing options
    let options=HashingOptions(
      algorithm: algorithm,
      metadata: nil
    )

    // Perform the hashing operation
    let hashResult=try Task {
      await cryptoService.hash(
        dataIdentifier: dataID,
        options: options
      )
    }.value

    // Retrieve the hash result
    switch hashResult {
      case let .success(hashID):
        let retrieveResult=try Task {
          await cryptoService.retrieveData(identifier: hashID)
        }.value

        switch retrieveResult {
          case let .success(hashData):
            return hashData
          case .failure:
            throw SecurityServiceError.providerError("Failed to retrieve hash data")
        }

      case .failure:
        throw SecurityServiceError.providerError("Hashing operation failed")
    }
  }
}

/**
 System security services provider.

 This provider delegates to CryptoServicesStandard for platform-optimised
 security operations using the system's standard cryptographic libraries.
 */
private final class SystemSecurityProvider: EncryptionProviderProtocol {
  public var providerType: SecurityProviderType { .system }

  // The CryptoServiceProtocol instance from CryptoServicesStandard
  private let cryptoService: CryptoServiceProtocol

  // Secure storage for cryptographic operations
  private let secureStorage: SecureStorageProtocol

  // Logger for secure operations
  private let logger: LoggingProtocol?

  init() throws {
    // Create a dedicated secure storage instance for this provider
    secureStorage=TemporarySecureStorage()
    logger=nil

    // Create the standard cryptographic service
    cryptoService=try Task {
      await CryptoServiceRegistry.createService(
        type: .standard,
        secureStorage: secureStorage,
        logger: logger
      )
    }.value
  }

  public func encrypt(
    plaintext: Data,
    key: Data,
    iv: Data,
    config: SecurityConfigDTO
  ) throws -> Data {
    // Store the data and key in secure storage
    let dataID=UUID().uuidString
    let keyID=UUID().uuidString

    // Convert async operations to synchronous for compatibility
    let dataStoreResult=try Task {
      await cryptoService.storeData(data: plaintext, identifier: dataID)
    }.value

    guard case .success=dataStoreResult else {
      throw SecurityServiceError.providerError("Failed to store plaintext data for encryption")
    }

    let keyStoreResult=try Task {
      await cryptoService.storeData(data: key, identifier: keyID)
    }.value

    guard case .success=keyStoreResult else {
      throw SecurityServiceError.providerError("Failed to store key for encryption")
    }

    // Create encryption options with the IV
    let options=EncryptionOptions(
      algorithm: config.encryptionAlgorithm.rawValue,
      mode: "GCM",
      padding: "NoPadding",
      iv: iv,
      aad: nil
    )

    // Perform the encryption operation
    let encryptResult=try Task {
      await cryptoService.encrypt(
        dataIdentifier: dataID,
        keyIdentifier: keyID,
        options: options
      )
    }.value

    // Retrieve the encrypted data
    switch encryptResult {
      case let .success(encryptedID):
        let retrieveResult=try Task {
          await cryptoService.retrieveData(identifier: encryptedID)
        }.value

        switch retrieveResult {
          case let .success(encryptedData):
            return encryptedData
          case .failure:
            throw SecurityServiceError.providerError("Failed to retrieve encrypted data")
        }

      case .failure:
        throw SecurityServiceError.providerError("Encryption operation failed")
    }
  }

  public func decrypt(
    ciphertext: Data,
    key: Data,
    iv: Data,
    config: SecurityConfigDTO
  ) throws -> Data {
    // Store the data and key in secure storage
    let dataID=UUID().uuidString
    let keyID=UUID().uuidString

    // Convert async operations to synchronous for compatibility
    let dataStoreResult=try Task {
      await cryptoService.storeData(data: ciphertext, identifier: dataID)
    }.value

    guard case .success=dataStoreResult else {
      throw SecurityServiceError.providerError("Failed to store ciphertext data for decryption")
    }

    let keyStoreResult=try Task {
      await cryptoService.storeData(data: key, identifier: keyID)
    }.value

    guard case .success=keyStoreResult else {
      throw SecurityServiceError.providerError("Failed to store key for decryption")
    }

    // Create decryption options with the IV
    let options=DecryptionOptions(
      algorithm: config.encryptionAlgorithm.rawValue,
      mode: "GCM",
      padding: "NoPadding",
      iv: iv,
      aad: nil
    )

    // Perform the decryption operation
    let decryptResult=try Task {
      await cryptoService.decrypt(
        encryptedDataIdentifier: dataID,
        keyIdentifier: keyID,
        options: options
      )
    }.value

    // Retrieve the decrypted data
    switch decryptResult {
      case let .success(decryptedID):
        let retrieveResult=try Task {
          await cryptoService.retrieveData(identifier: decryptedID)
        }.value

        switch retrieveResult {
          case let .success(decryptedData):
            return decryptedData
          case .failure:
            throw SecurityServiceError.providerError("Failed to retrieve decrypted data")
        }

      case .failure:
        throw SecurityServiceError.providerError("Decryption operation failed")
    }
  }

  public func generateKey(size: Int, config: SecurityConfigDTO) throws -> Data {
    // Create key generation options
    let options=KeyGenerationOptions(
      algorithm: config.encryptionAlgorithm.rawValue,
      keyUsage: "encryption",
      metadata: ["keySize": "\(size)"]
    )

    // Perform the key generation operation
    let generateResult=try Task {
      await cryptoService.generateKey(
        length: size / 8, // Convert bits to bytes
        options: options
      )
    }.value

    // Retrieve the generated key
    switch generateResult {
      case let .success(keyID):
        let retrieveResult=try Task {
          await cryptoService.retrieveData(identifier: keyID)
        }.value

        switch retrieveResult {
          case let .success(keyData):
            return keyData
          case .failure:
            throw SecurityServiceError.providerError("Failed to retrieve generated key")
        }

      case .failure:
        throw SecurityServiceError.providerError("Key generation failed")
    }
  }

  public func generateIV(size: Int) throws -> Data {
    // Delegate to crypto service for random bytes generation
    let generateResult=try Task {
      // Generate key with IV usage
      let options=KeyGenerationOptions(
        algorithm: "AES",
        keyUsage: "iv",
        metadata: ["size": "\(size)"]
      )

      let keyResult=await cryptoService.generateKey(length: size, options: options)

      switch keyResult {
        case let .success(keyID):
          let dataResult=await cryptoService.retrieveData(identifier: keyID)
          return dataResult
        case let .failure(error):
          return Result<Data, SecurityStorageError>.failure(error)
      }
    }.value

    switch generateResult {
      case let .success(ivData):
        return ivData
      case .failure:
        throw SecurityServiceError.providerError("Failed to generate IV")
    }
  }

  public func hash(data: Data, algorithm: String) throws -> Data {
    // Store the data in secure storage
    let dataID=UUID().uuidString

    // Convert async operations to synchronous for compatibility
    let dataStoreResult=try Task {
      await cryptoService.storeData(data: data, identifier: dataID)
    }.value

    guard case .success=dataStoreResult else {
      throw SecurityServiceError.providerError("Failed to store data for hashing")
    }

    // Create hashing options
    let options=HashingOptions(
      algorithm: algorithm,
      metadata: nil
    )

    // Perform the hashing operation
    let hashResult=try Task {
      await cryptoService.hash(
        dataIdentifier: dataID,
        options: options
      )
    }.value

    // Retrieve the hash result
    switch hashResult {
      case let .success(hashID):
        let retrieveResult=try Task {
          await cryptoService.retrieveData(identifier: hashID)
        }.value

        switch retrieveResult {
          case let .success(hashData):
            return hashData
          case .failure:
            throw SecurityServiceError.providerError("Failed to retrieve hash data")
        }

      case .failure:
        throw SecurityServiceError.providerError("Hashing operation failed")
    }
  }
}

/**
 Hardware Security Module provider.

 This provider interfaces with dedicated hardware security modules
 for the highest level of security.
 */
private final class HSMProvider: EncryptionProviderProtocol {
  public var providerType: SecurityProviderType { .hsm }

  /// Check if HSM is available on the current system
  static func isAvailable() -> Bool {
    // Logic to detect HSM
    false
  }

  init() throws {
    // Initialisation logic for HSM provider
  }

  func encrypt(
    plaintext _: Data,
    key _: Data,
    iv _: Data,
    config _: SecurityConfigDTO
  ) throws -> Data {
    // Implementation would use HSM for actual implementation
    fatalError("Implementation required")
  }

  func decrypt(
    ciphertext _: Data,
    key _: Data,
    iv _: Data,
    config _: SecurityConfigDTO
  ) throws -> Data {
    // Implementation would use HSM for actual implementation
    fatalError("Implementation required")
  }

  func generateKey(size _: Int, config _: SecurityConfigDTO) throws -> Data {
    // Implementation would use HSM for actual implementation
    fatalError("Implementation required")
  }

  func generateIV(size _: Int) throws -> Data {
    // Implementation would use HSM for actual implementation
    fatalError("Implementation required")
  }

  func hash(data _: Data, algorithm _: String) throws -> Data {
    // Implementation would use HSM for actual implementation
    fatalError("Implementation required")
  }
}

/**
 Standard security provider implementation with secure algorithms.

 This provider delegates to CryptoServicesStandard module for all cryptographic operations,
 providing a secure, well-tested implementation suitable for most security requirements.
 */
private final class StandardSecurityProvider: EncryptionProviderProtocol {
  public var providerType: SecurityProviderType { .basic }

  // The CryptoServiceProtocol instance from CryptoServicesStandard
  private let cryptoService: CryptoServiceProtocol

  // Secure storage for cryptographic operations
  private let secureStorage: SecureStorageProtocol

  // Logger for secure operations
  private let logger: LoggingProtocol?

  public init() throws {
    // Create a dedicated secure storage instance for this provider
    secureStorage=TemporarySecureStorage()
    logger=nil

    // Create the standard cryptographic service
    cryptoService=try Task {
      await CryptoServiceRegistry.createService(
        type: .standard,
        secureStorage: secureStorage,
        logger: logger
      )
    }.value
  }

  public func encrypt(
    plaintext: Data,
    key: Data,
    iv: Data,
    config: SecurityConfigDTO
  ) throws -> Data {
    guard !plaintext.isEmpty else {
      throw SecurityServiceError.invalidInputData("Plaintext data cannot be empty")
    }

    guard key.count >= 16 else {
      throw SecurityServiceError.invalidInputData("Encryption key must be at least 16 bytes")
    }

    guard iv.count >= 12 else {
      throw SecurityServiceError.invalidInputData("Initialisation vector must be at least 12 bytes")
    }

    // Store the data and key in secure storage
    let dataID=UUID().uuidString
    let keyID=UUID().uuidString

    // Convert async operations to synchronous for compatibility
    let dataStoreResult=try Task {
      await cryptoService.storeData(data: plaintext, identifier: dataID)
    }.value

    guard case .success=dataStoreResult else {
      throw SecurityServiceError.providerError("Failed to store plaintext data for encryption")
    }

    let keyStoreResult=try Task {
      await cryptoService.storeData(data: key, identifier: keyID)
    }.value

    guard case .success=keyStoreResult else {
      throw SecurityServiceError.providerError("Failed to store key for encryption")
    }

    // Create encryption options with the IV
    let options=EncryptionOptions(
      algorithm: config.encryptionAlgorithm.rawValue,
      mode: "GCM",
      padding: "NoPadding",
      iv: iv,
      aad: nil
    )

    // Perform the encryption operation
    let encryptResult=try Task {
      await cryptoService.encrypt(
        dataIdentifier: dataID,
        keyIdentifier: keyID,
        options: options
      )
    }.value

    // Retrieve the encrypted data
    switch encryptResult {
      case let .success(encryptedID):
        let retrieveResult=try Task {
          await cryptoService.retrieveData(identifier: encryptedID)
        }.value

        switch retrieveResult {
          case let .success(encryptedData):
            return encryptedData
          case .failure:
            throw SecurityServiceError.providerError("Failed to retrieve encrypted data")
        }

      case .failure:
        throw SecurityServiceError.providerError("Encryption operation failed")
    }
  }

  public func decrypt(
    ciphertext: Data,
    key: Data,
    iv: Data,
    config: SecurityConfigDTO
  ) throws -> Data {
    guard !ciphertext.isEmpty else {
      throw SecurityServiceError.invalidInputData("Ciphertext data cannot be empty")
    }

    guard key.count >= 16 else {
      throw SecurityServiceError.invalidInputData("Decryption key must be at least 16 bytes")
    }

    guard iv.count >= 12 else {
      throw SecurityServiceError.invalidInputData("Initialisation vector must be at least 12 bytes")
    }

    // Store the data and key in secure storage
    let dataID=UUID().uuidString
    let keyID=UUID().uuidString

    // Convert async operations to synchronous for compatibility
    let dataStoreResult=try Task {
      await cryptoService.storeData(data: ciphertext, identifier: dataID)
    }.value

    guard case .success=dataStoreResult else {
      throw SecurityServiceError.providerError("Failed to store ciphertext data for decryption")
    }

    let keyStoreResult=try Task {
      await cryptoService.storeData(data: key, identifier: keyID)
    }.value

    guard case .success=keyStoreResult else {
      throw SecurityServiceError.providerError("Failed to store key for decryption")
    }

    // Create decryption options with the IV
    let options=DecryptionOptions(
      algorithm: config.encryptionAlgorithm.rawValue,
      mode: "GCM",
      padding: "NoPadding",
      iv: iv,
      aad: nil
    )

    // Perform the decryption operation
    let decryptResult=try Task {
      await cryptoService.decrypt(
        encryptedDataIdentifier: dataID,
        keyIdentifier: keyID,
        options: options
      )
    }.value

    // Retrieve the decrypted data
    switch decryptResult {
      case let .success(decryptedID):
        let retrieveResult=try Task {
          await cryptoService.retrieveData(identifier: decryptedID)
        }.value

        switch retrieveResult {
          case let .success(decryptedData):
            return decryptedData
          case .failure:
            throw SecurityServiceError.providerError("Failed to retrieve decrypted data")
        }

      case .failure:
        throw SecurityServiceError.providerError("Decryption operation failed")
    }
  }

  public func generateKey(size: Int, config: SecurityConfigDTO) throws -> Data {
    guard size >= 128, size % 8 == 0 else {
      throw SecurityServiceError
        .invalidInputData("Key size must be at least 128 bits and a multiple of 8")
    }

    // Create key generation options
    let options=KeyGenerationOptions(
      algorithm: config.encryptionAlgorithm.rawValue,
      keyUsage: "encryption",
      metadata: ["keySize": "\(size)"]
    )

    // Perform the key generation operation
    let generateResult=try Task {
      await cryptoService.generateKey(
        length: size / 8, // Convert bits to bytes
        options: options
      )
    }.value

    // Retrieve the generated key
    switch generateResult {
      case let .success(keyID):
        let retrieveResult=try Task {
          await cryptoService.retrieveData(identifier: keyID)
        }.value

        switch retrieveResult {
          case let .success(keyData):
            return keyData
          case .failure:
            throw SecurityServiceError.providerError("Failed to retrieve generated key")
        }

      case .failure:
        throw SecurityServiceError.providerError("Key generation failed")
    }
  }

  public func generateIV(size: Int) throws -> Data {
    guard size >= 12 else {
      throw SecurityServiceError.invalidInputData("IV size must be at least 12 bytes")
    }

    // Delegate to crypto service for random bytes generation
    let generateResult=try Task {
      // Generate key with IV usage
      let options=KeyGenerationOptions(
        algorithm: "AES",
        keyUsage: "iv",
        metadata: ["size": "\(size)"]
      )

      let keyResult=await cryptoService.generateKey(length: size, options: options)

      switch keyResult {
        case let .success(keyID):
          let dataResult=await cryptoService.retrieveData(identifier: keyID)
          return dataResult
        case let .failure(error):
          return Result<Data, SecurityStorageError>.failure(error)
      }
    }.value

    switch generateResult {
      case let .success(ivData):
        return ivData
      case .failure:
        throw SecurityServiceError.providerError("Failed to generate IV")
    }
  }

  public func hash(data: Data, algorithm: String) throws -> Data {
    guard !data.isEmpty else {
      throw SecurityServiceError.invalidInputData("Data to hash cannot be empty")
    }

    guard !algorithm.isEmpty else {
      throw SecurityServiceError.invalidInputData("Hash algorithm cannot be empty")
    }

    // Store the data in secure storage
    let dataID=UUID().uuidString

    // Convert async operations to synchronous for compatibility
    let dataStoreResult=try Task {
      await cryptoService.storeData(data: data, identifier: dataID)
    }.value

    guard case .success=dataStoreResult else {
      throw SecurityServiceError.providerError("Failed to store data for hashing")
    }

    // Create hashing options
    let options=HashingOptions(
      algorithm: algorithm,
      metadata: nil
    )

    // Perform the hashing operation
    let hashResult=try Task {
      await cryptoService.hash(
        dataIdentifier: dataID,
        options: options
      )
    }.value

    // Retrieve the hash result
    switch hashResult {
      case let .success(hashID):
        let retrieveResult=try Task {
          await cryptoService.retrieveData(identifier: hashID)
        }.value

        switch retrieveResult {
          case let .success(hashData):
            return hashData
          case .failure:
            throw SecurityServiceError.providerError("Failed to retrieve hash data")
        }

      case .failure:
        throw SecurityServiceError.providerError("Hashing operation failed")
    }
  }
}

/**
 A simple in-memory secure storage implementation used by providers for temporary data.

 This implementation is only intended for use during cryptographic operations within
 the provider functions, not for persistent storage.
 */
private class TemporarySecureStorage: SecureStorageProtocol {
  private actor StorageActor {
    private var storage: [String: Data]=[:]

    func store(
      _ data: Data,
      withIdentifier identifier: String
    ) -> Result<Void, SecurityStorageError> {
      storage[identifier]=data
      return .success(())
    }

    func retrieve(identifier: String) -> Result<Data, SecurityStorageError> {
      guard let data=storage[identifier] else {
        return .failure(.itemNotFound("Item with identifier \(identifier) not found"))
      }
      return .success(data)
    }

    func delete(identifier: String) -> Result<Void, SecurityStorageError> {
      storage.removeValue(forKey: identifier)
      return .success(())
    }

    func clear() -> Result<Void, SecurityStorageError> {
      storage.removeAll()
      return .success(())
    }
  }

  private let storageActor=StorageActor()

  public init() {}

  public func store(
    _ data: Data,
    withIdentifier identifier: String
  ) async -> Result<Void, SecurityStorageError> {
    await storageActor.store(data, withIdentifier: identifier)
  }

  public func retrieve(identifier: String) async -> Result<Data, SecurityStorageError> {
    await storageActor.retrieve(identifier: identifier)
  }

  public func delete(identifier: String) async -> Result<Void, SecurityStorageError> {
    await storageActor.delete(identifier: identifier)
  }

  public func clear() async -> Result<Void, SecurityStorageError> {
    await storageActor.clear()
  }
}
