import Foundation
import SecurityCoreInterfaces
import SecurityCoreTypes
import SecurityTypes

/**
 # SecurityProvider Validation Extension
 
 This extension adds comprehensive validation capabilities to the SecurityProviderImpl,
 ensuring that all inputs to security operations are properly validated before processing.
 
 ## Validation Standards
 
 - All inputs must be validated before use
 - Validation failures result in clear error messages
 - Context is provided for debugging
 - Common validation logic is centralised
 */
extension SecurityProviderImpl {
    /**
     Validates configuration for encryption operations.
     
     - Parameter config: The configuration to validate
     - Throws: SecurityError if the configuration is invalid
     */
    func validateEncryptionConfig(_ config: SecurityConfigDTO) throws {
        // Check for input data in options
        guard let inputDataString = config.options["inputData"],
              !inputDataString.isEmpty,
              let _ = Data(base64Encoded: inputDataString) else {
            throw SecurityError.invalidInput("No valid input data provided for encryption")
        }
        
        // Check key size is reasonable
        guard config.keySize >= 128 && config.keySize <= 4096 else {
            throw SecurityError.invalidKeySize("Invalid key size: \(config.keySize). Must be between 128 and 4096 bits")
        }
        
        // Validate key identifier
        guard let keyIdentifier = config.options["keyIdentifier"],
              !keyIdentifier.isEmpty else {
            throw SecurityError.invalidInput("No key identifier provided for encryption")
        }
        
        // Check for supported algorithm
        let algorithm = config.algorithm.rawValue
        let supportedAlgorithms = ["AES", "ChaCha20"]
        guard supportedAlgorithms.contains(algorithm) else {
            throw SecurityError.unsupportedAlgorithm(algorithm)
        }
    }
    
    /**
     Validates configuration for decryption operations.
     
     - Parameter config: The configuration to validate
     - Throws: SecurityError if the configuration is invalid
     */
    func validateDecryptionConfig(_ config: SecurityConfigDTO) throws {
        // Check for input data in options
        guard let inputDataString = config.options["inputData"],
              !inputDataString.isEmpty,
              let _ = Data(base64Encoded: inputDataString) else {
            throw SecurityError.invalidInput("No valid input data provided for decryption")
        }
        
        // Validate key identifier
        guard let keyIdentifier = config.options["keyIdentifier"],
              !keyIdentifier.isEmpty else {
            throw SecurityError.invalidInput("No key identifier provided for decryption")
        }
        
        // Check for supported algorithm
        let algorithm = config.algorithm.rawValue
        let supportedAlgorithms = ["AES", "ChaCha20"]
        guard supportedAlgorithms.contains(algorithm) else {
            throw SecurityError.unsupportedAlgorithm(algorithm)
        }
    }
    
    /**
     Validates configuration for key generation operations.
     
     - Parameter config: The configuration to validate
     - Throws: SecurityError if the configuration is invalid
     */
    func validateKeyGenerationConfig(_ config: SecurityConfigDTO) throws {
        // Check key size
        guard config.keySize >= 128 && config.keySize <= 4096 else {
            throw SecurityError.invalidKeySize("Invalid key size: \(config.keySize). Must be between 128 and 4096 bits")
        }
        
        // Validate key size is appropriate for algorithm
        let algorithm = config.algorithm.rawValue
        switch algorithm {
        case "AES":
            guard [128, 192, 256].contains(config.keySize) else {
                throw SecurityError.invalidKeySize("Invalid key size for AES: \(config.keySize). Must be 128, 192, or 256 bits")
            }
        case "RSA":
            guard config.keySize >= 2048 && config.keySize % 8 == 0 else {
                throw SecurityError.invalidKeySize("Invalid key size for RSA: \(config.keySize). Must be at least 2048 bits and a multiple of 8")
            }
        case "ECC":
            guard [256, 384, 521].contains(config.keySize) else {
                throw SecurityError.invalidKeySize("Invalid key size for ECC: \(config.keySize). Must be 256, 384, or 521 bits")
            }
        default:
            break
        }
        
        // Check for supported algorithm
        let supportedAlgorithms = ["AES", "ChaCha20", "RSA", "ECC", "ED25519"]
        guard supportedAlgorithms.contains(algorithm) else {
            throw SecurityError.unsupportedAlgorithm(algorithm)
        }
    }
    
