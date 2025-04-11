import Foundation
import PersistenceInterfaces
import LoggingInterfaces

/**
 Factory for creating persistence service instances.
 
 This factory simplifies the creation of persistence service instances
 with appropriate provider implementations.
 */
public class PersistenceServicesFactory {
    /**
     Creates a new instance of the persistence service.
     
     - Parameters:
        - provider: Provider for persistence operations
        - logger: Logger for operation logging
     - Returns: A new persistence services actor
     */
    public static func createPersistenceService(
        provider: PersistenceProviderProtocol,
        logger: PrivacyAwareLoggingProtocol
    ) -> PersistenceServicesActor {
        // Create command factory with provider and logger
        let commandFactory = PersistenceCommandFactory(
            provider: provider,
            logger: logger
        )
        
        // Create and return the persistence service actor
        return PersistenceServicesActor(
            commandFactory: commandFactory,
            logger: logger
        )
    }
    
    /**
     Creates a new persistence service with default provider for the platform.
     
     - Parameters:
        - databaseURL: URL to the database directory
        - logger: Logger for operation logging
     - Returns: A new persistence services actor
     */
    public static func createDefaultPersistenceService(
        databaseURL: URL,
        logger: PrivacyAwareLoggingProtocol
    ) -> PersistenceServicesActor {
        // Create provider based on platform
        let provider = PersistenceProviderFactory.createProvider(
            type: .default,
            databaseURL: databaseURL
        )
        
        return createPersistenceService(
            provider: provider,
            logger: logger
        )
    }
    
    /**
     Creates a new persistence service with Apple-specific provider.
     
     - Parameters:
        - databaseURL: URL to the database directory
        - logger: Logger for operation logging
     - Returns: A new persistence services actor
     */
    public static func createApplePersistenceService(
        databaseURL: URL,
        logger: PrivacyAwareLoggingProtocol
    ) -> PersistenceServicesActor {
        // Create Apple-specific provider
        let provider = PersistenceProviderFactory.createProvider(
            type: .apple,
            databaseURL: databaseURL
        )
        
        return createPersistenceService(
            provider: provider,
            logger: logger
        )
    }
    
    /**
     Creates a new persistence service with cross-platform provider.
     
     - Parameters:
        - databaseURL: URL to the database directory
        - logger: Logger for operation logging
     - Returns: A new persistence services actor
     */
    public static func createCrossPlatformPersistenceService(
        databaseURL: URL,
        logger: PrivacyAwareLoggingProtocol
    ) -> PersistenceServicesActor {
        // Create cross-platform provider
        let provider = PersistenceProviderFactory.createProvider(
            type: .crossPlatform,
            databaseURL: databaseURL
        )
        
        return createPersistenceService(
            provider: provider,
            logger: logger
        )
    }
}
