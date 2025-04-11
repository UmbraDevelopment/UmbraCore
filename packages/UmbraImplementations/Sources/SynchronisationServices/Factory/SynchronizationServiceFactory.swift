import Foundation
import LoggingInterfaces
import SynchronisationInterfaces

/**
 Factory for creating SynchronisationServiceProtocol implementations.

 This factory follows the provider pattern to create appropriate implementations
 of the synchronisation service based on configuration.
 */
public struct SynchronizationServiceFactory {
  /// Shared instance of the factory for convenience
  public static let shared=SynchronizationServiceFactory()

  /// Cache of created service instances by identifier
  private var serviceCache: [String: SynchronisationServiceProtocol]=[:]

  /**
   Creates or retrieves a synchronisation service instance.

   - Parameters:
      - identifier: Unique identifier for the service instance
      - logger: Logger instance for synchronization operations
   - Returns: A configured synchronisation service
   */
  public func createService(
    identifier: String="default",
    logger: PrivacyAwareLoggingProtocol
  ) -> SynchronisationServiceProtocol {
    // Return cached instance if available
    if let cachedService=serviceCache[identifier] {
      return cachedService
    }

    // Create a new instance
    let service=SynchronizationServicesActor(logger: logger)

    // Cache the instance
    serviceCache[identifier]=service

    return service
  }

  /**
   Clears the cache of service instances.
   */
  public func clearCache() {
    serviceCache.removeAll()
  }
}
