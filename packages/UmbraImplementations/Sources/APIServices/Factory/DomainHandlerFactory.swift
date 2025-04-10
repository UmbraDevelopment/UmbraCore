import APIInterfaces
import Foundation
import LoggingInterfaces
import LoggingTypes
import RepositoryInterfaces
import SecurityInterfaces

/**
 # Domain Handler Factory

 Creates and manages domain handlers for the Alpha Dot Five architecture.
 This factory provides a centralised way to create properly configured
 domain handlers with appropriate dependencies and logging.

 ## Thread Safety

 The factory is implemented as an actor to ensure thread safety when
 creating and accessing domain handlers.
 */
public actor DomainHandlerFactory {
  /// Shared instance for singleton access
  public static let shared=DomainHandlerFactory()

  /// Cache of created domain handlers
  private var handlerCache: [APIDomain: any DomainHandlerProtocol]=[:]

  /// Logger factory for creating appropriate loggers
  private let loggerFactory: LoggingServiceFactory

  /// The deployment environment
  private let environment: DeploymentEnvironment

  /**
   Initialises a new domain handler factory.

   - Parameters:
     - loggerFactory: Factory for creating loggers
     - environment: The deployment environment
   */
  public init(
    loggerFactory: LoggingServiceFactory=LoggingServiceFactory(),
    environment: DeploymentEnvironment = .development
  ) {
    self.loggerFactory=loggerFactory
    self.environment=environment
  }

  /**
   Creates or retrieves a domain handler for the specified domain.

   - Parameters:
     - domain: The API domain to create a handler for
     - forceNew: If true, creates a new handler even if one exists in the cache
   - Returns: A domain handler for the specified domain
   - Throws: APIError if the domain is not supported
   */
  public func createHandler(
    for domain: APIDomain,
    forceNew: Bool=false
  ) throws -> any DomainHandlerProtocol {
    // Return cached handler if available and not forcing new
    if !forceNew, let handler=handlerCache[domain] {
      return handler
    }

    // Create a new handler based on domain
    let handler: any DomainHandlerProtocol

    // Create a privacy-aware logger for the domain
    let logger=loggerFactory.createPrivacyAwareLogger(
      minimumLevel: .info,
      environment: environment
    )

    switch domain {
      case .security:
        let securityService=try SecurityServiceFactory.createSecurityService(
          providerType: .platform,
          logger: logger
        )
        handler=SecurityDomainHandler(service: securityService, logger: logger)

      case .backup:
        let backupService=try BackupServiceFactory.createService(
          storageProvider: .local,
          logger: logger
        )
        handler=BackupDomainHandler(service: backupService, logger: logger)

      case .repository:
        let repositoryService=try RepositoryServiceFactory.createRepositoryService(
          repositoryType: .standard,
          logger: logger
        )
        handler=RepositoryDomainHandler(service: repositoryService, logger: logger)

      default:
        throw APIError.operationNotSupported(
          message: "Domain not supported: \(domain)",
          code: "DOMAIN_NOT_SUPPORTED"
        )
    }

    // Cache the handler for future use
    handlerCache[domain]=handler

    return handler
  }

  /**
   Creates or retrieves all supported domain handlers.

   - Parameter forceNew: If true, creates new handlers even if they exist in the cache
   - Returns: Dictionary mapping domains to their handlers
   */
  public func createAllHandlers(forceNew: Bool=false) -> [APIDomain: any DomainHandlerProtocol] {
    var handlers: [APIDomain: any DomainHandlerProtocol]=[:]

    // Try to create a handler for each known domain
    for domain in APIDomain.allCases {
      do {
        let handler=try createHandler(for: domain, forceNew: forceNew)
        handlers[domain]=handler
      } catch {
        // Skip domains that aren't supported
        continue
      }
    }

    return handlers
  }

  /**
   Clears the cache of all domain handlers.
   */
  public func clearHandlerCache() async {
    // Clear the internal cache
    handlerCache.removeAll()

    // Clear the cache of each handler
    for (_, handler) in handlerCache {
      await handler.clearCache()
    }
  }
}

/**
 Factory for creating security services.
 */
public enum SecurityServiceFactory {
  /**
   Creates a security service with the appropriate configuration.

   - Parameters:
     - providerType: The type of security provider to use
     - logger: The logger to use for the service
   - Returns: A configured security service
   - Throws: Error if the service cannot be created
   */
  public static func createSecurityService(
    providerType _: SecurityProviderType,
    logger _: Logger
  ) throws -> SecurityServiceProtocol {
    // This is a placeholder implementation
    // In a real implementation, this would create the appropriate security service
    // based on configuration, environment, etc.
    fatalError("SecurityServiceFactory.createSecurityService() not implemented")
  }
}

/**
 Factory for creating backup services.
 */
public enum BackupServiceFactory {
  /**
   Creates a backup service with the appropriate configuration.

   - Parameters:
     - storageProvider: The type of storage provider to use
     - logger: The logger to use for the service
   - Returns: A configured backup service
   - Throws: Error if the service cannot be created
   */
  public static func createService(
    storageProvider _: StorageProviderType,
    logger _: Logger
  ) throws -> BackupServiceProtocol {
    // This is a placeholder implementation
    // In a real implementation, this would create the appropriate backup service
    // based on configuration, environment, etc.
    fatalError("BackupServiceFactory.createService() not implemented")
  }

  public static func createDefault(
    logger _: Logger,
    repositoryPath _: String
  ) throws -> BackupServiceProtocol {
    fatalError(
      "BackupServiceFactory.createDefault() not implemented: unable to create default backup service"
    )
  }
}

/**
 Factory for creating repository services.
 */
public enum RepositoryServiceFactory {
  /**
   Creates a repository service with the appropriate configuration.

   - Parameters:
     - repositoryType: The type of repository to use
     - logger: The logger to use for the service
   - Returns: A configured repository service
   - Throws: Error if the service cannot be created
   */
  public static func createRepositoryService(
    repositoryType _: RepositoryType,
    logger _: Logger
  ) throws -> RepositoryServiceProtocol {
    // This is a placeholder implementation
    // In a real implementation, this would create the appropriate repository service
    // based on configuration, environment, etc.
    fatalError("RepositoryServiceFactory.createRepositoryService() not implemented")
  }
}
