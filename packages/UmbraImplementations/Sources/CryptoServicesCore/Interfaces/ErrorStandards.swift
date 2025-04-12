import CoreSecurityTypes
import Foundation

/**
 # Error Standards
 
 This file defines standardised error types and error handling patterns for the UmbraCore
 cryptographic services. All implementations should follow these standards to ensure
 consistent error reporting and handling across modules.
 
 ## Error Categories
 
 Errors in the cryptographic services are categorised into:
 
 1. Input validation errors
 2. Operational errors
 3. Storage errors
 4. Configuration errors
 5. Security boundary errors
 
 ## Error Handling Principles
 
 1. All errors should be properly typed and follow the categories defined here
 2. Error messages should be informative without leaking sensitive information
 3. Errors should include appropriate metadata for diagnostics
 4. Error codes should be consistent across implementations
 */

// MARK: - Error Types

/**
 Standardised error codes for cryptographic operation errors.
 
 These codes provide a consistent way to identify specific error conditions
 across different implementations and environments.
 */
public enum CryptoErrorCode: Int, Codable, Sendable {
    // Input validation errors (1-99)
    case invalidInput = 1
    case invalidKey = 2
    case invalidIV = 3
    case invalidAlgorithm = 4
    case invalidMode = 5
    case invalidPadding = 6
    case invalidSignature = 7
    case invalidHash = 8
    case invalidData = 9
    case invalidParameter = 10
    
    // Operational errors (100-199)
    case encryptionFailed = 100
    case decryptionFailed = 101
    case hashingFailed = 102
    case signatureFailed = 103
    case keyGenerationFailed = 104
    case randomGenerationFailed = 105
    case verificationFailed = 106
    case operationTimedOut = 107
    case operationCancelled = 108
    
    // Storage errors (200-299)
    case storageError = 200
    case itemNotFound = 201
    case itemAlreadyExists = 202
    case storageCorrupted = 203
    case storageFull = 204
    case storageUnavailable = 205
    case storagePermissionDenied = 206
    
    // Configuration errors (300-399)
    case invalidConfiguration = 300
    case missingConfiguration = 301
    case incompatibleConfiguration = 302
    
    // Security boundary errors (400-499)
    case securityBoundaryViolation = 400
    case unauthorizedAccess = 401
    case insufficientPermissions = 402
    
    // Platform-specific errors (500-599)
    case platformNotSupported = 500
    case hardwareFeatureUnavailable = 501
    case libraryNotAvailable = 502
    
    // Implementation-specific errors (1000+)
    case internalError = 1000
    case notImplemented = 1001
    case unspecifiedError = 9999
}

/**
 Standardised error for cryptographic operations.
 
 This provides a consistent error type across all cryptographic implementations,
 with appropriate error codes, messages, and metadata.
 */
public struct CryptoOperationError: Error, Equatable, Codable, Sendable {
    /// The error code that identifies the specific error
    public let code: CryptoErrorCode
    
    /// A human-readable description of the error
    public let message: String
    
    /// Additional metadata about the error (should not contain sensitive data)
    public let metadata: [String: String]?
    
    /// The underlying error, if applicable
    public let underlyingError: Error?
    
    /**
     Initialises a new CryptoOperationError.
     
     - Parameters:
        - code: The error code
        - message: A human-readable description
        - metadata: Additional diagnostic information
        - underlyingError: The original error that caused this error
     */
    public init(
        code: CryptoErrorCode,
        message: String,
        metadata: [String: String]? = nil,
        underlyingError: Error? = nil
    ) {
        self.code = code
        self.message = message
        self.metadata = metadata
        self.underlyingError = underlyingError
    }
    
    // Implement Equatable manually since Error doesn't conform to Equatable
    public static func == (lhs: CryptoOperationError, rhs: CryptoOperationError) -> Bool {
        return lhs.code == rhs.code && lhs.message == rhs.message
    }
    
    // Implement Codable manually to handle the underlying error
    private enum CodingKeys: String, CodingKey {
        case code, message, metadata, underlyingErrorDescription
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        code = try container.decode(CryptoErrorCode.self, forKey: .code)
        message = try container.decode(String.self, forKey: .message)
        metadata = try container.decodeIfPresent([String: String].self, forKey: .metadata)
        
