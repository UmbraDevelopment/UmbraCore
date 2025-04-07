/**
 # CryptoProviderProtocol
 
 Defines the interface for cryptographic providers in the Alpha Dot Five architecture.
 This protocol abstracts the core cryptographic capabilities required by various
 security implementations.
 
 Providers conforming to this protocol can leverage different cryptographic backends
 whilst presenting a unified interface to the rest of the system.
 */

import CoreSecurityTypes
import DomainSecurityTypes
import Foundation

/// Protocol defining the interface for cryptographic providers
public protocol CryptoProviderProtocol: Sendable {
    /**
     Generates random data of the specified length
     
     - Parameter length: The length of the random data to generate
     - Returns: The generated random data or an error
     */
    func generateRandomData(length: Int) async -> Result<Data, Error>
    
    /**
     Encrypts data using the provided key and options
     
     - Parameters:
        - data: The data to encrypt
        - key: The encryption key data
        - options: Configuration options for the encryption operation
     - Returns: The encrypted data or an error
     */
    func encrypt(
        data: Data,
        key: Data,
        options: CoreSecurityTypes.EncryptionOptions?
    ) async -> Result<Data, Error>
    
    /**
     Decrypts data using the provided key and options
     
     - Parameters:
        - data: The encrypted data to decrypt
        - key: The decryption key data
        - options: Configuration options for the decryption operation
     - Returns: The decrypted data or an error
     */
    func decrypt(
        data: Data,
        key: Data,
        options: CoreSecurityTypes.EncryptionOptions?
    ) async -> Result<Data, Error>
    
    /**
     Computes a hash of the provided data
     
     - Parameters:
        - data: The data to hash
        - algorithm: The hashing algorithm to use
     - Returns: The computed hash or an error
     */
    func hash(
        data: Data,
        algorithm: CoreSecurityTypes.HashAlgorithm
    ) async -> Result<Data, Error>
    
    /**
     Generates a cryptographic key for the specified purpose
     
     - Parameters:
        - keySize: The size of the key in bits
        - purpose: The intended purpose of the key
     - Returns: The generated key data or an error
     */
    func generateKey(
        keySize: Int,
        purpose: CoreSecurityTypes.KeyPurpose
    ) async -> Result<Data, Error>
}
