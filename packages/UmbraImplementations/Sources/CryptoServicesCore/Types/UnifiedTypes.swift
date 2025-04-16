import CoreSecurityTypes
import Foundation
import SecurityCoreInterfaces

/**
 Namespace for unified types to avoid ambiguity and naming conflicts.

 These types provide a unified interface for cryptographic operations
 across the UmbraCore system while maintaining compatibility with the
 Alpha Dot Five architecture.
 */
public enum UnifiedCryptoTypes {
  /**
   Unified key generation options.
   */
  public struct KeyGenerationOptions: Sendable {
    /// The key algorithm to use
    public let algorithm: KeyAlgorithm

    /// The key type (symmetric, asymmetric, etc.)
    public let keyType: CoreSecurityTypes.KeyType

    /// The key size in bits
    public let keySizeInBits: Int

    /// Whether the key can be extracted from the secure storage
    public let isExtractable: Bool

    /// Whether to use secure enclave (Apple platforms) or equivalent secure hardware
    public let useSecureEnclave: Bool

    /// Additional parameters for the operation (optional)
    public let parameters: [String: String]?

    /// Creates a new key generation options instance
    public init(
      algorithm: KeyAlgorithm = .symmetric,
      keyType: CoreSecurityTypes.KeyType = .aes,
      keySizeInBits: Int=256,
      isExtractable: Bool=false,
      useSecureEnclave: Bool=false,
      parameters: [String: String]?=nil
    ) {
      self.algorithm=algorithm
      self.keyType=keyType
      self.keySizeInBits=keySizeInBits
      self.isExtractable=isExtractable
      self.useSecureEnclave=useSecureEnclave
      self.parameters=parameters
    }

    /// Convert to CoreSecurityTypes.KeyGenerationOptions
    public func toCoreOptions() -> CoreSecurityTypes.KeyGenerationOptions {
      CoreSecurityTypes.KeyGenerationOptions(
        keyType: keyType,
        keySizeInBits: keySizeInBits,
        isExtractable: isExtractable,
        useSecureEnclave: useSecureEnclave
      )
    }

    /// Convert from CoreSecurityTypes.KeyGenerationOptions
    public init(from options: CoreSecurityTypes.KeyGenerationOptions) {
      keyType=options.keyType
      keySizeInBits=options.keySizeInBits
      isExtractable=options.isExtractable
      useSecureEnclave=options.useSecureEnclave
      algorithm = .symmetric // Default
      parameters=nil
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
      case chacha20
    }
  }

  /**
   Unified encryption options.
   */
  public struct EncryptionOptions: Sendable, Equatable {
    /// The encryption algorithm to use
    public let algorithm: CoreSecurityTypes.EncryptionAlgorithm

    /// Optional authenticated data for authenticated encryption modes
    public let authenticatedData: [UInt8]?

    /// Optional padding mode for algorithms that require padding
    public let padding: PaddingMode?

