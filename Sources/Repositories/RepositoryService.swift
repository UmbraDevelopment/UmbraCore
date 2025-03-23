// Standard modules
import Foundation

// Internal modules
import CoreErrors
import ErrorHandlingDomains
import RepositoriesTypes
import SecurityTypes
import SecurityTypesProtocols
import UmbraLogging

/// A service that manages repository registration, locking, and statistics.
///
/// The `RepositoryService` provides thread-safe access to repository operations through the actor
/// model.
/// It maintains a registry of repositories and provides operations for managing their lifecycle.
///
/// Example:
/// ```swift
/// let service = RepositoryService.shared
/// try await service.register(myRepository)
/// let stats = try await service.getStats(for: myRepository.identifier)
/// ```
public actor RepositoryService {
  /// Shared instance of the repository service
  public static let shared=RepositoryService()

  /// Currently registered repositories
  var repositories: [String: any Repository]

  /// Logger instance
  let logger: LoggingProtocol

  /// Initializes a new repository service instance.
  ///
  /// - Parameter logger: The logging service to use for operation tracking. Defaults to the shared
  /// logger.
  public init(
    logger: LoggingProtocol=UmbraLogging.createLogger()
  ) {
    repositories=[:]
    self.logger=logger
  }

  // MARK: - Repository Management

  /// Registers a repository with the service.
  ///
  /// - Parameter repository: The repository to register. Must conform to the `Repository` protocol.
  /// - Throws: `UmbraErrors.Repository.Core.permissionDenied` if the repository cannot be
  /// accessed,
  ///           `UmbraErrors.Repository.Core.internalError` if a repository with the same
  /// identifier exists.
  public func register(_ repository: some Repository) async throws {
    let identifier=await repository.identifier
    let location=await repository.location
    let state=await repository.state

    let metadata=LogMetadata([
      "repository_id": identifier,
      "location": location.path,
      "state": String(describing: state)
    ])

    await logger.info("Registering repository", metadata: metadata)

    // Ensure repository is accessible
    guard await repository.isAccessible() else {
      await logger.error("Repository not accessible", metadata: metadata)
      throw UmbraErrors.Repository.Core.permissionDenied(
        operation: "register",
        reason: "Repository is not accessible"
      )
    }

    // Check for duplicate
    guard repositories[identifier] == nil else {
      await logger.error(
        "Duplicate repository identifier",
        metadata: metadata
      )
      throw UmbraErrors.Repository.Core
        .internalError(reason: "Repository with identifier '\(identifier)' already exists")
    }

    // Initialize repository if needed
    if case RepositoryState.uninitialized=state {
      await logger.info("Initializing uninitialized repository", metadata: metadata)
      try await repository.initialize()
    }

    // Validate repository
    do {
      guard try await repository.validate() else {
        await logger.error("Repository validation failed", metadata: metadata)
        throw UmbraErrors.Repository.Core.internalError(
          reason: "Repository validation failed"
        )
      }
    } catch {
      await logger.error(
        "Repository validation error: \(error.localizedDescription)",
        metadata: metadata
      )
      throw error
    }

    repositories[identifier]=repository
    await logger.info("Repository registered successfully", metadata: metadata)
  }

  /// Deregisters a repository from the service.
  ///
  /// - Parameter identifier: The identifier of the repository to deregister.
  /// - Throws: `UmbraErrors.Repository.Core.repositoryNotFound` if no repository exists with the
  /// given
  /// identifier.
  public func deregister(identifier: String) async throws {
    let metadata=LogMetadata([
      "repository_id": identifier
    ])
    await logger.info("Deregistering repository", metadata: metadata)

    guard repositories.removeValue(forKey: identifier) != nil else {
      await logger.error("Repository not found", metadata: metadata)
      throw UmbraErrors.Repository.Core.repositoryNotFound(resource: identifier)
    }

    await logger.info("Repository deregistered successfully", metadata: metadata)
  }

  /// Lists all registered repositories.
  ///
  /// - Returns: An array of registered repositories.
  public func listRepositories() async -> [any Repository] {
    await logger.debug(
      "Listing repositories",
      metadata: LogMetadata([
        "count": String(repositories.count)
      ])
    )
    return Array(repositories.values)
  }

  /// Gets a repository by its identifier.
  ///
  /// - Parameter identifier: The identifier of the repository.
  /// - Returns: The repository if found, nil otherwise.
  public func getRepository(identifier: String) async -> (any Repository)? {
    await logger.debug(
      "Getting repository",
      metadata: LogMetadata([
        "repository_id": identifier
      ])
    )
    return repositories[identifier]
  }

  /// Gets a repository at the specified URL.
  ///
  /// - Parameter url: The URL of the repository.
  /// - Returns: The repository if found, nil otherwise.
  public func getRepository(at url: URL) async -> (any Repository)? {
    let path=url.path
    await logger.debug(
      "Getting repository by URL",
      metadata: LogMetadata([
        "path": path
      ])
    )

    for (_, repository) in repositories {
      if await repository.location.path == path {
        return repository
      }
    }

    return nil
  }

  // MARK: - Internal Helpers

  /// Creates a new repository instance at the specified URL.
  ///
  /// - Parameter url: The URL where the repository should be created
  /// - Returns: A new repository instance
  /// - Throws: `UmbraErrors.Repository.Core` if creation fails
  func createRepository(at url: URL) async throws -> any Repository {
    let repository=FileSystemRepository(
      identifier: url.path,
      location: url,
      state: RepositoryState.uninitialized
    )
    try await repository.initialize()
    return repository
  }
}
