import Foundation
import UmbraErrors

/**
 # Core Service Protocol
 
 This protocol defines the main entry point for accessing core services throughout the application.
 
 ## Purpose
 
 - Serves as the central access point for all core system services
 - Manages initialisation and lifecycle of critical system components
 - Provides service location functionality via a dependency container
 
 ## Architecture Notes
 
 The CoreServiceProtocol follows the façade pattern, simplifying access to 
 the various subsystems while managing their lifecycle. It uses adapter protocols
 to isolate components from implementation details of other system parts.
 */
public protocol CoreServiceProtocol: Sendable {
    /**
     Container for resolving service dependencies
     
     This container manages the registration and resolution of service instances,
     facilitating dependency injection throughout the application.
     */
    var container: ServiceContainerProtocol { get }
    
    /**
     Initialises all core services
     
     Performs necessary setup and initialisation of all managed services,
     ensuring they are ready for use.
     
     - Throws: CoreError if initialisation fails for any required service
     */
    func initialise() async throws
    
    /**
     Gets the crypto service for cryptographic operations
     
     Returns an adapter that provides simplified access to the full
     cryptographic implementation.
     
     - Returns: Crypto service implementation conforming to CoreCryptoServiceProtocol
     - Throws: CoreError if service not available
     */
    func getCryptoService() async throws -> CoreCryptoServiceProtocol
    
    /**
     Gets the security service for security operations
     
     Returns an adapter that provides simplified access to the full
     security implementation.
     
     - Returns: Security service implementation conforming to CoreSecurityProviderProtocol
     - Throws: CoreError if service not available
     */
    func getSecurityService() async throws -> CoreSecurityProviderProtocol
    
    /**
     Shuts down all services
     
     Performs necessary cleanup and orderly shutdown of all managed services.
     */
    func shutdown() async
}
