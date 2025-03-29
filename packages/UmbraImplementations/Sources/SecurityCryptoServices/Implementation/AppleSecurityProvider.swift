import Foundation
import SecurityCoreInterfaces
import SecurityCoreTypes
import SecurityTypes

#if canImport(CryptoKit)
import CryptoKit

/**
 # AppleSecurityProvider
 
 Native Apple security provider implementation using the CryptoKit framework.
 
 This provider offers high-performance cryptographic operations optimised for
 Apple platforms, with hardware acceleration on supported devices. It provides
 modern cryptographic algorithms and follows Apple's security best practices.
 
 ## Security Features
 
 - Uses AES-GCM for authenticated encryption
 - Provides secure key generation and management
 - Utilises hardware acceleration where available
 - Uses modern cryptographic hash functions
 
 ## Platform Support
 
 This provider is only available on Apple platforms that support CryptoKit:
 - macOS 10.15+
 - iOS 13.0+
 - tvOS 13.0+
 - watchOS 6.0+
 */
public struct AppleSecurityProvider: EncryptionProviderProtocol {
    /// The type of provider implementation
    public let providerType: SecurityProviderType = .apple
    
    /// Initialises a new Apple security provider
    public init() {}
    
    /**
     Encrypts plaintext using AES-GCM via CryptoKit.
     
     - Parameters:
        - plaintext: Data to encrypt
        - key: Encryption key
        - iv: Nonce for encryption (12 bytes for AES-GCM)
        - config: Additional configuration options
     - Returns: Encrypted data
     - Throws: CryptoError if encryption fails
     */
    public func encrypt(plaintext: Data, key: Data, iv: Data, config: SecurityConfigDTO) throws -> Data {
        // Validate key size
        guard let keySize = validateKeySize(key.count, algorithm: config.algorithm) else {
            throw SecurityProtocolError.invalidInput("Invalid key size for algorithm \(config.algorithm)")
        }
        
        // Validate nonce/IV
        guard iv.count == 12 else {
            throw SecurityProtocolError.invalidInput("Invalid nonce size, must be 12 bytes for AES-GCM")
        }
        
        // Set up symmetric key
        let symmetricKey: SymmetricKey
        switch keySize {
        case 128:
            symmetricKey = SymmetricKey(data: key)
        case 192:
            symmetricKey = SymmetricKey(data: key)
        case 256:
            symmetricKey = SymmetricKey(data: key)
        default:
            throw SecurityProtocolError.invalidInput("Unsupported key size: \(keySize) bits")
        }
        
        // Create AES-GCM nonce
        let nonce = try AES.GCM.Nonce(data: iv)
        
        // Perform encryption
        let sealedBox = try AES.GCM.seal(plaintext, using: symmetricKey, nonce: nonce)
        
        // Return combined data (nonce + ciphertext + tag)
        guard let combined = sealedBox.combined else {
            throw SecurityProtocolError.cryptographicError("Failed to combine encrypted data components")
        }
        
        return combined
    }
    
    /**
     Decrypts ciphertext using AES-GCM via CryptoKit.
     
     - Parameters:
        - ciphertext: Data to decrypt (must include nonce and tag)
        - key: Decryption key
        - iv: Nonce for decryption (ignored as it's included in the ciphertext)
        - config: Additional configuration options
     - Returns: Decrypted plaintext
     - Throws: CryptoError if decryption fails
     */
    public func decrypt(ciphertext: Data, key: Data, iv: Data, config: SecurityConfigDTO) throws -> Data {
        // Validate key size
        guard let keySize = validateKeySize(key.count, algorithm: config.algorithm) else {
            throw SecurityProtocolError.invalidInput("Invalid key size for algorithm \(config.algorithm)")
        }
        
        // Set up symmetric key
        let symmetricKey: SymmetricKey
        switch keySize {
        case 128:
            symmetricKey = SymmetricKey(data: key)
        case 192:
            symmetricKey = SymmetricKey(data: key)
        case 256:
            symmetricKey = SymmetricKey(data: key)
        default:
            throw SecurityProtocolError.invalidInput("Unsupported key size: \(keySize) bits")
        }
        
        // Create sealed box from combined data
        let sealedBox = try AES.GCM.SealedBox(combined: ciphertext)
        
        // Perform decryption
        let plaintext = try AES.GCM.open(sealedBox, using: symmetricKey)
        
        return plaintext
    }
    
    /**
     Generates a cryptographic key of the specified size using CryptoKit.
     
     - Parameters:
        - size: Key size in bits (128, 192, or 256 for AES)
        - config: Additional configuration options
     - Returns: Generated key data
     - Throws: CryptoError if key generation fails
     */
    public func generateKey(size: Int, config: SecurityConfigDTO) throws -> Data {
        // Validate key size
        guard size == 128 || size == 192 || size == 256 else {
            throw SecurityProtocolError.invalidInput("Invalid key size, must be 128, 192, or 256 bits")
        }
        
        // Generate key of appropriate size
        let keyBytes = size / 8
        let symmetricKey = SymmetricKey(size: SymmetricKeySize(bitCount: size))
        
        // Extract key data
        let keyData = symmetricKey.withUnsafeBytes { Data($0) }
        
        // Ensure we got the right number of bytes
        guard keyData.count == keyBytes else {
            throw SecurityProtocolError.cryptographicError("Key generation produced incorrect key length")
        }
        
        return keyData
    }
    
    /**
     Generates a random nonce of the specified size using CryptoKit.
     
     - Parameters:
        - size: Nonce size in bytes (typically 12 for AES-GCM)
     - Returns: Generated nonce data
     - Throws: CryptoError if nonce generation fails
     */
    public func generateIV(size: Int) throws -> Data {
        guard size > 0 else {
            throw SecurityProtocolError.invalidInput("IV size must be greater than 0")
        }
        
        if size == 12 {
            // Use AES.GCM.Nonce for optimal generation
            let nonce = AES.GCM.Nonce()
            return Data(nonce)
        } else {
            // For other sizes, use secure random generation
            var nonceData = Data(count: size)
            let result = nonceData.withUnsafeMutableBytes { 
                SecRandomCopyBytes(kSecRandomDefault, size, $0.baseAddress!)
            }
            
            guard result == errSecSuccess else {
                throw SecurityProtocolError.cryptographicError("IV generation failed with status \(result)")
            }
            
            return nonceData
        }
    }
    
    /**
     Creates a cryptographic hash of the input data using CryptoKit.
     
     - Parameters:
        - data: Data to hash
        - algorithm: Hash algorithm to use (SHA256, SHA384, SHA512)
     - Returns: Hash value
     - Throws: CryptoError if hashing fails
     */
    public func hash(data: Data, algorithm: String) throws -> Data {
        switch algorithm.uppercased() {
        case "SHA256":
            let digest = SHA256.hash(data: data)
            return Data(digest)
            
        case "SHA384":
            let digest = SHA384.hash(data: data)
            return Data(digest)
            
        case "SHA512":
            let digest = SHA512.hash(data: data)
            return Data(digest)
            
        default:
            throw SecurityProtocolError.unsupportedOperation(name: "Hash algorithm \(algorithm)")
        }
    }
    
    // MARK: - Private Helpers
    
    private func validateKeySize(_ keySize: Int, algorithm: String) -> Int? {
        let keySizeBits = keySize * 8
        
        switch algorithm.uppercased() {
        case "AES":
            if keySizeBits == 128 || keySizeBits == 192 || keySizeBits == 256 {
                return keySizeBits
            }
        default:
            break
        }
        
        return nil
    }
}
#endif
