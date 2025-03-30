import CoreInterfaces
import CryptoInterfaces
import Foundation
import SecurityCoreInterfaces

/**
 # UmbraCore
 
 Main entry point for all UmbraCore functionality.
 
 This class provides centralised access to core services
 and manages framework initialisation.
 
 ## Usage Example
 
 ```swift
 // Initialise the framework
 try await UmbraCore.initialise()
 
 // Access core services
 let cryptoService = try await UmbraCore.getCryptoService()
 let securityProvider = try await UmbraCore.getSecurityProvider()
 ```
 */
public enum UmbraCore {
  /// Current version of UmbraCore
  public static let version = "1.0.0"

  /// Flag indicating if the framework has been initialised
  private static var isInitialised = false

  /**
   Initialises UmbraCore with default configuration.
   
   This method sets up all required services and ensures
   they're properly initialised before use.
   
   - Throws: CoreError if initialisation fails
   */
  public static func initialise() async throws {
    guard !isInitialised else {
      return
    }

    // Initialise core services
    try await CoreServiceFactory.initialise()

    isInitialised = true
  }

  /**
   Gets the core service instance.
   
   - Returns: Core service actor instance
   */
  public static func getCoreService() async -> CoreServiceProtocol {
    await CoreServiceFactory.getService()
  }

  /**
   Gets the crypto service instance.
   
   This provides access to cryptographic operations such as
   encryption, decryption, and key management.
   
   - Returns: Crypto service implementation
   - Throws: CoreError if service not available
   */
  public static func getCryptoService() async throws -> CoreCryptoServiceProtocol {
    try await (await getCoreService()).getCryptoService()
  }

  /**
   Gets the security provider instance.
   
   This provides access to security operations such as
   authentication, authorisation, and secure storage.
   
   - Returns: Security provider implementation
   - Throws: CoreError if service not available
   */
  public static func getSecurityProvider() async throws -> CoreSecurityProviderProtocol {
    try await (await getCoreService()).getSecurityProvider()
  }
}
