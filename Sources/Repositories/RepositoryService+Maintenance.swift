// Standard modules
import Foundation

// Internal modules
import ErrorHandlingDomains
import RepositoriesTypes
import UmbraLogging

/// Extension for repository maintenance functionality
extension RepositoryService {
  // MARK: - Maintenance Operations

  /// Performs maintenance on a repository.
  ///
  /// - Parameters:
  ///   - identifier: The identifier of the repository to maintain
  ///   - rebuildIndex: Whether to rebuild the repository index
  /// - Throws: `UmbraErrors.Repository.Core.repositoryNotFound` if the repository is not
  /// found,
  ///           `UmbraErrors.Repository.Core.internalError` if the operation fails
  public func maintain(
    _ identifier: String,
    rebuildIndex: Bool=false
  ) async throws {
    let metadata=LogMetadata([
      "repository_id": identifier,
      "rebuild_index": String(rebuildIndex)
    ])

    await logger.info("Starting repository maintenance", metadata: metadata)

    guard let repository=repositories[identifier] else {
      await logger.error("Repository not found", metadata: metadata)
      throw UmbraErrors.Repository.Core.repositoryNotFound(resource: identifier)
    }

    do {
      // Prune unused data
      try await repository.prune()

      if rebuildIndex {
        try await repository.rebuildIndex()
      }

      await logger.info(
        "Repository maintenance completed successfully",
        metadata: metadata
      )
    } catch {
      await logger.error(
        "Repository maintenance failed: \(error.localizedDescription)",
        metadata: metadata
      )
      throw UmbraErrors.Repository.Core.internalError(
        reason: "Maintenance operation failed: \(error.localizedDescription)"
      )
    }
  }

  /// Compacts a repository to reduce its size.
  ///
  /// - Parameter identifier: The repository identifier
  /// - Throws: `UmbraErrors.Repository.Core.repositoryNotFound` if the repository does not exist,
  ///           `UmbraErrors.Repository.Core.internalError` if the compact operation fails
  public func compactRepository(_ identifier: String) async throws {
    let metadata=LogMetadata([
      "repository_id": identifier
    ])

    await logger.info("Compacting repository", metadata: metadata)

    guard let repository=repositories[identifier] else {
      await logger.error("Repository not found", metadata: metadata)
      throw UmbraErrors.Repository.Core.repositoryNotFound(resource: identifier)
    }

    do {
      // Call maintenance instead of compact which doesn't exist on Repository
      try await repository.prune()
      await logger.info("Repository compacted successfully", metadata: metadata)
    } catch {
      await logger.error(
        "Repository compact operation failed: \(error.localizedDescription)",
        metadata: metadata
      )
      throw UmbraErrors.Repository.Core.internalError(
        reason: "Compact operation failed: \(error.localizedDescription)"
      )
    }
  }

  /// Repairs a repository if it's in an inconsistent state.
  ///
  /// - Parameter identifier: The repository identifier
  /// - Throws: `UmbraErrors.Repository.Core.repositoryNotFound` if the repository does not exist,
  ///           `UmbraErrors.Repository.Core.internalError` if the repair operation fails
  public func repairRepository(_ identifier: String) async throws {
    let metadata=LogMetadata([
      "repository_id": identifier
    ])

    await logger.info("Repairing repository", metadata: metadata)

    guard let repository=repositories[identifier] else {
      await logger.error("Repository not found", metadata: metadata)
      throw UmbraErrors.Repository.Core.repositoryNotFound(resource: identifier)
    }

    do {
      // Store the result to avoid the warning
      let repairResult=try await repository.repair()
      await logger.info("Repository repaired successfully: \(repairResult)", metadata: metadata)
    } catch {
      await logger.error(
        "Repository repair operation failed: \(error.localizedDescription)",
        metadata: metadata
      )
      throw UmbraErrors.Repository.Core.internalError(
        reason: "Repair operation failed: \(error.localizedDescription)"
      )
    }
  }

