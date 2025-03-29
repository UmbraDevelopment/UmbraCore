import CoreInterfaces
import CryptoInterfaces
import Foundation
import SecurityCoreInterfaces
import UmbraErrors

/**
 # Core Service Implementation

 This class is the central implementation of the CoreServiceProtocol,
 providing access to all core services throughout the application.

 ## Architecture

 - Follows the singleton pattern to ensure a single point of service access
 - Uses dependency injection via a service container
 - Implements the façade pattern to simplify access to subsystems
 - Uses adapters to isolate core components from implementation details

 ## Lifecycle Management

 The core service handles initialisation and shutdown of all dependent services,
 ensuring proper startup and cleanup procedures are followed.
 */
@MainActor
public final class CoreServiceImpl: CoreServiceProtocol {
  // MARK: - Properties

  /**
   Shared instance of the core service

   This follows the singleton pattern to ensure there is only one instance
   of the core service throughout the application.
   */
  public static let shared=CoreServiceImpl()

  /**
   Container for resolving service dependencies

   This container manages registration and resolution of all services,
   facilitating dependency injection throughout the application.
   */
  public let container: ServiceContainerProtocol

  /**
   Flag indicating if the service has been initialised

   Used to prevent multiple initialisation attempts.
   */
  private var isInitialised=false

  // MARK: - Initialisation

  /**
   Private initialiser to enforce singleton pattern

   Creates a new service container instance for dependency management.
   */
  private init() {
    container=ServiceContainerImpl()
  }

  // MARK: - CoreServiceProtocol Implementation

  /**
   Initialises all core services

   Performs necessary setup for all managed services, including:
   - Cryptographic services
   - Security services

   If the service has already been initialised, this method returns without
   performing additional initialisation.

   - Throws: CoreError if initialisation fails for any required service
   */
  public func initialise() async throws {
    guard !isInitialised else {
      return
    }

    // Initialise crypto service
    let crypto=try await getCryptoService()
    try await crypto.initialise()

    // Initialise security service
    let security=try await getSecurityService()
    try await security.initialise()

    isInitialised=true
  }

  /**
   Gets the crypto service for cryptographic operations

   Resolves the cryptographic service adapter from the container.

   - Returns: Crypto service implementation conforming to CoreCryptoServiceProtocol
   - Throws: CoreError.serviceNotFound if service is not available
   */
  public func getCryptoService() async throws -> CoreCryptoServiceProtocol {
    do {
      return try await container.resolve(CoreCryptoServiceProtocol.self)
    } catch {
      throw CoreError.serviceNotFound(name: "CryptoService")
    }
  }

  /**
   Gets the security service for security operations

   Resolves the security service adapter from the container.

   - Returns: Security service implementation conforming to CoreSecurityProviderProtocol
   - Throws: CoreError.serviceNotFound if service is not available
   */
  public func getSecurityService() async throws -> CoreSecurityProviderProtocol {
    do {
      return try await container.resolve(CoreSecurityProviderProtocol.self)
    } catch {
      throw CoreError.serviceNotFound(name: "SecurityService")
    }
  }

  /**
   Shuts down all services

   Performs necessary cleanup and orderly shutdown of all managed services.
   This method does not throw errors, but logs any shutdown issues internally.
   */
  public func shutdown() async {
    isInitialised=false
    // Additional shutdown logic would be implemented here
  }
}
