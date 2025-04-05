import CoreSecurityTypes
import CryptoTypes
import DomainSecurityTypes
import Foundation
import SecurityCoreInterfaces

// MARK: - Adapter Extensions for EncryptionOptions

/// Extension to adapt between SecurityCoreInterfaces.EncryptionOptions and
/// CryptoTypes.CryptoOperationOptionsDTO
extension SecurityCoreInterfaces.EncryptionOptions {
  /// Convert to CryptoOperationOptionsDTO for use with internal APIs
  public func toCryptoOperationOptionsDTO() -> CryptoOperationOptionsDTO {
    // Map the algorithm and mode
    let cryptoMode: CryptoMode=switch algorithm {
      case .aes256CBC:
        .cbc
      case .aes256GCM:
        .gcm
      default:
        .gcm // Use GCM mode as fallback
    }

    return CryptoOperationOptionsDTO(
      mode: cryptoMode,
      padding: .pkcs7, // Default to PKCS7
      initializationVector: nil, // Will be generated during operation
      authenticatedData: authenticatedData
    )
  }

  /// Convert to SecurityConfigDTO for use with SecurityProvider
  public func toSecurityConfigDTO(withMetadata metadata: [String: String]?=nil)
  -> SecurityConfigDTO {
    var configOptions=SecurityConfigOptions()

    var metadataDict=metadata ?? [:]
    if let authenticatedData {
      metadataDict["authenticatedData"]=Data(authenticatedData).base64EncodedString()
    }

    if !metadataDict.isEmpty {
      configOptions.metadata=metadataDict
    }

    return SecurityConfigDTO(
      encryptionAlgorithm: toAlgorithmEnum(),
      hashAlgorithm: CoreSecurityTypes.HashAlgorithm.sha256, // Default
      providerType: .basic, // Use basic provider type instead of non-existent .default
      options: configOptions
    )
  }

  /// Convert to interface EncryptionOptions (used when adapting options)
  public func toInterfaceOptions() -> SecurityCoreInterfaces.EncryptionOptions {
    SecurityCoreInterfaces.EncryptionOptions(
      algorithm: toAlgorithmEnum()
    )
  }

  /// Convert internal encryption algorithm to enum representation
  private func toAlgorithmEnum() -> CoreSecurityTypes.EncryptionAlgorithm {
    switch algorithm {
      case .aes256GCM:
        .aes256GCM
      case .aes256CBC:
        .aes256CBC
      case .chacha20Poly1305:
        .chacha20Poly1305
    }
  }
}

// MARK: - Adapter Extensions for DecryptionOptions

/// Extension to adapt between SecurityCoreInterfaces.DecryptionOptions and
/// CryptoTypes.CryptoOperationOptionsDTO
extension SecurityCoreInterfaces.DecryptionOptions {
  /// Convert to CryptoOperationOptionsDTO for use with internal APIs
  public func toCryptoOperationOptionsDTO() -> CryptoOperationOptionsDTO {
    // Map the algorithm and mode
    let cryptoMode: CryptoMode=switch algorithm {
      case .aes256CBC:
        .cbc
      case .aes256GCM:
        .gcm
      default:
        .gcm // Use GCM mode as fallback
    }

    return CryptoOperationOptionsDTO(
      mode: cryptoMode,
      padding: .pkcs7, // Default to PKCS7
      initializationVector: nil, // Will be provided during operation
      authenticatedData: authenticatedData
    )
  }

  /// Convert to SecurityConfigDTO for use with SecurityProvider
  public func toSecurityConfigDTO(withMetadata metadata: [String: String]?=nil)
  -> SecurityConfigDTO {
    var configOptions=SecurityConfigOptions()

    var metadataDict=metadata ?? [:]
    if let authenticatedData {
      metadataDict["authenticatedData"]=Data(authenticatedData).base64EncodedString()
    }

    if !metadataDict.isEmpty {
      configOptions.metadata=metadataDict
    }

    return SecurityConfigDTO(
      encryptionAlgorithm: toAlgorithmEnum(),
      hashAlgorithm: CoreSecurityTypes.HashAlgorithm.sha256, // Default
      providerType: .basic, // Use basic provider type instead of non-existent .default
      options: configOptions
    )
  }

