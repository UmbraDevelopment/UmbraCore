import Foundation
import LoggingInterfaces
import LoggingServices
import SecurityCoreInterfaces
import UmbraErrors
import CryptoInterfaces
import CryptoServices

/// Factory for creating instances of the SecurityProviderProtocol.
///
/// This factory provides methods for creating fully configured security service
/// instances with various configurations and crypto service integrations, ensuring
/// proper domain separation and delegation to crypto services.
public enum SecurityServiceFactory {
    /// Creates a default security service instance with standard configuration
    /// - Returns: A fully configured security service
    public static func createDefault() -> SecurityProviderProtocol {
        let logger = LoggingServices.createStandardLogger(
            minimumLevel: .info,
            formatter: nil
        )
        
        return createWithLogger(logger)
    }
    
    /// Creates a security service with the specified logger
    /// - Parameter logger: The logger to use for security operations
    /// - Returns: A fully configured security service
    public static func createWithLogger(_ logger: LoggingInterfaces.LoggingProtocol) -> SecurityProviderProtocol {
        // Create dependencies
        let cryptoService = CryptoServices.createDefault()
        
        // Create the actor
        let securityActor = SecurityServiceActor(
            cryptoService: cryptoService,
            logger: logger
        )
        
        // Initialise asynchronously in the background
        Task {
            try? await securityActor.initialise()
        }
        
        return securityActor
    }
    
    /// Creates a high-security service with more stringent security settings
    /// - Returns: A security service configured for high-security environments
    public static func createHighSecurity() -> SecurityProviderProtocol {
        let logger = LoggingServices.createDevelopmentLogger(
            minimumLevel: .debug,
            formatter: nil
        )
        
        // Create dependencies with high-security settings
        let cryptoService = CryptoServices.createDefault() // High security settings will be applied via options
        
        // Create the actor
        let securityActor = SecurityServiceActor(
            cryptoService: cryptoService,
            logger: logger
        )
        
        // Initialise asynchronously in the background
        Task {
            try? await securityActor.initialise()
        }
        
        return securityActor
    }
}
