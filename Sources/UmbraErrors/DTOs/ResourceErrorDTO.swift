import Foundation

/// DTO for resource errors
public struct ResourceErrorDTO: Error, Hashable, Equatable {
    /// The type of resource error
    public enum ResourceErrorType: String, Hashable, Equatable {
        /// Failed to acquire resource
        case acquisitionFailed = "ACQUISITION_FAILED"
        /// Resource is in invalid state
        case invalidState = "INVALID_STATE"
        /// Resource pool is exhausted
        case poolExhausted = "POOL_EXHAUSTED"
        /// Resource not found
        case resourceNotFound = "RESOURCE_NOT_FOUND"
        /// Operation on resource failed
        case operationFailed = "OPERATION_FAILED"
        /// Resource already exists
        case alreadyExists = "ALREADY_EXISTS"
        /// Resource is locked
        case locked = "LOCKED"
        /// Resource has expired
        case expired = "EXPIRED"
        /// General failure
        case generalFailure = "GENERAL_FAILURE"
        /// Unknown resource error
        case unknown = "UNKNOWN"
    }
    
    /// The type of resource error
    public let type: ResourceErrorType
    
    /// Human-readable description of the error
    public let description: String
    
    /// Additional context information about the error
    public let context: [String: Any]
    
    /// The underlying error, if any
    public let underlyingError: Error?
    
    /// Creates a new ResourceErrorDTO
    /// - Parameters:
    ///   - type: The type of resource error
    ///   - description: Human-readable description
    ///   - context: Additional context information
    ///   - underlyingError: The underlying error
    public init(
        type: ResourceErrorType,
        description: String,
        context: [String: Any] = [:],
        underlyingError: Error? = nil
    ) {
        self.type = type
        self.description = description
        self.context = context
        self.underlyingError = underlyingError
    }
    
    /// Creates a ResourceErrorDTO from a generic error
    /// - Parameter error: The source error
    /// - Returns: A ResourceErrorDTO
    public static func from(_ error: Error) -> ResourceErrorDTO {
        if let resourceError = error as? ResourceErrorDTO {
            return resourceError
        }
        
        return ResourceErrorDTO(
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
    
    public static func == (lhs: ResourceErrorDTO, rhs: ResourceErrorDTO) -> Bool {
        lhs.type == rhs.type &&
        lhs.description == rhs.description
        // Not comparing context or underlyingError for equality
    }
}
