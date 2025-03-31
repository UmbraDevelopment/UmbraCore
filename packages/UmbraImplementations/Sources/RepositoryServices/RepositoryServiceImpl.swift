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
      await self.logger.info(
        "Repository service initialised",
        metadata: nil,
        source: "RepositoryService"
      )
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

    // Create privacy-aware metadata
    var metadata=PrivacyMetadata()
    metadata["repository_id"]=PrivacyMetadataValue(value: identifier, privacy: .public)
    metadata["location"]=PrivacyMetadataValue(value: location.path, privacy: .public)
    metadata["state"]=PrivacyMetadataValue(value: "\(state)", privacy: .public)

    await logger.info("Registering repository", metadata: metadata, source: "RepositoryService")

    // Ensure repository is accessible
    guard await repository.isAccessible() else {
      await logger.error(
        "Repository not accessible",
        metadata: metadata,
        source: "RepositoryService"
      )
      throw RepositoryError.permissionDenied
    }

    // Check for duplicate
    guard repositories[identifier] == nil else {
      await logger.error(
        "Duplicate repository identifier",
        metadata: metadata,
        source: "RepositoryService"
      )
      throw RepositoryError.duplicateIdentifier
    }

    // Initialise repository if needed
    if case RepositoryState.uninitialized=state {
      await logger.info(
        "Initialising uninitialised repository",
        metadata: metadata,
        source: "RepositoryService"
      )
      try await repository.initialise()
    }

    // Validate repository
    do {
      guard try await repository.validate() else {
        await logger.error(
          "Repository validation failed",
          metadata: metadata,
          source: "RepositoryService"
        )
        throw RepositoryError.invalidRepository
      }
    } catch {
      await logger.error(
        "Repository validation error: \(error.localizedDescription)",
        metadata: metadata,
        source: "RepositoryService"
      )
      throw RepositoryError.internalError
    }

    // Add to registry
    repositories[identifier]=repository
    await logger.info(
      "Repository registered successfully",
      metadata: metadata,
      source: "RepositoryService"
    )
  }

  /// Unregisters a repository from the service.
  ///
  /// - Parameter identifier: The identifier of the repository to unregister.
  /// - Throws: `RepositoryError.notFound` if the repository doesn't exist.
  public func unregister(identifier: String) async throws {
    // Create privacy-aware metadata
    var metadata=PrivacyMetadata()
    metadata["repository_id"]=PrivacyMetadataValue(value: identifier, privacy: .public)

    await logger.info("Unregistering repository", metadata: metadata, source: "RepositoryService")

    guard repositories[identifier] != nil else {
      await logger.error("Repository not found", metadata: metadata, source: "RepositoryService")
      throw RepositoryError.notFound
    }

    repositories.removeValue(forKey: identifier)
    await logger.info(
      "Repository unregistered successfully",
      metadata: metadata,
      source: "RepositoryService"
    )
  }

  /// Gets a registered repository by its identifier.
  ///
  /// - Parameter identifier: The repository identifier.
  /// - Returns: The repository if found.
  /// - Throws: `RepositoryError.notFound` if the repository is not found.
  public func getRepository(identifier: String) async throws -> any RepositoryProtocol {
    // Create privacy-aware metadata
    var metadata=PrivacyMetadata()
    metadata["repository_id"]=PrivacyMetadataValue(value: identifier, privacy: .public)

    await logger.debug("Getting repository", metadata: metadata, source: "RepositoryService")

    guard let repository=repositories[identifier] else {
      await logger.error("Repository not found", metadata: metadata, source: "RepositoryService")
      throw RepositoryError.notFound
    }

    return repository
  }

  /// Gets all registered repositories.
  ///
  /// - Returns: Dictionary of repositories keyed by their identifiers.
  public func getAllRepositories() async -> [String: any RepositoryProtocol] {
    await logger.debug(
      "Listing all repositories",
      metadata: nil,
      source: "RepositoryService"
    )

    return repositories
  }

  /// Checks if a repository with the given identifier is registered.
  ///
  /// - Parameter identifier: The repository identifier to check.
  /// - Returns: `true` if the repository is registered, `false` otherwise.
  public func isRegistered(identifier: String) async -> Bool {
    // Create privacy-aware metadata
    var metadata=PrivacyMetadata()
    metadata["repository_id"]=PrivacyMetadataValue(value: identifier, privacy: .public)

    await logger.debug(
      "Checking repository registration",
      metadata: metadata,
      source: "RepositoryService"
    )

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
