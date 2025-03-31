import CoreInterfaces
import LoggingInterfaces

/// CoreServiceFactory
///
/// Factory for creating instances of CoreServiceProtocol.
/// This factory follows the dependency injection pattern to create
/// properly configured core service instances with their dependencies.
///
/// # Usage Example
/// ```swift
/// let coreService = CoreServiceFactory.createDefault()
/// try await coreService.initialise(configuration: config)
/// ```
public enum CoreServiceFactory {
    /// Creates a default instance of CoreServiceProtocol with standard configuration
    /// - Parameter logger: Optional logger for core operations. If nil, a default logger will be created.
    /// - Returns: A configured instance of CoreServiceProtocol
    public static func createDefault(
        logger: DomainLogger? = nil
    ) -> CoreServiceProtocol {
        // Create the default configuration
        let defaultConfiguration = CoreConfigurationDTO(
            environment: .development,
            loggingLevel: .info,
            featureFlags: [
                "enableDetailedLogging": true,
                "enablePerformanceMonitoring": true,
                "strictErrorHandling": false
            ],
            applicationIdentifier: "uk.co.umbra.core"
        )
        
        // Use provided logger or create a default one
        let coreLogger = logger ?? LoggerFactory.createLogger(
            domain: "CoreService", 
            category: "Service"
        )
        
        // Create and return the core service actor
        return CoreServiceActor(
            configuration: defaultConfiguration,
            logger: coreLogger
        )
    }
    
    /// Creates a custom instance of CoreServiceProtocol with the specified configuration
    /// - Parameters:
    ///   - configuration: Custom configuration for the core service
    ///   - logger: Logger for core operations
    /// - Returns: A configured instance of CoreServiceProtocol
    public static func createCustom(
        configuration: CoreConfigurationDTO,
        logger: DomainLogger
    ) -> CoreServiceProtocol {
        // Create and return the core service actor with custom dependencies
        return CoreServiceActor(
            configuration: configuration,
            logger: logger
        )
    }
}
