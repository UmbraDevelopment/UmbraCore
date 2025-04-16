import Foundation
import CoreSecurityTypes
import SecurityCoreInterfaces
import CryptoKit

/// Bridge between UmbraCore's cryptographic abstractions and Apple's CryptoKit.
///
/// This utility provides conversion methods and wrappers to bridge between
/// UmbraCore's cryptographic types and Apple's CryptoKit implementations.
/// It allows for type-safe conversion and operation using Apple's highly
/// optimised cryptographic primitives focused on AES-GCM with hardware 
/// acceleration on Apple Silicon.
public enum CryptoKitBridge {
    
    /// Initialises the CryptoKit bridge.
    ///
    /// This method performs any necessary setup for the CryptoKit bridge.
    public static func initialise() {
        // No initialisation required for CryptoKit
    }
    
    // MARK: - AES-GCM Operations
    
    /// Performs AES-GCM encryption using Apple's CryptoKit.
    ///
    /// This implementation leverages hardware acceleration on Apple Silicon
    /// for optimal performance and security. AES-GCM provides both confidentiality
    /// and authenticity protection through authenticated encryption.
    ///
    /// - Parameters:
    ///   - data: The data to encrypt
    ///   - key: The encryption key (must be 32 bytes for AES-256)
    ///   - nonce: Optional nonce (if nil, a secure random nonce will be generated)
    ///   - authenticatedData: Optional additional authenticated data
    /// - Returns: Result containing the encrypted data with authentication tag and nonce
    public static func encryptAESGCM(
        data: Data,
        key: Data,
        nonce: Data? = nil,
        authenticatedData: Data? = nil
    ) -> Result<(encryptedData: Data, nonce: Data), CryptoOperationError> {
        // Validate key
        guard key.count == 32 else {
            return .failure(CryptoOperationError(
                code: .invalidKey,
                message: "AES-GCM requires a 32-byte (256-bit) key"
            ))
        }
        
        do {
            // Convert key to SymmetricKey
            let symmetricKey = SymmetricKey(data: key)
            
            // Create or use provided nonce
            let aeadNonce: AES.GCM.Nonce
            if let providedNonce = nonce {
                guard providedNonce.count == 12 else {
                    return .failure(CryptoOperationError(
                        code: .invalidInputData,
                        message: "AES-GCM nonce must be 12 bytes"
                    ))
                }
                aeadNonce = try AES.GCM.Nonce(data: providedNonce)
            } else {
                aeadNonce = AES.GCM.Nonce()
            }
            
            // Perform encryption
            let sealedBox: AES.GCM.SealedBox
            if let authenticatedData = authenticatedData {
                sealedBox = try AES.GCM.seal(
                    data,
                    using: symmetricKey,
                    nonce: aeadNonce,
                    authenticating: authenticatedData
                )
            } else {
                sealedBox = try AES.GCM.seal(
                    data,
                    using: symmetricKey,
                    nonce: aeadNonce
                )
            }
            
            // Return encrypted data and nonce
            return .success((sealedBox.ciphertext + sealedBox.tag, Data(aeadNonce)))
            
        } catch {
            return .failure(CryptoOperationError(
                code: .encryptionFailed,
                message: "AES-GCM encryption failed: \(error.localizedDescription)",
                underlyingError: error
            ))
        }
    }
    
