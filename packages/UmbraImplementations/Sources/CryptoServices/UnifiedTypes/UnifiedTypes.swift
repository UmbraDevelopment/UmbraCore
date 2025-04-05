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
   Unified encryption algorithm type.
   */
  public enum EncryptionAlgorithm: String, Sendable, Equatable, CaseIterable {
    /// AES 256-bit in CBC (Cipher Block Chaining) mode
    case aes256CBC

    /// AES 256-bit in GCM (Galois/Counter Mode) mode - provides authenticated encryption
    case aes256GCM

    /// AES 128-bit in GCM (Galois/Counter Mode) mode - provides authenticated encryption
    case aes128GCM

    /// ChaCha20-Poly1305 authenticated encryption
    case chacha20Poly1305="chacha20poly1305"

    /// Description of the algorithm
    public var description: String {
      rawValue
    }
  }

  /**
   Unified key generation options.
   */
  public struct KeyGenerationOptions: Sendable, Equatable {
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

    /// Convert from SecurityCoreInterfaces.EncryptionOptions if available
    public init(from options: SecurityCoreInterfaces.EncryptionOptions?) {
      // Default values if options is nil
      if let options {
        // Map the algorithm
        switch options.algorithm {
          case .aes128GCM:
            algorithm = .aes128GCM
          case .aes256GCM:
            algorithm = .aes256GCM
          case .aes256CBC:
            algorithm = .aes256CBC
          case .chacha20Poly1305:
            algorithm = .chacha20Poly1305
        }

        authenticatedData=options.authenticatedData
        padding=options.padding
      } else {
        // Defaults
        algorithm = .aes256GCM
        authenticatedData=nil
        padding=nil
      }
    }
  }

  /**
   Unified decryption options.
   */
  public struct DecryptionOptions: Sendable, Equatable {
    /// The encryption algorithm that was used (needed for decryption)
    public let algorithm: EncryptionAlgorithm

    /// Optional authenticated data for authenticated encryption modes
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
        // Map the algorithm
        switch options.algorithm {
          case .aes128GCM:
            algorithm = .aes128GCM
          case .aes256GCM:
            algorithm = .aes256GCM
          case .aes256CBC:
            algorithm = .aes256CBC
          case .chacha20Poly1305:
            algorithm = .chacha20Poly1305
        }

        authenticatedData=options.authenticatedData
        padding=options.padding
      } else {
        // Defaults
        algorithm = .aes256GCM
        authenticatedData=nil
        padding=nil
      }
    }
  }

  /**
   Unified error types for crypto operations.
   */
  public enum CryptoError: Error, Equatable {
    /// Operation failed with the specified reason
    case operationFailed(String)

    /// Key not found
    case keyNotFound(String)

    /// Invalid key format
    case invalidKey

    /// Invalid data format
    case invalidData

    /// Storage failure
    case storageFailure(Error?)

    /// Static comparison for Equatable
    public static func == (lhs: CryptoError, rhs: CryptoError) -> Bool {
      switch (lhs, rhs) {
        case let (.operationFailed(lhsReason), .operationFailed(rhsReason)):
          lhsReason == rhsReason
        case let (.keyNotFound(lhsID), .keyNotFound(rhsID)):
          lhsID == rhsID
        case (.invalidKey, .invalidKey):
          true
        case (.invalidData, .invalidData):
          true
        case (.storageFailure(_), .storageFailure(_)):
          // Can't compare errors directly
          true
        default:
          false
      }
    }
  }
}

// Type aliases to help with migration
public typealias UEncryptionAlgorithm=UnifiedCryptoTypes.EncryptionAlgorithm
public typealias UKeyGenerationOptions=UnifiedCryptoTypes.KeyGenerationOptions
public typealias UKeyAlgorithm=UnifiedCryptoTypes.KeyGenerationOptions.KeyAlgorithm
public typealias UEncryptionOptions=UnifiedCryptoTypes.EncryptionOptions
public typealias UDecryptionOptions=UnifiedCryptoTypes.DecryptionOptions
public typealias UCryptoError=UnifiedCryptoTypes.CryptoError
