import CryptoInterfaces
import SecurityInterfaces
import LoggingInterfaces
import BuildConfig
import Foundation

/**
 # CryptoServiceRegistry
 
 Registry for creating CryptoServiceProtocol implementations with explicit type selection.
 
 This registry provides factory methods for creating crypto service implementations
 based on the explicitly selected type, ensuring developers make conscious decisions
 about which implementation to use rather than relying on automatic selection.
 
 ## Implementation Types
 
 - `standard`: Default implementation using AES encryption with Restic integration
 - `crossPlatform`: Implementation using RingFFI with Argon2id for any environment
 - `applePlatform`: Apple-native implementation using CryptoKit with optimisations
 
 ## Usage Example
 
 ```swift
 // Create a service with explicit type selection
 let cryptoService = await CryptoServiceRegistry.createService(
     type: .applePlatform,
     logger: myLogger
 )
 ```
 */
public enum CryptoServiceRegistry {
    /**
     Creates a crypto service implementation with explicit type selection.
     
     - Parameters:
       - type: The explicitly selected implementation type
       - secureStorage: Optional secure storage to use
       - logger: Optional logger to use
       - environment: Optional override for the environment configuration
     - Returns: A CryptoServiceProtocol implementation of the selected type
     */
    public static func createService(
        type: CryptoServiceType,
        secureStorage: SecureStorageProtocol? = nil,
        logger: LoggingProtocol? = nil,
        environment: UmbraEnvironment? = nil
    ) async -> CryptoServiceProtocol {
        // Create the factory with the explicit implementation type
        let factory = CryptoServiceFactory(serviceType: type)
        
        // Create the service using the factory
        return await factory.createService(
            secureStorage: secureStorage,
            logger: logger,
            environment: environment
        )
    }
}
