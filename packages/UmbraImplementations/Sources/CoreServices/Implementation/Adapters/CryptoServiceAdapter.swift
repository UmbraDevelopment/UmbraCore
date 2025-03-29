import CoreInterfaces
import CryptoInterfaces
import Foundation
import UmbraErrors

/**
 # Crypto Service Adapter

 This class implements the adapter pattern to bridge between the CoreCryptoServiceProtocol
 and the full CryptoServiceProtocol implementation.

 ## Purpose

 - Provides a simplified interface for core modules to access cryptographic functionality
 - Delegates operations to the actual cryptographic implementation
 - Converts between data types as necessary

 ## Design Pattern

 This adapter follows the classic adapter design pattern, where it implements
 one interface (CoreCryptoServiceProtocol) while wrapping an instance of another
 interface (CryptoServiceProtocol).
 */
public class CryptoServiceAdapter: CoreInterfaces.CoreCryptoServiceProtocol {
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

   Delegates to the underlying crypto service implementation.

   - Throws: CryptoError if initialisation fails
   */
  public func initialise() async throws {
    try await cryptoService.initialise()
  }

  /**
   Encrypts data using the provided key

   Delegates to the underlying crypto service implementation.

   - Parameters:
       - data: Data to encrypt
       - key: Encryption key
   - Returns: Encrypted data
   - Throws: CryptoError if encryption fails
   */
  public func encrypt(data: Data, key: Data) async throws -> Data {
    try await cryptoService.encrypt(data: data, key: key)
  }

  /**
   Decrypts data using the provided key

   Delegates to the underlying crypto service implementation.

   - Parameters:
       - data: Data to decrypt
       - key: Decryption key
   - Returns: Decrypted data
   - Throws: CryptoError if decryption fails
   */
  public func decrypt(data: Data, key: Data) async throws -> Data {
    try await cryptoService.decrypt(data: data, key: key)
  }

  /**
   Generates a new key of specified size

   Delegates to the underlying crypto service implementation.

   - Parameter size: Key size in bits
   - Returns: Generated key data
   - Throws: CryptoError if key generation fails
   */
  public func generateKey(size: Int) async throws -> Data {
    try await cryptoService.generateKey(size: size)
  }
}
