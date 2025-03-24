import Foundation

import UmbraErrorsCore

/// Domain identifier for crypto errors
public enum CryptoErrorDomain: String, CaseIterable, Sendable {
    /// Domain identifier
    public static let domain = "Crypto"
    
    // Error codes within the crypto domain
    case encryptionFailed = "ENCRYPTION_FAILED"
    case decryptionFailed = "DECRYPTION_FAILED"
    case signatureFailed = "SIGNATURE_FAILED"
    case verificationFailed = "VERIFICATION_FAILED"
    case keyGenerationFailed = "KEY_GENERATION_FAILED"
    case keyDerivationFailed = "KEY_DERIVATION_FAILED"
    case algorithmNotSupported = "ALGORITHM_NOT_SUPPORTED"
    case invalidParameters = "INVALID_PARAMETERS"
    case invalidKeyData = "INVALID_KEY_DATA"
    case invalidKey = "INVALID_KEY"
    case invalidInput = "INVALID_INPUT"
    case hashFailed = "HASH_FAILED"
    case dataCorrupted = "DATA_CORRUPTED"
    case randomDataGenerationFailed = "RANDOM_DATA_GENERATION_FAILED"
    case osError = "OS_ERROR"
    case internalError = "INTERNAL_ERROR"
    case unspecified = "UNSPECIFIED"
}

/// Enhanced implementation of a CryptoError
public struct CryptoError: UmbraError {
    /// Domain identifier
    public let domain: String = CryptoErrorDomain.domain
    
    /// The type of crypto error
    public enum ErrorType: Sendable, Equatable {
        case encryption
        case decryption
        case signature
        case verification
        case keyGeneration
        case keyDerivation
        case algorithm
        case parameters
        case keyData
        case key
        case input
        case hash
        case data
        case randomData
        case os
        case `internal`
        case unspecified
    }
    
    /// The specific error type
    public let type: ErrorType
    
    /// Error code used for serialization and identification
    public var code: String
    
    /// Human-readable description of the error
    public let description: String
    
    /// Additional context information about the error
    public let context: ErrorContext
    
    /// The underlying error, if any
    public let underlyingError: Error?
    
    /// Source information about where the error occurred
    public let source: ErrorSource?
    
    /// Human-readable description of the error (UmbraError protocol requirement)
    public var errorDescription: String {
        if let details = context.typedValue(for: "details") as String?, !details.isEmpty {
            return "\(description): \(details)"
        }
        return description
    }
    
    /// Creates a formatted description of the error
    public var localizedDescription: String {
        if let details = context.typedValue(for: "details") as String?, !details.isEmpty {
            return "\(description): \(details)"
        }
        return description
    }
    
    /// Creates a new CryptoError
    /// - Parameters:
    ///   - type: The error type
    ///   - code: The error code
    ///   - description: Human-readable description
    ///   - context: Additional context information
    ///   - underlyingError: Optional underlying error
    ///   - source: Optional source information
    public init(
        type: ErrorType,
        code: String,
        description: String,
        context: ErrorContext = ErrorContext(),
        underlyingError: Error? = nil,
        source: ErrorSource? = nil
    ) {
        self.type = type
        self.code = code
        self.description = description
        self.context = context
        self.underlyingError = underlyingError
        self.source = source
    }
    
    /// Creates a new instance of the error with additional context
    public func with(context: ErrorContext) -> CryptoError {
        CryptoError(
            type: type,
            code: code,
            description: description,
            context: context,
            underlyingError: underlyingError,
            source: source
        )
    }
    
    /// Creates a new instance of the error with a specified underlying error
    public func with(underlyingError: Error) -> CryptoError {
        CryptoError(
            type: type,
            code: code,
            description: description,
            context: context,
            underlyingError: underlyingError,
            source: source
        )
    }
    
    /// Creates a new instance of the error with source information
    public func with(source: ErrorSource) -> CryptoError {
        CryptoError(
            type: type,
            code: code,
            description: description,
            context: context,
            underlyingError: underlyingError,
            source: source
        )
    }
}

