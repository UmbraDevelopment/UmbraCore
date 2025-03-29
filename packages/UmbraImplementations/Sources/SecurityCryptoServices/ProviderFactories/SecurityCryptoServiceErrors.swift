import Foundation

/**
 # SecurityServiceError
 
 Error types for security service operations in UmbraCore.
 */
public enum SecurityServiceError: Error, LocalizedError {
    /// Provider-related error with description
    case providerError(String)
    
    /// Operation is not supported by this provider
    case operationNotSupported(String)
    
    /// Configuration error with description
    case configurationError(String)
    
    /// Invalid or malformed data was provided
    case invalidInputData(String)
    
    /// Error in key management
    case keyManagementError(String)
    
    public var errorDescription: String? {
        switch self {
        case .providerError(let message):
            return "Security provider error: \(message)"
        case .operationNotSupported(let message):
            return "Operation not supported: \(message)"
        case .configurationError(let message):
            return "Configuration error: \(message)"
        case .invalidInputData(let message):
            return "Invalid input data: \(message)"
        case .keyManagementError(let message):
            return "Key management error: \(message)"
        }
    }
}
