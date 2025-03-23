// Standard modules
import Foundation

// Internal modules
import ErrorHandlingDomains
import RepositoriesTypes
import UmbraLogging

/// Extension for repository validation functionality
extension RepositoryService {
  // MARK: - Validation Operations

  /// Validates a repository at a given URL.
  ///
  /// - Parameter url: The URL of the repository to validate
  /// - Returns: Whether the repository is valid
  /// - Throws: `UmbraErrors.Repository.Core.repositoryNotFound` if repository does not exist
  public func validateRepository(at url: URL) async throws -> Bool {
    let metadata=LogMetadata([
      "path": url.path
    ])

    await logger.info("Validating repository", metadata: metadata)

    guard let repository=await getRepository(at: url) else {
      await logger.error("Repository not found", metadata: metadata)
      throw UmbraErrors.Repository.Core.repositoryNotFound(resource: url.path)
    }

    do {
      let result=try await repository.validate()
      if result {
        await logger.info("Repository validated successfully", metadata: metadata)
      } else {
        await logger.warning("Repository validation failed", metadata: metadata)
      }
      return result
    } catch {
      await logger.error(
        "Repository validation error: \(error.localizedDescription)",
        metadata: metadata
      )
      throw UmbraErrors.Repository.Core.internalError(
        reason: error.localizedDescription
      )
    }
  }

  /// Checks if a repository exists at the specified location.
  ///
  /// - Parameter url: URL to check
  /// - Returns: Whether a repository exists at the URL
  public func repositoryExists(at url: URL) async -> Bool {
    await getRepository(at: url) != nil
  }

  /// Creates a new repository at the specified URL.
  ///
  /// - Parameters:
  ///   - url: URL where the repository should be created
  /// - Returns: The created repository
  /// - Throws: `UmbraErrors.Repository.Core.internalError` if repository already exists
  public func createNewRepository(
    at url: URL
  ) async throws -> any Repository {
    let metadata=LogMetadata([
      "path": url.path
    ])

    await logger.info("Creating repository", metadata: metadata)

    if await repositoryExists(at: url) {
      await logger.error(
        "Repository already exists at location",
        metadata: metadata
      )
      throw UmbraErrors.Repository.Core.internalError(
        reason: "Repository already exists at \(url.path)"
      )
    }

    await logger.info("Creating directory at \(url.path)", metadata: metadata)

    do {
      try FileManager.default.createDirectory(
        at: url,
        withIntermediateDirectories: true,
        attributes: nil
      )
    } catch {
      await logger.error(
        "Failed to create directory: \(error.localizedDescription)",
        metadata: metadata
      )
      throw UmbraErrors.Repository.Core.internalError(
        reason: "Failed to create directory: \(error.localizedDescription)"
      )
    }

    // Create repository
    let repository: any Repository
    do {
      repository=try await createRepository(at: url)
    } catch {
      await logger.error(
        "Failed to create repository: \(error.localizedDescription)",
        metadata: metadata
      )
      throw UmbraErrors.Repository.Core.internalError(
        reason: "Failed to create repository: \(error.localizedDescription)"
      )
    }

    await logger.info("Repository created successfully", metadata: metadata)

    return repository
  }

  /// Removes a repository at the specified URL.
  ///
  /// - Parameter url: URL of the repository to remove
  /// - Throws: `UmbraErrors.Repository.Core.repositoryNotFound` if repository does not exist
  public func removeRepository(at url: URL) async throws {
    let metadata=LogMetadata([
      "path": url.path
    ])

    await logger.info("Removing repository", metadata: metadata)

    guard let repository=await getRepository(at: url) else {
      await logger.error("Repository not found", metadata: metadata)
      throw UmbraErrors.Repository.Core.repositoryNotFound(resource: url.path)
    }

    // Unregister from the service
    try await deregister(identifier: repository.identifier)

    // Remove the repository files
    let fileManager=FileManager.default
    try fileManager.removeItem(at: url)

    await logger.info("Repository removed successfully", metadata: metadata)
  }

  /// Initialises a new repository at the specified URL.
  ///
  /// - Parameter url: Repository URL
  /// - Returns: Repository instance
  /// - Throws: `UmbraErrors.Repository.Core.internalError` if a repository already
  /// exists at the URL
  public func initialiseRepository(at url: URL) async throws -> any Repository {
    let metadata=LogMetadata([
      "path": url.path
    ])
    await logger.info("Initialising new repository", metadata: metadata)

    guard !repositories.contains(where: { $0.key == url.path }) else {
      await logger.error(
        "Repository already exists at location",
        metadata: metadata
      )
      throw UmbraErrors.Repository.Core.internalError(
        reason: "Repository already exists at \(url.path)"
      )
    }

    do {
      // Create a concrete repository instance based on the URL
      let repository: any Repository
      do {
        repository=try await createRepository(at: url)
      } catch {
        await logger.error(
          "Failed to create repository: \(error.localizedDescription)",
          metadata: metadata
        )
        throw UmbraErrors.Repository.Core.internalError(
          reason: "Failed to create repository: \(error.localizedDescription)"
        )
      }

      repositories[url.path]=repository
      await logger.info(
        "Repository initialised successfully",
        metadata: metadata
      )
      return repository
    } catch {
      await logger.error(
        "Repository initialisation failed: \(error.localizedDescription)",
        metadata: metadata
      )
      throw UmbraErrors.Repository.Core.internalError(
        reason: "Repository initialisation failed: \(error.localizedDescription)"
      )
    }
  }

  /// Checks a repository at a given URL.
  ///
  /// - Parameter url: The URL of the repository to check
  /// - Returns: The repository statistics
  /// - Throws: `UmbraErrors.Repository.Core.repositoryNotFound` if the repository is not found
  public func checkRepository(at url: URL) async throws -> RepositoryStats {
    let metadata=LogMetadata([
      "path": url.path
    ])
    await logger.info("Starting repository check", metadata: metadata)

    guard let repository=await getRepository(at: url) else {
      await logger.error("Repository not found", metadata: metadata)
      throw UmbraErrors.Repository.Core.repositoryNotFound(resource: url.path)
    }

    do {
      let stats=try await repository.check(
        readData: true,
        checkUnused: true
      )
      await logger.info(
        "Repository check completed successfully",
        metadata: metadata
      )
      return stats
    } catch {
      await logger.error(
        "Repository check failed: \(error.localizedDescription)",
        metadata: metadata
      )
      throw UmbraErrors.Repository.Core.internalError(
        reason: error.localizedDescription
      )
    }
  }
}