/// Convenience functions for creating specific crypto errors
extension CryptoError {
    /// Creates an encryption failed error
    /// - Parameters:
    ///   - details: Optional details about the error
    ///   - context: Additional context information
    ///   - underlyingError: Optional underlying error
    /// - Returns: A fully configured CryptoError
    public static func encryptionFailed(
        details: String? = nil,
        context: [String: Any] = [:],
        underlyingError: Error? = nil
    ) -> CryptoError {
        var contextDict = context
        if let details = details {
            contextDict["details"] = details
        }
        
        let errorContext = ErrorContext(contextDict)
        
        return CryptoError(
            type: .encryption,
            code: CryptoErrorDomain.encryptionFailed.rawValue,
            description: "Encryption operation failed",
            context: errorContext,
            underlyingError: underlyingError
        )
    }
    
    /// Creates a decryption failed error
    /// - Parameters:
    ///   - details: Optional details about the error
    ///   - context: Additional context information
    ///   - underlyingError: Optional underlying error
    /// - Returns: A fully configured CryptoError
    public static func decryptionFailed(
        details: String? = nil,
        context: [String: Any] = [:],
        underlyingError: Error? = nil
    ) -> CryptoError {
        var contextDict = context
        if let details = details {
            contextDict["details"] = details
        }
        
        let errorContext = ErrorContext(contextDict)
        
        return CryptoError(
            type: .decryption,
            code: CryptoErrorDomain.decryptionFailed.rawValue,
            description: "Decryption operation failed",
            context: errorContext,
            underlyingError: underlyingError
        )
    }
    
    /// Creates an algorithm not supported error
    /// - Parameters:
    ///   - algorithm: The unsupported algorithm name
    ///   - context: Additional context information
    ///   - underlyingError: Optional underlying error
    /// - Returns: A fully configured CryptoError
    public static func algorithmNotSupported(
        algorithm: String,
        context: [String: Any] = [:],
        underlyingError: Error? = nil
    ) -> CryptoError {
        var contextDict = context
        contextDict["algorithm"] = algorithm
        contextDict["details"] = "Algorithm '\(algorithm)' is not supported"
        
        let errorContext = ErrorContext(contextDict)
        
        return CryptoError(
            type: .algorithm,
            code: CryptoErrorDomain.algorithmNotSupported.rawValue,
            description: "Unsupported algorithm",
            context: errorContext,
            underlyingError: underlyingError
        )
    }
    
    /// Creates an invalid key error
    /// - Parameters:
    ///   - details: Optional details about the error
    ///   - context: Additional context information
    ///   - underlyingError: Optional underlying error
    /// - Returns: A fully configured CryptoError
    public static func invalidKey(
        details: String? = nil,
        context: [String: Any] = [:],
        underlyingError: Error? = nil
    ) -> CryptoError {
        var contextDict = context
        if let details = details {
            contextDict["details"] = details
        }
        
        let errorContext = ErrorContext(contextDict)
        
        return CryptoError(
            type: .key,
            code: CryptoErrorDomain.invalidKey.rawValue,
            description: "Invalid cryptographic key",
            context: errorContext,
            underlyingError: underlyingError
        )
    }
    
    /// Creates an internal error
    /// - Parameters:
    ///   - details: Optional details about the error
    ///   - context: Additional context information
    ///   - underlyingError: Optional underlying error
    /// - Returns: A fully configured CryptoError
    public static func internalError(
        details: String? = nil,
        context: [String: Any] = [:],
        underlyingError: Error? = nil
    ) -> CryptoError {
        var contextDict = context
        if let details = details {
            contextDict["details"] = details
        }
        
        let errorContext = ErrorContext(contextDict)
        
        return CryptoError(
            type: .`internal`,
            code: CryptoErrorDomain.internalError.rawValue,
            description: "Internal cryptography error",
            context: errorContext,
            underlyingError: underlyingError
        )
    }
}
