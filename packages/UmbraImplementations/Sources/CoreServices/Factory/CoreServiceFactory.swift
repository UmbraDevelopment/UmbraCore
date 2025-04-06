import CoreInterfaces
import Foundation
import LoggingInterfaces
import LoggingTypes
import LoggingServices
import SecurityCoreInterfaces
import UmbraErrors

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
  /// Domain-specific logger for factory operations
  private static let logger = LoggerFactory.createCoreLogger(source: "CoreServiceFactory")
  
  /**
   Gets the shared core service actor.

   This method returns the singleton instance of the core service actor,
   ensuring a single point of access throughout the application.

   - Returns: Core service implementation
   */
  public static func getService() async -> CoreServiceProtocol {
    let context = CoreLogContext.service(
      source: "CoreServiceFactory.getService"
    )
    
    await logger.debug("Retrieving shared core service actor", context: context)
    return CoreServiceActor.shared
  }

  /**
   Creates a new service container.

   - Returns: Service container implementation
   */
  public static func createServiceContainer() -> ServiceContainerProtocol {
    let context = CoreLogContext.service(
      source: "CoreServiceFactory.createServiceContainer"
    )
    
    Task {
      await logger.debug("Creating new service container", context: context)
    }
    
    return ServiceContainerImpl()
  }

  /**
   Initialises the core framework.

   This method initialises all required services and ensures they're ready for use.

   - Throws: CoreError if initialisation fails
   */
  public static func initialise() async throws {
    let context = CoreLogContext.initialisation(
      source: "CoreServiceFactory.initialise"
    )
    
    await logger.info("Initialising core framework", context: context)
    
    do {
      try await CoreServiceActor.shared.initialise()
      await logger.info("Core framework initialised successfully", context: context)
    } catch {
      let loggableError = LoggableErrorDTO(
        error: error,
        message: "Failed to initialise core framework",
        details: "Core service actor initialisation failed"
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
      message: "Core framework initialisation failed: \(error.localizedDescription)"
    )
  }
}
