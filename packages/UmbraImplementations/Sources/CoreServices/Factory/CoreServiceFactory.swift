import CoreInterfaces
import Foundation
import LoggingInterfaces
import LoggingServices
import SecurityCoreInterfaces

/**
 # Core Service Factory

 Factory for creating core service instances following the Alpha Dot Five
 architecture pattern with actor-based concurrency.

 ## Usage Example

 ```swift
 // Get the shared core service
 let coreService = await CoreServiceFactory.getService()

 // Create a service container
 let container = CoreServiceFactory.createServiceContainer()

 // Initialise the core framework
 try await CoreServiceFactory.initialise()
 ```
 */
public enum CoreServiceFactory {
  /**
   Gets the shared core service actor.

   This method returns the singleton instance of the core service actor,
   ensuring a single point of access throughout the application.

   - Returns: Core service implementation
   */
  public static func getService() async -> CoreServiceProtocol {
    CoreServiceActor.shared
  }

  /**
   Creates a new service container.

   - Returns: Service container implementation
   */
  public static func createServiceContainer() -> ServiceContainerProtocol {
    ServiceContainerImpl()
  }

  /**
   Initialises the core framework.

   This method initialises all required services and ensures they're ready for use.

   - Throws: CoreError if initialisation fails
   */
  public static func initialise() async throws {
    try await CoreServiceActor.shared.initialise()
  }
}
