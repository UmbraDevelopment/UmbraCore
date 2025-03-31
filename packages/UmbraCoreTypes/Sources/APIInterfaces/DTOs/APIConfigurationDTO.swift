/// APIConfigurationDTO
///
/// Represents configuration options for the UmbraCore API service.
/// This DTO is Foundation-independent to ensure it can be used
/// across module boundaries and in concurrent contexts.
///
/// All properties are immutable to ensure thread safety when
/// passing instances between actors or across module boundaries.
public struct APIConfigurationDTO: Sendable, Equatable {
    /// The environment in which the API operates
    public let environment: APIEnvironment
    
    /// Optional logging level for API operations
    public let loggingLevel: APILoggingLevel?
    
    /// Optional timeout for API operations in milliseconds
    public let timeoutMilliseconds: UInt64?
    
    /// Creates a new APIConfigurationDTO instance
    /// - Parameters:
    ///   - environment: The operating environment
    ///   - loggingLevel: Optional logging level
    ///   - timeoutMilliseconds: Optional timeout in milliseconds
    public init(
        environment: APIEnvironment,
        loggingLevel: APILoggingLevel? = nil,
        timeoutMilliseconds: UInt64? = nil
    ) {
        self.environment = environment
        self.loggingLevel = loggingLevel
        self.timeoutMilliseconds = timeoutMilliseconds
    }
}

/// Represents the environment in which the API operates
public enum APIEnvironment: String, Sendable, Equatable, CaseIterable {
    case development
    case staging
    case production
}

/// Represents logging levels for API operations
public enum APILoggingLevel: String, Sendable, Equatable, CaseIterable {
    case debug
    case info
    case warning
    case error
    case none
}