  /// Convert to interface DecryptionOptions (used when adapting options)
  public func toInterfaceOptions() -> SecurityCoreInterfaces.DecryptionOptions {
    SecurityCoreInterfaces.DecryptionOptions(
      algorithm: toAlgorithmEnum()
    )
  }

  /// Convert internal encryption algorithm to enum representation
  private func toAlgorithmEnum() -> CoreSecurityTypes.EncryptionAlgorithm {
    switch algorithm {
      case .aes256GCM:
        .aes256GCM
      case .aes256CBC:
        .aes256CBC
      case .chacha20Poly1305:
        .chacha20Poly1305
    }
  }
}

// MARK: - Adapter Extensions for KeyGenerationOptions

/// Extension to adapt between various key generation options types
extension SecurityCoreInterfaces.KeyGenerationOptions {
  /// Convert to KeyGenerationOptionsDTO for internal use
  public func toKeyGenerationOptionsDTO(keySize: Int) -> KeyGenerationOptionsDTO {
    KeyGenerationOptionsDTO(
      algorithm: .aes, // Default to AES
      keySize: keySize,
      exportable: false, // Default to not exportable
      requiresAuthentication: false // Default to not requiring auth
    )
  }

  /// Convert to SecurityConfigDTO for use with SecurityProvider
  public func toSecurityConfigDTO(
    keySize: Int,
    withMetadata _: [String: String]?=nil
  ) -> SecurityConfigDTO {
    var configOptions=SecurityConfigOptions()

    let metadataDict=addMetadata(keySize: keySize, keyType: keyType)

    if !metadataDict.isEmpty {
      configOptions.metadata=metadataDict
    }

    return SecurityConfigDTO(
      encryptionAlgorithm: CoreSecurityTypes.EncryptionAlgorithm.aes256GCM,
      // Default encryption algorithm
      hashAlgorithm: .sha256, // Default
      providerType: .basic, // Use basic provider type instead of non-existent .default
      options: configOptions
    )
  }

  /// Convert to interface KeyGenerationOptions (used when adapting options)
  public func toInterfaceOptions() -> SecurityCoreInterfaces.KeyGenerationOptions {
    // Create equivalent interface options
    SecurityCoreInterfaces.KeyGenerationOptions(
      persistent: persistent,
      keyType: keyType
    )
  }

  private func addMetadata(keySize: Int, keyType: KeyType) -> [String: String] {
    var metadataDict=[String: String]()
    metadataDict["keySize"]="\(keySize)"
    metadataDict["keyType"]="\(keyType.rawValue)" // Convert UInt8 to String
    return metadataDict
  }
}

// MARK: - Adapter Extensions for HashingOptions

/// Extension to adapt between SecurityCoreInterfaces.HashingOptions and various format options
extension SecurityCoreInterfaces.HashingOptions {
  /// Convert to SecurityConfigDTO for use with SecurityProvider
  public func toSecurityConfigDTO(withMetadata metadata: [String: String]?=nil)
  -> SecurityConfigDTO {
    var configOptions=SecurityConfigOptions()

    if let metadata, !metadata.isEmpty {
      configOptions.metadata=metadata
    }

    return SecurityConfigDTO(
      encryptionAlgorithm: CoreSecurityTypes.EncryptionAlgorithm.aes256GCM,
      // Default encryption algorithm
      hashAlgorithm: algorithm,
      providerType: .basic, // Use basic provider type instead of non-existent .default
      options: configOptions
    )
  }

  /// Convert to interface HashingOptions (used when adapting options)
  public func toInterfaceOptions() -> SecurityCoreInterfaces.HashingOptions {
    SecurityCoreInterfaces.HashingOptions(
      algorithm: toHashAlgorithm()
    )
  }

  /// Convert internal hash algorithm to interface type
  private func toHashAlgorithm() -> CoreSecurityTypes.HashAlgorithm {
    switch algorithm {
      case .sha256, .sha512:
        algorithm
      default:
        .sha256
    }
  }
}

