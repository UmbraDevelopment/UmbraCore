import CommonCrypto
import CoreSecurityTypes
import CryptoInterfaces
import DomainSecurityTypes
import Foundation
import LoggingInterfaces
import LoggingTypes
import Security

/**
 Command for deriving cryptographic keys from existing keys.
 
 This command implements high-security key derivation with multiple algorithms.
 It follows the Alpha Dot Five architecture principles with privacy-aware
 logging and strong error handling.
 */
public class DeriveKeyCommand: BaseCryptoCommand, CryptoCommand {
    /// The type of result returned by this command
    public typealias ResultType = CryptoKey
    
    /// The identifier of the source key
    private let sourceKeyIdentifier: String
    
    /// Optional salt for key derivation
    private let salt: [UInt8]?
    
    /// Optional context information for key derivation
    private let info: [UInt8]?
    
    /// The type of key to derive
    private let keyType: KeyType
    
    /// Optional identifier for the derived key
    private let targetIdentifier: String?
    
    /**
     Initialises a new derive key command.
     
     - Parameters:
        - sourceKeyIdentifier: The identifier of the source key
        - salt: Optional salt for key derivation
        - info: Optional context information for key derivation
        - keyType: The type of key to derive
        - targetIdentifier: Optional identifier for the derived key
        - secureStorage: Secure storage for cryptographic materials
        - logger: Optional logger for operation tracking and auditing
     */
    public init(
        sourceKeyIdentifier: String,
        salt: [UInt8]? = nil,
        info: [UInt8]? = nil,
        keyType: KeyType,
        targetIdentifier: String? = nil,
        secureStorage: SecureStorageProtocol,
        logger: LoggingProtocol? = nil
    ) {
        self.sourceKeyIdentifier = sourceKeyIdentifier
        self.salt = salt
        self.info = info
        self.keyType = keyType
        self.targetIdentifier = targetIdentifier
        super.init(secureStorage: secureStorage, logger: logger)
    }
    
    /**
     Executes the key derivation operation.
     
     - Parameters:
        - context: Logging context for the operation
        - operationID: Unique identifier for this operation instance
     - Returns: The derived cryptographic key
     */
    public func execute(
        context: LogContextDTO,
        operationID: String
    ) async -> Result<CryptoKey, SecurityStorageError> {
        // Create a log context with proper privacy classification
        let logContext = createLogContext(
            operation: "deriveKey",
            correlationID: operationID,
            additionalMetadata: [
                "sourceKeyIdentifier": (value: sourceKeyIdentifier, privacyLevel: .private),
                "keyType": (value: keyType.rawValue, privacyLevel: .public),
                "saltProvided": (value: salt != nil ? "true" : "false", privacyLevel: .public),
                "infoProvided": (value: info != nil ? "true" : "false", privacyLevel: .public)
            ]
        )
        
        await logDebug("Starting key derivation operation", context: logContext)
        
        // Retrieve the source key
        let keyResult = await secureStorage.retrieveSecureData(identifier: sourceKeyIdentifier)
        
        switch keyResult {
        case .success(let sourceKeyData):
            do {
                // Perform the key derivation based on the key type
                let derivedKeyData: [UInt8]
                var actualSalt = salt
                
                // Generate salt if not provided
                if actualSalt == nil {
                    actualSalt = try generateRandomBytes(count: 16)
                }
                
                switch keyType {
                case .aes128, .aes256:
                    // Determine the key size based on key type
                    let keySize: Int = keyType == .aes256 ? 32 : 16
                    
                    // Derive the key using PBKDF2 or HKDF
                    derivedKeyData = try deriveKeyUsingPBKDF2(
                        sourceKey: sourceKeyData,
                        salt: actualSalt!,
                        keySize: keySize
                    )
                    
                case .hmacSHA256, .hmacSHA512:
                    // Determine the key size based on key type
                    let keySize: Int = keyType == .hmacSHA512 ? 64 : 32
                    
                    // Derive the key using HKDF
                    derivedKeyData = try deriveKeyUsingHKDF(
                        sourceKey: sourceKeyData,
                        salt: actualSalt!,
                        info: info,
                        keySize: keySize
                    )
                    
                case .ecdsaP256, .ecdsaP384, .ecdsaP521, .rsaEncryption, .rsaSignature:
                    // Asymmetric keys cannot be derived using simple KDFs
                    throw SecurityStorageError.operationFailed(
                        "Key derivation not supported for asymmetric key types"
                    )
                }
                
                // Generate a unique identifier if not provided
                let keyIdentifier = targetIdentifier ?? UUID().uuidString
                
                // Store the derived key in secure storage
                let storeResult = await secureStorage.storeSecureData(derivedKeyData, identifier: keyIdentifier)
                
                switch storeResult {
                case .success:
                    // Create the key object
                    let key = CryptoKey(
                        identifier: keyIdentifier,
                        type: keyType,
                        size: derivedKeyData.count * 8,  // Convert bytes to bits
                        creationDate: Date()
                    )
                    
                    await logInfo(
                        "Successfully derived \(keyType.rawValue) key",
                        context: logContext.adding(
                            key: "keyIdentifier",
                            value: keyIdentifier,
                            privacyLevel: .private
                        )
                    )
                    
                    return .success(key)
                    
                case .failure(let error):
                    await logError(
                        "Failed to store derived key: \(error)",
                        context: logContext
                    )
                    return .failure(error)
                }
                
            } catch {
                await logError(
                    "Key derivation failed: \(error.localizedDescription)",
                    context: logContext
                )
                if let securityError = error as? SecurityStorageError {
                    return .failure(securityError)
                } else {
                    return .failure(.operationFailed("Key derivation failed: \(error.localizedDescription)"))
                }
            }
            
        case .failure(let error):
            await logError(
                "Failed to retrieve source key: \(error)",
                context: logContext
            )
            return .failure(error)
        }
    }
    