    /// Creates a new encryption options instance
    public init(
      algorithm: CoreSecurityTypes.EncryptionAlgorithm = .aes256GCM,
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

    /// Convert to CoreSecurityTypes.EncryptionOptions
    public func toCoreOptions() -> CoreSecurityTypes.EncryptionOptions {
      CoreSecurityTypes.EncryptionOptions(
        algorithm: algorithm,
        mode: .gcm, // Default to GCM mode
        padding: .pkcs7, // Default to PKCS7 padding
        iv: nil, // Will be generated during operation
        additionalAuthenticatedData: authenticatedData
      )
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
    public let algorithm: CoreSecurityTypes.EncryptionAlgorithm

    /// Optional authenticated data that was used for encryption
    public let authenticatedData: [UInt8]?

    /// Optional padding mode for algorithms that require padding
    public let padding: PaddingMode?

    /// Creates a new decryption options instance
    public init(
      algorithm: CoreSecurityTypes.EncryptionAlgorithm = .aes256GCM,
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

    /// Convert to CoreSecurityTypes.DecryptionOptions
    public func toCoreOptions() -> CoreSecurityTypes.DecryptionOptions {
      CoreSecurityTypes.DecryptionOptions(
        algorithm: algorithm,
        mode: .gcm, // Default to GCM mode
        padding: .pkcs7, // Default to PKCS7 padding
        iv: nil, // Will be provided during operation
        additionalAuthenticatedData: authenticatedData
      )
    }

    // Implement Equatable manually
    public static func == (lhs: DecryptionOptions, rhs: DecryptionOptions) -> Bool {
      lhs.algorithm == rhs.algorithm &&
        lhs.authenticatedData == rhs.authenticatedData &&
        lhs.padding == rhs.padding
    }
  }

  /**
   Unified hashing options.
   */
  public struct HashingOptions: Sendable, Equatable {
    /// The hash algorithm to use
    public let algorithm: CoreSecurityTypes.HashAlgorithm

    /// Additional parameters for hashing
    public let parameters: [String: String]?

    /// Creates a new hashing options instance
    public init(
      algorithm: CoreSecurityTypes.HashAlgorithm = .sha256,
      parameters: [String: String]?=nil
    ) {
      self.algorithm=algorithm
      self.parameters=parameters
    }

    /// Convert to CoreSecurityTypes.HashingOptions
    public func toCoreOptions() -> CoreSecurityTypes.HashingOptions {
      CoreSecurityTypes.HashingOptions(
        algorithm: algorithm
      )
    }

    /// Convert from CoreSecurityTypes.HashingOptions
    public init(from options: CoreSecurityTypes.HashingOptions?) {
      if let options {
        algorithm=options.algorithm
        parameters=nil
      } else {
        algorithm = .sha256
        parameters=nil
      }
    }

    // Implement Equatable manually
    public static func == (lhs: HashingOptions, rhs: HashingOptions) -> Bool {
      lhs.algorithm == rhs.algorithm &&
        areMetadataEqual(lhs.parameters, rhs.parameters)
    }
  }

  /**
   Padding modes for cryptographic operations.
   */
  public enum PaddingMode: String, Sendable, CaseIterable {
    /// PKCS#7 padding (standard padding for block ciphers)
    case pkcs7

    /// No padding (data must be a multiple of the block size)
    case none
  }

  /**
   Map SecurityStorageError to a user-presentable error message.

   - Parameter error: The security storage error
   - Returns: A user-friendly error message
   */
  public static func userFriendlyErrorMessage(for error: SecurityStorageError) -> String {
    switch error {
      case .dataNotFound:
        "The security data requested was not found."
      case .keyNotFound:
        "The key requested was not found."
      case .hashNotFound:
        "The hash requested was not found."
      case let .operationFailed(message):
        "The security operation failed: \(message)"
      case .storageUnavailable:
        "The secure storage is not available."
      case .encryptionFailed:
        "The encryption operation failed."
      case .decryptionFailed:
        "The decryption operation failed."
      case .hashingFailed:
        "The hashing operation failed."
      case .hashVerificationFailed:
        "The hash verification failed."
      case .keyGenerationFailed:
        "The key generation failed."
      case .unsupportedOperation:
        "The requested operation is not supported."
      case .implementationUnavailable:
        "The security implementation is not available."
      case let .invalidIdentifier(reason):
        "The identifier is invalid: \(reason)"
      case let .identifierNotFound(identifier):
        "The security identifier '\(identifier)' was not found."
      case let .storageFailure(reason):
        "A storage system error occurred: \(reason)"
      case let .generalError(reason):
        "A general security error occurred: \(reason)"
      case let .invalidInput(message):
        "Invalid input provided: \(message)"
      case .operationRateLimited:
        "The security operation was rate limited for security purposes."
      case .storageError:
        "A storage system error occurred."
    }
  }
}

// Helper function to compare metadata dictionaries
private func areMetadataEqual(_ lhs: [String: String]?, _ rhs: [String: String]?) -> Bool {
  guard let lhs, let rhs else {
    return lhs == nil && rhs == nil
  }

  guard lhs.count == rhs.count else {
    return false
  }

  for (key, value) in lhs {
    guard let rhsValue=rhs[key], rhsValue == value else {
      return false
    }
  }

  return true
}
