import UmbraErrors

/**
 # XPC Service Errors
 
 Comprehensive error types for XPC service operations, providing
 structured error reporting for inter-process communication failures.
 
 These errors follow the Alpha Dot Five architecture principle of
 domain-specific error hierarchies and rich context information.
 */
public enum XPCServiceError: Error, Sendable {
    /// The service connection has failed or timed out
    case connectionFailed(String)
    
    /// The service is not running
    case serviceNotRunning(String)
    
    /// The requested endpoint does not exist
    case endpointNotFound(String)
    
    /// The message could not be encoded
    case messageEncodingFailed(String)
    
    /// The response could not be decoded
    case responseDecodingFailed(String)
    
    /// Authentication for the XPC connection failed
    case authenticationFailed(String)
    
    /// The handler for an endpoint threw an error
    case handlerError(String, Error)
    
    /// The message type is not compatible with the endpoint
    case incompatibleMessageType(String)
    
    /// The operation was cancelled
    case cancelled(String)
    
    /// An unexpected error occurred
    case unexpected(String)
}

/// Extension to provide richer error context suitable for logging
extension XPCServiceError {
    /**
     Creates a log context with privacy-aware information about the error.
     
     - Returns: A log context suitable for privacy-aware logging
     */
    public func createLogContext() -> XPCErrorLogContext {
        let description: String
        let details: String
        
        switch self {
        case .connectionFailed(let message):
            description = "XPC connection failed"
            details = message
        case .serviceNotRunning(let message):
            description = "XPC service not running"
            details = message
        case .endpointNotFound(let message):
            description = "XPC endpoint not found"
            details = message
        case .messageEncodingFailed(let message):
            description = "XPC message encoding failed"
            details = message
        case .responseDecodingFailed(let message):
            description = "XPC response decoding failed"
            details = message
        case .authenticationFailed(let message):
            description = "XPC authentication failed"
            details = message
        case .handlerError(let message, let error):
            description = "XPC handler error"
            details = "\(message): \(error)"
        case .incompatibleMessageType(let message):
            description = "XPC incompatible message type"
            details = message
        case .cancelled(let message):
            description = "XPC operation cancelled"
            details = message
        case .unexpected(let message):
            description = "Unexpected XPC error"
            details = message
        }
        
        return XPCErrorLogContext(description: description, details: details)
    }
}

/**
 Structured log context for XPC errors.
 
 This context provides privacy-aware information for logging XPC-related errors,
 ensuring that sensitive data is properly handled.
 */
public struct XPCErrorLogContext: Sendable {
    /// General description of the error
    public let description: String
    
    /// More detailed information, potentially sensitive
    public let details: String
    
    /**
     Initialises a new XPC error log context.
     
     - Parameters:
        - description: General description of the error
        - details: More detailed information, potentially sensitive
     */
    public init(description: String, details: String) {
        self.description = description
        self.details = details
    }
}
