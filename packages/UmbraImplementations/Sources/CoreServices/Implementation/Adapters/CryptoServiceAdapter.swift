import CoreInterfaces
import CryptoInterfaces
import DomainSecurityTypes
import Foundation
import LoggingInterfaces
import LoggingTypes
import UmbraErrors

/**
 # Crypto Service Adapter

 This actor implements the adapter pattern to bridge between the CoreCryptoServiceProtocol
 and the full CryptoServiceProtocol implementation.

 ## Purpose

 - Provides a simplified interface for core modules to access cryptographic functionality
 - Delegates operations to the actual cryptographic implementation
 - Converts between data types as necessary
 - Ensures thread safety through the actor concurrency model

 ## Design Pattern

 This adapter follows the classic adapter design pattern, where it implements
 one interface (CoreCryptoServiceProtocol) while wrapping an instance of another
 interface (CryptoServiceProtocol).
 */
public actor CryptoServiceAdapter: CoreInterfaces.CoreCryptoServiceProtocol {
  // MARK: - Properties

  /**
   The underlying crypto service implementation

   This is the adaptee in the adapter pattern.
   */
  private let cryptoService: CryptoServiceProtocol
  
  /**
   Domain-specific logger for crypto operations
   
   Used for privacy-aware logging of cryptographic operations.
   */
  private let logger: DomainLogger

  // MARK: - Initialisation

  /**
   Creates a new crypto service adapter with the provided implementation

   - Parameter cryptoService: The underlying crypto service to adapt
   */
  public init(cryptoService: CryptoServiceProtocol) {
    self.cryptoService = cryptoService
    // Create a domain logger for crypto operations
    self.logger = LoggerFactory.createCryptoLogger(source: "CryptoServiceAdapter")
    
    Task {
      await logInitialisation()
    }
  }
  
  /**
   Log the initialisation of the adapter
   */
  private func logInitialisation() async {
    let context = CoreLogContext.initialisation(
      source: "CryptoServiceAdapter.init"
    )
    
    await logger.info("Crypto service adapter initialised", context: context)
  }

  // MARK: - CoreCryptoServiceProtocol Implementation

  /**
   Encrypts the provided data using the system default encryption

   Delegates to the underlying crypto service implementation.

   - Parameters:
     - data: The data to encrypt
     - key: The key to use for encryption
   - Returns: The encrypted data
   - Throws: CryptoError if encryption fails
   */
  public func encrypt(data: Data, using key: Data) async throws -> Data {
    let context = {
      var metadata = LogMetadataDTOCollection()
      metadata = metadata.withPrivate(key: "dataSize", value: String(data.count))
      metadata = metadata.withPrivate(key: "keySize", value: String(key.count))
      return CoreLogContext(
        source: "CryptoServiceAdapter.encrypt",
        metadata: metadata
      )
    }()
    
    await logger.debug("Encrypting data", context: context)
    
    do {
      let encryptionOptions = EncryptionOptions(
        algorithm: .aes256GCM,
        key: key
      )
      
      let result = try await cryptoService.encrypt(
        data: data,
        options: encryptionOptions
      )
      
      await logger.debug("Data encrypted successfully", context: context)
      return result
    } catch {
      let loggableError = LoggableErrorDTO(
        error: error,
        message: "Failed to encrypt data",
        details: "Encryption operation failed in adapter"
      )
      
      await logger.error(
        loggableError,
        context: context,
        privacyLevel: .private
      )
      
      throw adaptError(error)
    }
  }

  /**
   Decrypts the provided data using the system default encryption

   Delegates to the underlying crypto service implementation.

   - Parameters:
     - data: The encrypted data to decrypt
     - key: The key to use for decryption
   - Returns: The decrypted data
   - Throws: CryptoError if decryption fails
   */
  public func decrypt(data: Data, using key: Data) async throws -> Data {
    let context = {
      var metadata = LogMetadataDTOCollection()
      metadata = metadata.withPrivate(key: "dataSize", value: String(data.count))
      metadata = metadata.withPrivate(key: "keySize", value: String(key.count))
      return CoreLogContext(
        source: "CryptoServiceAdapter.decrypt",
        metadata: metadata
      )
    }()
    
    await logger.debug("Decrypting data", context: context)
    
    do {
      let decryptionOptions = EncryptionOptions(
        algorithm: .aes256GCM,
        key: key
      )
      
      let result = try await cryptoService.decrypt(
        data: data,
        options: decryptionOptions
      )
      
      await logger.debug("Data decrypted successfully", context: context)
      return result
    } catch {
      let loggableError = LoggableErrorDTO(
        error: error,
        message: "Failed to decrypt data",
        details: "Decryption operation failed in adapter"
      )
      
      await logger.error(
        loggableError,
        context: context,
        privacyLevel: .private
      )
      
      throw adaptError(error)
    }
  }

  /**
   Generates a random encryption key of the specified size

   Delegates to the underlying crypto service implementation.

   - Parameter size: The size of the key to generate in bytes
   - Returns: A random key of the specified size
   - Throws: CryptoError if key generation fails
   */
  public func generateKey(size: Int) async throws -> Data {
    let context = {
      var metadata = LogMetadataDTOCollection()
      metadata = metadata.withPublic(key: "keySize", value: String(size))
      return CoreLogContext(
        source: "CryptoServiceAdapter.generateKey",
        metadata: metadata
      )
    }()
    
    await logger.debug("Generating random encryption key", context: context)
    
    do {
      let result = try await cryptoService.generateRandomBytes(count: size)
      
      await logger.debug("Random encryption key generated successfully", context: context)
      return result
    } catch {
      let loggableError = LoggableErrorDTO(
        error: error,
        message: "Failed to generate random key",
        details: "Key generation failed in adapter"
      )
      
      await logger.error(
        loggableError,
        context: context,
        privacyLevel: .private
      )
      
      throw adaptError(error)
    }
  }

  /**
   Derives a key from the provided source material

   Delegates to the underlying crypto service implementation.

   - Parameters:
     - password: The password or source material to derive from
     - salt: Salt to use in the derivation process
     - iterations: Number of iterations to use in the derivation
     - keySize: Size of the output key in bytes
   - Returns: The derived key
   - Throws: CryptoError if key derivation fails
   */
  public func deriveKey(
    from password: String,
    salt: Data,
    iterations: Int,
    keySize: Int
  ) async throws -> Data {
    let context = {
      var metadata = LogMetadataDTOCollection()
      // Not logging password, even in private logging
      metadata = metadata.withPublic(key: "saltSize", value: String(salt.count))
      metadata = metadata.withPublic(key: "iterations", value: String(iterations))
      metadata = metadata.withPublic(key: "keySize", value: String(keySize))
      return CoreLogContext(
        source: "CryptoServiceAdapter.deriveKey",
        metadata: metadata
      )
    }()
    
    await logger.debug("Deriving key from password", context: context)
    
    do {
      let derivationOptions = KeyDerivationOptions(
        algorithm: .pbkdf2,
        iterations: iterations,
        salt: salt,
        keySize: keySize
      )
      
      let result = try await cryptoService.deriveKey(
        from: password.data(using: .utf8) ?? Data(),
        options: derivationOptions
      )
      
      await logger.debug("Key derived successfully", context: context)
      return result
    } catch {
      let loggableError = LoggableErrorDTO(
        error: error,
        message: "Failed to derive key",
        details: "Key derivation failed in adapter"
      )
      
      await logger.error(
        loggableError,
        context: context,
        privacyLevel: .private
      )
      
      throw adaptError(error)
    }
  }
  
  // MARK: - Private Methods
  
  /**
   Adapts domain-specific errors to the core error domain
   
   - Parameter error: The original error to adapt
   - Returns: A CoreError representing the adapted error
   */
  private func adaptError(_ error: Error) -> Error {
    // If it's already a CoreError, return it directly
    if let coreError = error as? CoreError {
      return coreError
    }
    
    // Map domain-specific errors to core errors
    if let cryptoError = error as? CryptoError {
      switch cryptoError {
      case .encryptionFailed(let message):
        return CoreError.initialisation(message: "Encryption failed: \(message)")
      case .decryptionFailed(let message):
        return CoreError.initialisation(message: "Decryption failed: \(message)")
      case .keyGenerationFailed(let message):
        return CoreError.initialisation(message: "Key generation failed: \(message)")
      case .keyDerivationFailed(let message):
        return CoreError.initialisation(message: "Key derivation failed: \(message)")
      case .randomGenerationFailed(let message):
        return CoreError.initialisation(message: "Random generation failed: \(message)")
      case .invalidParameters(let message):
        return CoreError.invalidState(message: "Invalid crypto parameters: \(message)",
                                     currentState: .error)
      }
    }
    
    // For any other error, wrap it in a generic message
    return CoreError.initialisation(
      message: "Crypto operation failed: \(error.localizedDescription)"
    )
  }
}
