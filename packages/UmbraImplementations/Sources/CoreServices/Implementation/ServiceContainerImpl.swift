import CoreInterfaces
import CryptoInterfaces
import CryptoServices
import Foundation
import SecurityCoreInterfaces
import SecurityImplementation
import UmbraErrors

/**
 # Service Container Implementation
 
 This class implements the service container pattern for managing
 service dependencies throughout the application.
 
 ## Thread Safety
 
 The service container uses an internal actor to ensure thread-safe
 access to its registry of factories and singletons.
 
 ## Design Pattern
 
 This implements the service locator pattern with:
 - Lazy initialisation of services
 - Support for both singletons and factory-created instances
 - Thread-safe access through actor isolation
 */
public final class ServiceContainerImpl: ServiceContainerProtocol {
  /// Actor for thread-safe access to the factory and singleton maps
  private actor Container {
    var factories: [String: Any] = [:]
    var singletons: [String: Any] = [:]

    func registerFactory<T>(_ type: T.Type, factory: @escaping () async throws -> T) {
      let key = String(describing: type)
      factories[key] = factory
    }

    func registerSingleton<T>(_ type: T.Type, instance: T) {
      let key = String(describing: type)
      singletons[key] = instance
    }

    func getFactory<T>(_ type: T.Type) -> (() async throws -> T)? {
      let key = String(describing: type)
      return factories[key] as? () async throws -> T
    }

    func getSingleton<T>(_ type: T.Type) -> T? {
      let key = String(describing: type)
      return singletons[key] as? T
    }
  }

  /// Container actor instance
  private let container = Container()

  /**
   Initialises a new service container with default service registrations.
   */
  public init() {
    registerDefaultServices()
  }

  /**
   Registers default services used by the core framework.
   
   This includes:
   - Core service implementations
   - Crypto service implementations
   - Security provider implementations
   */
  private func registerDefaultServices() {
    Task {
      // Register the core service implementation
      await self.registerSingleton(CoreServiceProtocol.self, instance: CoreServiceActor.shared)

      // Register crypto service implementation
      await self.registerFactory(CoreCryptoServiceProtocol.self) {
        let cryptoService = await CryptoServiceFactory.createDefault()
        return CryptoServiceAdapter(cryptoService: cryptoService)
      }

      // Register security provider implementation
      await self.registerFactory(CoreSecurityProviderProtocol.self) {
        let securityProvider = await SecurityProviderFactory.createSecurityProvider()
        return SecurityProviderAdapter(securityProvider: securityProvider)
      }
    }
  }

  /**
   Registers a singleton instance of a service type.
   
   Singleton instances are reused across all requests for the service type.
   
   - Parameters:
     - type: The service type to register
     - instance: The singleton instance to return for this type
   */
  public func registerSingleton<T>(_ type: T.Type, instance: T) async {
    await container.registerSingleton(type, instance: instance)
  }

  /**
   Registers a factory for creating instances of a service type.
   
   Factories are used to create new instances each time the service is resolved.
   
   - Parameters:
     - type: The service type to register
     - factory: A closure that creates instances of the service
   */
  public func registerFactory<T>(_ type: T.Type, factory: @escaping () async throws -> T) async {
    await container.registerFactory(type, factory: factory)
  }

  /**
   Resolves a service implementation from the container.
   
   This will return a singleton if registered, otherwise create a new
   instance using the registered factory.
   
   - Parameter type: The service type to resolve
   - Returns: An implementation of the requested service type
   - Throws: ContainerError if the service type is not registered
   */
  public func resolve<T>(_ type: T.Type) async throws -> T {
    // First check if we have a singleton
    if let singleton = await container.getSingleton(type) {
      return singleton
    }
    
    // Then check if we have a factory
    if let factory = await container.getFactory(type) {
      do {
        return try await factory()
      } catch {
        throw ContainerError.factoryFailed(
          type: String(describing: type),
          message: error.localizedDescription
        )
      }
    }
    
    // No registration found
    throw ContainerError.serviceNotRegistered(type: String(describing: type))
  }
}

/**
 # Container Error
 
 Error type for service container operations.
 */
public enum ContainerError: Error, Sendable {
  /// The requested service type is not registered
  case serviceNotRegistered(type: String)
  
  /// The factory for creating the service failed
  case factoryFailed(type: String, message: String)
}
