import CoreInterfaces
import CryptoInterfaces
import CryptoServices
import Foundation
import SecurityCoreInterfaces
import SecurityImplementation
import UmbraErrors

/// Implementation of the service container for managing service dependencies
public final class ServiceContainerImpl: ServiceContainerProtocol {
  /// Actor for thread-safe access to the factory and singleton maps
  private actor Container {
    var factories: [String: Any]=[:]
    var singletons: [String: Any]=[:]

    func registerFactory<T>(_ type: T.Type, factory: @escaping () async throws -> T) {
      let key=String(describing: type)
      factories[key]=factory
    }

    func registerSingleton<T>(_ type: T.Type, instance: T) {
      let key=String(describing: type)
      singletons[key]=instance
    }

    func getFactory<T>(_ type: T.Type) -> (() async throws -> T)? {
      let key=String(describing: type)
      return factories[key] as? () async throws -> T
    }

    func getSingleton<T>(_ type: T.Type) -> T? {
      let key=String(describing: type)
      return singletons[key] as? T
    }
  }

  /// Container actor instance
  private let container=Container()

  /// Initialises a new service container
  public init() {
    registerDefaultServices()
  }

  /// Registers default services used by the core framework
  private func registerDefaultServices() {
    // Register the core service implementation
    Task {
      await self.registerSingleton(CoreServiceProtocol.self, instance: CoreServiceImpl.shared)

      // Register crypto service implementation
      let cryptoService=CryptoServiceFactory.createDefault()
      self.register(CryptoInterfaces.CryptoServiceProtocol.self) {
        cryptoService
      }

      // Register adapter for core crypto service protocol
      self.register(CoreCryptoServiceProtocol.self) {
        CryptoServiceAdapter(cryptoService: cryptoService)
      }

      // Register security service implementation
      let securityProvider=await SecurityImplementation.createSecurityProvider()
      self.register(SecurityCoreInterfaces.SecurityProviderProtocol.self) {
        securityProvider
      }

      // Register adapter for core security provider protocol
      self.register(CoreSecurityProviderProtocol.self) {
        SecurityProviderAdapter(securityProvider: securityProvider)
      }
    }
  }

  /// Resolves a service by type
  /// - Returns: Instance of the requested service
  /// - Throws: CoreError if service not found or cannot be instantiated
  public func resolve<T>(_ type: T.Type) async throws -> T {
    // First check if a singleton exists
    if let singleton=await container.getSingleton(type) {
      return singleton
    }

    // Otherwise try to create using a factory
    if let factory=await container.getFactory(type) {
      do {
        let instance=try await factory()
        return instance
      } catch {
        throw CoreError.serviceNotFound(name: String(describing: type))
      }
    }

    throw CoreError.serviceNotFound(name: String(describing: type))
  }

  /// Registers a factory for creating service instances
  /// - Parameters:
  ///   - type: The service type
  ///   - factory: Factory closure for creating service instances
  public func register<T>(_ type: T.Type, factory: @escaping () async throws -> T) {
    Task {
      await container.registerFactory(type, factory: factory)
    }
  }

  /// Registers a singleton instance of a service
  /// - Parameters:
  ///   - type: The service type
  ///   - instance: The singleton instance
  public func registerSingleton<T>(_ type: T.Type, instance: T) {
    Task {
      await container.registerSingleton(type, instance: instance)
    }
  }
}