  /// Optimizes a repository for better performance.
  ///
  /// - Parameter identifier: The repository identifier
  /// - Throws: `UmbraErrors.Repository.Core.repositoryNotFound` if the repository does not exist,
  ///           `UmbraErrors.Repository.Core.internalError` if the optimize operation fails
  public func optimizeRepository(_ identifier: String) async throws {
    let metadata=LogMetadata([
      "repository_id": identifier
    ])

    await logger.info("Optimizing repository", metadata: metadata)

    guard let repository=repositories[identifier] else {
      await logger.error("Repository not found", metadata: metadata)
      throw UmbraErrors.Repository.Core.repositoryNotFound(resource: identifier)
    }

    do {
      // Call maintenance instead of optimize which doesn't exist on Repository
      try await repository.rebuildIndex()
      await logger.info("Repository optimized successfully", metadata: metadata)
    } catch {
      await logger.error(
        "Repository optimization failed: \(error.localizedDescription)",
        metadata: metadata
      )
      throw UmbraErrors.Repository.Core.internalError(
        reason: "Optimization failed: \(error.localizedDescription)"
      )
    }
  }

  /// Performs full maintenance on all repositories.
  ///
  /// - Parameter force: Whether to continue after failures (default: false)
  /// - Throws: `UmbraErrors.Repository.Core.internalError` if any maintain operation fails and
  /// force is false
  public func maintainAllRepositories(force: Bool=false) async throws {
    let metadata=LogMetadata([
      "force": String(force),
      "repository_count": String(repositories.count)
    ])

    await logger.info("Maintaining all repositories", metadata: metadata)

    var failedRepositories: [String]=[]

    for (identifier, repository) in repositories {
      let repoMetadata=LogMetadata([
        "repository_id": identifier
      ])

      do {
        try await repository.prune()
        try await repository.rebuildIndex()
        await logger.info("Repository maintained successfully", metadata: repoMetadata)
      } catch {
        await logger.error(
          "Repository maintenance failed: \(error.localizedDescription)",
          metadata: repoMetadata
        )

        if !force {
          throw UmbraErrors.Repository.Core.internalError(
            reason: "Maintenance failed for repository '\(identifier)': \(error.localizedDescription)"
          )
        }

        failedRepositories.append(identifier)
      }
    }

    if !failedRepositories.isEmpty {
      let failedList=failedRepositories.joined(separator: ", ")
      await logger.warning("Failed to maintain repositories: \(failedList)", metadata: metadata)
    }
  }

  /// Compacts all repositories to reduce their size.
  ///
  /// - Parameter force: Whether to continue after failures (default: false)
  /// - Throws: `UmbraErrors.Repository.Core.internalError` if any compact operation fails and force
  /// is false
  public func compactAllRepositories(force: Bool=false) async throws {
    let metadata=LogMetadata([
      "force": String(force),
      "repository_count": String(repositories.count)
    ])

    await logger.info("Compacting all repositories", metadata: metadata)

    var failedRepositories: [String]=[]

    for (identifier, repository) in repositories {
      let repoMetadata=LogMetadata([
        "repository_id": identifier
      ])

      do {
        // Call maintenance instead of compact which doesn't exist on Repository
        try await repository.prune()
        await logger.info("Repository compacted successfully", metadata: repoMetadata)
      } catch {
        await logger.error(
          "Repository compact operation failed: \(error.localizedDescription)",
          metadata: repoMetadata
        )

        if !force {
          throw UmbraErrors.Repository.Core.internalError(
            reason: "Compact operation failed for repository '\(identifier)': \(error.localizedDescription)"
          )
        }

        failedRepositories.append(identifier)
      }
    }

    if !failedRepositories.isEmpty {
      let failedList=failedRepositories.joined(separator: ", ")
      await logger.warning("Failed to compact repositories: \(failedList)", metadata: metadata)
    }
  }

