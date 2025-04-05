import CoreInterfaces
import CryptoInterfaces
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
    // Convert to SecureBytes
    let secureData=SecureBytes(data: data)
    let secureKey=SecureBytes(data: key)

    // Generate a secure random IV
    let secureIV=try await cryptoService.generateSecureRandomBytes(length: 16)

    // Perform encryption
    let encryptedResult=try await cryptoService.encrypt(secureData, using: secureKey, iv: secureIV)

    // Create a combined output that includes the IV and encrypted data
    var result=Data()
    result.append(secureIV.extractUnderlyingData()) // IV first
    result.append(encryptedResult.extractUnderlyingData()) // Then encrypted data

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
    guard data.count > 16 else {
      throw CryptoError.invalidInput(reason: "Data too short, missing IV")
    }

    // Extract IV and encrypted data
    let iv=data.prefix(16)
    let encryptedData=data.suffix(from: 16)

    // Convert to SecureBytes
    let secureIV=SecureBytes(data: iv)
    let secureEncryptedData=SecureBytes(data: encryptedData)
    let secureKey=SecureBytes(data: key)

    // Perform decryption
    let decryptedResult=try await cryptoService.decrypt(
      secureEncryptedData,
      using: secureKey,
      iv: secureIV
    )

    return decryptedResult.extractUnderlyingData()
  }

  /**
   Generates a secure random key of the specified length

   Delegates to the underlying crypto service implementation.

   - Parameter length: The length of the key in bytes
   - Returns: A secure random key
   - Throws: CryptoError if key generation fails
   */
  public func generateKey(length: Int) async throws -> Data {
    let key=try await cryptoService.generateSecureRandomKey(length: length)
    return key.extractUnderlyingData()
  }

  /**
   Computes a hash of the provided data

   Delegates to the underlying crypto service for hashing functionality.

   - Parameter data: The data to hash
   - Returns: The computed hash
   - Throws: CryptoError if hashing fails
   */
  public func hash(data: Data) async throws -> Data {
    // Convert to SecureBytes
    let secureData=SecureBytes(data: data)

    // We don't have a direct hash method in the CryptoServiceProtocol shown here,
    // so we would need to use the appropriate method from the underlying implementation
    // or extend the protocol. For this example, we'll throw an unimplemented error.
    throw CryptoError.operationFailed("Hash operation not implemented")
  }
}