    /// Performs AES-GCM decryption using Apple's CryptoKit.
    ///
    /// This implementation leverages hardware acceleration on Apple Silicon
    /// for optimal performance and security, ensuring both confidentiality
    /// and authenticity of the encrypted data.
    ///
    /// - Parameters:
    ///   - encryptedData: The encrypted data with authentication tag
    ///   - key: The encryption key (must be 32 bytes for AES-256)
    ///   - nonce: The nonce used during encryption
    ///   - authenticatedData: Optional additional authenticated data
    /// - Returns: Result containing the decrypted data or an error
    public static func decryptAESGCM(
        encryptedData: Data,
        key: Data,
        nonce: Data,
        authenticatedData: Data? = nil
    ) -> Result<Data, CryptoOperationError> {
        // Validate key
        guard key.count == 32 else {
            return .failure(CryptoOperationError(
                code: .invalidKey,
                message: "AES-GCM requires a 32-byte (256-bit) key"
            ))
        }
        
        // Validate nonce
        guard nonce.count == 12 else {
            return .failure(CryptoOperationError(
                code: .invalidInputData,
                message: "AES-GCM nonce must be 12 bytes"
            ))
        }
        
        // Validate encrypted data (must be at least 16 bytes for the authentication tag)
        guard encryptedData.count >= 16 else {
            return .failure(CryptoOperationError(
                code: .invalidInputData,
                message: "AES-GCM encrypted data must include authentication tag (at least 16 bytes)"
            ))
        }
        
        do {
            // Convert key to SymmetricKey
            let symmetricKey = SymmetricKey(data: key)
            
            // Convert nonce to AES.GCM.Nonce
            let aeadNonce = try AES.GCM.Nonce(data: nonce)
            
            // Split encryptedData into ciphertext and tag
            let ciphertext = encryptedData.prefix(encryptedData.count - 16)
            let tag = encryptedData.suffix(16)
            
            // Create sealed box
            let sealedBox = try AES.GCM.SealedBox(
                nonce: aeadNonce,
                ciphertext: ciphertext,
                tag: tag
            )
            
            // Perform decryption
            if let authenticatedData = authenticatedData {
                return .success(try AES.GCM.open(
                    sealedBox,
                    using: symmetricKey,
                    authenticating: authenticatedData
                ))
            } else {
                return .success(try AES.GCM.open(
                    sealedBox,
                    using: symmetricKey
                ))
            }
            
        } catch CryptoKit.CryptoKitError.authenticationFailure {
            return .failure(CryptoOperationError(
                code: .authenticationFailed,
                message: "AES-GCM authentication failed",
                underlyingError: error
            ))
        } catch {
            return .failure(CryptoOperationError(
                code: .decryptionFailed,
                message: "AES-GCM decryption failed: \(error.localizedDescription)",
                underlyingError: error
            ))
        }
    }
    
    // MARK: - Digital Signatures
    
    /// Represents the type of cryptographic signature to use.
    public enum SignatureType {
        /// Secure Enclave P-256 signature (hardware-backed when available)
        case secureEnclaveP256
        
        /// Curve25519 EdDSA signature (high performance)
        case curve25519
        
        /// P-521 ECDSA signature (higher security level)
        case p521ECDSA
    }
    
    /// Signs data using the specified private key and signature type.
    ///
    /// - Parameters:
    ///   - data: The data to sign
    ///   - privateKey: The private key as raw data
    ///   - signatureType: The type of signature to generate
    /// - Returns: Result containing the signature or an error
    public static func signData(
        data: Data,
        privateKey: Data,
        signatureType: SignatureType
    ) -> Result<Data, CryptoOperationError> {
        do {
            switch signatureType {
            case .secureEnclaveP256:
                // Secure Enclave signatures require a SecureEnclave.P256.Signing.PrivateKey
                // which cannot be directly created from raw data
                return .failure(CryptoOperationError(
                    code: .invalidKey,
                    message: "Secure Enclave P-256 signatures must use a key stored in the Secure Enclave"
                ))
                
            case .curve25519:
                // Create Curve25519 private key
                let privateKey = try Curve25519.Signing.PrivateKey(rawRepresentation: privateKey)
                let signature = try privateKey.signature(for: data)
                return .success(Data(signature))
                
            case .p521ECDSA:
                // Create P-521 private key
                let privateKey = try P521.Signing.PrivateKey(rawRepresentation: privateKey)
                let signature = try privateKey.signature(for: data)
                return .success(Data(signature.rawRepresentation))
            }
        } catch {
            return .failure(CryptoOperationError(
                code: .signingFailed,
                message: "Signing operation failed: \(error.localizedDescription)",
                underlyingError: error
            ))
        }
    }
    
    /// Alias for signData to support existing code
    public static func generateSignature(
        for data: Data,
        using privateKey: Data,
        signatureType: SignatureType
    ) -> Result<Data, CryptoOperationError> {
        return signData(data: data, privateKey: privateKey, signatureType: signatureType)
    }
    
