import CoreSecurityTypes
import CryptoTypes
import DomainSecurityTypes
import Foundation
import SecurityCoreInterfaces
import UmbraErrors

/**
 Namespace for unified types to avoid ambiguity and naming conflicts.
 */
public enum UnifiedCryptoTypes {
  /**
   Canonical reference to CoreSecurityTypes.EncryptionAlgorithm.
   Using type alias to ensure consistent algorithm definitions across the codebase.
   */
  public typealias EncryptionAlgorithm=CoreSecurityTypes.EncryptionAlgorithm

  /**
   Unified key generation options.
   */
  public struct KeyGenerationOptions: @unchecked Sendable {
    /// The key algorithm to use
    public let algorithm: KeyAlgorithm

    /// Additional parameters for the operation (optional)
    public let parameters: [String: Any]?

    /// Creates a new key generation options instance
    public init(
      algorithm: KeyAlgorithm = .symmetric,
      parameters: [String: Any]?=nil
    ) {
      self.algorithm=algorithm
      self.parameters=parameters
    }

    /**
     Key algorithm enumeration.
     */
    public enum KeyAlgorithm: String, Sendable, Equatable, CaseIterable {
      /// Symmetric key algorithm
      case symmetric

      /// RSA algorithm
      case rsa

      /// ECC algorithm
      case ecc

      /// ChaCha20 algorithm
      case chaCha20
    }
  }

  /**
   Unified encryption options.
   */
  public struct EncryptionOptions: Sendable, Equatable {
    /// The encryption algorithm to use
    public let algorithm: EncryptionAlgorithm

    /// Optional authenticated data for authenticated encryption modes
    public let authenticatedData: [UInt8]?

    /// Optional padding mode for algorithms that require padding
    public let padding: PaddingMode?

    /// Creates a new encryption options instance
    public init(
      algorithm: EncryptionAlgorithm = .aes256GCM,
      authenticatedData: [UInt8]?=nil,
      padding: PaddingMode?=nil
    ) {
      self.algorithm=algorithm
      self.authenticatedData=authenticatedData
      self.padding=padding
    }

    /// Convert from CoreSecurityTypes.EncryptionOptions if available
    public init(from options: CoreSecurityTypes.EncryptionOptions?) {
      // Default values if options is nil
      if let options {
        // Map the algorithm
        algorithm=options.algorithm // Direct assignment since it's the same type
        authenticatedData=options.additionalAuthenticatedData
        // Padding is optional and depends on implementation
        padding=nil
      } else {
        // Defaults
        algorithm = .aes256GCM
        authenticatedData=nil
        padding=nil
      }
    }

    // Implement Equatable manually
    public static func == (lhs: EncryptionOptions, rhs: EncryptionOptions) -> Bool {
      lhs.algorithm == rhs.algorithm &&
        lhs.authenticatedData == rhs.authenticatedData &&
        lhs.padding == rhs.padding
    }
  }

  /**
   Unified decryption options.
   */
  public struct DecryptionOptions: Sendable, Equatable {
    /// The encryption algorithm that was used (needed for decryption)
    public let algorithm: EncryptionAlgorithm

    /// Optional authenticated data that was used for encryption
    public let authenticatedData: [UInt8]?

    /// Optional padding mode for algorithms that require padding
    public let padding: PaddingMode?

    /// Creates a new decryption options instance
    public init(
      algorithm: EncryptionAlgorithm = .aes256GCM,
      authenticatedData: [UInt8]?=nil,
      padding: PaddingMode?=nil
    ) {
      self.algorithm=algorithm
      self.authenticatedData=authenticatedData
      self.padding=padding
    }

    /// Convert from SecurityCoreInterfaces.DecryptionOptions if available
    public init(from options: SecurityCoreInterfaces.DecryptionOptions?) {
      // Default values if options is nil
      if let options {
        // Map the algorithm - both use the same type
        algorithm=options.algorithm
        authenticatedData=nil
        // Padding is optional and depends on implementation
        padding=nil
      } else {
        // Defaults
        algorithm = .aes256GCM
        authenticatedData=nil
        padding=nil
      }
    }

    // Implement Equatable manually
    public static func == (lhs: DecryptionOptions, rhs: DecryptionOptions) -> Bool {
      lhs.algorithm == rhs.algorithm &&
        lhs.authenticatedData == rhs.authenticatedData &&
        lhs.padding == rhs.padding
    }
  }

  /**
   Unified error types for crypto operations.
   */
  public enum CryptoError: Error, Equatable {
    /// Operation failed with the specified reason
    case operationFailed(String)

    /// Key not found
    case keyNotFound

    /// Key generation failed
    case keyGenerationFailed(String)

    /// Key retrieval failed
    case keyRetrievalFailed(String)

    /// Encryption failed
    case encryptionFailed(String)

    /// Decryption failed
    case decryptionFailed(String)

    /// Hashing failed
    case hashingFailed(String)

    /// Storage failed
    case storageFailed(String)

    /// Retrieval failed
    case retrievalFailed(String)

    /// Invalid key format
    case invalidKey

    /// Invalid data format
    case invalidData

    /// Invalid input
    case invalidInput(String)

    /// Storage failure
    case storageFailure(Error?)

    /// Static comparison for Equatable
    public static func == (lhs: CryptoError, rhs: CryptoError) -> Bool {
      switch (lhs, rhs) {
        case let (.operationFailed(lhsReason), .operationFailed(rhsReason)):
          lhsReason == rhsReason
        case (.keyNotFound, .keyNotFound):
          true
        case let (.keyGenerationFailed(lhsReason), .keyGenerationFailed(rhsReason)):
          lhsReason == rhsReason
        case let (.keyRetrievalFailed(lhsReason), .keyRetrievalFailed(rhsReason)):
          lhsReason == rhsReason
        case let (.encryptionFailed(lhsReason), .encryptionFailed(rhsReason)):
          lhsReason == rhsReason
        case let (.decryptionFailed(lhsReason), .decryptionFailed(rhsReason)):
          lhsReason == rhsReason
        case let (.hashingFailed(lhsReason), .hashingFailed(rhsReason)):
          lhsReason == rhsReason
        case let (.storageFailed(lhsReason), .storageFailed(rhsReason)):
          lhsReason == rhsReason
        case let (.retrievalFailed(lhsReason), .retrievalFailed(rhsReason)):
          lhsReason == rhsReason
        case (.invalidKey, .invalidKey):
          true
        case (.invalidData, .invalidData):
          true
        case let (.invalidInput(lhsReason), .invalidInput(rhsReason)):
          lhsReason == rhsReason
        case (.storageFailure(_), .storageFailure(_)):
          // Can't compare errors directly
          true
        default:
          false
      }
    }
  }

  /**
   Padding mode for encryption algorithms.
   */
  public enum PaddingMode: String, Sendable, Equatable, CaseIterable {
    /// No padding
    case none

    /// PKCS#7 padding
    case pkcs7
  }
}

// Type aliases to help with migration
public typealias UEncryptionAlgorithm=UnifiedCryptoTypes.EncryptionAlgorithm
public typealias UKeyGenerationOptions=UnifiedCryptoTypes.KeyGenerationOptions
public typealias UKeyAlgorithm=UnifiedCryptoTypes.KeyGenerationOptions.KeyAlgorithm
public typealias UEncryptionOptions=UnifiedCryptoTypes.EncryptionOptions
public typealias UDecryptionOptions=UnifiedCryptoTypes.DecryptionOptions
public typealias UCryptoError=UnifiedCryptoTypes.CryptoError
