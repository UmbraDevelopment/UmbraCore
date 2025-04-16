import Foundation
import CoreSecurityTypes
import SecurityCoreInterfaces

/// Types of signature algorithms supported by the CryptoKit implementation.
///
/// This enum defines the different signature algorithm types available
/// in the Apple CryptoKit implementation, with different security and
/// performance characteristics.
public enum SignatureKeyType: String, Sendable, Equatable, CaseIterable {
    /// P-256 ECDSA signatures, can use Secure Enclave on supported devices
    case p256 = "P256"
    
    /// P-521 ECDSA signatures for maximum security level
    case p521 = "P521"
    
    /// Curve25519 EdDSA signatures, modern and efficient
    case curve25519 = "Curve25519"
}

/// Options for cryptographic key generation.
///
/// This structure provides configuration options for cryptographic key generation,
/// allowing customisation of key characteristics, tagging, and storage.
public struct KeyGenerationOptions: Sendable, Equatable {
    /// Desired size of the key in bytes
    public let keySize: Int?
    
    /// Identifier for the key being generated
    public let resultIdentifier: String?
    
    /// Tag for identifying the key purpose
    public let keyTag: String?
    
    /// Identifier for the public key in a key pair
    public let publicKeyIdentifier: String?
    
    /// Identifier for the private key in a key pair
    public let privateKeyIdentifier: String?
    
    /// Whether to use Secure Enclave if available
    public let useSecureEnclaveIfAvailable: Bool?
    
    /// Correlation ID for tracking related operations
    public let correlationID: String?
    
    /// Initialises key generation options.
    ///
    /// - Parameters:
    ///   - keySize: Desired size of the key in bytes
    ///   - resultIdentifier: Identifier for the key being generated
    ///   - keyTag: Tag for identifying the key purpose
    ///   - publicKeyIdentifier: Identifier for the public key in a key pair
    ///   - privateKeyIdentifier: Identifier for the private key in a key pair
    ///   - useSecureEnclaveIfAvailable: Whether to use Secure Enclave if available
    ///   - correlationID: Correlation ID for tracking related operations
    public init(
        keySize: Int? = nil,
        resultIdentifier: String? = nil,
        keyTag: String? = nil,
        publicKeyIdentifier: String? = nil,
        privateKeyIdentifier: String? = nil,
        useSecureEnclaveIfAvailable: Bool? = nil,
        correlationID: String? = nil
    ) {
        self.keySize = keySize
        self.resultIdentifier = resultIdentifier
        self.keyTag = keyTag
        self.publicKeyIdentifier = publicKeyIdentifier
        self.privateKeyIdentifier = privateKeyIdentifier
        self.useSecureEnclaveIfAvailable = useSecureEnclaveIfAvailable
        self.correlationID = correlationID
    }
}

/// Options for key derivation operations.
///
/// This structure provides configuration options for key derivation operations,
/// allowing customisation of output parameters and output tracking.
public struct KeyDerivationOptions: Sendable, Equatable {
    /// Identifier for the derived key
    public let resultIdentifier: String?
    
    /// Correlation ID for tracking related operations
    public let correlationID: String?
    
    /// Initialises key derivation options.
    ///
    /// - Parameters:
    ///   - resultIdentifier: Identifier for the derived key
    ///   - correlationID: Correlation ID for tracking related operations
    public init(
        resultIdentifier: String? = nil,
        correlationID: String? = nil
    ) {
        self.resultIdentifier = resultIdentifier
        self.correlationID = correlationID
    }
}

/// Options for signature verification operations.
///
/// This structure provides configuration options for signature verification,
/// allowing customisation of verification parameters and correlation tracking.
public struct VerificationOptions: Sendable, Equatable {
    /// Correlation ID for tracking related operations
    public let correlationID: String?
    
    /// Initialises verification options.
    ///
    /// - Parameter correlationID: Correlation ID for tracking related operations
    public init(
        correlationID: String? = nil
    ) {
        self.correlationID = correlationID
    }
}

/// Options for digital signing operations.
///
/// This structure provides configuration options for digital signature generation,
/// allowing customisation of signature parameters and output tracking.
public struct SigningOptions: Sendable, Equatable {
    /// Identifier for the generated signature
    public let resultIdentifier: String?
    
    /// Correlation ID for tracking related operations
    public let correlationID: String?
    
    /// Initialises signing options.
    ///
    /// - Parameters:
    ///   - resultIdentifier: Identifier for the generated signature
    ///   - correlationID: Correlation ID for tracking related operations
    public init(
        resultIdentifier: String? = nil,
        correlationID: String? = nil
    ) {
        self.resultIdentifier = resultIdentifier
        self.correlationID = correlationID
    }
}
