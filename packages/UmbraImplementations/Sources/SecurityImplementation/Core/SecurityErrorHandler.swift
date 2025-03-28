import Foundation
import SecurityCoreInterfaces
import UmbraErrors
import LoggingInterfaces

/**
 # Security Error Handler
 
 This component provides standardised error handling for the security subsystem,
 ensuring consistent error reporting, logging, and conversion between error types.
 
 ## Error Handling Principles
 
 - Domain-specific error enums for clarity
 - Comprehensive contextual information
 - Consistent error mapping
 - Proper British spelling in error messages
 */
public struct SecurityErrorHandler {
    /// Logger for recording error information
    private let logger: any LoggingProtocol
    
    /**
     Initialises a new SecurityErrorHandler with the specified logger.
     
     - Parameter logger: Logger for recording error information
     */
    public init(logger: any LoggingProtocol) {
        self.logger = logger
    }
    
    /**
     Handles an error by mapping it to the appropriate domain-specific error type
     and logging relevant information.
     
     - Parameters:
       - error: The error to handle
       - operation: The security operation that produced the error
       - context: Additional contextual information
     - Returns: A mapped SecurityError
     */
    public func handleError(
        _ error: Error,
        operation: SecurityOperation,
        context: [String: String]? = nil
    ) async -> SecurityError {
        // Create metadata for logging
        var metadata: [String: String] = [
            "operation": operation.description,
            "errorType": "\(type(of: error))"
        ]
        
        // Add any additional context
        if let context = context {
            for (key, value) in context {
                metadata[key] = value
            }
        }
        
        // Map the error to an appropriate SecurityError type
        let securityError: SecurityError
        
        if let cryptoError = error as? UmbraErrors.Crypto.Core {
            // Map crypto errors
            securityError = mapCryptoError(cryptoError, operation: operation)
        } else if let securityErrorEnum = error as? SecurityError {
            // Already a SecurityError
            securityError = securityErrorEnum
        } else if let nsError = error as NSError {
            // Map NSError
            securityError = mapNSError(nsError, operation: operation)
        } else {
            // Generic mapping for unknown errors
            securityError = SecurityError.operationFailed("Security operation failed: \(error.localizedDescription)")
        }
        
        // Log the error
        await logger.error("Security error: \(securityError.localizedDescription)", metadata: metadata)
        
        return securityError
    }
    
    /**
     Maps a CryptoError to an appropriate SecurityError.
     
     - Parameters:
       - error: The CryptoError to map
       - operation: The security operation that produced the error
     - Returns: A mapped SecurityError
     */
    private func mapCryptoError(
        _ error: UmbraErrors.Crypto.Core,
        operation: SecurityOperation
    ) -> SecurityError {
        switch error {
        case .keyNotFound(let keyID):
            return SecurityError.operationFailed("Key not found: \(keyID)")
            
        case .invalidKey(let reason):
            return SecurityError.invalidInput("Invalid key: \(reason)")
            
        case .decryptionFailed(let reason):
            return SecurityError.decryptionFailed("Decryption failed: \(reason)")
            
        case .encryptionFailed(let reason):
            return SecurityError.encryptionFailed("Encryption failed: \(reason)")
            
        case .unsupportedAlgorithm(let algorithm):
            return SecurityError.unsupportedAlgorithm("Unsupported algorithm: \(algorithm)")
            
        case .invalidData(let reason):
            return SecurityError.invalidInput("Invalid data: \(reason)")
            
        case .operationCancelled:
            return SecurityError.operationFailed("Operation cancelled")
            
        case .operationTimeout:
            return SecurityError.operationFailed("Operation timed out")
            
        default:
            return SecurityError.operationFailed(
                "Crypto operation failed during \(operation.description): \(error.localizedDescription)"
            )
        }
    }
    
    /**
     Maps an NSError to an appropriate SecurityError based on its domain and code.
     
     - Parameters:
       - error: The NSError to map
       - operation: The security operation that produced the error
     - Returns: A mapped SecurityError
     */
    private func mapNSError(
        _ error: NSError,
        operation: SecurityOperation
    ) -> SecurityError {
        // Map based on error domain
        switch error.domain {
        case "NSOSStatusErrorDomain":
            // Security framework errors
            return mapSecurityFrameworkError(error, operation: operation)
            
        case "NSURLErrorDomain":
            // Network-related errors
            return SecurityError.networkError("Network error during security operation: \(error.localizedDescription)")
            
        default:
            return SecurityError.operationFailed(
                "Security operation failed with error: \(error.localizedDescription)"
            )
        }
    }
    
