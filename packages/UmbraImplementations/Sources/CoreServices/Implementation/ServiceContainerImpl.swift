import CoreInterfaces
import CryptoInterfaces
import CryptoServices
import Foundation
import LoggingInterfaces
import LoggingTypes
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
    var factories: [String: Any]=[:]
    var singletons: [String: Any]=[:]

    let logger: DomainLogger

    init(logger: DomainLogger) {
      self.logger=logger
    }

    func registerFactory<T>(_ type: T.Type, factory: @escaping () async throws -> T) async {
      let key=String(describing: type)

      let context=CoreLogContext.service(
        serviceName: "ServiceContainer",
        operation: "registerFactory",
        metadata: {
          var metadata=LogMetadataDTOCollection()
          metadata=metadata.withPublic(key: "serviceType", value: key)
          return metadata
        }()
      )

      factories[key]=factory

      await logger.debug("Registered factory for service type", context: context)
    }

    func registerSingleton<T>(_ type: T.Type, instance: T) async {
      let key=String(describing: type)

      let context=CoreLogContext.service(
        serviceName: "ServiceContainer",
        operation: "registerSingleton",
        metadata: {
          var metadata=LogMetadataDTOCollection()
          metadata=metadata.withPublic(key: "serviceType", value: key)
          return metadata
        }()
      )

      singletons[key]=instance

      await logger.debug("Registered singleton for service type", context: context)
    }

    func getFactory<T>(_ type: T.Type) async throws -> (() async throws -> T)? {
      let key=String(describing: type)

      let context=CoreLogContext.service(
        serviceName: "ServiceContainer",
        operation: "getFactory",
        metadata: {
          var metadata=LogMetadataDTOCollection()
          metadata=metadata.withPublic(key: "serviceType", value: key)
          return metadata
        }()
      )

      let factory=factories[key] as? () async throws -> T

      if factory == nil {
        await logger.debug("Factory not found for service type", context: context)
      } else {
        await logger.trace("Retrieved factory for service type", context: context)
      }

      return factory
    }

    func getSingleton<T>(_ type: T.Type) async throws -> T? {
      let key=String(describing: type)

      let context=CoreLogContext.service(
        serviceName: "ServiceContainer",
        operation: "getSingleton",
        metadata: {
          var metadata=LogMetadataDTOCollection()
          metadata=metadata.withPublic(key: "serviceType", value: key)
          return metadata
        }()
      )

      let singleton=singletons[key] as? T

      if singleton == nil {
        await logger.debug("Singleton not found for service type", context: context)
      } else {
        await logger.trace("Retrieved singleton for service type", context: context)
      }

      return singleton
    }
  }

  /// Container actor instance
  private let container: Container

  /// Logger for service container operations
  private let logger: DomainLogger

  /**
   Initialises a new service container with default service registrations.
   */
  public init() {
    // Create a domain logger for service container
    logger=LoggerFactory.createCoreLogger(source: "ServiceContainer")
    container=Container(logger: logger)

    Task {
      await logInitialisation()
      await registerDefaultServices()
    }
  }

  /**
   Log initialisation of the service container
   */
  private func logInitialisation() async {
    let context=CoreLogContext.initialisation(
      source: "ServiceContainerImpl.init"
    )

    await logger.info("Service container initialised", context: context)
  }

  /**
   Registers default services used by the core framework.

   This includes:
   - Core service implementations
   - Crypto service implementations
   - Security provider implementations
   */
  private func registerDefaultServices() async {
    let context=CoreLogContext.initialisation(
      source: "ServiceContainerImpl.registerDefaultServices"
    )

    await logger.info("Registering default services", context: context)

    // Register the core service implementation
    await registerSingleton(CoreServiceProtocol.self, instance: CoreServiceImpl.shared)

    // Register crypto service implementation
    await registerFactory(CoreCryptoServiceProtocol.self) {
      let context=CoreLogContext.service(
        serviceName: "ServiceContainer",
        operation: "createCryptoService"
      )

      await self.logger.debug("Creating crypto service adapter", context: context)

      let cryptoService=await CryptoServiceFactory.createDefault()
      return CryptoServiceAdapter(cryptoService: cryptoService)
    }

    // Register security provider implementation
    await registerFactory(CoreSecurityProviderProtocol.self) {
      let context=CoreLogContext.service(
        serviceName: "ServiceContainer",
        operation: "createSecurityProvider"
      )

      await self.logger.debug("Creating security provider adapter", context: context)

      let securityProvider=await SecurityProviderFactory.createSecurityProvider()
      return SecurityProviderAdapter(securityProvider: securityProvider)
    }

    await logger.info("Default services registered successfully", context: context)
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

   The factory is called each time the service is resolved.

   - Parameters:
     - type: The service type to register
     - factory: The factory function that creates instances of the service
   */
  public func registerFactory<T>(_ type: T.Type, factory: @escaping () async throws -> T) async {
    await container.registerFactory(type, factory: factory)
  }

  /**
   Resolves a service by type, returning an instance of the service.

   If the service has been registered as a singleton, the singleton instance is returned.
   If the service has been registered with a factory, the factory is called to create
   a new instance.

   - Parameter type: The service type to resolve
   - Returns: An instance of the service
   - Throws: CoreError.serviceNotAvailable if the service is not registered
   */
  public func resolve<T>(_ type: T.Type) async throws -> T {
    let context=CoreLogContext.service(
      serviceName: "ServiceContainer",
      operation: "resolve",
      metadata: {
        var metadata=LogMetadataDTOCollection()
        metadata=metadata.withPublic(key: "serviceType", value: String(describing: type))
        return metadata
      }()
    )

    await logger.debug("Resolving service", context: context)

    // Check for singleton first
    if let singleton=try await container.getSingleton(type) {
      await logger.trace("Resolved service as singleton", context: context)
      return singleton
    }

    // Try factory next
    if let factory=try await container.getFactory(type) {
      do {
        let instance=try await factory()
        await logger.trace("Resolved service using factory", context: context)
        return instance
      } catch {
        let loggableError=LoggableErrorDTO(
          error: error,
          message: "Failed to create service using factory",
          details: "Factory creation failed for \(String(describing: type))"
        )

        await logger.error(
          loggableError,
          context: context,
          privacyLevel: .private
        )

        throw CoreError.serviceNotAvailable(serviceName: String(describing: type))
      }
    }

    // Service not available
    let errorMessage="Service of type \(String(describing: type)) is not registered"

    await logger.warning(errorMessage, context: context)

    throw CoreError.serviceNotAvailable(serviceName: String(describing: type))
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
