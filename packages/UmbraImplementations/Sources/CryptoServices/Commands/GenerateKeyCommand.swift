import CommonCrypto
import CoreSecurityTypes
import CryptoInterfaces
import DomainSecurityTypes
import Foundation
import LoggingInterfaces
import LoggingTypes
import Security

/**
 Command for generating cryptographic keys.
 
 This command implements high-security key generation with multiple key types.
 It follows the Alpha Dot Five architecture principles with privacy-aware
 logging and strong error handling.
 */
public class GenerateKeyCommand: BaseCryptoCommand, CryptoCommand {
    /// The type of result returned by this command
    public typealias ResultType = CryptoKey
    
    /// The type of key to generate
    private let keyType: KeyType
    
    /// Optional key size in bits
    private let size: Int?
    
    /// Optional predefined identifier for the key
    private let identifier: String?
    
    /**
     Initialises a new generate key command.
     
     - Parameters:
        - keyType: The type of key to generate
        - size: Optional key size in bits
        - identifier: Optional predefined identifier for the key
        - secureStorage: Secure storage for cryptographic materials
        - logger: Optional logger for operation tracking and auditing
     */
    public init(
        keyType: KeyType,
        size: Int? = nil,
        identifier: String? = nil,
        secureStorage: SecureStorageProtocol,
        logger: LoggingProtocol? = nil
    ) {
        self.keyType = keyType
        self.size = size
        self.identifier = identifier
        super.init(secureStorage: secureStorage, logger: logger)
    }
    
    /**
     Executes the key generation operation.
     
     - Parameters:
        - context: Logging context for the operation
        - operationID: Unique identifier for this operation instance
     - Returns: The generated cryptographic key
     */
    public func execute(
        context: LogContextDTO,
        operationID: String
    ) async -> Result<CryptoKey, SecurityStorageError> {
        // Create a log context with proper privacy classification
        let logContext = createLogContext(
            operation: "generateKey",
            correlationID: operationID,
            additionalMetadata: [
                "keyType": (value: keyType.rawValue, privacyLevel: .public),
                "keySize": (value: size != nil ? "\(size!)" : "default", privacyLevel: .public)
            ]
        )
        
        await logDebug("Starting key generation operation", context: logContext)
        
        do {
            // Generate the key material based on key type
            var keyData: [UInt8]
            var actualSize: Int
            
            switch keyType {
            case .aes128:
                actualSize = size ?? 128 / 8  // Default to 128-bit key (16 bytes)
                keyData = try generateRandomBytes(count: actualSize)
                
            case .aes256:
                actualSize = size ?? 256 / 8  // Default to 256-bit key (32 bytes)
                keyData = try generateRandomBytes(count: actualSize)
                
            case .hmacSHA256:
                actualSize = size ?? 256 / 8  // Default to 256-bit key (32 bytes)
                keyData = try generateRandomBytes(count: actualSize)
                
            case .ecdsaP256, .ecdsaP384, .ecdsaP521:
                // ECDSA keys would typically be generated with SecKey APIs
                // This is a simplified placeholder for the implementation
                throw SecurityStorageError.operationFailed("ECDSA key generation not implemented")
                
            case .rsaEncryption, .rsaSignature:
                // RSA keys would typically be generated with SecKey APIs
                // This is a simplified placeholder for the implementation
                throw SecurityStorageError.operationFailed("RSA key generation not implemented")
            }
            
            // Generate a unique identifier if not provided
            let keyIdentifier = identifier ?? UUID().uuidString
            
            // Store the key in secure storage
            let storeResult = await secureStorage.storeSecureData(keyData, identifier: keyIdentifier)
            
            switch storeResult {
            case .success:
                // Create the key object
                let key = CryptoKey(
                    identifier: keyIdentifier,
                    type: keyType,
                    size: actualSize * 8,  // Convert bytes to bits
                    creationDate: Date()
                )
                
                await logInfo(
                    "Successfully generated \(keyType.rawValue) key",
                    context: logContext.adding(
                        key: "keyIdentifier",
                        value: keyIdentifier,
                        privacyLevel: .private
                    )
                )
                
                return .success(key)
                
            case .failure(let error):
                await logError(
                    "Failed to store generated key: \(error)",
                    context: logContext
                )
                return .failure(error)
            }
        } catch {
            await logError(
                "Key generation failed: \(error.localizedDescription)",
                context: logContext
            )
            if let securityError = error as? SecurityStorageError {
                return .failure(securityError)
            } else {
                return .failure(.operationFailed("Key generation failed: \(error.localizedDescription)"))
            }
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
}