    /// Verifies a signature against data using the specified public key.
    ///
    /// - Parameters:
    ///   - signature: The signature to verify
    ///   - data: The original data that was signed
    ///   - publicKey: The public key as raw data
    ///   - signatureType: The type of signature to verify
    /// - Returns: Result containing a boolean indicating if the signature is valid
    public static func verifySignature(
        signature: Data,
        data: Data,
        publicKey: Data,
        signatureType: SignatureType
    ) -> Result<Bool, CryptoOperationError> {
        do {
            switch signatureType {
            case .secureEnclaveP256:
                // For Secure Enclave verification, we use a regular P-256 public key
                let publicKey = try P256.Signing.PublicKey(rawRepresentation: publicKey)
                let ecdsaSignature = try P256.Signing.ECDSASignature(rawRepresentation: signature)
                let isValid = publicKey.isValidSignature(ecdsaSignature, for: data)
                return .success(isValid)
                
            case .curve25519:
                // Create Curve25519 public key
                let publicKey = try Curve25519.Signing.PublicKey(rawRepresentation: publicKey)
                let isValid = publicKey.isValidSignature(signature, for: data)
                return .success(isValid)
                
            case .p521ECDSA:
                // Create P-521 public key
                let publicKey = try P521.Signing.PublicKey(rawRepresentation: publicKey)
                let ecdsaSignature = try P521.Signing.ECDSASignature(rawRepresentation: signature)
                let isValid = publicKey.isValidSignature(ecdsaSignature, for: data)
                return .success(isValid)
            }
        } catch {
            return .failure(CryptoOperationError(
                code: .verificationFailed,
                message: "Signature verification failed: \(error.localizedDescription)",
                underlyingError: error
            ))
        }
    }
    
    /// Alias for verifySignature to support existing code
    public static func verifySignature(
        _ signature: Data,
        for data: Data,
        using publicKey: Data, 
        signatureType: SignatureType
    ) -> Result<Bool, CryptoOperationError> {
        return verifySignature(
            signature: signature, 
            data: data, 
            publicKey: publicKey, 
            signatureType: signatureType
        )
    }
    
    // MARK: - Key Derivation Functions
    
    /// Derives a key using HKDF with SHA-512.
    ///
    /// HKDF (HMAC-based Extract-and-Expand Key Derivation Function) is a secure
    /// key derivation function that can be used to derive multiple keys from a
    /// single master key.
    ///
    /// - Parameters:
    ///   - masterKey: The master key to derive from
    ///   - salt: Optional salt value (recommended)
    ///   - info: Optional context information
    ///   - outputByteCount: Number of bytes to derive
    /// - Returns: Result containing the derived key data
    public static func deriveKeyHKDF(
        masterKey: Data,
        salt: Data? = nil,
        info: Data? = nil,
        outputByteCount: Int = 32
    ) -> Result<Data, CryptoOperationError> {
        do {
            // Create a SymmetricKey from the master key
            let symmetricKey = SymmetricKey(data: masterKey)
            
            // Derive key using HKDF
            let derivedKey = HKDF<SHA512>.deriveKey(
                inputKeyMaterial: symmetricKey,
                salt: salt.map { SymmetricKey(data: $0) },
                info: info ?? Data(),
                outputByteCount: outputByteCount
            )
            
            return .success(derivedKey.withUnsafeBytes { Data($0) })
            
        } catch {
            return .failure(CryptoOperationError(
                code: .keyDerivationFailed,
                message: "HKDF key derivation failed: \(error.localizedDescription)",
                underlyingError: error
            ))
        }
    }
    
    // MARK: - HMAC Operations
    
    /// Computes an HMAC-SHA512 for the provided data with the given key.
    ///
    /// - Parameters:
    ///   - data: The data to authenticate
    ///   - key: The key to use for the HMAC
    /// - Returns: Result containing the HMAC or an error
    public static func computeHMACSHA512(
        data: Data,
        key: Data
    ) -> Result<Data, CryptoOperationError> {
        do {
            // Create a symmetric key from the provided key material
            let symmetricKey = SymmetricKey(data: key)
            
            // Compute HMAC
            let authenticationCode = HMAC<SHA512>.authenticationCode(
                for: data,
                using: symmetricKey
            )
            return .success(Data(authenticationCode))
            
        } catch let error {
            return .failure(CryptoOperationError(
                code: .internalError,
                message: "HMAC-SHA512 computation failed: \(error.localizedDescription)",
                underlyingError: error
            ))
        }
    }
    
    /// Alias for computeHMACSHA512 to support existing code
    public static func hmacSHA512(
        data: Data,
        key: Data
    ) -> Result<Data, CryptoOperationError> {
        return computeHMACSHA512(data: data, key: key)
    }
    
