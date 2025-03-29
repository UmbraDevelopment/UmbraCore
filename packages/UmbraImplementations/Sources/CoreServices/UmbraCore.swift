import Foundation
import CoreInterfaces
import CryptoInterfaces
import SecurityCoreInterfaces

/// Main entry point for UmbraCore functionality
public enum UmbraCore {
    /// Current version of UmbraCore
    public static let version = "1.0.0"
    
    /// Flag indicating if the framework has been initialised
    private static var isInitialised = false
    
    /// Initialises UmbraCore with default configuration
    /// - Throws: CoreError if initialisation fails
    public static func initialise() async throws {
        guard !isInitialised else {
            return
        }
        
        // Initialise core services
        try await CoreServiceFactory.initialise()
        
        isInitialised = true
    }
    
    /// Gets the core service instance
    /// - Returns: Core service instance
    public static func getCoreService() -> CoreServiceProtocol {
        return CoreServiceFactory.createCoreService()
    }
    
    /// Gets the crypto service instance
    /// - Returns: Crypto service implementation
    /// - Throws: CoreError if service not available
    public static func getCryptoService() async throws -> CoreCryptoServiceProtocol {
        return try await getCoreService().getCryptoService()
    }
    
    /// Gets the security service instance
    /// - Returns: Security service implementation
    /// - Throws: CoreError if service not available
    public static func getSecurityService() async throws -> CoreSecurityProviderProtocol {
        return try await getCoreService().getSecurityService()
    }
}
