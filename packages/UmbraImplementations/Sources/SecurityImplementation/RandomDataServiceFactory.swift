import Foundation
import LoggingInterfaces
import SecurityInterfaces

/// Factory for creating instances of the RandomDataServiceProtocol.
///
/// This factory provides methods for creating fully configured random data service
/// instances with various configurations.
public enum RandomDataServiceFactory {
    /// Creates a default random data service instance with standard configuration
    /// - Returns: A fully configured random data service
    public static func createDefault() -> RandomDataServiceProtocol {
        let logger = LoggingFactory.createDefault(
            subsystem: "uk.co.umbra.security",
            category: "RandomDataService"
        )
        
        return RandomDataServiceActor(logger: logger)
    }
    
    /// Creates a custom random data service instance with the specified logger
    /// - Parameter logger: The logger to use for logging security events
    /// - Returns: A fully configured random data service
    public static func createCustom(
        logger: LoggingProtocol
    ) -> RandomDataServiceProtocol {
        return RandomDataServiceActor(logger: logger)
    }
    
    /// Creates a high-security random data service instance with enhanced security settings
    /// - Returns: A fully configured high-security random data service
    public static func createHighSecurity() -> RandomDataServiceProtocol {
        let logger = LoggingFactory.createDefault(
            subsystem: "uk.co.umbra.security",
            category: "HighSecurityRandomDataService"
        )
        
        let service = RandomDataServiceActor(logger: logger)
        
        // Pre-configure with high security options
        Task {
            try? await service.initialise(configuration: .highSecurity)
        }
        
        return service
    }
    
    /// Creates a minimal random data service instance for resource-constrained environments
    /// - Returns: A minimally configured random data service
    public static func createMinimal() -> RandomDataServiceProtocol {
        let logger = LoggingFactory.createMinimal(
            subsystem: "uk.co.umbra.security",
            category: "MinimalRandomDataService"
        )
        
        let service = RandomDataServiceActor(logger: logger)
        
        // Pre-configure with basic security options
        Task {
            try? await service.initialise(configuration: .basic)
        }
        
        return service
    }
}
