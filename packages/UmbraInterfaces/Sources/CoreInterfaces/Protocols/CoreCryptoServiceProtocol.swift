import Foundation

/**
 # Core Cryptographic Service Protocol
 
 This protocol defines a simplified interface for cryptographic operations required by Core modules.
 
 ## Purpose
 
 - Provides an abstraction layer over the full cryptographic service implementation
 - Isolates Core modules from changes in the cryptographic implementation details
 - Follows the adapter pattern to reduce coupling between modules
 
 ## Implementation Notes
 
 This protocol should be implemented by an adapter class that delegates to the actual
 CryptoServiceProtocol implementation, converting between simplified Core types and
 security-specific types as needed.
 */
public protocol CoreCryptoServiceProtocol: Sendable {
    /**
     Initialises the crypto service
     
     Performs any required setup for the cryptographic service.
     
     - Throws: Error if initialisation fails
     */
    func initialise() async throws
    
    /**
     Encrypts data using the provided key
     
     - Parameters:
         - data: Data to encrypt
         - key: Encryption key
     - Returns: Encrypted data
     - Throws: Error if encryption fails
     */
    func encrypt(data: Data, key: Data) async throws -> Data
    
    /**
     Decrypts data using the provided key
     
     - Parameters:
         - data: Data to decrypt
         - key: Decryption key
     - Returns: Decrypted data
     - Throws: Error if decryption fails
     */
    func decrypt(data: Data, key: Data) async throws -> Data
    
    /**
     Generates a new key of specified size
     
     - Parameter size: Key size in bits
     - Returns: Generated key data
     - Throws: Error if key generation fails
     */
    func generateKey(size: Int) async throws -> Data
}
