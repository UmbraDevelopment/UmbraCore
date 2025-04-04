import CoreSecurityTypes
import CryptoTypes
import DomainSecurityTypes
import Foundation
import SecurityCoreInterfaces

// MARK: - Adapter Extensions for EncryptionOptions

/// Extension to adapt between SecurityCoreInterfaces.EncryptionOptions and CryptoTypes.CryptoOperationOptionsDTO
extension EncryptionOptions {
    /// Convert to CryptoOperationOptionsDTO for use with internal APIs
    public func toCryptoOperationOptionsDTO() -> CryptoOperationOptionsDTO {
        // Map the algorithm and mode
        let cryptoMode: CryptoMode
        switch algorithm {
        case .aes256CBC:
            cryptoMode = .cbc
        case .aes256GCM:
            cryptoMode = .gcm
        }
        
        // Use padding from options or default to PKCS7
        let paddingMode = padding ?? .pkcs7
        
        return CryptoOperationOptionsDTO(
            mode: cryptoMode,
            padding: paddingMode,
            initializationVector: nil, // Will be generated during operation
            authenticatedData: authenticatedData
        )
    }
}

/// Extension to adapt between SecurityCoreInterfaces.DecryptionOptions and CryptoTypes.CryptoOperationOptionsDTO
extension DecryptionOptions {
    /// Convert to CryptoOperationOptionsDTO for use with internal APIs
    public func toCryptoOperationOptionsDTO() -> CryptoOperationOptionsDTO {
        // Map the algorithm and mode
        let cryptoMode: CryptoMode
        switch algorithm {
        case .aes256CBC:
            cryptoMode = .cbc
        case .aes256GCM:
            cryptoMode = .gcm
        }
        
        // Use padding from options or default to PKCS7
        let paddingMode = padding ?? .pkcs7
        
        return CryptoOperationOptionsDTO(
            mode: cryptoMode,
            padding: paddingMode,
            initializationVector: nil, // Will be parsed from encrypted data
            authenticatedData: authenticatedData
        )
    }
}

// MARK: - Adapter Extensions for KeyGenerationOptions

/// Extension to adapt between SecurityCoreInterfaces.KeyGenerationOptions and CryptoTypes.KeyGenerationOptionsDTO
extension KeyGenerationOptions {
    /// Convert to KeyGenerationOptionsDTO for use with internal APIs
    /// - Parameter keySize: The size of the key in bits
    /// - Returns: A DTO compatible with the CryptoTypes module
    public func toKeyGenerationOptionsDTO(keySize: Int) -> KeyGenerationOptionsDTO {
        return KeyGenerationOptionsDTO(
            algorithm: algorithm,
            keySize: keySize,
            exportable: exportable,
            requiresAuthentication: requiresAuthentication
        )
    }
}

// MARK: - Adapter Extensions for HashingOptions

/// Extension to adapt between SecurityCoreInterfaces.HashingOptions and CryptoTypes.HashAlgorithm
extension HashingOptions {
    /// Get the equivalent CoreSecurityTypes.HashAlgorithm
    public var hashAlgorithm: CoreSecurityTypes.HashAlgorithm {
        return algorithm
    }
}
