import Foundation
import LoggingInterfaces
import SecurityInterfaces
import UmbraErrors
import CryptoInterfaces
import CryptoXPCServices

/// Factory for creating instances of the SecurityServiceProtocol.
///
/// This factory provides methods for creating fully configured security service
/// instances with various configurations and crypto service integrations, ensuring
/// proper domain separation and delegation to crypto services.
public enum SecurityServiceFactory {
    /// Creates a default security service instance with standard configuration
    /// - Returns: A fully configured security service
    public static func createDefault() -> SecurityServiceProtocol {
        let logger = LoggingFactory.createDefault(
            subsystem: "uk.co.umbra.security",
            category: "SecurityService"
        )
        
        // Use the crypto XPC service for cryptographic operations
        let cryptoService = CryptoXPCServiceFactory.createDefault()
        
        return SecurityServiceActor(
            cryptoService: cryptoService,
            logger: logger
        )
    }
    
    /// Creates a custom security service instance with the specified configuration
    /// - Parameters:
    ///   - cryptoService: The crypto service to use for cryptographic operations
    ///   - logger: The logger to use for logging security events
    /// - Returns: A fully configured security service
    public static func createCustom(
        cryptoService: CryptoXPCServiceProtocol,
        logger: LoggingProtocol
    ) -> SecurityServiceProtocol {
        return SecurityServiceActor(
            cryptoService: cryptoService,
            logger: logger
        )
    }
    
    /// Creates a high-security service instance with enhanced security settings
    /// - Returns: A fully configured high-security service
    public static func createHighSecurity() -> SecurityServiceProtocol {
        let logger = LoggingFactory.createDefault(
            subsystem: "uk.co.umbra.security",
            category: "HighSecurityService"
        )
        
        // Use the high-security crypto service
        let cryptoService = CryptoXPCServiceFactory.createHighSecurity()
        
        return SecurityServiceActor(
            cryptoService: cryptoService,
            logger: logger
        )
    }
    
    /// Creates a minimal security service instance for resource-constrained environments
    /// - Returns: A minimally configured security service
    public static func createMinimal() -> SecurityServiceProtocol {
        let logger = LoggingFactory.createMinimal(
            subsystem: "uk.co.umbra.security",
            category: "MinimalSecurityService"
        )
        
        // Use the minimal crypto service
        let cryptoService = CryptoXPCServiceFactory.createMinimal()
        
        return SecurityServiceActor(
            cryptoService: cryptoService,
            logger: logger
        )
    }
}
