import CoreInterfaces
import CryptoInterfaces
import Foundation
import SecurityCoreInterfaces
import UmbraErrors

/**
 # Core Service Implementation

 This actor is the central implementation of the CoreServiceProtocol,
 providing access to all core services throughout the application.

 ## Architecture

 - Follows the singleton pattern to ensure a single point of service access
 - Uses dependency injection via a service container
 - Implements the façade pattern to simplify access to subsystems
 - Uses adapters to isolate core components from implementation details
 - Ensures thread safety through the actor concurrency model

 ## Lifecycle Management

 The core service handles initialisation and shutdown of all dependent services,
 ensuring proper startup and cleanup procedures are followed.
 */
public actor CoreServiceActor: CoreServiceProtocol, Sendable {
  // MARK: - Properties

  /**
   Shared instance of the core service

   This follows the singleton pattern to ensure there is only one instance
   of the core service throughout the application.
   */
  public static let shared = CoreServiceActor()

  /**
   Container for resolving service dependencies

   This container manages registration and resolution of all services,
   facilitating dependency injection throughout the application.
   */
  public nonisolated let container: ServiceContainerProtocol

  /**
   Flag indicating if the service has been initialised

   Used to prevent multiple initialisation attempts.
   */
  private var isInitialised = false

  // MARK: - Initialisation

  /**
   Private initialiser to enforce singleton pattern

   Creates a new core service with a default service container.
   */
  private init() {
    self.container = ServiceContainerImpl()
  }

  /**
   Initialises all core services

   Performs necessary setup and initialisation of all managed services,
   ensuring they are ready for use.

   - Throws: CoreError if initialisation fails for any required service
   */
  public func initialise() async throws {
    // Prevent multiple initialisation
    guard !isInitialised else {
      return
    }

    do {
      // Initialise critical services
      try await initialiseSecurityServices()
      try await initialiseCryptoServices()
      
      // Mark as initialised
      isInitialised = true
    } catch {
      // Wrap any initialisation errors in a CoreError
      throw CoreError.initialisation(message: "Failed to initialise core services: \(error.localizedDescription)")
    }
  }

  /**
   Initialises security-related services
   
   - Throws: CoreError if initialisation fails
   */
  private func initialiseSecurityServices() async throws {
    // Nothing to do here yet - services are initialised on demand
  }

  /**
   Initialises cryptography-related services
   
   - Throws: CoreError if initialisation fails
   */
  private func initialiseCryptoServices() async throws {
    // Nothing to do here yet - services are initialised on demand
  }

  // MARK: - Service Access Methods

  /**
   Gets the crypto service for cryptographic operations

   Returns an adapter that provides simplified access to the full
   cryptographic implementation.

   - Returns: Crypto service implementation conforming to CoreCryptoServiceProtocol
   - Throws: CoreError if service not available
   */
  public func getCryptoService() async throws -> CoreCryptoServiceProtocol {
    do {
      return try await container.resolve(CoreCryptoServiceProtocol.self)
    } catch {
      throw CoreError.serviceNotAvailable(
        message: "Crypto service is not available: \(error.localizedDescription)"
      )
    }
  }

  /**
   Gets the security provider for authentication and encryption

   Returns an adapter that provides simplified access to the full
   security implementation.

   - Returns: Security provider implementation conforming to CoreSecurityProviderProtocol
   - Throws: CoreError if service not available
   */
  public func getSecurityProvider() async throws -> CoreSecurityProviderProtocol {
    do {
      return try await container.resolve(CoreSecurityProviderProtocol.self)
    } catch {
      throw CoreError.serviceNotAvailable(
        message: "Security provider is not available: \(error.localizedDescription)"
      )
    }
  }

  /**
   Shuts down all services

   Performs necessary cleanup and orderly shutdown of all managed services.
   This method does not throw errors, but logs any shutdown issues internally.
   */
  public func shutdown() async {
    isInitialised = false
    // Additional shutdown logic would be implemented here
  }
}

/**
 # Core Error
 
 Error type for core service operations.
 Provides specific error cases for different failure scenarios.
 */
public enum CoreError: Error, Sendable {
  /// Initialisation of a core service failed
  case initialisation(message: String)
  
  /// A requested service is not available
  case serviceNotAvailable(message: String)
  
  /// An operation failed due to invalid configuration
  case invalidConfiguration(message: String)
  
  /// An operation failed due to an internal error
  case internalError(message: String)
}
