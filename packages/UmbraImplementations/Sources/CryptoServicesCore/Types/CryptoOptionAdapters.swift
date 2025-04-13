import CoreSecurityTypes
import Foundation
import SecurityCoreInterfaces

// MARK: - Adapter Extensions for EncryptionOptions

/// Extension to adapt between CoreSecurityTypes.EncryptionOptions and other types
extension CoreSecurityTypes.EncryptionOptions {
  /// Convert to SecurityConfigDTO for use with SecurityProvider
  public func toSecurityConfigDTO(withMetadata metadata: [String: String]?=nil)
  -> SecurityConfigDTO {
    var configOptions = SecurityConfigOptions()

    var metadataDict = metadata ?? [:]
    if let additionalAuthenticatedData {
      metadataDict["authenticatedData"] = Data(additionalAuthenticatedData).base64EncodedString()
    }

    if !metadataDict.isEmpty {
      configOptions.metadata = metadataDict
    }

    return SecurityConfigDTO(
      encryptionAlgorithm: algorithm, // Use directly since it's the same type
      hashAlgorithm: CoreSecurityTypes.HashAlgorithm.sha256, // Default
      providerType: .basic, // Use basic provider type
      options: configOptions
    )
  }
}

// MARK: - Adapter Extensions for KeyGenerationOptions

/// Extension to adapt between various key generation options types
extension CoreSecurityTypes.KeyGenerationOptions {
  /// Convert to SecurityConfigDTO for use with SecurityProvider
  public func toSecurityConfigDTO(withMetadata additionalMetadata: [String: String]? = nil)
  -> SecurityConfigDTO {
    var configOptions = SecurityConfigOptions()

    // Create metadata
    var metadataDict = additionalMetadata ?? [:]
    metadataDict["keySize"] = String(keySizeInBits)
    metadataDict["keyType"] = keyType.rawValue
    metadataDict["extractable"] = isExtractable ? "true" : "false"
    metadataDict["useSecureEnclave"] = useSecureEnclave ? "true" : "false"

    if !metadataDict.isEmpty {
      configOptions.metadata = metadataDict
    }

    return SecurityConfigDTO(
      encryptionAlgorithm: CoreSecurityTypes.EncryptionAlgorithm.aes256GCM,
      hashAlgorithm: .sha256, // Default
      providerType: .basic, // Use basic provider type
      options: configOptions
    )
  }
}

// MARK: - Adapter Extensions for HashingOptions

/// Extension to adapt between various hashing options types
extension CoreSecurityTypes.HashingOptions {
  /// Convert to SecurityConfigDTO for use with SecurityProvider
  public func toSecurityConfigDTO(withMetadata additionalMetadata: [String: String]? = nil)
  -> SecurityConfigDTO {
    var configOptions = SecurityConfigOptions()

    // Create metadata
    var metadataDict = additionalMetadata ?? [:]
    metadataDict["algorithm"] = algorithm.rawValue
    
    if !metadataDict.isEmpty {
      configOptions.metadata = metadataDict
    }

    return SecurityConfigDTO(
      encryptionAlgorithm: .aes256GCM, // Default
      hashAlgorithm: algorithm,
      providerType: .basic, // Use basic provider type
      options: configOptions
    )
  }
}

// MARK: - Helper Methods

/// Utility to determine if two hash dictionaries are equivalent
func areHashesEquivalent(_ lhs: [String: String]?, _ rhs: [String: String]?) -> Bool {
  guard let lhs = lhs, let rhs = rhs else {
    return lhs == nil && rhs == nil
  }
  
  guard lhs.count == rhs.count else {
    return false
  }
  
  for (key, value) in lhs {
    guard let rhsValue = rhs[key], rhsValue == value else {
      return false
    }
  }
  
  return true
}
