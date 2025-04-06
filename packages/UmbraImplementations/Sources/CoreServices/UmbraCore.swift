import CoreInterfaces
import CryptoInterfaces
import Foundation
import LoggingInterfaces
import LoggingTypes
import SecurityCoreInterfaces
import UmbraErrors

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
  
  /// Domain-specific logger for UmbraCore operations
  private static let logger = LoggerFactory.createCoreLogger(source: "UmbraCore")

  /**
   Initialises UmbraCore with default configuration.

   This method sets up all required services and ensures
   they're properly initialised before use.

   - Throws: CoreError if initialisation fails
   */
  public static func initialise() async throws {
    let context = CoreLogContext.initialisation(
      source: "UmbraCore.initialise"
    )
    
    guard !isInitialised else {
      await logger.debug("UmbraCore already initialised, skipping", context: context)
      return
    }

    await logger.info("Initialising UmbraCore framework", context: context)
    
    do {
      // Initialise core services
      try await CoreServiceFactory.initialise()
      
      isInitialised = true
      await logger.info("UmbraCore framework initialised successfully", context: context)
    } catch {
      let loggableError = LoggableErrorDTO(
        error: error,
        message: "Failed to initialise UmbraCore framework",
        details: "Core service factory initialisation failed"
      )
      
      await logger.error(
        loggableError,
        context: context,
        privacyLevel: .private
      )
      
      throw adaptError(error)
    }
  }

  /**
   Gets the core service instance.

   - Returns: Core service actor instance
   */
  public static func getCoreService() async -> CoreServiceProtocol {
    let context = CoreLogContext.service(
      source: "UmbraCore.getCoreService"
    )
    
    await logger.debug("Getting core service instance", context: context)
    
    let service = await CoreServiceFactory.getService()
    await logger.debug("Core service instance retrieved", context: context)
    
    return service
  }

  /**
   Gets the crypto service instance.

   This provides access to cryptographic operations such as
   encryption, decryption, and key management.

   - Returns: Crypto service implementation
   - Throws: CoreError if service not available
   */
  public static func getCryptoService() async throws -> CoreCryptoServiceProtocol {
    let context = CoreLogContext.service(
      source: "UmbraCore.getCryptoService"
    )
    
    await logger.debug("Getting crypto service instance", context: context)
    
    do {
      let service = try await (await getCoreService()).getCryptoService()
      await logger.debug("Crypto service instance retrieved", context: context)
      return service
    } catch {
      let loggableError = LoggableErrorDTO(
        error: error,
        message: "Failed to get crypto service",
        details: "Service resolution failed"
      )
      
      await logger.error(
        loggableError,
        context: context,
        privacyLevel: .private
      )
      
      throw adaptError(error)
    }
  }

  /**
   Gets the security provider instance.

   This provides access to security operations such as
   authentication, authorisation, and secure storage.

   - Returns: Security provider implementation
   - Throws: CoreError if service not available
   */
  public static func getSecurityProvider() async throws -> CoreSecurityProviderProtocol {
    let context = CoreLogContext.service(
      source: "UmbraCore.getSecurityProvider"
    )
    
    await logger.debug("Getting security provider instance", context: context)
    
    do {
      let provider = try await (await getCoreService()).getSecurityProvider()
      await logger.debug("Security provider instance retrieved", context: context)
      return provider
    } catch {
      let loggableError = LoggableErrorDTO(
        error: error,
        message: "Failed to get security provider",
        details: "Provider resolution failed"
      )
      
      await logger.error(
        loggableError,
        context: context,
        privacyLevel: .private
      )
      
      throw adaptError(error)
    }
  }
  
  // MARK: - Private Methods
  
  /**
   Adapts domain-specific errors to the core error domain
   
   - Parameter error: The original error to adapt
   - Returns: A CoreError representing the adapted error
   */
  private static func adaptError(_ error: Error) -> Error {
    // If it's already a CoreError, return it directly
    if let coreError = error as? CoreError {
      return coreError
    }
    
    // For any other error, wrap it in a generic message
    return CoreError.initialisation(
      message: "Core framework operation failed: \(error.localizedDescription)"
    )
  }
}
