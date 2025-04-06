import Foundation
import LoggingAdapters
import LoggingInterfaces
import LoggingTypes
import RepositoryInterfaces

/// A service that manages repository registration, locking, and statistics.
///
/// The `RepositoryServiceImpl` provides thread-safe access to repository operations through the
/// actor
/// model. It maintains a registry of repositories and provides operations for managing their
/// lifecycle.
///
/// Example:
/// ```swift
/// let service = RepositoryServiceFactory.createSharedInstance()
/// try await service.register(myRepository)
/// let stats = try await service.getStats(for: myRepository.identifier)
/// ```
public actor RepositoryServiceImpl: RepositoryServiceProtocol {
  /// Currently registered repositories
  var repositories: [String: any RepositoryProtocol]

  /// Logger instance - internal access allows extensions to use it
  let logger: LoggingProtocol

  /// Initialises a new repository service instance.
  ///
  /// - Parameter logger: The logging service to use for operation tracking. Defaults to the shared
  /// logger.
  public init(logger: LoggingProtocol=UmbraLoggingAdapters.createLogger()) {
    repositories=[:]
    self.logger=logger
    Task {
      let context = RepositoryLogContext(
        operation: "initialisation"
      )
      await self.logger.info("Repository service initialised", context: context)
    }
  }

  // MARK: - Repository Management

  /// Registers a repository with the service.
  ///
  /// - Parameter repository: The repository to register. Must conform to the `RepositoryProtocol`.
  /// - Throws: `RepositoryError.permissionDenied` if the repository cannot be accessed,
  ///           `RepositoryError.duplicateIdentifier` if a repository with the same identifier
  /// exists.
  public func register(_ repository: some RepositoryProtocol) async throws {
    let identifier=await repository.identifier
    let location=await repository.location
    let state=await repository.state

    // Create repository log context
    let context = RepositoryLogContext(
      repositoryID: identifier,
      locationPath: location.path,
      state: "\(state)",
      operation: "register"
    )

    await logger.info("Registering repository", context: context)

    // Ensure repository is accessible
    guard await repository.isAccessible() else {
      await logger.error("Repository not accessible", context: context)
      throw RepositoryError.permissionDenied
    }

    // Check for duplicate
    guard repositories[identifier] == nil else {
      await logger.error("Duplicate repository identifier", context: context)
      throw RepositoryError.duplicateIdentifier
    }

    // Initialise repository if needed
    if case RepositoryState.uninitialized=state {
      await logger.info("Initialising uninitialised repository", context: context)
      try await repository.initialise()
    }

    // Validate repository
    do {
      guard try await repository.validate() else {
        await logger.error("Repository validation failed", context: context)
        throw RepositoryError.invalidRepository
      }
    } catch {
      await logger.error("Repository validation error: \(error.localizedDescription)", context: context)
      throw RepositoryError.internalError
    }

    // Add to registry
    repositories[identifier]=repository
    await logger.info("Repository registered successfully", context: context)
  }

  /// Unregisters a repository from the service.
  ///
  /// - Parameter identifier: The identifier of the repository to unregister.
  /// - Throws: `RepositoryError.notFound` if the repository doesn't exist.
  public func unregister(identifier: String) async throws {
    // Create repository log context
    let context = RepositoryLogContext(
      repositoryID: identifier,
      operation: "unregister"
    )

    await logger.info("Unregistering repository", context: context)

    guard repositories[identifier] != nil else {
      await logger.error("Repository not found", context: context)
      throw RepositoryError.notFound
    }

    repositories.removeValue(forKey: identifier)
    await logger.info("Repository unregistered successfully", context: context)
  }

  /// Gets a registered repository by its identifier.
  ///
  /// - Parameter identifier: The repository identifier.
  /// - Returns: The repository if found.
  /// - Throws: `RepositoryError.notFound` if the repository is not found.
  public func getRepository(identifier: String) async throws -> any RepositoryProtocol {
    // Create repository log context
    let context = RepositoryLogContext(
      repositoryID: identifier,
      operation: "getRepository"
    )

    await logger.debug("Getting repository", context: context)

    guard let repository=repositories[identifier] else {
      await logger.error("Repository not found", context: context)
      throw RepositoryError.notFound
    }

    return repository
  }

  /// Gets all registered repositories.
  ///
  /// - Returns: Dictionary of repositories keyed by their identifiers.
  public func getAllRepositories() async -> [String: any RepositoryProtocol] {
    let context = RepositoryLogContext(
      operation: "getAllRepositories"
    )
    
    await logger.debug("Listing all repositories", context: context)

    return repositories
  }

  /// Checks if a repository with the given identifier is registered.
  ///
  /// - Parameter identifier: The repository identifier to check.
  /// - Returns: `true` if the repository is registered, `false` otherwise.
  public func isRegistered(identifier: String) async -> Bool {
    // Create repository log context
    let context = RepositoryLogContext(
      repositoryID: identifier,
      operation: "isRegistered"
    )

    await logger.debug("Checking repository registration", context: context)

    return repositories[identifier] != nil
  }

  /// Creates a new repository at the specified location.
  ///
  /// - Parameter url: The URL where the repository should be created.
  /// - Returns: The newly created repository.
  /// - Throws: Repository-specific errors if creation fails.
  public func createRepository(at _: URL) async throws -> any RepositoryProtocol {
    // This is a placeholder implementation. The actual implementation would depend
    // on the specific repository type being created.
    throw RepositoryError.internalError
  }
}