  /// Optimizes all repositories for better performance.
  ///
  /// - Parameter force: Whether to continue after failures (default: false)
  /// - Throws: `UmbraErrors.Repository.Core.internalError` if any optimize operation fails and
  /// force is false
  public func optimizeAllRepositories(force: Bool=false) async throws {
    let metadata=LogMetadata([
      "force": String(force),
      "repository_count": String(repositories.count)
    ])

    await logger.info("Optimizing all repositories", metadata: metadata)

    var failedRepositories: [String]=[]

    for (identifier, repository) in repositories {
      let repoMetadata=LogMetadata([
        "repository_id": identifier
      ])

      do {
        // Call maintenance instead of optimize which doesn't exist on Repository
        try await repository.rebuildIndex()
        await logger.info("Repository optimized successfully", metadata: repoMetadata)
      } catch {
        await logger.error(
          "Repository optimization failed: \(error.localizedDescription)",
          metadata: repoMetadata
        )

        if !force {
          throw UmbraErrors.Repository.Core.internalError(
            reason: "Optimization failed for repository '\(identifier)': \(error.localizedDescription)"
          )
        }

        failedRepositories.append(identifier)
      }
    }

    if !failedRepositories.isEmpty {
      let failedList=failedRepositories.joined(separator: ", ")
      await logger.warning("Failed to optimize repositories: \(failedList)", metadata: metadata)
    }
  }

  /// Repairs a repository at a given URL.
  ///
  /// - Parameter url: The URL of the repository to repair
  /// - Returns: Whether the repository was successfully repaired
  /// - Throws: `UmbraErrors.Repository.Core.repositoryNotFound` if the repository is not found
  public func repairRepository(at url: URL) async throws -> Bool {
    let metadata=LogMetadataBuilder.forRepository(
      path: url.path
    )
    await logger.info("Starting repository repair", metadata: metadata)

    guard let repository=await getRepository(at: url) else {
      await logger.error("Repository not found", metadata: metadata)
      throw UmbraErrors.Repository.Core.repositoryNotFound(resource: url.path)
    }

    do {
      let result=try await repository.repair()
      if result {
        await logger.info(
          "Repository repair completed successfully",
          metadata: metadata
        )
      } else {
        await logger.warning(
          "Repository repair completed but no issues were fixed",
          metadata: metadata
        )
      }
      return result
    } catch {
      await logger.error(
        "Repository repair failed: \(error.localizedDescription)",
        metadata: metadata
      )
      throw UmbraErrors.Repository.Core.internalError(
        reason: "Repair operation failed: \(error.localizedDescription)"
      )
    }
  }

  /// Compacts a repository at a given URL.
  ///
  /// - Parameter url: The URL of the repository to compact
  /// - Throws: `UmbraErrors.Repository.Core.repositoryNotFound` if the repository does not exist,
  ///           `UmbraErrors.Repository.Core.internalError` if compaction fails
  public func compactRepository(at url: URL) async throws {
    let metadata=LogMetadata([
      "path": url.path
    ])

    await logger.info("Compacting repository", metadata: metadata)

    guard let repository=await getRepository(at: url) else {
      await logger.error("Repository not found", metadata: metadata)
      throw UmbraErrors.Repository.Core.repositoryNotFound(resource: url.path)
    }

    do {
      // Repository doesn't have compact method, use prune instead
      try await repository.prune()
      await logger.info("Repository compacted successfully", metadata: metadata)
    } catch {
      await logger.error(
        "Repository compaction failed: \(error.localizedDescription)",
        metadata: metadata
      )
      throw UmbraErrors.Repository.Core.internalError(
        reason: "Compact operation failed: \(error.localizedDescription)"
      )
    }
  }

  /// Optimizes a repository at a given URL.
  ///
  /// - Parameter url: The URL of the repository to optimize
  /// - Throws: `UmbraErrors.Repository.Core.repositoryNotFound` if the repository does not exist,
  ///           `UmbraErrors.Repository.Core.internalError` if optimization fails
  public func optimizeRepository(at url: URL) async throws {
    let metadata=LogMetadata([
      "path": url.path
    ])

    await logger.info("Optimizing repository", metadata: metadata)

    guard let repository=await getRepository(at: url) else {
      await logger.error("Repository not found", metadata: metadata)
      throw UmbraErrors.Repository.Core.repositoryNotFound(resource: url.path)
    }

    do {
      // Repository doesn't have optimize method, use rebuildIndex instead
      try await repository.rebuildIndex()
      await logger.info("Repository optimized successfully", metadata: metadata)
    } catch {
      await logger.error(
        "Repository optimization failed: \(error.localizedDescription)",
        metadata: metadata
      )
      throw UmbraErrors.Repository.Core.internalError(
        reason: "Optimization operation failed: \(error.localizedDescription)"
      )
    }
  }
}