// MARK: - Adapter Extensions for CryptoOptions and HMACOptions

extension CryptoOptions {
  /// Convert CryptoOptions to SecurityConfigDTO
  public func toSecurityConfigDTO(withMetadata metadata: [String: String]?=nil)
  -> SecurityConfigDTO {
    var configOptions=SecurityConfigOptions()

    var metadataDict=metadata ?? [:]
    // Add any additional metadata from parameters
    if let params=parameters {
      for (key, param) in params {
        if case let .string(value)=param {
          metadataDict[key]=value
        }
      }
    }

    if !metadataDict.isEmpty {
      configOptions.metadata=metadataDict
    }

    return SecurityConfigDTO(
      encryptionAlgorithm: algorithm,
      hashAlgorithm: .sha256, // Default
      providerType: .basic,
      options: configOptions
    )
  }
}

extension HMACOptions {
  /// Convert HMACOptions to SecurityConfigDTO
  public func toSecurityConfigDTO(withMetadata metadata: [String: String]?=nil)
  -> SecurityConfigDTO {
    var configOptions=SecurityConfigOptions()

    var metadataDict=metadata ?? [:]
    // Add any additional metadata from parameters
    if let params=parameters {
      for (key, param) in params {
        if case let .string(value)=param {
          metadataDict[key]=value
        }
      }
    }

    if !metadataDict.isEmpty {
      configOptions.metadata=metadataDict
    }

    return SecurityConfigDTO(
      encryptionAlgorithm: .aes256GCM, // Default
      hashAlgorithm: algorithm,
      providerType: .basic,
      options: configOptions
    )
  }
}

// MARK: - Dictionary Extensions

extension [String: CryptoParameter] {
  /// Test whether two dictionaries of parameters are equivalent
  func isEquivalentTo(_ other: [String: CryptoParameter]?) -> Bool {
    guard let other else { return false }
    guard count == other.count else { return false }

    // Compare keys and values for semantic equivalence
    for (key, value) in self {
      guard let otherValue=other[key] else { return false }
      if value != otherValue {
        return false
      }
    }

    return true
  }
}

// MARK: - SecurityConfigDTO Extensions

/// Extension to extract options from SecurityConfigDTO
extension SecurityConfigDTO {
  /// Extract encryption options from the configuration
  public var extractedEncryptionOptions: SecurityCoreInterfaces.EncryptionOptions? {
    nil // Simplified until we have the proper members
  }

  /// Extract decryption options from the configuration
  public var extractedDecryptionOptions: SecurityCoreInterfaces.DecryptionOptions? {
    nil // Simplified until we have the proper members
  }

  /// Extract key generation options from the configuration
  public var extractedKeyGenerationOptions: SecurityCoreInterfaces.KeyGenerationOptions? {
    nil // Simplified until we have the proper members
  }

  /// Extract hashing options from the configuration
  public var extractedHashingOptions: SecurityCoreInterfaces.HashingOptions? {
    nil // Simplified until we have the proper members
  }

  /// Extract a typed value from metadata
  public func extractMetadataValue<T>(forKey key: String) -> T? {
    guard let metadataValue=options?.metadata?[key] else {
      return nil
    }

    // Direct string value handling without redundant cast
    if T.self == String.self {
      return metadataValue as? T
    }

    // Handle string conversion to other types
    if T.self == Int.self, let intValue=Int(metadataValue) {
      return intValue as? T
    } else if T.self == Bool.self, let boolValue=Bool(metadataValue) {
      return boolValue as? T
    }

    return nil
  }
}

// MARK: - Public API Extensions for Hash Algorithms

/// Extension to facilitate conversion between hash algorithm types
extension CoreSecurityTypes.HashAlgorithm {
  /// Convert to interface HashAlgorithm
  public func toInterfaceHashAlgorithm() -> CoreSecurityTypes.HashAlgorithm {
    switch self {
      case .sha256:
        CoreSecurityTypes.HashAlgorithm.sha256
      case .sha512:
        CoreSecurityTypes.HashAlgorithm.sha512
      default:
        CoreSecurityTypes.HashAlgorithm.sha256
    }
  }
}