    /**
     Generates cryptographically secure random bytes.
     
     - Parameter count: Number of bytes to generate
     - Returns: Array of random bytes
     - Throws: Error if generation fails
     */
    private func generateRandomBytes(count: Int) throws -> [UInt8] {
        var randomBytes = [UInt8](repeating: 0, count: count)
        let result = SecRandomCopyBytes(kSecRandomDefault, count, &randomBytes)
        
        guard result == errSecSuccess else {
            throw SecurityStorageError.operationFailed("Failed to generate secure random bytes")
        }
        
        return randomBytes
    }
    
    /**
     Derives a key using PBKDF2 (Password-Based Key Derivation Function 2).
     
     - Parameters:
        - sourceKey: The source key material
        - salt: Salt for the derivation
        - keySize: The size of the derived key in bytes
     - Returns: The derived key bytes
     - Throws: Error if derivation fails
     */
    private func deriveKeyUsingPBKDF2(
        sourceKey: [UInt8],
        salt: [UInt8],
        keySize: Int
    ) throws -> [UInt8] {
        // Set up derivation parameters
        let iterations = 10000  // Minimum recommended for PBKDF2
        var derivedKeyData = [UInt8](repeating: 0, count: keySize)
        
        // Derive the key using PBKDF2
        let status = CCKeyDerivationPBKDF(
            CCPBKDFAlgorithm(kCCPBKDF2),
            sourceKey,
            sourceKey.count,
            salt,
            salt.count,
            CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA256),
            UInt32(iterations),
            &derivedKeyData,
            keySize
        )
        
        guard status == kCCSuccess else {
            throw SecurityStorageError.operationFailed("PBKDF2 key derivation failed with status \(status)")
        }
        
        return derivedKeyData
    }
    
    /**
     Derives a key using HKDF (HMAC-based Key Derivation Function).
     
     - Parameters:
        - sourceKey: The source key material
        - salt: Salt for the derivation
        - info: Optional context information
        - keySize: The size of the derived key in bytes
     - Returns: The derived key bytes
     - Throws: Error if derivation fails
     */
    private func deriveKeyUsingHKDF(
        sourceKey: [UInt8],
        salt: [UInt8],
        info: [UInt8]?,
        keySize: Int
    ) throws -> [UInt8] {
        // HKDF implementation using CommonCrypto
        // This is a simplified implementation of HKDF
        
        // Step 1: HMAC-Extract - Extract a pseudorandom key from the input
        var hmacContext = CCHmacContext()
        CCHmacInit(&hmacContext, CCHmacAlgorithm(kCCHmacAlgSHA256), salt, salt.count)
        CCHmacUpdate(&hmacContext, sourceKey, sourceKey.count)
        var prk = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        CCHmacFinal(&hmacContext, &prk)
        
        // Step 2: HMAC-Expand - Expand the pseudorandom key to the desired output length
        var derivedKeyData = [UInt8]()
        let hashLength = Int(CC_SHA256_DIGEST_LENGTH)
        let iterations = (keySize + hashLength - 1) / hashLength
        
        var lastBlock = [UInt8]()
        for i in 1...iterations {
            var hmacContext = CCHmacContext()
            CCHmacInit(&hmacContext, CCHmacAlgorithm(kCCHmacAlgSHA256), prk, prk.count)
            CCHmacUpdate(&hmacContext, lastBlock, lastBlock.count)
            if let infoData = info {
                CCHmacUpdate(&hmacContext, infoData, infoData.count)
            }
            let counter: UInt8 = UInt8(i)
            CCHmacUpdate(&hmacContext, [counter], 1)
            
            var block = [UInt8](repeating: 0, count: hashLength)
            CCHmacFinal(&hmacContext, &block)
            
            lastBlock = block
            derivedKeyData.append(contentsOf: block)
        }
        
        // Truncate to the requested key size
        return [UInt8](derivedKeyData[0..<keySize])
    }
}
