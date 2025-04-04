import CoreSecurityTypes
import CryptoTypes
import DomainSecurityTypes
import Foundation
import SecurityCoreInterfaces

// MARK: - Adapter Extensions for EncryptionOptions

/// Extension to adapt between SecurityCoreInterfaces.EncryptionOptions and CryptoTypes.CryptoOperationOptionsDTO
extension SecurityCoreInterfaces.EncryptionOptions {
    /// Convert to CryptoOperationOptionsDTO for use with internal APIs
    public func toCryptoOperationOptionsDTO() -> CryptoOperationOptionsDTO {
        // Map the algorithm and mode
        let cryptoMode: CryptoMode
        switch algorithm {
        case .aes256CBC:
            cryptoMode = .cbc
        case .aes256GCM:
            cryptoMode = .gcm
        case .chacha20Poly1305:
            cryptoMode = .gcm // Use GCM mode as fallback
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

/// Extension to adapt between EncryptionOptions and SecurityCoreInterfaces.EncryptionOptions
extension EncryptionOptions {
    /// Convert to SecurityCoreInterfaces.EncryptionOptions for interface compatibility
    public func toInterfaceOptions() -> SecurityCoreInterfaces.EncryptionOptions {
        // Create equivalent interface options
        return SecurityCoreInterfaces.EncryptionOptions(
            algorithm: .aes256GCM, // Default to most secure
            padding: .pkcs7,
            authenticatedData: nil
        )
    }
}

/// Extension to adapt between SecurityCoreInterfaces.DecryptionOptions and CryptoTypes.CryptoOperationOptionsDTO
extension SecurityCoreInterfaces.DecryptionOptions {
    /// Convert to CryptoOperationOptionsDTO for use with internal APIs
    public func toCryptoOperationOptionsDTO() -> CryptoOperationOptionsDTO {
        // Map the algorithm and mode
        let cryptoMode: CryptoMode
        switch algorithm {
        case .aes256CBC:
            cryptoMode = .cbc
        case .aes256GCM:
            cryptoMode = .gcm
        case .chacha20Poly1305:
            cryptoMode = .gcm // Use GCM mode as fallback
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

/// Extension to adapt between DecryptionOptions and SecurityCoreInterfaces.DecryptionOptions
extension DecryptionOptions {
    /// Convert to SecurityCoreInterfaces.DecryptionOptions for interface compatibility
    public func toInterfaceOptions() -> SecurityCoreInterfaces.DecryptionOptions {
        // Create equivalent interface options
        return SecurityCoreInterfaces.DecryptionOptions(
            algorithm: .aes256GCM, // Default to most secure
            padding: .pkcs7,
            authenticatedData: nil
        )
    }
}

// MARK: - Adapter Extensions for KeyGenerationOptions

/// Extension to adapt between SecurityCoreInterfaces.KeyGenerationOptions and CryptoTypes.KeyGenerationOptionsDTO
extension SecurityCoreInterfaces.KeyGenerationOptions {
    /// Convert to KeyGenerationOptionsDTO for use with internal APIs
    /// - Parameter keySize: The size of the key in bits
    /// - Returns: A DTO compatible with the CryptoTypes module
    public func toKeyGenerationOptionsDTO(keySize: Int) -> KeyGenerationOptionsDTO {
        return KeyGenerationOptionsDTO(
            algorithm: self.algorithm,
            keySize: keySize,
            exportable: self.exportable,
            requiresAuthentication: self.requiresAuthentication
        )
    }
}

/// Extension to adapt between KeyGenerationOptions and SecurityCoreInterfaces.KeyGenerationOptions
extension KeyGenerationOptions {
    /// Convert to SecurityCoreInterfaces.KeyGenerationOptions for interface compatibility
    public func toInterfaceOptions() -> SecurityCoreInterfaces.KeyGenerationOptions {
        // Create equivalent interface options
        return SecurityCoreInterfaces.KeyGenerationOptions(
            algorithm: .aes256,
            exportable: true,
            requiresAuthentication: false
        )
    }
}

// MARK: - Adapter Extensions for HashingOptions

/// Extension to adapt between SecurityCoreInterfaces.HashingOptions and CoreSecurityTypes.HashAlgorithm
extension SecurityCoreInterfaces.HashingOptions {
    /// Get the equivalent CoreSecurityTypes.HashAlgorithm
    public var hashAlgorithm: CoreSecurityTypes.HashAlgorithm {
        return algorithm
    }
}

/// Extension to adapt between HashingOptions and SecurityCoreInterfaces.HashingOptions
extension HashingOptions {
    /// Convert to SecurityCoreInterfaces.HashingOptions for interface compatibility
    public func toInterfaceOptions() -> SecurityCoreInterfaces.HashingOptions {
        // Create equivalent interface options
        return SecurityCoreInterfaces.HashingOptions(
            algorithm: CoreSecurityTypes.HashAlgorithm.sha256
        )
    }
}

// MARK: - HashAlgorithm disambiguation extensions

/// Extension to disambiguate between different HashAlgorithm types
extension HMACOptions {
    /// Get the core security hash algorithm from HMAC options
    public var coreHashAlgorithm: CoreSecurityTypes.HashAlgorithm {
        // Use SHA-256 as default for ambiguous cases
        return CoreSecurityTypes.HashAlgorithm.sha256
    }
}

// MARK: - Equatable conformance helpers

/// Helper for comparing dictionaries that aren't naturally Equatable
extension Dictionary where Key == String, Value == Any {
    /// Check if two dictionaries have the same keys and values that match when converted to strings
    func isEquivalentTo(_ other: [String: Any]?) -> Bool {
        guard let other = other else {
            return self.isEmpty
        }
        guard self.keys.count == other.keys.count else {
            return false
        }
        
        for (key, value) in self {
            guard let otherValue = other[key] else {
                return false
            }
            
            // Compare string representations as a best effort
            if String(describing: value) != String(describing: otherValue) {
                return false
            }
        }
        
        return true
    }
}

// MARK: - Equatable implementations

/// Equatable implementation for CryptoOptions
extension CryptoOptions {
    public static func == (lhs: CryptoOptions, rhs: CryptoOptions) -> Bool {
        return lhs.algorithm == rhs.algorithm &&
            (lhs.parameters?.isEquivalentTo(rhs.parameters) ?? rhs.parameters == nil)
    }
}

/// Equatable implementation for HMACOptions
extension HMACOptions {
    public static func == (lhs: HMACOptions, rhs: HMACOptions) -> Bool {
        // Use string representation for algorithm comparison to avoid ambiguity
        return String(describing: lhs.algorithm) == String(describing: rhs.algorithm) &&
            (lhs.parameters?.isEquivalentTo(rhs.parameters) ?? rhs.parameters == nil)
    }
}