        // We can't decode the actual Error, but we can decode its description
        let errorDescription = try container.decodeIfPresent(String.self, forKey: .underlyingErrorDescription)
        underlyingError = errorDescription.map { NSError(domain: "CryptoErrorDomain", code: code.rawValue, userInfo: [NSLocalizedDescriptionKey: $0]) }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(code, forKey: .code)
        try container.encode(message, forKey: .message)
        try container.encodeIfPresent(metadata, forKey: .metadata)
        
        // Store the underlying error as a description
        if let error = underlyingError {
            try container.encode(error.localizedDescription, forKey: .underlyingErrorDescription)
        }
    }
}

// MARK: - Error Mapping

/**
 Standardised error mapper from platform-specific errors to CryptoOperationError.
 
 This provides consistent error mapping logic for different cryptographic implementations.
 */
public enum CryptoErrorMapper {
    /**
     Maps a SecurityStorageError to a CryptoOperationError.
     
     - Parameter error: The storage error to map
     - Returns: A standardised CryptoOperationError
     */
    public static func map(storageError: SecurityStorageError) -> CryptoOperationError {
        switch storageError {
        case .itemNotFound(let message):
            return CryptoOperationError(
                code: .itemNotFound,
                message: message,
                underlyingError: storageError
            )
        case .storageError(let message):
            return CryptoOperationError(
                code: .storageError,
                message: message,
                underlyingError: storageError
            )
        }
    }
    
    /**
     Creates a standardised validation error.
     
     - Parameters:
        - code: The specific validation error code
        - message: A human-readable error message
        - metadata: Additional diagnostic information
     - Returns: A standardised CryptoOperationError
     */
    public static func validationError(
        code: CryptoErrorCode,
        message: String,
        metadata: [String: String]? = nil
    ) -> CryptoOperationError {
        precondition(
            code.rawValue < 100,
            "Validation errors must have codes less than 100"
        )
        
        return CryptoOperationError(
            code: code,
            message: message,
            metadata: metadata
        )
    }
    
    /**
     Creates a standardised operational error.
     
     - Parameters:
        - code: The specific operational error code
        - message: A human-readable error message
        - underlyingError: The original error that caused this error
        - metadata: Additional diagnostic information
     - Returns: A standardised CryptoOperationError
     */
    public static func operationalError(
        code: CryptoErrorCode,
        message: String,
        underlyingError: Error? = nil,
        metadata: [String: String]? = nil
    ) -> CryptoOperationError {
        precondition(
            code.rawValue >= 100 && code.rawValue < 200,
            "Operational errors must have codes between 100 and 199"
        )
        
        return CryptoOperationError(
            code: code,
            message: message,
            metadata: metadata,
            underlyingError: underlyingError
        )
    }
}

// MARK: - Result Extension for Error Handling

/**
 Extensions to Result for standardised error handling in cryptographic operations.
 */
public extension Result where Failure == SecurityStorageError {
    /**
     Maps a SecurityStorageError result to a CryptoOperationError result.
     
     - Returns: A new Result with the same success value but with CryptoOperationError failure
     */
    func mapError() -> Result<Success, CryptoOperationError> {
        return mapError { CryptoErrorMapper.map(storageError: $0) }
    }
    
    /**
     Maps the success value and maps the error to a standard CryptoOperationError.
     
     - Parameter transform: A function to transform the success value
     - Returns: A new Result with the transformed success value and CryptoOperationError failure
     */
    func mapBoth<NewSuccess>(
        _ transform: (Success) -> NewSuccess
    ) -> Result<NewSuccess, CryptoOperationError> {
        return self.map(transform).mapError()
    }
}

/**
 Extensions to Result for handling CryptoOperationError.
 */
public extension Result where Failure == CryptoOperationError {
    /**
     Adds metadata to the error if this result is a failure.
     
     - Parameter metadata: Metadata to add to the error
     - Returns: A new Result with the same success value but with added metadata in the error
     */
    func withMetadata(_ metadata: [String: String]) -> Self {
        return mapError { error in
            var combinedMetadata = error.metadata ?? [:]
            for (key, value) in metadata {
                combinedMetadata[key] = value
            }
            
            return CryptoOperationError(
                code: error.code,
                message: error.message,
                metadata: combinedMetadata,
                underlyingError: error.underlyingError
            )
        }
    }
}

