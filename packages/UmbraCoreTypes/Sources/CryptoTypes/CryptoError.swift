import Foundation
import LoggingTypes

/// Errors that can occur during cryptographic operations.
public enum CryptoError: Error, Sendable, Equatable, CustomStringConvertible, LocalizedError,
LoggableErrorProtocol {
  // MARK: - Key Management Errors

  /// Failed to generate a secure random key.
  case keyGenerationFailed(reason: String)

  /// Invalid key format or length.
  case invalidKey(reason: String)

  /// Key not found in storage.
  case keyNotFound(identifier: String)

  /// Key derivation from password failed.
  case keyDerivationFailed(reason: String)

  /// Insufficient entropy for secure key generation.
  case insufficientEntropy(required: Int, available: Int)

  // MARK: - Encryption/Decryption Errors

  /// Failed to encrypt data.
  case encryptionFailed(reason: String)

  /// Failed to decrypt data.
  case decryptionFailed(reason: String)

  /// Failed to verify the integrity of encrypted data.
  case integrityCheckFailed(reason: String)

  /// Invalid padding or formatting in encrypted data.
  case invalidPadding(reason: String)

  // MARK: - Input/Algorithm Errors

  /// Invalid input data provided.
  case invalidInput(reason: String)

  /// Invalid algorithm or parameters specified.
  case invalidAlgorithm(reason: String)

  /// Incompatible algorithm versions.
  case algorithmVersionMismatch(expected: String, received: String)

  /// Operation not supported by the current implementation.
  case unsupportedOperation(reason: String)

  // MARK: - System/Resource Errors

  /// System crypto resources unavailable.
  case resourceUnavailable(resource: String)

  /// Memory allocation or access error.
  case memoryError(reason: String)

  /// General cryptographic operation failure.
  case operationFailed(reason: String)

  // MARK: - Description

  /// A human-readable description of the error.
  public var description: String {
    switch self {
      case let .keyGenerationFailed(reason):
        "Key generation failed: \(reason)"
      case let .encryptionFailed(reason):
        "Encryption failed: \(reason)"
      case let .decryptionFailed(reason):
        "Decryption failed: \(reason)"
      case let .invalidKey(reason):
        "Invalid key: \(reason)"
      case let .invalidInput(reason):
        "Invalid input: \(reason)"
      case let .invalidAlgorithm(reason):
        "Invalid algorithm: \(reason)"
      case let .unsupportedOperation(reason):
        "Unsupported operation: \(reason)"
      case let .keyNotFound(identifier):
        "Key not found: \(identifier)"
      case let .operationFailed(reason):
        "Cryptographic operation failed: \(reason)"
      case let .keyDerivationFailed(reason):
        "Key derivation failed: \(reason)"
      case let .insufficientEntropy(required, available):
        "Insufficient entropy: required \(required) bytes, available \(available) bytes"
      case let .integrityCheckFailed(reason):
        "Integrity check failed: \(reason)"
      case let .invalidPadding(reason):
        "Invalid padding: \(reason)"
      case let .algorithmVersionMismatch(expected, received):
        "Algorithm version mismatch: expected \(expected), received \(received)"
      case let .resourceUnavailable(resource):
        "Cryptographic resource unavailable: \(resource)"
      case let .memoryError(reason):
        "Memory error: \(reason)"
    }
  }

  // MARK: - LocalizedError Conformance

  /// The localized description of the error.
  public var errorDescription: String? {
    description
  }

  /// A localized message describing the reason for the failure.
  public var failureReason: String? {
    switch self {
      case let .keyGenerationFailed(reason),
           let .encryptionFailed(reason),
           let .decryptionFailed(reason),
           let .invalidKey(reason),
           let .invalidInput(reason),
           let .invalidAlgorithm(reason),
           let .unsupportedOperation(reason),
           let .operationFailed(reason),
           let .keyDerivationFailed(reason),
           let .integrityCheckFailed(reason),
           let .invalidPadding(reason),
           let .memoryError(reason):
        reason
      case let .keyNotFound(identifier):
        "No key found with identifier: \(identifier)"
      case let .insufficientEntropy(required, available):
        "System could only provide \(available) bytes of entropy, but \(required) bytes were needed"
      case let .algorithmVersionMismatch(expected, received):
        "Expected algorithm version \(expected), but received \(received)"
      case let .resourceUnavailable(resource):
        "The required resource '\(resource)' is unavailable or access was denied"
    }
  }

  /// A localized message describing how one might recover from the failure.
  public var recoverySuggestion: String? {
    switch self {
      case .keyGenerationFailed:
        "Try again or check system entropy sources"
      case .encryptionFailed, .decryptionFailed:
        "Verify that the key and input data are correct"
      case .invalidKey:
        "Ensure the key has the correct size and format"
      case .invalidInput:
        "Verify the input data is properly formatted"
      case .invalidAlgorithm:
        "Use a supported algorithm with correct parameters"
      case .unsupportedOperation:
        "Use an alternative operation supported by this implementation"
      case .keyNotFound:
        "Create or import the required key before using it"
      case .operationFailed:
        "Check logs for more details and try again"
      case .keyDerivationFailed:
        "Check that the password and salt are correct"
      case .insufficientEntropy:
        "Wait for the system to gather more entropy and try again"
      case .integrityCheckFailed:
        "The data may have been tampered with or corrupted"
      case .invalidPadding:
        "The data format or padding scheme may be incorrect"
      case .algorithmVersionMismatch:
        "Use the same algorithm version for encryption and decryption"
      case .resourceUnavailable:
        "Check system permissions and availability of cryptographic services"
      case .memoryError:
        "Close unnecessary applications to free memory"
    }
  }

  /// The help anchor for the corresponding documentation.
  public var helpAnchor: String? {
    switch self {
      case .keyGenerationFailed, .keyNotFound, .invalidKey, .keyDerivationFailed,
           .insufficientEntropy:
        "crypto_key_management"
      case .encryptionFailed, .decryptionFailed, .integrityCheckFailed, .invalidPadding:
        "crypto_encryption_decryption"
      case .invalidInput, .invalidAlgorithm, .algorithmVersionMismatch, .unsupportedOperation:
        "crypto_algorithms"
      case .resourceUnavailable, .memoryError, .operationFailed:
        "crypto_system_resources"
    }
  }

  // MARK: - LoggableErrorProtocol Conformance

  /// Get the metadata collection for logging this error
  /// - Returns: A structured metadata collection with privacy annotations
  public func createMetadataCollection() -> LogMetadataDTOCollection {
    var metadata = LogMetadataDTOCollection()
    
    // Add domain and error type info
    metadata = metadata.withPublic(key: "errorDomain", value: "Crypto")
    metadata = metadata.withPublic(key: "errorType", value: String(describing: type(of: self)))
    
    // Add common context for all error types
    switch self {
      case let .keyGenerationFailed(reason):
        metadata = metadata.withPrivate(key: "errorReason", value: reason)
        metadata = metadata.withPublic(key: "operation", value: "keyGeneration")
        
      case let .invalidKey(reason):
        metadata = metadata.withPrivate(key: "errorReason", value: reason)
        metadata = metadata.withPublic(key: "operation", value: "keyValidation")
        
      case let .keyNotFound(identifier):
        // Key IDs are sensitive, so mark as private
        metadata = metadata.withPrivate(key: "keyIdentifier", value: identifier)
        metadata = metadata.withPublic(key: "operation", value: "keyAccess")
        
      case let .keyDerivationFailed(reason):
        metadata = metadata.withPrivate(key: "errorReason", value: reason)
        metadata = metadata.withPublic(key: "operation", value: "keyDerivation")
        
      case let .insufficientEntropy(required, available):
        metadata = metadata.withPublic(key: "requiredEntropy", value: "\(required)")
        metadata = metadata.withPublic(key: "availableEntropy", value: "\(available)")
        metadata = metadata.withPublic(key: "operation", value: "entropyGeneration")
        
      case let .encryptionFailed(reason):
        metadata = metadata.withPrivate(key: "errorReason", value: reason)
        metadata = metadata.withPublic(key: "operation", value: "encryption")
        
      case let .decryptionFailed(reason):
        metadata = metadata.withPrivate(key: "errorReason", value: reason)
        metadata = metadata.withPublic(key: "operation", value: "decryption")
        
      case let .integrityCheckFailed(reason):
        metadata = metadata.withPrivate(key: "errorReason", value: reason)
        metadata = metadata.withPublic(key: "operation", value: "integrityVerification")
        
      case let .invalidPadding(reason):
        metadata = metadata.withPrivate(key: "errorReason", value: reason)
        metadata = metadata.withPublic(key: "operation", value: "paddingValidation")
        
      case let .invalidInput(reason):
        metadata = metadata.withPrivate(key: "errorReason", value: reason)
        metadata = metadata.withPublic(key: "operation", value: "dataValidation")
        
      case let .invalidAlgorithm(reason):
        metadata = metadata.withPrivate(key: "errorReason", value: reason)
        metadata = metadata.withPublic(key: "operation", value: "algorithmSupport")
        
      case let .algorithmVersionMismatch(expected, received):
        metadata = metadata.withPublic(key: "expectedVersion", value: expected)
        metadata = metadata.withPublic(key: "receivedVersion", value: received)
        metadata = metadata.withPublic(key: "operation", value: "versionCheck")
        
      case let .unsupportedOperation(reason):
        metadata = metadata.withPrivate(key: "errorReason", value: reason)
        metadata = metadata.withPublic(key: "operation", value: "featureSupport")
        
      case let .resourceUnavailable(resource):
        metadata = metadata.withPublic(key: "resource", value: resource)
        metadata = metadata.withPublic(key: "operation", value: "resourceAccess")
        
      case let .memoryError(reason):
        metadata = metadata.withPrivate(key: "errorReason", value: reason)
        metadata = metadata.withPublic(key: "operation", value: "memoryOperation")
        
      case let .operationFailed(reason):
        metadata = metadata.withPrivate(key: "errorReason", value: reason)
        metadata = metadata.withPublic(key: "operation", value: "cryptoOperation")
    }
    
    return metadata
  }

  /// Get the privacy metadata for this error
  /// - Returns: Privacy metadata for logging this error
  public func getPrivacyMetadata() -> PrivacyMetadata {
    var metadata=PrivacyMetadata()

    // Add domain and error type info
    metadata["errorDomain"]=PrivacyMetadataValue(value: "Crypto", privacy: .public)
    metadata["errorType"]=PrivacyMetadataValue(value: String(describing: type(of: self)),
                                               privacy: .public)

    // Add common context for all error types
    switch self {
      case let .keyGenerationFailed(reason):
        metadata["errorReason"]=PrivacyMetadataValue(value: reason, privacy: .private)
        metadata["operation"]=PrivacyMetadataValue(value: "keyGeneration", privacy: .public)

      case let .invalidKey(reason):
        metadata["errorReason"]=PrivacyMetadataValue(value: reason, privacy: .private)
        metadata["operation"]=PrivacyMetadataValue(value: "keyValidation", privacy: .public)

      case let .keyNotFound(identifier):
        // Key IDs are sensitive, so mark as private
        metadata["keyIdentifier"]=PrivacyMetadataValue(value: identifier, privacy: .private)
        metadata["operation"]=PrivacyMetadataValue(value: "keyAccess", privacy: .public)

      case let .keyDerivationFailed(reason):
        metadata["errorReason"]=PrivacyMetadataValue(value: reason, privacy: .private)
        metadata["operation"]=PrivacyMetadataValue(value: "keyDerivation", privacy: .public)

      case let .insufficientEntropy(required, available):
        metadata["requiredEntropy"]=PrivacyMetadataValue(value: "\(required)", privacy: .public)
        metadata["availableEntropy"]=PrivacyMetadataValue(value: "\(available)", privacy: .public)
        metadata["operation"]=PrivacyMetadataValue(value: "entropyGeneration", privacy: .public)

      case let .encryptionFailed(reason):
        metadata["errorReason"]=PrivacyMetadataValue(value: reason, privacy: .private)
        metadata["operation"]=PrivacyMetadataValue(value: "encryption", privacy: .public)

      case let .decryptionFailed(reason):
        metadata["errorReason"]=PrivacyMetadataValue(value: reason, privacy: .private)
        metadata["operation"]=PrivacyMetadataValue(value: "decryption", privacy: .public)

      case let .invalidInput(reason):
        metadata["errorReason"]=PrivacyMetadataValue(value: reason, privacy: .private)
        metadata["operation"]=PrivacyMetadataValue(value: "dataValidation", privacy: .public)

      case let .invalidAlgorithm(reason):
        metadata["errorReason"]=PrivacyMetadataValue(value: reason, privacy: .private)
        metadata["operation"]=PrivacyMetadataValue(value: "algorithmSupport", privacy: .public)

      case let .algorithmVersionMismatch(expected, received):
        metadata["expectedVersion"]=PrivacyMetadataValue(value: expected, privacy: .public)
        metadata["receivedVersion"]=PrivacyMetadataValue(value: received, privacy: .public)
        metadata["operation"]=PrivacyMetadataValue(value: "algorithmVersion", privacy: .public)

      case let .unsupportedOperation(reason):
        metadata["errorReason"]=PrivacyMetadataValue(value: reason, privacy: .private)
        metadata["operation"]=PrivacyMetadataValue(value: "operationSupport", privacy: .public)

      case let .resourceUnavailable(resource):
        metadata["resource"]=PrivacyMetadataValue(value: resource, privacy: .public)
        metadata["operation"]=PrivacyMetadataValue(value: "resourceAccess", privacy: .public)

      case let .memoryError(reason):
        metadata["errorReason"]=PrivacyMetadataValue(value: reason, privacy: .public)
        metadata["operation"]=PrivacyMetadataValue(value: "memoryAccess", privacy: .public)

      case let .operationFailed(reason):
        metadata["errorReason"]=PrivacyMetadataValue(value: reason, privacy: .private)
        metadata["operation"]=PrivacyMetadataValue(value: "operationExecution", privacy: .public)

      case let .integrityCheckFailed(reason):
        metadata["errorReason"]=PrivacyMetadataValue(value: reason, privacy: .private)
        metadata["operation"]=PrivacyMetadataValue(value: "integrityCheck", privacy: .public)

      case let .invalidPadding(reason):
        metadata["errorReason"]=PrivacyMetadataValue(value: reason, privacy: .private)
        metadata["operation"]=PrivacyMetadataValue(value: "paddingValidation", privacy: .public)
    }

    return metadata
  }

  /// Get the source information for this error
  /// - Returns: A formatted source string for logging
  public func getSource() -> String {
    return "CryptoServices.\(self.operationName)"
  }
  
  /// Gets a log message for this error
  /// - Returns: A formatted message for logging
  public func getLogMessage() -> String {
    return "Crypto operation failed: \(self.localizedDescription)"
  }
  
  /// The operation name for this error type
  private var operationName: String {
    switch self {
      case .keyGenerationFailed: return "KeyGeneration"
      case .invalidKey: return "KeyValidation"
      case .keyNotFound: return "KeyAccess"
      case .keyDerivationFailed: return "KeyDerivation"
      case .insufficientEntropy: return "EntropyGeneration"
      case .encryptionFailed: return "Encryption"
      case .decryptionFailed: return "Decryption"
      case .integrityCheckFailed: return "IntegrityVerification"
      case .invalidPadding: return "PaddingValidation"
      case .invalidInput: return "DataValidation"
      case .invalidAlgorithm: return "AlgorithmSupport"
      case .algorithmVersionMismatch: return "VersionCheck"
      case .unsupportedOperation: return "FeatureSupport"
      case .resourceUnavailable: return "ResourceAccess"
      case .memoryError: return "MemoryOperation"
      case .operationFailed: return "CryptoOperation"
    }
  }

  /// The appropriate privacy classification for this error
  public var privacyClassification: PrivacyClassification {
    switch self {
      // Key management errors with varying sensitivity
      case .keyGenerationFailed:
        .private
      case .invalidKey:
        .private
      case .keyNotFound where isSystemKey:
        .sensitive // System keys get higher protection
      case .keyNotFound:
        .private
      case .keyDerivationFailed:
        .private
      case .insufficientEntropy:
        .public // Not sensitive, just system state
      // Encryption/Decryption errors
      case .encryptionFailed, .decryptionFailed:
        .private
      case .integrityCheckFailed:
        .sensitive // Could indicate tampering attempts
      case .invalidPadding:
        .private
      // Input/Algorithm errors (generally less sensitive)
      case .invalidInput, .invalidAlgorithm, .algorithmVersionMismatch, .unsupportedOperation:
        .public
      // System/Resource errors
      case .resourceUnavailable:
        .public
      case .memoryError:
        .public
      // General errors have default protection
      case .operationFailed:
        .private
    }
  }

  /// Additional metadata for logging this error
  public var loggingMetadata: LogMetadataDTOCollection {
    var metadata=LogMetadataDTOCollection()
      .withPublic(key: "errorDomain", value: "Crypto")
      .withPublic(key: "errorType", value: String(describing: type(of: self)))

    // Add case-specific metadata with appropriate privacy
    switch self {
      case let .keyGenerationFailed(reason):
        metadata=metadata.withPrivate(key: "reason", value: reason)
      case let .invalidKey(reason):
        metadata=metadata.withPrivate(key: "reason", value: reason)
      case let .keyNotFound(identifier):
        metadata=metadata.withPrivate(key: "identifier", value: identifier)
      case let .keyDerivationFailed(reason):
        metadata=metadata.withPrivate(key: "reason", value: reason)
      case let .insufficientEntropy(required, available):
        metadata=metadata
          .withPublic(key: "requiredEntropy", value: String(required))
          .withPublic(key: "availableEntropy", value: String(available))
      case let .encryptionFailed(reason):
        metadata=metadata.withPrivate(key: "reason", value: reason)
      case let .decryptionFailed(reason):
        metadata=metadata.withPrivate(key: "reason", value: reason)
      case let .integrityCheckFailed(reason):
        metadata=metadata.withPrivate(key: "reason", value: reason)
      case let .invalidPadding(reason):
        metadata=metadata.withPrivate(key: "reason", value: reason)
      case let .invalidInput(reason):
        metadata=metadata.withPublic(key: "reason", value: reason)
      case let .invalidAlgorithm(reason):
        metadata=metadata.withPublic(key: "reason", value: reason)
      case let .algorithmVersionMismatch(expected, received):
        metadata=metadata
          .withPublic(key: "expectedVersion", value: expected)
          .withPublic(key: "receivedVersion", value: received)
      case let .unsupportedOperation(reason):
        metadata=metadata.withPublic(key: "reason", value: reason)
      case let .resourceUnavailable(resource):
        metadata=metadata.withPublic(key: "resource", value: resource)
      case let .memoryError(reason):
        metadata=metadata.withPublic(key: "reason", value: reason)
      case let .operationFailed(reason):
        metadata=metadata.withPrivate(key: "reason", value: reason)
    }

    return metadata
  }

  /// A human-readable description suitable for logging
  public var loggingDescription: String {
    localizedDescription
  }

  /// Helper to determine if a key is a system key
  private var isSystemKey: Bool {
    if case let .keyNotFound(identifier)=self {
      return identifier.hasPrefix("system.") || identifier.hasPrefix("master.")
    }
    return false
  }
}
