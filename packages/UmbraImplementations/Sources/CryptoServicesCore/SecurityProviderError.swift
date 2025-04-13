import CoreSecurityTypes
import Foundation

/**
 Error types for security provider operations.
 
 These errors represent the various failure modes that can occur during
 cryptographic operations and are consistently used across all security provider
 implementations to ensure uniform error handling.
 */
public enum SecurityProviderError: Error, Sendable, Equatable {
    /// Invalid key size for the requested operation
    case invalidKeySize(expected: Int, actual: Int)
    
    /// Invalid initialization vector size for the requested operation
    case invalidIVSize(expected: Int, actual: Int)
    
    /// Encryption operation failed
    case encryptionFailed(String)
    
    /// Decryption operation failed
    case decryptionFailed(String)
    
    /// Hashing operation failed
    case hashingFailed(String)
    
    /// Digital signature operation failed
    case signingFailed(String)
    
    /// Signature verification failed
    case verificationFailed(String)
    
    /// Random number generation failed
    case randomGenerationFailed(String)
    
    /// Key generation failed
    case keyGenerationFailed(String)
    
    /// Algorithm not supported by this provider
    case unsupportedAlgorithm(CoreSecurityTypes.EncryptionAlgorithm)
    
    /// Provider configuration error
    case configurationError(String)
    
    /// Internal error in the provider
    case internalError(String)
    
    // MARK: - Equatable Implementation
    
    public static func == (lhs: SecurityProviderError, rhs: SecurityProviderError) -> Bool {
        switch (lhs, rhs) {
        case (.invalidKeySize(let lhsExpected, let lhsActual), .invalidKeySize(let rhsExpected, let rhsActual)):
            return lhsExpected == rhsExpected && lhsActual == rhsActual
        case (.invalidIVSize(let lhsExpected, let lhsActual), .invalidIVSize(let rhsExpected, let rhsActual)):
            return lhsExpected == rhsExpected && lhsActual == rhsActual
        case (.encryptionFailed(let lhsReason), .encryptionFailed(let rhsReason)):
            return lhsReason == rhsReason
        case (.decryptionFailed(let lhsReason), .decryptionFailed(let rhsReason)):
            return lhsReason == rhsReason
        case (.hashingFailed(let lhsReason), .hashingFailed(let rhsReason)):
            return lhsReason == rhsReason
        case (.signingFailed(let lhsReason), .signingFailed(let rhsReason)):
            return lhsReason == rhsReason
        case (.verificationFailed(let lhsReason), .verificationFailed(let rhsReason)):
            return lhsReason == rhsReason
        case (.randomGenerationFailed(let lhsReason), .randomGenerationFailed(let rhsReason)):
            return lhsReason == rhsReason
        case (.keyGenerationFailed(let lhsReason), .keyGenerationFailed(let rhsReason)):
            return lhsReason == rhsReason
        case (.unsupportedAlgorithm(let lhsAlgo), .unsupportedAlgorithm(let rhsAlgo)):
            return lhsAlgo == rhsAlgo
        case (.configurationError(let lhsReason), .configurationError(let rhsReason)):
            return lhsReason == rhsReason
        case (.internalError(let lhsReason), .internalError(let rhsReason)):
            return lhsReason == rhsReason
        default:
            return false
        }
    }
}
