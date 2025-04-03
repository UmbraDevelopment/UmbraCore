import Foundation
import LoggingTypes

/**
 # API Configuration DTO
 
 Data transfer object for configuring the API service in the Alpha Dot Five architecture.
 This provides all the required settings for an API service instance.
 */
public struct APIConfigurationDTO: Equatable, Hashable, Sendable {
    // MARK: - Environment
    
    /// API environment type
    public enum Environment: String, Sendable, Equatable, Hashable, CaseIterable {
        /// Development environment for local testing
        case development
        
        /// Testing environment for integration tests
        case testing
        
        /// Staging environment for pre-production validation
        case staging
        
        /// Production environment for live usage
        case production
    }
    
    // MARK: - Log Level
    
    /// Logging level for the API service
    public enum LogLevel: String, Sendable, Equatable, Hashable, CaseIterable {
        /// Debug level: comprehensive detailed information
        case debug
        
        /// Info level: general information about request flow
        case info
        
        /// Warning level: potential issues that aren't errors
        case warning
        
        /// Error level: error events
        case error
        
        /// Critical level: very severe errors
        case critical
    }
    
    // MARK: - Properties
    
    /// The environment this API service operates in
    public let environment: Environment
    
    /// The logging level for API operations
    public let loggingLevel: LogLevel
    
    /// Default timeout in milliseconds for operations
    public let timeoutMilliseconds: UInt64
    
    /// Whether the service should automatically retry failed operations
    public let retryEnabled: Bool
    
    /// Maximum number of retries for operations
    public let maxRetries: UInt
    
    /// Additional configuration options as key-value pairs
    public let options: [String: String]
    
    // MARK: - Initialization
    
    /**
     Creates a new API configuration with the specified settings.
     
     - Parameters:
        - environment: The API environment
        - loggingLevel: The logging level for operations
        - timeoutMilliseconds: Default operation timeout in milliseconds
        - retryEnabled: Whether automatic retries are enabled
        - maxRetries: Maximum number of retries
        - options: Additional configuration options
     */
    public init(
        environment: Environment,
        loggingLevel: LogLevel,
        timeoutMilliseconds: UInt64 = 30000,
        retryEnabled: Bool = true,
        maxRetries: UInt = 3,
        options: [String: String] = [:]
    ) {
        self.environment = environment
        self.loggingLevel = loggingLevel
        self.timeoutMilliseconds = timeoutMilliseconds
        self.retryEnabled = retryEnabled
        self.maxRetries = maxRetries
        self.options = options
    }
    
    // MARK: - Factory Methods
    
    /**
     Creates a default development configuration.
     
     - Returns: A configuration suitable for development
     */
    public static func createDevelopment() -> APIConfigurationDTO {
        APIConfigurationDTO(
            environment: .development,
            loggingLevel: .debug,
            timeoutMilliseconds: 60000, // 60 seconds
            retryEnabled: true,
            maxRetries: 2,
            options: [
                "debug_mode": "true",
                "validation_level": "strict"
            ]
        )
    }
    
    /**
     Creates a default production configuration.
     
     - Returns: A configuration suitable for production
     */
    public static func createProduction() -> APIConfigurationDTO {
        APIConfigurationDTO(
            environment: .production,
            loggingLevel: .info,
            timeoutMilliseconds: 30000, // 30 seconds
            retryEnabled: true,
            maxRetries: 3,
            options: [
                "cache_enabled": "true", 
                "validation_level": "standard"
            ]
        )
    }
    
    /**
     Creates a configuration for testing with short timeouts.
     
     - Returns: A configuration suitable for automated testing
     */
    public static func createTesting() -> APIConfigurationDTO {
        APIConfigurationDTO(
            environment: .testing,
            loggingLevel: .debug,
            timeoutMilliseconds: 5000, // 5 seconds
            retryEnabled: false,
            maxRetries: 0,
            options: [
                "debug_mode": "true",
                "validation_level": "strict",
                "mock_responses": "true"
            ]
        )
    }
}
