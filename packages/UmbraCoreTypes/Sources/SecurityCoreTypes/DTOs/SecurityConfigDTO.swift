import Foundation
import SecurityTypes

/**
 # SecurityConfigDTO

 Data transfer object for configuring security operations with specific options.

 This structure follows the Alpha Dot Five architecture pattern for DTOs, providing
 a clear and standardised way to configure security operations across the system.
 */
public struct SecurityConfigDTO: Sendable, Equatable {
  /// Algorithm to use for cryptographic operations (e.g., "AES", "RSA", "ChaCha20")
  public let algorithm: String

  /// Key size in bits (e.g., 128, 256, 2048)
  public let keySize: Int

  /// Mode of operation for block ciphers (e.g., "GCM", "CBC")
  public let mode: String?

  /// Hash algorithm for hashing operations (e.g., "SHA256", "SHA512")
  public let hashAlgorithm: String?

  /// The specific security provider type to use for this operation
  public let providerType: SecurityProviderType?

  /// Additional options as key-value pairs
  public let options: [String: String]

  /**
   Initialises a new SecurityConfigDTO with the specified parameters.

   - Parameters:
     - algorithm: Algorithm to use (e.g., "AES", "RSA", "ChaCha20")
     - keySize: Key size in bits
     - mode: Mode of operation for block ciphers
     - hashAlgorithm: Hash algorithm to use
     - providerType: Specific security provider to use (optional)
     - options: Additional operation-specific options
   */
  public init(
    algorithm: String,
    keySize: Int,
    mode: String?=nil,
    hashAlgorithm: String?=nil,
    providerType: SecurityProviderType?=nil,
    options: [String: String]=[:]
  ) {
    self.algorithm=algorithm
    self.keySize=keySize
    self.mode=mode
    self.hashAlgorithm=hashAlgorithm
    self.providerType=providerType
    self.options=options
  }

  /**
   Initialises a new SecurityConfigDTO with the Sendable SecurityConfigOptions struct.

   This initialiser provides a type-safe way to create a configuration with
   options that can safely cross actor boundaries.

   - Parameter options: Structured configuration options that conform to Sendable
   */
  public init(options: SecurityConfigOptions) {
    // Use provided values or defaults
    algorithm=options.algorithm ?? "AES"
    keySize=options.keySize ?? 256
    mode=options.mode
    hashAlgorithm=options.hashAlgorithm
    providerType=nil // Not included in options

    // Build options dictionary
    var optionsDict: [String: String]=[:]

    // Add identifier and data fields if present
    if let identifier=options.identifier {
      optionsDict["identifier"]=identifier
    }
    if let dataBase64=options.dataBase64 {
      optionsDict["dataBase64"]=dataBase64
    }
    if let dataHex=options.dataHex {
      optionsDict["dataHex"]=dataHex
    }
    if let keyBase64=options.keyBase64 {
      optionsDict["keyBase64"]=keyBase64
    }
    if let keyIdentifier=options.keyIdentifier {
      optionsDict["keyIdentifier"]=keyIdentifier
    }
    if let signatureBase64=options.signatureBase64 {
      optionsDict["signatureBase64"]=signatureBase64
    }

    // Add all additional options
    for (key, value) in options.additionalOptions {
      optionsDict[key]=value
    }

    self.options=optionsDict
  }

  /**
   Creates a configuration for AES encryption.

   - Parameters:
     - keySize: Key size in bits (128, 192, or 256)
     - mode: Mode of operation ("GCM", "CBC", or "CTR")
     - providerType: Specific security provider to use (optional)
     - additionalOptions: Additional operation-specific options
   - Returns: A configured SecurityConfigDTO
   */
  public static func aesEncryption(
    keySize: Int=256,
    mode: String="GCM",
    providerType: SecurityProviderType?=nil,
    additionalOptions: [String: String]=[:]
  ) -> SecurityConfigDTO {
    var options=additionalOptions
    options["encryptionType"]="symmetric"

    return SecurityConfigDTO(
      algorithm: "AES",
      keySize: keySize,
      mode: mode,
      providerType: providerType,
      options: options
    )
  }

  /**
   Creates a configuration for RSA encryption.

   - Parameters:
     - keySize: Key size in bits (2048 or 4096)
     - providerType: Specific security provider to use (optional)
     - additionalOptions: Additional operation-specific options
   - Returns: A configured SecurityConfigDTO
   */
  public static func rsaEncryption(
    keySize: Int=2048,
    providerType: SecurityProviderType?=nil,
    additionalOptions: [String: String]=[:]
  ) -> SecurityConfigDTO {
    var options=additionalOptions
    options["encryptionType"]="asymmetric"

    return SecurityConfigDTO(
      algorithm: "RSA",
      keySize: keySize,
      providerType: providerType,
      options: options
    )
  }

  /**
   Creates a configuration for digital signatures.

   - Parameters:
     - algorithm: Signature algorithm ("RSA", "ECDSA")
     - hashAlgorithm: Hash algorithm to use ("SHA256", "SHA384", "SHA512")
     - providerType: Specific security provider to use (optional)
     - additionalOptions: Additional operation-specific options
   - Returns: A configured SecurityConfigDTO
   */
  public static func signature(
    algorithm: String="RSA",
    hashAlgorithm: String="SHA256",
    providerType: SecurityProviderType?=nil,
    additionalOptions: [String: String]=[:]
  ) -> SecurityConfigDTO {
    var options=additionalOptions
    options["operation"]="sign"

    return SecurityConfigDTO(
      algorithm: algorithm,
      keySize: algorithm == "RSA" ? 2048 : 256,
      hashAlgorithm: hashAlgorithm,
      providerType: providerType,
      options: options
    )
  }

  /**
   Creates a configuration for secure key generation.

   - Parameters:
     - algorithm: Key algorithm ("AES", "RSA", "ECDSA")
     - keySize: Key size in bits
     - providerType: Specific security provider to use (optional)
     - additionalOptions: Additional key generation options
   - Returns: A configured SecurityConfigDTO
   */
  public static func keyGeneration(
    algorithm: String,
    keySize: Int,
    providerType: SecurityProviderType?=nil,
    additionalOptions: [String: String]=[:]
  ) -> SecurityConfigDTO {
    var options=additionalOptions
    options["operation"]="generateKey"

    return SecurityConfigDTO(
      algorithm: algorithm,
      keySize: keySize,
      providerType: providerType,
      options: options
    )
  }
}
