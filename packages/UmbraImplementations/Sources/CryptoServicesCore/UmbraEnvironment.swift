import Foundation

/**
 # UmbraEnvironment
 
 Environment information for the UmbraCore system.
 This struct provides a standardised way to access environment-specific
 configuration and capabilities.
 
 The environment can influence security policy decisions, cryptographic 
 algorithm selection, and logging behavior based on whether the application
 is running in production, staging, development, or test environments.
 */
public struct UmbraEnvironment: Sendable, Equatable {
    /// The type of environment
    public enum EnvironmentType: String, Sendable, Codable, CaseIterable {
        /// Production environment with maximum security
        case production
        
        /// Staging environment with near-production security
        case staging
        
        /// Development environment with standard security
        case development
        
        /// Test environment with relaxed security
        case test
    }
    
    /// The type of this environment
    public let type: EnvironmentType
    
    /// Whether hardware security is available
    public let hasHardwareSecurity: Bool
    
    /// Whether enhanced logging is enabled
    public let enhancedLoggingEnabled: Bool
    
    /// Platform identifier (iOS, macOS, etc.)
    public let platformIdentifier: String
    
    /// Additional configuration parameters
    public let parameters: [String: String]
    
    /// The name of the environment (string representation of the type)
    public var name: String {
        return type.rawValue
    }
    
    /**
     Creates a new environment configuration.
     
     - Parameters:
        - type: The environment type
        - hasHardwareSecurity: Whether hardware security is available
        - enhancedLoggingEnabled: Whether enhanced logging is enabled
        - platformIdentifier: Platform identifier
        - parameters: Additional configuration parameters
     */
    public init(
        type: EnvironmentType,
        hasHardwareSecurity: Bool = false,
        enhancedLoggingEnabled: Bool = false,
        platformIdentifier: String = "unknown",
        parameters: [String: String] = [:]
    ) {
        self.type = type
        self.hasHardwareSecurity = hasHardwareSecurity
        self.enhancedLoggingEnabled = enhancedLoggingEnabled
        self.platformIdentifier = platformIdentifier
        self.parameters = parameters
    }
    
    /// Returns a production environment configuration
    public static var production: UmbraEnvironment {
        UmbraEnvironment(type: .production, hasHardwareSecurity: true)
    }
    
    /// Returns a development environment configuration
    public static var development: UmbraEnvironment {
        UmbraEnvironment(type: .development, enhancedLoggingEnabled: true)
    }
    
    /// Returns a test environment configuration
    public static var test: UmbraEnvironment {
        UmbraEnvironment(type: .test, enhancedLoggingEnabled: true)
    }
}
