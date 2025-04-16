import Foundation
import CoreSecurityTypes
import SecurityCoreInterfaces

/// Standard error codes for cryptographic operations.
///
/// These codes provide a consistent categorisation of errors that may occur
/// during cryptographic operations with the Apple CryptoKit implementation.
public enum CryptoErrorCode: Int, Error {
    /// Invalid or corrupted input data
    case invalidInputData = 1000
    
    /// Invalid key material (wrong size, format, or type)
    case invalidKey = 1001
    
    /// Authentication failure during authenticated encryption
    case authenticationFailed = 1002
    
    /// Invalid algorithm specified for the operation
    case unsupportedAlgorithm = 1003
    
    /// Invalid mode specified for the operation
    case unsupportedMode = 1004
    
    /// Key derivation failure
    case keyDerivationFailed = 1005
    
    /// Error during encryption operation
    case encryptionFailed = 1006
    
    /// Error during decryption operation
    case decryptionFailed = 1007
    
    /// Error during signing operation
    case signingFailed = 1008
    
    /// Error during verification operation
    case verificationFailed = 1009
    
    /// Error during random number generation
    case randomGenerationFailed = 1010
    
    /// Internal error in the cryptographic implementation
    case internalError = 1011
}

/// Error type for cryptographic operations.
///
/// This error type encapsulates errors that may occur during cryptographic
/// operations with the Apple CryptoKit implementation, providing rich
/// context and categorisation to assist with troubleshooting.
public struct CryptoOperationError: Error {
    /// The error code indicating the category of error
    public let code: CryptoErrorCode
    
    /// A descriptive message for the error
    public let message: String
    
    /// Optional underlying error that caused this error
    public let underlyingError: Error?
    
    /// Initialise a new cryptographic operation error.
    ///
    /// - Parameters:
    ///   - code: The error code
    ///   - message: A descriptive message
    ///   - underlyingError: Optional underlying error
    public init(
        code: CryptoErrorCode,
        message: String,
        underlyingError: Error? = nil
    ) {
        self.code = code
        self.message = message
        self.underlyingError = underlyingError
    }
    
    /// Convert to a SecurityStorageError for interface compatibility.
    ///
    /// - Returns: A SecurityStorageError equivalent to this error
    public func toSecurityStorageError() -> SecurityStorageError {
        switch code {
        case .invalidInputData:
            return .generalError(reason: "Invalid input data: \(message)")
        case .invalidKey:
            return .generalError(reason: "Invalid key: \(message)")
        case .authenticationFailed:
            return .generalError(reason: "Authentication failed: \(message)")
        case .unsupportedAlgorithm, .unsupportedMode:
            return .unsupportedOperation
        case .encryptionFailed:
            return .encryptionFailed
        case .decryptionFailed:
            return .decryptionFailed
        case .signingFailed:
            return .operationFailed("Signing failed: \(message)")
        case .verificationFailed:
            return .operationFailed("Verification failed: \(message)")
        case .keyDerivationFailed:
            return .operationFailed("Key derivation failed: \(message)")
        case .randomGenerationFailed:
            return .operationFailed("Random number generation failed: \(message)")
        case .internalError:
            return .generalError(reason: "Internal error: \(message)")
        }
    }
}

/// Extension to SecurityStorageError to add detailed messages.
extension SecurityStorageError {
    /// Creates a user-friendly error message
    public var userFriendlyMessage: String {
        switch self {
        case .storageUnavailable:
            return "The secure storage is temporarily unavailable. Please try again later."
        case .dataNotFound:
            return "The requested data could not be found in secure storage."
        case .keyNotFound:
            return "The cryptographic key could not be found."
        case .hashNotFound:
            return "The cryptographic hash could not be found."
        case .encryptionFailed:
            return "An error occurred during encryption. Your data was not secured."
        case .decryptionFailed:
            return "An error occurred during decryption. Your data could not be accessed."
        case .hashingFailed:
            return "An error occurred during hashing operation."
        case .hashVerificationFailed:
            return "The integrity check failed. The data may have been tampered with."
        case .keyGenerationFailed:
            return "Failed to generate a secure cryptographic key."
        case .unsupportedOperation:
            return "This cryptographic operation is not supported on your device."
        case .implementationUnavailable:
            return "The required security module is not available on your device."
        case let .invalidIdentifier(reason):
            return "Invalid security identifier: \(reason)"
        case let .identifierNotFound(identifier):
            return "Security identifier not found: \(identifier)"
        case let .storageFailure(reason):
            return "Storage operation failed: \(reason)"
        case let .generalError(reason):
            return "Security error: \(reason)"
        case let .operationFailed(message):
            return message.isEmpty ? "Security operation failed" : "Security operation failed: \(message)"
        }
    }
    
    /// Creates a detailed developer-facing error message
    public var detailedMessage: String {
        switch self {
        case .storageUnavailable:
            return "Security storage provider is unavailable or inaccessible"
        case .dataNotFound:
            return "Data not found in secure storage"
        case .keyNotFound:
            return "Cryptographic key not found in key storage"
        case .hashNotFound:
            return "Hash value not found in secure storage"
        case .encryptionFailed:
            return "Encryption operation failed"
        case .decryptionFailed:
            return "Decryption operation failed"
        case .hashingFailed:
            return "Hashing operation failed"
        case .hashVerificationFailed:
            return "Hash verification failed - data integrity check negative"
        case .keyGenerationFailed:
            return "Failed to generate cryptographic key"
        case .unsupportedOperation:
            return "Operation not supported by current security provider"
        case .implementationUnavailable:
            return "Security provider implementation unavailable"
        case let .invalidIdentifier(reason):
            return "Invalid identifier: \(reason)"
        case let .identifierNotFound(identifier):
            return "Identifier not found: \(identifier)"
        case let .storageFailure(reason):
            return "Storage failure: \(reason)"
        case let .generalError(reason):
            return "General security error: \(reason)"
        case let .operationFailed(message):
            return "Operation failed: \(message)"
        }
    }
}
