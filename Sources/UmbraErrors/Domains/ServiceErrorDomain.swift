import Foundation

import UmbraErrorsCore

/// Domain identifier for service errors
public enum ServiceErrorDomain: String, CaseIterable, Sendable {
    /// The domain identifier string
    public static let domain = "Service"
    
    // Error codes within the service domain
    case connectionFailedError = "CONNECTION_FAILED"
    case requestFailedError = "REQUEST_FAILED"
    case parseErrorError = "PARSE_ERROR"
    case unauthorisedError = "UNAUTHORISED"
    case generalError = "GENERAL_ERROR"
}

/// Enhanced implementation of a ServiceError
public struct ServiceError: UmbraError {
    /// Domain identifier
    public let domain: String = ServiceErrorDomain.domain
    
    /// The type of service error
    public enum ErrorType: Sendable, Equatable {
        /// Failed to connect to service
        case connectionFailed
        /// Request to service failed
        case requestFailed
        /// Failed to parse response from service
        case parseError
        /// Not authorised to perform operation
        case unauthorised
        /// General service error
        case general
    }
    
    /// The specific error type
    public let type: ErrorType
    
    /// Error code used for serialisation and identification
    public let code: String
    
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
    
    /// Creates a new ServiceError
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
    public func with(context: ErrorContext) -> ServiceError {
        ServiceError(
            type: type,
            code: code,
            description: description,
            context: context,
            underlyingError: underlyingError,
            source: source
        )
    }
    
    /// Creates a new instance of the error with a specified underlying error
    public func with(underlyingError: Error) -> ServiceError {
        ServiceError(
            type: type,
            code: code,
            description: description,
            context: context,
            underlyingError: underlyingError,
            source: source
        )
    }
    
    /// Creates a new instance of the error with source information
    public func with(source: ErrorSource) -> ServiceError {
        ServiceError(
            type: type,
            code: code,
            description: description,
            context: context,
            underlyingError: underlyingError,
            source: source
        )
    }
}

/// Convenience functions for creating specific service errors
extension ServiceError {
    /// Creates a connection failed error
    /// - Parameters:
    ///   - serviceName: Service name that couldn't be connected to
    ///   - reason: The reason connection failed
    ///   - context: Additional context information
    ///   - underlyingError: Optional underlying error
    /// - Returns: A fully configured ServiceError
    public static func connectionFailed(
        serviceName: String,
        reason: String,
        context: [String: Any] = [:],
        underlyingError: Error? = nil
    ) -> ServiceError {
        var contextDict = context
        contextDict["serviceName"] = serviceName
        contextDict["reason"] = reason
        contextDict["details"] = "Failed to connect to service '\(serviceName)': \(reason)"
        
        let errorContext = ErrorContext(contextDict)
        
        return ServiceError(
            type: .connectionFailed,
            code: ServiceErrorDomain.connectionFailedError.rawValue,
            description: "Service connection failed",
            context: errorContext,
            underlyingError: underlyingError
        )
    }
    
    /// Creates a request failed error
    /// - Parameters:
    ///   - serviceName: Service name
    ///   - endpoint: The endpoint that failed
    ///   - reason: The reason the request failed
    ///   - context: Additional context information
    ///   - underlyingError: Optional underlying error
    /// - Returns: A fully configured ServiceError
    public static func requestFailed(
        serviceName: String,
        endpoint: String,
        reason: String,
        context: [String: Any] = [:],
        underlyingError: Error? = nil
    ) -> ServiceError {
        var contextDict = context
        contextDict["serviceName"] = serviceName
        contextDict["endpoint"] = endpoint
        contextDict["reason"] = reason
        contextDict["details"] = "Request to '\(serviceName)/\(endpoint)' failed: \(reason)"
        
        let errorContext = ErrorContext(contextDict)
        
        return ServiceError(
            type: .requestFailed,
            code: ServiceErrorDomain.requestFailedError.rawValue,
            description: "Service request failed",
            context: errorContext,
            underlyingError: underlyingError
        )
    }
    
    /// Creates a parse error
    /// - Parameters:
    ///   - serviceName: Service name
    ///   - endpoint: The endpoint that returned the unparseable response
    ///   - reason: The reason parsing failed
    ///   - context: Additional context information
    ///   - underlyingError: Optional underlying error
    /// - Returns: A fully configured ServiceError
    public static func parseError(
        serviceName: String,
        endpoint: String,
        reason: String,
        context: [String: Any] = [:],
        underlyingError: Error? = nil
    ) -> ServiceError {
        var contextDict = context
        contextDict["serviceName"] = serviceName
        contextDict["endpoint"] = endpoint
        contextDict["reason"] = reason
        contextDict["details"] = "Failed to parse response from '\(serviceName)/\(endpoint)': \(reason)"
        
        let errorContext = ErrorContext(contextDict)
        
        return ServiceError(
            type: .parseError,
            code: ServiceErrorDomain.parseErrorError.rawValue,
            description: "Service parse error",
            context: errorContext,
            underlyingError: underlyingError
        )
    }
    
    /// Creates an unauthorised error
    /// - Parameters:
    ///   - serviceName: Service name
    ///   - operation: The operation that was not authorised
    ///   - context: Additional context information
    ///   - underlyingError: Optional underlying error
    /// - Returns: A fully configured ServiceError
    public static func unauthorised(
        serviceName: String,
        operation: String,
        context: [String: Any] = [:],
        underlyingError: Error? = nil
    ) -> ServiceError {
        var contextDict = context
        contextDict["serviceName"] = serviceName
        contextDict["operation"] = operation
        contextDict["details"] = "Not authorised to perform '\(operation)' on service '\(serviceName)'"
        
        let errorContext = ErrorContext(contextDict)
        
        return ServiceError(
            type: .unauthorised,
            code: ServiceErrorDomain.unauthorisedError.rawValue,
            description: "Service unauthorised",
            context: errorContext,
            underlyingError: underlyingError
        )
    }
    
    /// Creates a general service error
    /// - Parameters:
    ///   - serviceName: Service name
    ///   - message: A descriptive message about the error
    ///   - context: Additional context information
    ///   - underlyingError: Optional underlying error
    /// - Returns: A fully configured ServiceError
    public static func generalError(
        serviceName: String,
        message: String,
        context: [String: Any] = [:],
        underlyingError: Error? = nil
    ) -> ServiceError {
        var contextDict = context
        contextDict["serviceName"] = serviceName
        contextDict["details"] = "Error in service '\(serviceName)': \(message)"
        
        let errorContext = ErrorContext(contextDict)
        
        return ServiceError(
            type: .general,
            code: ServiceErrorDomain.generalError.rawValue,
            description: "Service error",
            context: errorContext,
            underlyingError: underlyingError
        )
    }
}
