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
        let metadata = LogMetadata(["repository_id": identifier])
        
        await logger.info("Getting stats for repository", metadata: metadata)
        
        guard let repository = repositories[identifier] else {
            await logger.error("Repository not found", metadata: metadata)
            throw RepositoryError.notFound
        }
        
        do {
            let stats = try await repository.getStats()
            await logger.info("Retrieved repository stats", metadata: metadata)
            return stats
        } catch {
            await logger.error(
                "Failed to get repository stats: \(error.localizedDescription)",
                metadata: metadata
            )
            throw RepositoryError.internalError
        }
    }
}