    /**
     Maps a Security framework error to an appropriate SecurityError.
     
     - Parameters:
       - error: The NSError from the Security framework
       - operation: The security operation that produced the error
     - Returns: A mapped SecurityError
     */
    private func mapSecurityFrameworkError(
        _ error: NSError,
        operation: SecurityOperation
    ) -> SecurityError {
        // Map common Security framework error codes
        switch error.code {
        case -25300: // errSecItemNotFound
            return SecurityError.operationFailed("Item not found in keychain")
            
        case -25291: // errSecDuplicateItem
            return SecurityError.operationFailed("Duplicate item")
            
        case -25292: // errSecInvalidItemRef
            return SecurityError.invalidInput("Invalid item reference")
            
        case -25293: // errSecInvalidData
            return SecurityError.invalidInput("Invalid data format")
            
        case -25316: // errSecAuthFailed
            return SecurityError.operationFailed("Authentication failed")
            
        default:
            return SecurityError.operationFailed(
                "Security framework error during \(operation.description): \(error.localizedDescription) (code: \(error.code))"
            )
        }
    }
    
    /**
     Converts a SecurityResultDTO error into a detailed SecurityError.
     
     - Parameters:
       - result: The SecurityResultDTO with error information
       - operation: The security operation that produced the result
     - Returns: A mapped SecurityError, or nil if the result was successful
     */
    public func convertResultError(
        _ result: SecurityResultDTO,
        operation: SecurityOperation
    ) -> SecurityError? {
        // Only process failures
        guard !result.success else {
            return nil
        }
        
        // Map based on error code
        switch result.errorCode {
        case .keyNotFound:
            return SecurityError.operationFailed("Key not found: \(result.errorMessage ?? "Unknown key")")
            
        case .encryptionFailed:
            return SecurityError.encryptionFailed("Encryption failed: \(result.errorMessage ?? "Unknown reason")")
            
        case .decryptionFailed:
            return SecurityError.decryptionFailed("Decryption failed: \(result.errorMessage ?? "Unknown reason")")
            
        case .invalidInput:
            return SecurityError.invalidInput("Invalid input: \(result.errorMessage ?? "Invalid input")")
            
        case .operationFailed:
            return SecurityError.operationFailed("Operation failed: \(result.errorMessage ?? "Operation failed")")
            
        case .permissionDenied:
            return SecurityError.operationFailed("Permission denied: \(result.errorMessage ?? "Permission denied")")
            
        case .unsupportedOperation:
            return SecurityError.operationFailed("Unsupported operation: \(result.errorMessage ?? "Unsupported operation")")
            
        default:
            return SecurityError.operationFailed(
                "Security operation \(operation.description) failed: \(result.errorMessage ?? "Unknown error")"
            )
        }
    }
}

/**
 # SecurityError
 
 Domain-specific error type for security operations.
 */
public enum SecurityError: Error, LocalizedError {
    // Configuration errors
    case invalidConfiguration(String)
    case unsupportedAlgorithm(String)
    case invalidKeySize(String)
    
    // Input errors
    case invalidInput(String)
    case invalidSignature(String)
    
    // Operation errors
    case operationFailed(String)
    case encryptionFailed(String)
    case decryptionFailed(String)
    case keyGenerationFailed(String)
    case signatureGenerationFailed(String)
    case signatureVerificationFailed(String)
    
    // Storage errors
    case storageError(String)
    case retrievalError(String)
    case deletionError(String)
    
    // System errors
    case systemError(String)
    case networkError(String)
    
    // Security policy errors
    case securityPolicyViolation(String)
    
    public var errorDescription: String? {
        switch self {
        case .invalidConfiguration(let reason):
            return "Invalid security configuration: \(reason)"
        case .unsupportedAlgorithm(let algorithm):
            return "Unsupported algorithm: \(algorithm)"
        case .invalidKeySize(let details):
            return "Invalid key size: \(details)"
        case .invalidInput(let details):
            return "Invalid input: \(details)"
        case .invalidSignature(let details):
            return "Invalid signature: \(details)"
        case .operationFailed(let reason):
            return "Security operation failed: \(reason)"
        case .encryptionFailed(let reason):
            return "Encryption failed: \(reason)"
        case .decryptionFailed(let reason):
            return "Decryption failed: \(reason)"
        case .keyGenerationFailed(let reason):
            return "Key generation failed: \(reason)"
        case .signatureGenerationFailed(let reason):
            return "Signature generation failed: \(reason)"
        case .signatureVerificationFailed(let reason):
            return "Signature verification failed: \(reason)"
        case .storageError(let reason):
            return "Secure storage error: \(reason)"
        case .retrievalError(let reason):
            return "Secure retrieval error: \(reason)"
        case .deletionError(let reason):
            return "Secure deletion error: \(reason)"
        case .systemError(let reason):
            return "System security error: \(reason)"
        case .networkError(let reason):
            return "Network security error: \(reason)"
        case .securityPolicyViolation(let reason):
            return "Security policy violation: \(reason)"
        }
    }
}
