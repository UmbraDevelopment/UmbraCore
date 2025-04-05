import CoreInterfaces
import CryptoInterfaces
import DomainSecurityTypes
import Foundation
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

   This is the actual implementation that performs the cryptographic operations.
   */
  private let cryptoService: CryptoInterfaces.CryptoServiceProtocol

  // MARK: - Initialisation

  /**
   Initialises a new adapter with the provided crypto service

   - Parameter cryptoService: The crypto service implementation to adapt
   */
  public init(cryptoService: CryptoInterfaces.CryptoServiceProtocol) {
    self.cryptoService=cryptoService
  }

  // MARK: - CoreCryptoServiceProtocol Implementation

  /**
   Initialises the crypto service

   This method ensures the underlying crypto service is properly initialised.
   With actor-based implementations, this may be a no-op as initialisation
   is often handled at creation time.

   - Throws: CryptoError if initialisation fails
   */
  public func initialise() async throws {
    // No explicit initialisation needed for modern actor-based crypto services
  }

  /**
   Encrypts data with the provided key

   Delegates to the underlying crypto service implementation.

   - Parameters:
     - data: The data to encrypt
     - key: The encryption key
   - Returns: The encrypted data
   - Throws: CryptoError if encryption fails
   */
  public func encrypt(data: Data, with key: Data) async throws -> Data {
    // Convert to SendableCryptoMaterial
    let secureMaterial=SendableCryptoMaterial(bytes: [UInt8](data))
    let keyMaterial=SendableCryptoMaterial(bytes: [UInt8](key))

    // Generate a secure random IV
    let ivMaterial=try await cryptoService.generateSecureRandomBytes(length: 16)

    // Perform encryption
    let encryptedResult=try await cryptoService.encrypt(
      secureMaterial,
      using: keyMaterial,
      iv: ivMaterial
    )

    // Create a combined output that includes the IV and encrypted data
    var result=Data()
    result.append(Data(ivMaterial.toByteArray())) // IV first
    result.append(Data(encryptedResult.toByteArray())) // Then encrypted data

    return result
  }

  /**
   Decrypts data with the provided key

   Delegates to the underlying crypto service implementation.

   - Parameters:
     - data: The data to decrypt (includes IV + encrypted data)
     - key: The decryption key
   - Returns: The decrypted data
   - Throws: CryptoError if decryption fails
   */
  public func decrypt(data: Data, with key: Data) async throws -> Data {
    // Extract IV (first 16 bytes) and encrypted data (remaining bytes)
    guard data.count > 16 else {
      throw CryptoError.invalidInput("Data too short for IV+ciphertext format")
    }

    let iv=data.prefix(16)
    let encryptedData=data.suffix(from: 16)

    // Convert to SendableCryptoMaterial
    let ivMaterial=SendableCryptoMaterial(bytes: [UInt8](iv))
    let encryptedMaterial=SendableCryptoMaterial(bytes: [UInt8](encryptedData))
    let keyMaterial=SendableCryptoMaterial(bytes: [UInt8](key))

    // Perform decryption
    let decryptedResult=try await cryptoService.decrypt(
      encryptedMaterial,
      using: keyMaterial,
      iv: ivMaterial
    )

    // Return the decrypted data
    return Data(decryptedResult.toByteArray())
  }

  /**
   Generates a secure random key of the specified length

   Delegates to the underlying crypto service implementation.

   - Parameter length: The length of the key in bytes
   - Returns: The generated key
   - Throws: CryptoError if key generation fails
   */
  public func generateKey(length: Int) async throws -> Data {
    // Generate secure random bytes using the crypto service
    let keyMaterial=try await cryptoService.generateSecureRandomBytes(length: length)

    // Return the key as Data
    return Data(keyMaterial.toByteArray())
  }

  /**
   Computes a hash of the provided data using the specified algorithm

   Delegates to the underlying crypto service implementation.

   - Parameters:
     - data: The data to hash
     - algorithm: The hashing algorithm to use
   - Returns: The hash as data
   - Throws: CryptoError if hashing fails
   */
  public func hash(data: Data, algorithm: String) async throws -> Data {
    // Convert to SendableCryptoMaterial
    let secureMaterial=SendableCryptoMaterial(bytes: [UInt8](data))

    // Compute the hash
    let hashResult=try await cryptoService.hash(secureMaterial, algorithm: algorithm)

    // Return the hash as Data
    return Data(hashResult.toByteArray())
  }

  /**
   Derives a key from the provided source material

   Delegates to the underlying crypto service implementation.

   - Parameters:
     - sourceMaterial: The source material for key derivation
     - salt: Optional salt for key derivation
     - iterations: Number of iterations for key derivation
     - length: The length of the derived key in bytes
   - Returns: The derived key
   - Throws: CryptoError if key derivation fails
   */
  public func deriveKey(
    from sourceMaterial: Data,
    salt: Data?,
    iterations: Int,
    length: Int
  ) async throws -> Data {
    // Convert source material to SendableCryptoMaterial
    let sourceSecureMaterial=SendableCryptoMaterial(bytes: [UInt8](sourceMaterial))

    // Convert salt to SendableCryptoMaterial if provided
    let saltMaterial: SendableCryptoMaterial?=if let salt {
      SendableCryptoMaterial(bytes: [UInt8](salt))
    } else {
      nil
    }

    // Derive the key
    let derivedKeyMaterial=try await cryptoService.deriveKey(
      from: sourceSecureMaterial,
      salt: saltMaterial,
      iterations: iterations,
      keyLength: length
    )

    // Return the derived key as Data
    return Data(derivedKeyMaterial.toByteArray())
  }
}