    /**
     Validates configuration for secure storage operations.
     
     - Parameter config: The configuration to validate
     - Throws: SecurityError if the configuration is invalid
     */
    func validateSecureStorageConfig(_ config: SecurityConfigDTO) throws {
        // Check for required data
        guard let dataString = config.options["storeData"],
              !dataString.isEmpty else {
            throw SecurityError.invalidInput("No data provided for secure storage")
        }
        
        // Validate identifier
        guard let identifier = config.options["storageIdentifier"],
              !identifier.isEmpty else {
            throw SecurityError.invalidInput("No identifier provided for secure storage")
        }
    }
    
    /**
     Validates configuration for secure retrieval operations.
     
     - Parameter config: The configuration to validate
     - Throws: SecurityError if the configuration is invalid
     */
    func validateSecureRetrievalConfig(_ config: SecurityConfigDTO) throws {
        // Validate identifier
        guard let identifier = config.options["storageIdentifier"],
              !identifier.isEmpty else {
            throw SecurityError.invalidInput("No identifier provided for secure retrieval")
        }
    }
    
    /**
     Validates configuration for secure deletion operations.
     
     - Parameter config: The configuration to validate
     - Throws: SecurityError if the configuration is invalid
     */
    func validateSecureDeletionConfig(_ config: SecurityConfigDTO) throws {
        // Validate identifier
        guard let identifier = config.options["storageIdentifier"],
              !identifier.isEmpty else {
            throw SecurityError.invalidInput("No identifier provided for secure deletion")
        }
    }
    
    /**
     Validates configuration for signing operations.
     
     - Parameter config: The configuration to validate
     - Throws: SecurityError if the configuration is invalid
     */
    func validateSigningConfig(_ config: SecurityConfigDTO) throws {
        // Check for required data
        guard let dataString = config.options["inputData"],
              !dataString.isEmpty else {
            throw SecurityError.invalidInput("No data provided for signing")
        }
        
        // Validate key identifier
        guard let keyIdentifier = config.options["keyIdentifier"],
              !keyIdentifier.isEmpty else {
            throw SecurityError.invalidInput("No key identifier provided for signing")
        }
        
        // Check for supported algorithm based on hash algorithm
        let hashAlg = config.hashAlgorithm.rawValue
        let supportedHashAlgorithms = ["SHA256", "SHA384", "SHA512"]
        guard supportedHashAlgorithms.contains(hashAlg) else {
            throw SecurityError.unsupportedAlgorithm("Hash algorithm: \(hashAlg)")
        }
    }
    
    /**
     Validates configuration for verification operations.
     
     - Parameter config: The configuration to validate
     - Throws: SecurityError if the configuration is invalid
     */
    func validateVerificationConfig(_ config: SecurityConfigDTO) throws {
        // Check for required data
        guard let dataString = config.options["inputData"],
              !dataString.isEmpty else {
            throw SecurityError.invalidInput("No data provided for verification")
        }
        
        // Check for signature
        guard let signatureBase64 = config.options["signature"],
              !signatureBase64.isEmpty else {
            throw SecurityError.invalidInput("No signature provided for verification")
        }
        
        // Validate key identifier
        guard let keyIdentifier = config.options["keyIdentifier"],
              !keyIdentifier.isEmpty else {
            throw SecurityError.invalidInput("No key identifier provided for verification")
        }
        
        // Check for supported algorithm based on hash algorithm
        let hashAlg = config.hashAlgorithm.rawValue
        let supportedHashAlgorithms = ["SHA256", "SHA384", "SHA512"]
        guard supportedHashAlgorithms.contains(hashAlg) else {
            throw SecurityError.unsupportedAlgorithm("Hash algorithm: \(hashAlg)")
        }
    }
}
