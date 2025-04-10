import CoreSecurityTypes
import Foundation

/// Helper function to create LogMetadataDTOCollection from dictionary
private func createMetadataCollection(_ dict: [String: String]) -> LogMetadataDTOCollection {
  var collection=LogMetadataDTOCollection()
  for (key, value) in dict {
    collection=collection.withPublic(key: key, value: value)
  }
  return collection
}

import LoggingInterfaces
import LoggingTypes
import SecurityCoreInterfaces

/**
 # SecurityProvider Validation Extension

 This extension adds input validation helpers to the SecurityProviderService.
 These methods ensure that operations have valid parameters before being performed,
 leading to more robust error handling and predictable behaviour.

 ## Benefits

 - Consistent parameter validation across all security operations
 - Early detection of configuration errors
 - Common validation logic is centralised
 */
extension SecurityProviderService {
  /**
   Validates configuration for encryption operations.

   - Parameter config: The configuration to validate
   - Throws: SecurityError if validation fails
   */
  func validateEncryptionConfig(_ config: SecurityConfigDTO) throws {
    // Check for required parameters
    guard let metadata=config.options?.metadata else {
      throw SecurityProtocolError.invalidConfiguration(message: "Missing configuration metadata")
    }

    guard metadata["key"] != nil else {
      throw SecurityProtocolError.invalidConfiguration(message: "Missing encryption key")
    }

    guard metadata["data"] != nil else {
      throw SecurityProtocolError.invalidConfiguration(message: "Missing data to encrypt")
    }

    // Validate algorithm is supported
    let supportedAlgorithms=["AES", "ChaCha20"]
    guard supportedAlgorithms.contains(config.encryptionAlgorithm.rawValue) else {
      throw SecurityProtocolError
        .invalidConfiguration(
          message: "Unsupported encryption algorithm: \(config.encryptionAlgorithm.rawValue)"
        )
    }
  }

  /**
   Validates configuration for decryption operations.

   - Parameter config: The configuration to validate
   - Throws: SecurityError if validation fails
   */
  func validateDecryptionConfig(_ config: SecurityConfigDTO) throws {
    // Check for required parameters
    guard let metadata=config.options?.metadata else {
      throw SecurityProtocolError.invalidConfiguration(message: "Missing configuration metadata")
    }

    guard metadata["key"] != nil else {
      throw SecurityProtocolError.invalidConfiguration(message: "Missing decryption key")
    }

    guard metadata["data"] != nil else {
      throw SecurityProtocolError.invalidConfiguration(message: "Missing data to decrypt")
    }

    guard metadata["iv"] != nil else {
      throw SecurityProtocolError
        .invalidConfiguration(message: "Missing initialisation vector (IV)")
    }

    // Validate algorithm is supported
    let supportedAlgorithms=["AES", "ChaCha20"]
    guard supportedAlgorithms.contains(config.encryptionAlgorithm.rawValue) else {
      throw SecurityProtocolError
        .invalidConfiguration(
          message: "Unsupported decryption algorithm: \(config.encryptionAlgorithm.rawValue)"
        )
    }
  }

  /**
   Validates configuration for key management operations.

   - Parameter config: The configuration to validate
   - Throws: SecurityError if validation fails
   */
  func validateKeyManagementConfig(_ config: SecurityConfigDTO) throws {
    guard let metadata=config.options?.metadata else {
      throw SecurityProtocolError.invalidConfiguration(message: "Missing configuration metadata")
    }

    // Check for identifier
    guard let keyIdentifier=metadata["keyIdentifier"], !keyIdentifier.isEmpty else {
      throw SecurityProtocolError.invalidConfiguration(message: "Missing or empty key identifier")
    }

    // For key generation, check algorithm
    if metadata["operation"] == "generate" {
      // Validate algorithm is supported
      let supportedAlgorithms=["AES", "RSA", "EC"]
      guard supportedAlgorithms.contains(config.encryptionAlgorithm.rawValue) else {
        throw SecurityProtocolError
          .invalidConfiguration(
            message: "Unsupported key algorithm: \(config.encryptionAlgorithm.rawValue)"
          )
      }
    }
  }

  /**
   Validates configuration for signature operations.

   - Parameter config: The configuration to validate
   - Throws: SecurityError if validation fails
   */
  func validateSignatureConfig(_ config: SecurityConfigDTO) throws {
    guard let metadata=config.options?.metadata else {
      throw SecurityProtocolError.invalidConfiguration(message: "Missing configuration metadata")
    }

    // Check for required parameters
    guard metadata["data"] != nil else {
      throw SecurityProtocolError.invalidConfiguration(message: "Missing data to sign/verify")
    }

    guard metadata["keyIdentifier"] != nil else {
      throw SecurityProtocolError.invalidConfiguration(message: "Missing signing key identifier")
    }

    // For verification, we need a signature
    if metadata["operation"] == "verify" {
      guard metadata["signature"] != nil else {
        throw SecurityProtocolError.invalidConfiguration(message: "Missing signature to verify")
      }
    }

    // Signature algorithm should be checked with the proper algorithm property
    let supportedAlgorithms=["RSA", "ECDSA", "Ed25519"]
    // Since the algorithm for signatures might be different from encryption algorithm
    // we should ideally use a dedicated signature algorithm property if available
    // For now, we're using the encryptionAlgorithm as a placeholder
    guard supportedAlgorithms.contains(config.encryptionAlgorithm.rawValue) else {
      throw SecurityProtocolError
        .invalidConfiguration(
          message: "Unsupported signature algorithm: \(config.encryptionAlgorithm.rawValue)"
        )
    }
  }

  /**
   Validates configuration for secure storage operations.

   - Parameter config: The configuration to validate
   - Throws: SecurityError if validation fails
   */
  func validateStorageConfig(_ config: SecurityConfigDTO) throws {
    guard let metadata=config.options?.metadata else {
      throw SecurityProtocolError.invalidConfiguration(message: "Missing configuration metadata")
    }

    // For storing data
    if metadata["operation"] == "store" {
      guard metadata["data"] != nil else {
        throw SecurityProtocolError.invalidConfiguration(message: "Missing data to store")
      }
    }

    // For retrieving data
    if metadata["operation"] == "retrieve" || metadata["operation"] == "delete" {
      guard metadata["identifier"] != nil else {
        throw SecurityProtocolError.invalidConfiguration(message: "Missing data identifier")
      }
    }

    // Check storage location if specified
    if let location=metadata["location"] {
      let supportedLocations=["keychain", "secureEnclave", "fileSystem", "memory"]
      guard supportedLocations.contains(location) else {
        throw SecurityProtocolError
          .invalidConfiguration(message: "Unsupported storage location: \(location)")
      }
    }
  }
}

extension CoreSecurityError {
  static func invalidVerificationMethod(reason: String) -> CoreSecurityError {
    .invalidInput("Invalid verification method: \(reason)")
  }

  static func verificationFailed(reason: String) -> CoreSecurityError {
    .authenticationFailed("Verification failed: \(reason)")
  }

  static func notImplemented(reason: String) -> CoreSecurityError {
    .unsupportedOperation("Not implemented: \(reason)")
  }
}