    /// Verifies an HMAC-SHA512 for the provided data against the given authentication code.
    ///
    /// - Parameters:
    ///   - authenticationCode: The HMAC authentication code to verify
    ///   - data: The original data
    ///   - key: The key used for the HMAC
    /// - Returns: Result containing a boolean indicating if the HMAC is valid
    public static func verifyHMACSHA512(
        authenticationCode: Data,
        data: Data,
        key: Data
    ) -> Result<Bool, CryptoOperationError> {
        do {
            // Create a symmetric key from the provided key material
            let symmetricKey = SymmetricKey(data: key)
            
            // Convert the authentication code to a comparable format
            // We'll compare our own computed HMAC with the provided one
            let computedAuthCode = HMAC<SHA512>.authenticationCode(
                for: data, 
                using: symmetricKey
            )
            let computedAuthData = Data(computedAuthCode)
            
            // Verify HMAC by comparing with constant-time comparison
            let isValid = constantTimeCompare(computedAuthData, authenticationCode)
            return .success(isValid)
            
        } catch let error {
            return .failure(CryptoOperationError(
                code: .internalError,
                message: "HMAC-SHA512 verification failed: \(error.localizedDescription)",
                underlyingError: error
            ))
        }
    }
    
    /// Performs a constant-time comparison of two Data objects.
    /// This prevents timing attacks when comparing sensitive values like HMACs.
    ///
    /// - Parameters:
    ///   - lhs: First Data object
    ///   - rhs: Second Data object
    /// - Returns: True if the Data objects contain identical bytes
    private static func constantTimeCompare(_ lhs: Data, _ rhs: Data) -> Bool {
        // If lengths differ, they're not equal, but still use constant time
        guard lhs.count == rhs.count else {
            return false
        }
        
        // Convert both to byte arrays
        let lhsBytes = [UInt8](lhs)
        let rhsBytes = [UInt8](rhs)
        
        // Constant-time comparison
        var result: UInt8 = 0
        for i in 0..<lhs.count {
            result |= lhsBytes[i] ^ rhsBytes[i]
        }
        
        return result == 0
    }
    
    // MARK: - Hashing Operations
    
    /// Performs SHA-256 hashing using Apple's CryptoKit.
    ///
    /// - Parameter data: The data to hash
    /// - Returns: The SHA-256 hash as Data
    public static func sha256(data: Data) -> Data {
        return Data(SHA256.hash(data: data))
    }
    
    /// Performs SHA-512 hashing using Apple's CryptoKit.
    ///
    /// - Parameter data: The data to hash
    /// - Returns: The SHA-512 hash as Data
    public static func sha512(data: Data) -> Data {
        return Data(SHA512.hash(data: data))
    }
    
    // MARK: - ChaCha20-Poly1305 Operations
    
    /// Performs ChaCha20-Poly1305 encryption using Apple's CryptoKit.
    ///
    /// - Parameters:
    ///   - data: The data to encrypt
    ///   - key: The encryption key (must be 32 bytes)
    ///   - nonce: Optional nonce (if nil, a secure random nonce will be generated)
    ///   - authenticatedData: Optional additional authenticated data
    /// - Returns: Result containing the encrypted data with authentication tag and nonce
    public static func encryptChaCha20Poly1305(
        data: Data,
        key: Data,
        nonce: Data? = nil,
        authenticatedData: Data? = nil
    ) -> Result<(encryptedData: Data, nonce: Data), CryptoOperationError> {
        // Validate key
        guard key.count == 32 else {
            return .failure(CryptoOperationError(
                code: .invalidKey,
                message: "ChaCha20-Poly1305 requires a 32-byte key"
            ))
        }
        
        do {
            // Convert key to SymmetricKey
            let symmetricKey = SymmetricKey(data: key)
            
            // Create or use provided nonce
            let chachaPolyNonce: ChaChaPoly.Nonce
            if let providedNonce = nonce {
                guard providedNonce.count == 12 else {
                    return .failure(CryptoOperationError(
                        code: .invalidInputData,
                        message: "ChaCha20-Poly1305 nonce must be 12 bytes"
                    ))
                }
                chachaPolyNonce = try ChaChaPoly.Nonce(data: providedNonce)
            } else {
                chachaPolyNonce = ChaChaPoly.Nonce()
            }
            
            // Perform encryption
            let sealedBox: ChaChaPoly.SealedBox
            if let authenticatedData = authenticatedData {
                sealedBox = try ChaChaPoly.seal(
                    data,
                    using: symmetricKey,
                    nonce: chachaPolyNonce,
                    authenticating: authenticatedData
                )
            } else {
                sealedBox = try ChaChaPoly.seal(
                    data,
                    using: symmetricKey,
                    nonce: chachaPolyNonce
                )
            }
            
            // Return encrypted data and nonce
            return .success((sealedBox.ciphertext + sealedBox.tag, Data(chachaPolyNonce)))
            
        } catch {
            return .failure(CryptoOperationError(
                code: .encryptionFailed,
                message: "ChaCha20-Poly1305 encryption failed: \(error.localizedDescription)",
                underlyingError: error
            ))
        }
    }
    
