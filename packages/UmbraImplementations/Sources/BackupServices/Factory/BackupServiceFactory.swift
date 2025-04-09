import BackupInterfaces
import Foundation
import LoggingInterfaces
import ResticInterfaces
import ResticServices

/**
 * Factory for creating backup-related services
 *
 * This factory provides methods for creating properly configured
 * backup and snapshot services with appropriate dependencies,
 * following the Alpha Dot Five architecture principles.
 *
 * As an actor, this factory provides thread safety for service creation
 * and maintains a cache of created services for improved performance.
 */
public actor BackupServiceFactory {
  /// Shared singleton instance
  public static let shared=BackupServiceFactory()

  /// Cache of created services by repository path
  private var serviceCache: [String: BackupServiceProtocol]=[:]

  /// Creates a new backup service factory
  public init() {}

  /**
   * Creates a default backup service with standard configuration.
   *
   * - Parameters:
   *   - logger: Logger for operation tracking
   *   - repositoryPath: Path to the repository
   *   - repositoryPassword: Optional repository password
   *   - useCache: Whether to cache and reuse the created service
   * - Returns: A configured backup service
   * - Throws: Error if Restic service creation fails
   */
  public func createDefault(
    logger: any LoggingProtocol,
    repositoryPath: String,
    repositoryPassword: String? = nil,
    useCache: Bool = true
  ) async throws -> BackupServiceProtocol {
    // Create a default Restic service
    let resticService = try await ResticServiceFactory.shared.createDefault(
      logger: logger,
      repositoryPath: repositoryPath,
      repositoryPassword: repositoryPassword
    )
    
    // Create repository info
    let repositoryInfo = RepositoryInfo(
      location: repositoryPath,
      password: repositoryPassword
    )
    
    // Create the backup service
    return await createService(
      resticService: resticService,
      logger: logger,
      repositoryInfo: repositoryInfo,
      useCache: useCache
    )
  }

  /**
   * Creates a new backup service with the specified dependencies
   * following the Alpha Dot Five architecture.
   *
   * - Parameters:
   *   - resticService: The Restic service to use for backend operations
   *   - logger: Logger for operation tracking
   *   - repositoryInfo: Repository information
   *   - useCache: Whether to cache and reuse the created service
   * - Returns: A configured backup service
   */
  public func createService(
    resticService: ResticServiceProtocol,
    logger: any LoggingProtocol,
    repositoryInfo: RepositoryInfo,
    useCache: Bool=true
  ) async -> BackupServiceProtocol {
    // Check cache first if enabled
    if useCache, let cachedService=serviceCache[repositoryInfo.location] {
      return cachedService
    }

    // Create dependencies
    let errorMapper=BackupErrorMapper()
    let cancellationHandler=CancellationHandler()
    let metricsCollector=BackupMetricsCollector()

    // Create operations service
    let operationsService=BackupOperationsService(
      resticService: resticService,
      repositoryInfo: repositoryInfo,
      commandFactory: BackupCommandFactory(),
      resultParser: BackupResultParser()
    )

    // Create operation executor
    let operationExecutor=BackupOperationExecutor(
      logger: logger,
      cancellationHandler: cancellationHandler,
      metricsCollector: metricsCollector,
      errorLogContextMapper: ErrorLogContextMapper(),
      errorMapper: errorMapper
    )

    // Create the actor-based implementation
    let service=BackupServicesActor(
      resticService: resticService,
      logger: logger,
      repositoryInfo: repositoryInfo
    )

    // Cache the service if enabled
    if useCache {
      serviceCache[repositoryInfo.location]=service
    }

    return service
  }

  /**
   * Creates a new backup service using the Restic service factory
   *
   * - Parameters:
   *   - resticServiceFactory: Factory for creating Restic services
   *   - logger: Logger for operation tracking
   *   - repositoryPath: Path to the repository
   *   - repositoryPassword: Optional repository password
   *   - useCache: Whether to cache and reuse the created service
   * - Returns: A configured backup service
   * - Throws: Error if Restic service creation fails
   */
  public func createService(
    resticServiceFactory: ResticServiceFactory,
    logger: any LoggingProtocol,
    repositoryPath: String,
    repositoryPassword: String?=nil,
    useCache: Bool=true
  ) async throws -> BackupServiceProtocol {
    // Check cache first if enabled
    if useCache, let cachedService=serviceCache[repositoryPath] {
      return cachedService
    }

    // Create the Restic service
    let resticService=try resticServiceFactory.createService(
      executablePath: "/usr/local/bin/restic",
      defaultRepository: repositoryPath,
      defaultPassword: repositoryPassword,
      progressDelegate: nil
    )

    // Create repository info
    let repositoryInfo=RepositoryInfo(
      location: repositoryPath,
      id: UUID().uuidString, // This would be obtained from the repository
      password: repositoryPassword
    )

    // Create backup service using Alpha Dot Five architecture
    return await createService(
      resticService: resticService,
      logger: logger,
      repositoryInfo: repositoryInfo,
      useCache: useCache
    )
  }

  /**
   * Clears the service cache
   *
   * This can be useful when testing or when services need to be recreated
   * with fresh configurations.
   */
  public func clearCache() {
    serviceCache.removeAll()
  }

  /**
   * Removes a specific service from the cache
   *
   * - Parameter repositoryPath: The repository path associated with the service to remove
   * - Returns: True if a service was removed, false if no service was found
   */
  public func removeFromCache(repositoryPath: String) -> Bool {
    if serviceCache[repositoryPath] != nil {
      serviceCache[repositoryPath]=nil
      return true
    }
    return false
  }
}
