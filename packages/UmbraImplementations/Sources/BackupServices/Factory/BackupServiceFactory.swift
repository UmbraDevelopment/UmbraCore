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
    repositoryPassword: String?=nil,
    useCache: Bool=true
  ) async throws -> BackupServiceProtocol {
    // Create a default Restic service
    let resticService=try await ResticServiceFactory.shared.createDefault(
      logger: logger,
      repositoryPath: repositoryPath,
      repositoryPassword: repositoryPassword
    )

    // Create repository info
    let repositoryInfo=RepositoryInfo(
      path: repositoryPath,
      password: repositoryPassword
    )

    // Check if we have a cached service
    if useCache, let cachedService=serviceCache[repositoryPath] {
      return cachedService
    }

    // Create a new backup services actor
    let backupService=BackupServicesActor(
      resticService: resticService,
      logger: logger,
      repositoryInfo: repositoryInfo
    )

    // Cache the service if requested
    if useCache {
      serviceCache[repositoryPath]=backupService
    }

    return backupService
  }

  /**
   * Creates a backup service with a custom Restic service.
   *
   * - Parameters:
   *   - resticService: The Restic service to use
   *   - logger: Logger for operation tracking
   *   - repositoryPath: Path to the repository
   *   - repositoryPassword: Optional repository password
   *   - useCache: Whether to cache and reuse the created service
   * - Returns: A configured backup service
   */
  public func create(
    resticService: ResticServiceProtocol,
    logger: any LoggingProtocol,
    repositoryPath: String,
    repositoryPassword: String?=nil,
    useCache: Bool=true
  ) async -> BackupServiceProtocol {
    // Create repository info
    let repositoryInfo=RepositoryInfo(
      path: repositoryPath,
      password: repositoryPassword
    )

    // Check if we have a cached service
    if useCache, let cachedService=serviceCache[repositoryPath] {
      return cachedService
    }

    // Create a new backup services actor
    let backupService=BackupServicesActor(
      resticService: resticService,
      logger: logger,
      repositoryInfo: repositoryInfo
    )

    // Cache the service if requested
    if useCache {
      serviceCache[repositoryPath]=backupService
    }

    return backupService
  }

  /**
   * Creates a backup service with a specific repository configuration.
   *
   * - Parameters:
   *   - logger: Logger for operation tracking
   *   - repositoryInfo: Repository connection details
   *   - useCache: Whether to cache and reuse the created service
   * - Returns: A configured backup service
   * - Throws: Error if Restic service creation fails
   */
  public func create(
    logger: any LoggingProtocol,
    repositoryInfo: RepositoryInfo,
    useCache: Bool=true
  ) async throws -> BackupServiceProtocol {
    // Create a default Restic service
    let resticService=try await ResticServiceFactory.shared.createDefault(
      logger: logger,
      repositoryPath: repositoryInfo.path,
      repositoryPassword: repositoryInfo.password
    )

    // Check if we have a cached service
    if useCache, let cachedService=serviceCache[repositoryInfo.path] {
      return cachedService
    }

    // Create a new backup services actor
    let backupService=BackupServicesActor(
      resticService: resticService,
      logger: logger,
      repositoryInfo: repositoryInfo
    )

    // Cache the service if requested
    if useCache {
      serviceCache[repositoryInfo.path]=backupService
    }

    return backupService
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
}
