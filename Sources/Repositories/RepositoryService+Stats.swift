// Standard modules
import Foundation

// Internal modules
import RepositoriesTypes
import UmbraLogging

/// Extension for repository statistics functionality
extension RepositoryService {
  // MARK: - Repository Statistics

  /// Retrieves aggregated statistics for all repositories.
  ///
  /// - Returns: A dictionary mapping repository identifiers to their statistics.
  /// - Throws: `RepositoriesTypes.RepositoryError.operationFailed` if stats cannot be retrieved for
  /// any repository.
  public func getAllStats() async throws -> [String: RepositoryStats] {
    let metadata=LogMetadataBuilder.forRepository(
      count: repositories.count
    )
    await logger.info("Retrieving stats for all repositories", metadata: metadata)

    var stats: [String: RepositoryStats]=[:]
    var errors: [String: Error]=[:]

    for repository in repositories.values {
      let identifier=await repository.identifier
      let repoMetadata=LogMetadataBuilder.forRepository(
        identifier: identifier
      )

      do {
        stats[identifier]=try await repository.check(readData: false, checkUnused: false)
        await logger.debug("Retrieved stats successfully", metadata: repoMetadata)
      } catch {
        await logger.error(
          "Failed to get repository stats: \(error.localizedDescription)",
          metadata: repoMetadata
        )
        errors[identifier]=error
      }
    }

    if !errors.isEmpty {
      await logger.error(
        "Failed to get stats for some repositories",
        metadata: LogMetadataBuilder.forRepository(
          errorCount: errors.count,
          successCount: stats.count
        )
      )
      throw RepositoriesTypes.RepositoryError.operationFailed(
        reason: "Failed to get stats for some repositories: \(errors)"
      )
    }

    await logger.info(
      "Retrieved all repository stats successfully",
      metadata: LogMetadataBuilder.forRepository(
        count: stats.count
      )
    )

    return stats
  }

  /// Gets statistics for a specific repository.
  ///
  /// - Parameter identifier: The identifier of the repository.
  /// - Returns: Statistics for the specified repository.
  /// - Throws: `RepositoriesTypes.RepositoryError.repositoryNotFound` if no repository exists with
  /// the given
  /// identifier,
  ///           `RepositoriesTypes.RepositoryError.operationFailed` if stats cannot be retrieved.
  public func getStats(for identifier: String) async throws -> RepositoryStats {
    let metadata=LogMetadataBuilder.forRepository(
      identifier: identifier
    )
    await logger.info("Retrieving repository stats", metadata: metadata)

    guard let repository=repositories[identifier] else {
      await logger.error("Repository not found", metadata: metadata)
      throw RepositoriesTypes.RepositoryError.notFound(
        identifier: identifier
      )
    }

    do {
      let stats=try await repository.check(readData: false, checkUnused: false)
      await logger.debug("Retrieved stats successfully", metadata: metadata)
      return stats
    } catch {
      await logger.error(
        "Failed to get repository stats: \(error.localizedDescription)",
        metadata: metadata
      )
      throw RepositoriesTypes.RepositoryError.operationFailed(
        reason: "Failed to get stats: \(error.localizedDescription)"
      )
    }
  }
}