// MARK: - Error Handling Utilities

/**
 Utilities for consistent error handling in cryptographic operations.
 */
public enum CryptoErrorHandling {
    /**
     Validates that a condition is true or returns a validation error.
     
     - Parameters:
        - condition: The condition to validate
        - code: The error code to use if validation fails
        - message: The error message to use if validation fails
     - Returns: A result with void on success or an error on failure
     */
    public static func validate(
        _ condition: Bool,
        code: CryptoErrorCode,
        message: String
    ) -> Result<Void, CryptoOperationError> {
        guard condition else {
            return .failure(CryptoErrorMapper.validationError(
                code: code,
                message: message
            ))
        }
        return .success(())
    }
    
    /**
     Validates input data for cryptographic operations.
     
     - Parameters:
        - data: The data to validate
        - minSize: The minimum size in bytes
        - maxSize: The maximum size in bytes, if applicable
        - name: A name for the data being validated (for error messages)
     - Returns: A result with void on success or an error on failure
     */
    public static func validateData(
        _ data: Data?,
        minSize: Int = 1,
        maxSize: Int? = nil,
        name: String
    ) -> Result<Void, CryptoOperationError> {
        guard let data = data else {
            return .failure(CryptoErrorMapper.validationError(
                code: .invalidData,
                message: "\(name) cannot be nil"
            ))
        }
        
        guard data.count >= minSize else {
            return .failure(CryptoErrorMapper.validationError(
                code: .invalidData,
                message: "\(name) must be at least \(minSize) bytes",
                metadata: ["actual_size": "\(data.count)"]
            ))
        }
        
        if let maxSize = maxSize {
            guard data.count <= maxSize else {
                return .failure(CryptoErrorMapper.validationError(
                    code: .invalidData,
                    message: "\(name) must be at most \(maxSize) bytes",
                    metadata: ["actual_size": "\(data.count)"]
                ))
            }
        }
        
        return .success(())
    }
    
    /**
     Validates a key for cryptographic operations.
     
     - Parameters:
        - key: The key data to validate
        - algorithm: The encryption algorithm
     - Returns: A result with void on success or an error on failure
     */
    public static func validateKey(
        _ key: Data?,
        algorithm: StandardEncryptionAlgorithm
    ) -> Result<Void, CryptoOperationError> {
        guard let key = key else {
            return .failure(CryptoErrorMapper.validationError(
                code: .invalidKey,
                message: "Encryption key cannot be nil"
            ))
        }
        
        let requiredSize = algorithm.keySizeBytes
        guard key.count == requiredSize else {
            return .failure(CryptoErrorMapper.validationError(
                code: .invalidKey,
                message: "Key for \(algorithm.rawValue) must be exactly \(requiredSize) bytes",
                metadata: [
                    "algorithm": algorithm.rawValue,
                    "required_size": "\(requiredSize)",
                    "actual_size": "\(key.count)"
                ]
            ))
        }
        
        return .success(())
    }
    
    /**
     Validates an initialisation vector for cryptographic operations.
     
     - Parameters:
        - iv: The initialisation vector data to validate
        - algorithm: The encryption algorithm
     - Returns: A result with void on success or an error on failure
     */
    public static func validateIV(
        _ iv: Data?,
        algorithm: StandardEncryptionAlgorithm
    ) -> Result<Void, CryptoOperationError> {
        guard let iv = iv else {
            return .failure(CryptoErrorMapper.validationError(
                code: .invalidIV,
                message: "Initialisation vector cannot be nil"
            ))
        }
        
        let requiredSize = algorithm.ivSizeBytes
        guard iv.count == requiredSize else {
            return .failure(CryptoErrorMapper.validationError(
                code: .invalidIV,
                message: "IV for \(algorithm.rawValue) must be exactly \(requiredSize) bytes",
                metadata: [
                    "algorithm": algorithm.rawValue,
                    "required_size": "\(requiredSize)",
                    "actual_size": "\(iv.count)"
                ]
            ))
        }
        
        return .success(())
    }
}
