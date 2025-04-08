import Foundation

/**
 Deployment environment for the application.
 
 This enum defines the different environments in which the application can run,
 allowing for environment-specific behavior such as logging levels and privacy controls.
 */
public enum DeploymentEnvironment: String, Sendable {
    /// Development environment with enhanced debugging and logging
    case development
    
    /// Staging environment for pre-production testing
    case staging
    
    /// Production environment with strict privacy controls
    case production
}
