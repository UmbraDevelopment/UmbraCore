// Standard modules
import Foundation

// Internal modules
import ErrorHandlingDomains
import RepositoriesTypes
import UmbraLogging

/// Extension for repository locking functionality
extension RepositoryService {
  // MARK: - Locking Operations

  /// Unlocks a repository.
  ///
  /// - Parameters:
  ///   - identifier: The identifier of the repository to unlock
  ///   - force: Whether to continue on errors (default: false)
  /// - Throws: `UmbraErrors.Repository.Core.internalError` if the unlock operation fails and force
  /// is false
  public func unlockRepository(
    _ identifier: String,
    force: Bool=false
  ) async throws {
    let metadata=LogMetadata([
      "repository_id": identifier,
      "force": String(force)
    ])

    await logger.info("Unlocking repository", metadata: metadata)

    guard let repository=repositories[identifier] else {
      await logger.error("Repository not found", metadata: metadata)
      throw UmbraErrors.Repository.Core.repositoryNotFound(resource: identifier)
    }

    do {
      try await repository.unlock()
      await logger.info("Repository unlocked successfully", metadata: metadata)
    } catch {
      await logger.error(
        "Failed to unlock repository: \(error.localizedDescription)",
        metadata: metadata
      )

      if !force {
        throw UmbraErrors.Repository.Core.internalError(
          reason: "Failed to unlock repository \(identifier): \(error.localizedDescription)"
        )
      }
    }
  }

  /// Unlocks all registered repositories.
  ///
  /// - Parameter force: Whether to continue on errors (default: false)
  /// - Throws: `UmbraErrors.Repository.Core.internalError` if any unlock operation fails and force
  /// is false
  public func unlockAllRepositories(force: Bool=false) async throws {
    let metadata=LogMetadata([
      "force": String(force)
    ])

    await logger.info("Unlocking all repositories", metadata: metadata)

    var failedRepositories: [String]=[]

    for (identifier, repository) in repositories {
      let repositoryMetadata=LogMetadata([
        "repository_id": identifier,
        "force": String(force)
      ])

      do {
        try await repository.unlock()
        await logger.info("Repository unlocked successfully", metadata: repositoryMetadata)
      } catch {
        await logger.error(
          "Failed to unlock repository: \(error.localizedDescription)",
          metadata: repositoryMetadata
        )

        if !force {
          throw UmbraErrors.Repository.Core.internalError(
            reason: "Failed to unlock repository \(identifier): \(error.localizedDescription)"
          )
        }

        failedRepositories.append(identifier)
      }
    }

    if !failedRepositories.isEmpty {
      let failedList=failedRepositories.joined(separator: ", ")
      await logger.warning("Failed to unlock repositories: \(failedList)", metadata: metadata)
    }
  }
}
