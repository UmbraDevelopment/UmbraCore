import Foundation
import LoggingInterfaces
import LoggingTypes
import RepositoryInterfaces

/// Extension for RepositoryServiceImpl that adds statistics functionality
extension RepositoryServiceImpl {
  /// Gets statistics for a repository.
  ///
  /// - Parameter identifier: The repository identifier.
  /// - Returns: Repository statistics.
  /// - Throws: `RepositoryError.notFound` if the repository is not found,
  ///           or other repository errors if stats collection fails.
  public func getStats(for identifier: String) async throws -> RepositoryStatistics {
    // Create repository log context
    let context = RepositoryLogContext(
      repositoryID: identifier,
      operation: "getStats"
    )

    await logger.info("Getting stats for repository", context: context)

    guard let repository=repositories[identifier] else {
      await logger.error("Repository not found", context: context)
      throw RepositoryError.notFound
    }

    // Get statistics
    do {
      let stats=try await repository.getStats()
      await logger.info("Retrieved repository stats", context: context)
      return stats
    } catch {
      await logger.error("Failed to get repository stats: \(error.localizedDescription)", context: context)
      throw RepositoryError.internalError
    }
  }
}