    /// An alias for encryptChaCha20Poly1305 to maintain compatibility with existing code
    public static func encryptChaChaPoly(
        data: Data,
        key: Data,
        nonce: Data? = nil,
        authenticatedData: Data? = nil
    ) -> Result<(encryptedData: Data, nonce: Data), CryptoOperationError> {
        return encryptChaCha20Poly1305(
            data: data,
            key: key,
            nonce: nonce,
            authenticatedData: authenticatedData
        )
    }
    
    /// Performs ChaCha20-Poly1305 decryption using Apple's CryptoKit.
    ///
    /// - Parameters:
    ///   - encryptedData: The encrypted data with authentication tag
    ///   - key: The encryption key (must be 32 bytes)
    ///   - nonce: The nonce used during encryption
    ///   - authenticatedData: Optional additional authenticated data
    /// - Returns: Result containing the decrypted data or an error
    public static func decryptChaCha20Poly1305(
        encryptedData: Data,
        key: Data,
        nonce: Data,
        authenticatedData: Data? = nil
    ) -> Result<Data, CryptoOperationError> {
        // Validate key
        guard key.count == 32 else {
            return .failure(CryptoOperationError(
                code: .invalidKey,
                message: "ChaCha20-Poly1305 requires a 32-byte key"
            ))
        }
        
        // Validate nonce
        guard nonce.count == 12 else {
            return .failure(CryptoOperationError(
                code: .invalidInputData,
                message: "ChaCha20-Poly1305 nonce must be 12 bytes"
            ))
        }
        
        // Validate encrypted data (must be at least 16 bytes for the authentication tag)
        guard encryptedData.count >= 16 else {
            return .failure(CryptoOperationError(
                code: .invalidInputData,
                message: "ChaCha20-Poly1305 encrypted data must include authentication tag (at least 16 bytes)"
            ))
        }
        
        do {
            // Convert key to SymmetricKey
            let symmetricKey = SymmetricKey(data: key)
            
            // Convert nonce to ChaChaPoly.Nonce
            let chachaPolyNonce = try ChaChaPoly.Nonce(data: nonce)
            
            // Split encryptedData into ciphertext and tag
            let ciphertext = encryptedData.prefix(encryptedData.count - 16)
            let tag = encryptedData.suffix(16)
            
            // Create sealed box
            let sealedBox = try ChaChaPoly.SealedBox(
                nonce: chachaPolyNonce,
                ciphertext: ciphertext,
                tag: tag
            )
            
            // Perform decryption
            if let authenticatedData = authenticatedData {
                return .success(try ChaChaPoly.open(
                    sealedBox,
                    using: symmetricKey,
                    authenticating: authenticatedData
                ))
            } else {
                return .success(try ChaChaPoly.open(
                    sealedBox,
                    using: symmetricKey
                ))
            }
            
        } catch CryptoKit.CryptoKitError.authenticationFailure {
            return .failure(CryptoOperationError(
                code: .authenticationFailed,
                message: "ChaCha20-Poly1305 authentication failed",
                underlyingError: error
            ))
        } catch {
            return .failure(CryptoOperationError(
                code: .decryptionFailed,
                message: "ChaCha20-Poly1305 decryption failed: \(error.localizedDescription)",
                underlyingError: error
            ))
        }
    }
    
    /// An alias for decryptChaCha20Poly1305 to maintain compatibility with existing code
    public static func decryptChaChaPoly(
        encryptedData: Data,
        key: Data,
        nonce: Data,
        authenticatedData: Data? = nil
    ) -> Result<Data, CryptoOperationError> {
        return decryptChaCha20Poly1305(
            encryptedData: encryptedData,
            key: key,
            nonce: nonce,
            authenticatedData: authenticatedData
        )
    }
}
