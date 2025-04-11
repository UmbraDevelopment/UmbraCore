import CoreSecurityTypes
import CryptoInterfaces
import CryptoTypes
import DomainSecurityTypes
import Foundation
import LoggingInterfaces
import LoggingTypes
import Security
import SecurityCoreInterfaces

/**
 # HighSecurityCryptoService
 
 High-security implementation of CryptoServiceProtocol using a command pattern architecture.
 
 This implementation provides enhanced security features suitable for sensitive
 applications, following the Alpha Dot Five architecture principles with a
 modular command-based approach for better separation of concerns and testability.
 
 ## Security Features
 
 - AES-256 encryption with GCM mode and additional integrity verification
 - Strong key derivation with secure parameters
 - Hardware-backed secure random generation where available
 - Enhanced security event logging
 - Constant-time implementations to prevent timing attacks
 
 ## Privacy Controls
 
 This implementation ensures proper privacy classification of sensitive information:
 - Cryptographic keys are treated as private information
 - Data identifiers are generally treated as public information
 - Error details are appropriately classified based on sensitivity
 - Metadata is structured for privacy-aware logging
 
 ## Thread Safety
 
 As an actor, this implementation guarantees thread safety when used from multiple
 concurrent contexts, preventing data races in cryptographic operations.
 */
