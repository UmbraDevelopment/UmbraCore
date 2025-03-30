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
  ///           or other repository errors if statistics cannot be retrieved.
  public func getStats(for identifier: String) async throws -> RepositoryStatistics {
    // Create privacy-aware metadata
    var metadata = PrivacyMetadata()
    metadata["repository_id"] = PrivacyMetadataValue(value: identifier, privacy: .public)

    await logger.info("Getting stats for repository", metadata: metadata, source: "RepositoryService")

    guard let repository=repositories[identifier] else {
      await logger.error("Repository not found", metadata: metadata, source: "RepositoryService")
      throw RepositoryError.notFound
    }

    do {
      let stats=try await repository.getStats()
      await logger.info("Retrieved repository stats", metadata: metadata, source: "RepositoryService")
      return stats
    } catch {
      await logger.error(
        "Failed to get repository stats: \(error.localizedDescription)",
        metadata: metadata,
        source: "RepositoryService"
      )
      throw RepositoryError.internalError
    }
  }
}
