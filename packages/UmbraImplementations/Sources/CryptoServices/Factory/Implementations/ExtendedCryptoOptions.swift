import CoreSecurityTypes
import CryptoInterfaces
import CryptoTypes
import DomainSecurityTypes
import Foundation
import SecurityCoreInterfaces

/**
 Extended configuration options for the CryptoService implementation.

 These options extend the core CryptoServiceOptions with additional settings
 specific to the factory implementation, including encryption strength,
 iteration counts for key derivation, and other security-related settings.
 */
public struct FactoryCryptoOptions: Sendable {
  /// The number of iterations to use for PBKDF2 key derivation
  public let defaultIterations: Int

  /// Whether to enforce strong key requirements
  public let enforceStrongKeys: Bool

  /// Whether to use secure random for all operations
  public let useSecureRandom: Bool

  /// Whether to zero memory after use
  public let zeroMemoryAfterUse: Bool

  /**
   Initialises a new set of factory crypto options.

   - Parameters:
     - defaultIterations: The number of iterations to use for PBKDF2 key derivation
     - enforceStrongKeys: Whether to enforce strong key requirements
     - useSecureRandom: Whether to use secure random for all operations
     - zeroMemoryAfterUse: Whether to zero memory after use
   */
  public init(
    defaultIterations: Int=10000,
    enforceStrongKeys: Bool=true,
    useSecureRandom: Bool=true,
    zeroMemoryAfterUse: Bool=true
  ) {
    self.defaultIterations=defaultIterations
    self.enforceStrongKeys=enforceStrongKeys
    self.useSecureRandom=useSecureRandom
    self.zeroMemoryAfterUse=zeroMemoryAfterUse
  }

  /**
   Converts these factory options to standard CryptoServiceOptions.

   - Parameters:
     - algorithm: The encryption algorithm to use (defaults to AES-256-GCM)
     - hashAlgorithm: The hash algorithm to use (defaults to SHA-256)
     - keyLength: The key length in bytes (defaults to 32 bytes / 256 bits)

   - Returns: A CryptoServiceOptions instance with the appropriate settings
   */
  public func toCryptoServiceOptions(
    algorithm: CoreSecurityTypes.EncryptionAlgorithm = .aes256GCM,
    hashAlgorithm: CoreSecurityTypes.HashAlgorithm = .sha256,
    keyLength: Int=32
  ) -> CryptoServiceOptions {
    // Create parameters dictionary with our additional options
    var parameters: [String: CryptoParameter]=[:]

    // Add PBKDF2 iterations if using key derivation
    parameters["iterations"] = .integer(defaultIterations)

    // Add strong key enforcement flag
    parameters["enforceStrongKeys"] = .boolean(enforceStrongKeys)

    // Add secure random flag
    parameters["useSecureRandom"] = .boolean(useSecureRandom)

    // Add memory zeroing flag
    parameters["zeroMemoryAfterUse"] = .boolean(zeroMemoryAfterUse)

    return CryptoServiceOptions(
      algorithm: algorithm,
      hashAlgorithm: hashAlgorithm,
      keyLength: keyLength,
      parameters: parameters
    )
  }
}

/**
 Extension to CryptoServiceOptions to add factory-specific functionality.
 */
extension CryptoServiceOptions {
  /**
   Creates a new instance with factory-specific options.

   - Parameters:
     - factoryOptions: The factory options to apply
     - algorithm: The encryption algorithm to use
     - hashAlgorithm: The hash algorithm to use
     - keyLength: The key length to use

   - Returns: A new CryptoServiceOptions instance
   */
  public static func withFactoryOptions(
    _ factoryOptions: FactoryCryptoOptions,
    algorithm: CoreSecurityTypes.EncryptionAlgorithm = .aes256GCM,
    hashAlgorithm: CoreSecurityTypes.HashAlgorithm = .sha256,
    keyLength: Int=32
  ) -> CryptoServiceOptions {
    factoryOptions.toCryptoServiceOptions(
      algorithm: algorithm,
      hashAlgorithm: hashAlgorithm,
      keyLength: keyLength
    )
  }

  /**
   Extracts an iterations count from the parameters.

   - Returns: The iterations count or a default value of 10000
   */
  public var iterations: Int {
    if
      let parameters,
      let iterationsParam=parameters["iterations"],
      case let .integer(iterations)=iterationsParam
    {
      return iterations
    }
    return 10000 // Default value
  }

  /**
   Checks if strong keys are enforced.

   - Returns: Whether strong keys are enforced
   */
  public var enforceStrongKeys: Bool {
    if
      let parameters,
      let enforceParam=parameters["enforceStrongKeys"],
      case let .boolean(enforce)=enforceParam
    {
      return enforce
    }
    return true // Default to safe option
  }
}

/**
 Options for key generation in CryptoService.
 */
// Removing this duplicate declaration as we'll use the typealias instead
// public struct KeyGenerationOptions: Sendable {
//   /// The purpose of the key
//   public let purpose: KeyPurpose
//
//   /// Whether the key should be exportable
//   public let isExportable: Bool
//
//   /// The expiration date of the key, if any
//   public let expirationDate: Date?
//
//   /**
//    Initialises a new set of key generation options.
//
//    - Parameters:
//      - purpose: The purpose of the key
//      - isExportable: Whether the key should be exportable
//      - expirationDate: The expiration date of the key, if any
//    */
//   public init(
//     purpose: KeyPurpose = .encryption,
//     isExportable: Bool=false,
//     expirationDate: Date?=nil
//   ) {
//     self.purpose=purpose
//     self.isExportable=isExportable
//     self.expirationDate=expirationDate
//   }
// }

/**
 The purpose of a cryptographic key.
 */
public enum KeyPurpose: String, Sendable {
  /// Key used for encryption
  case encryption

  /// Key used for signing
  case signing

  /// Key used for key wrapping
  case keyWrapping

  /// Key used for key derivation
  case keyDerivation

  /// Key used for multiple purposes
  case general
}

/**
 The algorithm to use for encryption.
 
 This uses the canonical EncryptionAlgorithm from CoreSecurityTypes.
 */
public typealias EncryptionAlgorithm = CoreSecurityTypes.EncryptionAlgorithm

/**
 The algorithm to use for hashing.
 
 This uses the canonical HashAlgorithm from CoreSecurityTypes.
 */
public typealias HashAlgorithm = CoreSecurityTypes.HashAlgorithm