public actor HighSecurityCryptoService: CryptoServiceProtocol {
    /// The secure storage to use
    public let secureStorage: SecureStorageProtocol
    
    /// Command factory for creating operation commands
    private let commandFactory: CryptoCommandFactory
    
    /// Optional logger for operation tracking
    private let logger: LoggingProtocol?
    
    /**
     Initialises the high-security crypto service.
     
     - Parameters:
        - secureStorage: The secure storage implementation to use
        - logger: Optional logger for recording operations (defaults to nil)
     */
    public init(secureStorage: SecureStorageProtocol, logger: LoggingProtocol? = nil) {
        self.secureStorage = secureStorage
        self.logger = logger
        self.commandFactory = CryptoCommandFactory(secureStorage: secureStorage, logger: logger)
    }
    
    /**
     Encrypts data using the specified key.
     
     - Parameters:
        - data: The data to encrypt
        - keyIdentifier: Identifier for the encryption key
        - algorithm: The encryption algorithm to use
     - Returns: The encryption result
     */
    public func encrypt(
        data: [UInt8],
        keyIdentifier: String,
        algorithm: EncryptionAlgorithm = .aes256GCM
    ) async -> Result<[UInt8], SecurityStorageError> {
        let operationID = UUID().uuidString
        let logContext = CryptoLogContext(
            operation: "encrypt",
            algorithm: algorithm.rawValue,
            correlationID: operationID
        )
        
        // Create and execute the encrypt command
        let command = commandFactory.createEncryptCommand(
            data: data,
            keyIdentifier: keyIdentifier,
            algorithm: algorithm
        )
        
        let result = await command.execute(context: logContext, operationID: operationID)
        
        switch result {
        case .success(let encryptedDataIdentifier):
            // Retrieve the encrypted data to return directly
            let exportCommand = commandFactory.createExportDataCommand(
                identifier: encryptedDataIdentifier
            )
            
            return await exportCommand.execute(context: logContext, operationID: operationID)
            
        case .failure(let error):
            return .failure(error)
        }
    }
    
    /**
     Decrypts data using the appropriate key.
     
     - Parameters:
        - data: The encrypted data to decrypt
        - keyIdentifier: Identifier for the decryption key
        - algorithm: The encryption algorithm used
     - Returns: The decryption result
     */
    public func decrypt(
        data: [UInt8],
        keyIdentifier: String,
        algorithm: EncryptionAlgorithm = .aes256GCM
    ) async -> Result<[UInt8], SecurityStorageError> {
        let operationID = UUID().uuidString
        let logContext = CryptoLogContext(
            operation: "decrypt",
            algorithm: algorithm.rawValue,
            correlationID: operationID
        )
        
        // First, import the encrypted data
        let importCommand = commandFactory.createImportDataCommand(
            data: data
        )
        
        let importResult = await importCommand.execute(context: logContext, operationID: operationID)
        
        switch importResult {
        case .success(let encryptedDataIdentifier):
            // Create and execute the decrypt command
            let command = commandFactory.createDecryptCommand(
                encryptedDataIdentifier: encryptedDataIdentifier,
                algorithm: algorithm
            )
            
            return await command.execute(context: logContext, operationID: operationID)
            
        case .failure(let error):
            return .failure(error)
        }
    }
    
    /**
     Computes a cryptographic hash of the specified data.
     
     - Parameters:
        - data: The data to hash
        - algorithm: The hash algorithm to use
     - Returns: The hashing result
     */
    public func hash(
        data: [UInt8],
        algorithm: HashAlgorithm = .sha256
    ) async -> Result<[UInt8], SecurityStorageError> {
        let operationID = UUID().uuidString
        let logContext = CryptoLogContext(
            operation: "hash",
            algorithm: algorithm.rawValue,
            correlationID: operationID
        )
        
        // Create and execute the hash command
        let command = commandFactory.createHashCommand(
            data: data,
            algorithm: algorithm
        )
        
        return await command.execute(context: logContext, operationID: operationID)
    }
    
    /**
     Verifies that a hash matches the expected value.
     
     - Parameters:
        - data: The data to verify
        - expectedHash: The expected hash value
        - algorithm: The hash algorithm to use
     - Returns: The verification result
     */
    public func verifyHash(
        data: [UInt8],
        expectedHash: [UInt8],
        algorithm: HashAlgorithm = .sha256
    ) async -> Result<Bool, SecurityStorageError> {
        let operationID = UUID().uuidString
        let logContext = CryptoLogContext(
            operation: "verifyHash",
            algorithm: algorithm.rawValue,
            correlationID: operationID
        )
        
        // Create and execute the verify hash command
        let command = commandFactory.createVerifyHashCommand(
            data: data,
            expectedHash: expectedHash,
            algorithm: algorithm
        )
        
        return await command.execute(context: logContext, operationID: operationID)
    }
    
    /**
     Generates a cryptographic key.
     
     - Parameters:
        - type: The type of key to generate
        - size: Optional key size in bits
        - identifier: Optional predefined identifier for the key
     - Returns: The key generation result
     */
    public func generateKey(
        type: KeyType,
        size: Int? = nil,
        identifier: String? = nil
    ) async -> Result<CryptoKey, SecurityStorageError> {
        let operationID = UUID().uuidString
        let logContext = CryptoLogContext(
            operation: "generateKey",
            correlationID: operationID
        )
        
        // Create and execute the generate key command
        let command = commandFactory.createGenerateKeyCommand(
            keyType: type,
            size: size,
            identifier: identifier
        )
        
        return await command.execute(context: logContext, operationID: operationID)
    }
    
    /**
     Derives a key from an existing key.
     
     - Parameters:
        - fromKey: Identifier of the source key
        - salt: Optional salt for key derivation
        - info: Optional context info for key derivation
        - keyType: The type of key to derive
        - targetIdentifier: Optional identifier for the derived key
     - Returns: The key derivation result
     */
    public func deriveKey(
        fromKey: String,
        salt: [UInt8]?,
        info: [UInt8]?,
        keyType: KeyType,
        targetIdentifier: String?
    ) async -> Result<CryptoKey, SecurityStorageError> {
        let operationID = UUID().uuidString
        let logContext = CryptoLogContext(
            operation: "deriveKey",
            correlationID: operationID
        )
        
        // Create and execute the derive key command
        let command = DeriveKeyCommand(
            sourceKeyIdentifier: fromKey,
            salt: salt,
            info: info,
            keyType: keyType,
            targetIdentifier: targetIdentifier,
            secureStorage: secureStorage,
            logger: logger
        )
        
        return await command.execute(context: logContext, operationID: operationID)
    }
}
