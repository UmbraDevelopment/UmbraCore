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
   - Throws: SecurityError if validation fails
   */
  func validateEncryptionConfig(_ config: SecurityConfigDTO) throws {
    // Check for required options
    guard config.options["inputData"] != nil else {
      throw SecurityError.invalidInput("Missing input data for encryption")
    }
    
    guard config.keySize > 0 else {
      throw SecurityError.invalidInput("Invalid key size for encryption: \(config.keySize)")
    }
    
    // Check for supported algorithm
    let algorithm = config.algorithm
    let supportedAlgorithms = ["AES", "ChaCha20"]
    guard supportedAlgorithms.contains(algorithm) else {
      throw SecurityError.unsupportedOperation("Unsupported algorithm: \(algorithm)")
    }
  }
  
  /**
   Validates configuration for decryption operations.
   
   - Parameter config: The configuration to validate
   - Throws: SecurityError if validation fails
   */
  func validateDecryptionConfig(_ config: SecurityConfigDTO) throws {
    // Check for required options
    guard config.options["ciphertext"] != nil else {
      throw SecurityError.invalidInput("Missing ciphertext for decryption")
    }
    
    guard config.keySize > 0 else {
      throw SecurityError.invalidInput("Invalid key size for decryption: \(config.keySize)")
    }
    
    // Check for supported algorithm
    let algorithm = config.algorithm
    let supportedAlgorithms = ["AES", "ChaCha20"]
    guard supportedAlgorithms.contains(algorithm) else {
      throw SecurityError.unsupportedOperation("Unsupported algorithm: \(algorithm)")
    }
  }
  
  /**
   Validates configuration for key generation operations.
   
   - Parameter config: The configuration to validate
   - Throws: SecurityError if validation fails
   */
  func validateKeyGenerationConfig(_ config: SecurityConfigDTO) throws {
    // Check for valid key size
    guard config.keySize >= 128 else {
      throw SecurityError.invalidInput("Key size must be at least 128 bits")
    }
    
    // Validate key size is appropriate for algorithm
    let algorithm = config.algorithm
    switch algorithm {
      case "AES":
        guard [128, 192, 256].contains(config.keySize) else {
          throw SecurityError
            .invalidInput(
              "Invalid key size for AES: \(config.keySize). Must be 128, 192, or 256 bits"
            )
        }
      case "RSA":
        guard config.keySize >= 2048 && config.keySize % 8 == 0 else {
          throw SecurityError
            .invalidInput(
              "Invalid key size for RSA: \(config.keySize). Must be at least 2048 bits and a multiple of 8"
            )
        }
      case "ECC":
        guard [256, 384, 521].contains(config.keySize) else {
          throw SecurityError
            .invalidInput(
              "Invalid key size for ECC: \(config.keySize). Must be 256, 384, or 521 bits"
            )
        }
      default:
        break
    }
    
    // Check for supported algorithm
    let supportedAlgorithms = ["AES", "ChaCha20", "RSA", "ECC", "ED25519"]
    guard supportedAlgorithms.contains(algorithm) else {
      throw SecurityError.unsupportedOperation("Unsupported algorithm: \(algorithm)")
    }
  }
  
  /**
   Validates configuration for secure storage operations.
   
   - Parameter config: The configuration to validate
   - Throws: SecurityError if validation fails
   */
  func validateSecureStorageConfig(_ config: SecurityConfigDTO) throws {
    // Validate identifier
    guard let identifier = config.options["identifier"] else {
      throw SecurityError.invalidInput("Missing identifier for secure storage")
    }
    
    // Check for valid identifier format (basic validation)
    guard !identifier.isEmpty else {
      throw SecurityError.invalidInput("Empty identifier for secure storage")
    }
    
    // Validate data is present
    guard config.options["data"] != nil else {
      throw SecurityError.invalidInput("Missing data for secure storage")
    }
  }
  
  /**
   Validates configuration for secure retrieval operations.
   
   - Parameter config: The configuration to validate
   - Throws: SecurityError if validation fails
   */
  func validateSecureRetrievalConfig(_ config: SecurityConfigDTO) throws {
    // Validate identifier
    guard let identifier = config.options["identifier"] else {
      throw SecurityError.invalidInput("Missing identifier for secure retrieval")
    }
    
    // Check for valid identifier format (basic validation)
    guard !identifier.isEmpty else {
      throw SecurityError.invalidInput("Empty identifier for secure retrieval")
    }
  }
  
  /**
   Validates configuration for secure deletion operations.
   
   - Parameter config: The configuration to validate
   - Throws: SecurityError if validation fails
   */
  func validateSecureDeletionConfig(_ config: SecurityConfigDTO) throws {
    // Validate identifier
    guard let identifier = config.options["identifier"] else {
      throw SecurityError.invalidInput("Missing identifier for secure deletion")
    }
    
    // Check for valid identifier format (basic validation)
    guard !identifier.isEmpty else {
      throw SecurityError.invalidInput("Empty identifier for secure deletion")
    }
  }
  
  /**
   Validates configuration for signing operations.
   
   - Parameter config: The configuration to validate
   - Throws: SecurityError if validation fails
   */
  func validateSigningConfig(_ config: SecurityConfigDTO) throws {
    // Check for required options
    guard config.options["data"] != nil else {
      throw SecurityError.invalidInput("Missing data for signing")
    }
    
    // Check for hash algorithm if specified
    if let hashAlg = config.hashAlgorithm {
      let supportedHashAlgorithms = ["SHA256", "SHA384", "SHA512"]
      guard supportedHashAlgorithms.contains(hashAlg) else {
        throw SecurityError.unsupportedOperation("Unsupported hash algorithm: \(hashAlg)")
      }
    }
  }
  
  /**
   Validates configuration for signature verification operations.
   
   - Parameter config: The configuration to validate
   - Throws: SecurityError if validation fails
   */
  func validateVerificationConfig(_ config: SecurityConfigDTO) throws {
    // Check for required options
    guard config.options["data"] != nil else {
      throw SecurityError.invalidInput("Missing data for verification")
    }
    
    guard config.options["signature"] != nil else {
      throw SecurityError.invalidInput("Missing signature for verification")
    }
    
    // Check for hash algorithm if specified
    if let hashAlg = config.hashAlgorithm {
      let supportedHashAlgorithms = ["SHA256", "SHA384", "SHA512"]
      guard supportedHashAlgorithms.contains(hashAlg) else {
        throw SecurityError.unsupportedOperation("Unsupported hash algorithm: \(hashAlg)")
      }
    }
  }
}
