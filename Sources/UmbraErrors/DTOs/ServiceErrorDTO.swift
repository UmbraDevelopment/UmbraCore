import Foundation

/// DTO for service errors
public struct ServiceErrorDTO: Error, Hashable, Equatable {
    /// The type of service error
    public enum ServiceErrorType: String, Hashable, Equatable {
        /// Service not available
        case serviceUnavailable = "SERVICE_UNAVAILABLE"
        /// Service timeout
        case timeout = "TIMEOUT"
        /// Invalid request to service
        case invalidRequest = "INVALID_REQUEST"
        /// Service operation failed
        case operationFailed = "OPERATION_FAILED"
        /// Service configuration error
        case configurationError = "CONFIGURATION_ERROR"
        /// Service dependency error
        case dependencyError = "DEPENDENCY_ERROR"
        /// Service authentication error
        case authenticationError = "AUTHENTICATION_ERROR"
        /// Service authorisation error
        case authorisationError = "AUTHORISATION_ERROR"
        /// Rate limit exceeded
        case rateLimitExceeded = "RATE_LIMIT_EXCEEDED"
        /// General service failure
        case generalFailure = "GENERAL_FAILURE"
        /// Unknown service error
        case unknown = "UNKNOWN"
    }
    
    /// The type of service error
    public let type: ServiceErrorType
    
    /// Human-readable description of the error
    public let description: String
    
    /// Additional context information about the error
    public let context: [String: Any]
    
    /// The underlying error, if any
    public let underlyingError: Error?
    
    /// Creates a new ServiceErrorDTO
    /// - Parameters:
    ///   - type: The type of service error
    ///   - description: Human-readable description
    ///   - context: Additional context information
    ///   - underlyingError: The underlying error
    public init(
        type: ServiceErrorType,
        description: String,
        context: [String: Any] = [:],
        underlyingError: Error? = nil
    ) {
        self.type = type
        self.description = description
        self.context = context
        self.underlyingError = underlyingError
    }
    
    /// Creates a ServiceErrorDTO from a generic error
    /// - Parameter error: The source error
    /// - Returns: A ServiceErrorDTO
    public static func from(_ error: Error) -> ServiceErrorDTO {
        if let serviceError = error as? ServiceErrorDTO {
            return serviceError
        }
        
        return ServiceErrorDTO(
            type: .unknown,
            description: "\(error)",
            context: [:],
            underlyingError: error
        )
    }
    
    // MARK: - Hashable & Equatable
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(type)
        hasher.combine(description)
        // Not hashing context or underlyingError as they may not be Hashable
    }
    
    public static func == (lhs: ServiceErrorDTO, rhs: ServiceErrorDTO) -> Bool {
        lhs.type == rhs.type &&
        lhs.description == rhs.description
        // Not comparing context or underlyingError for equality
    }
}
