import Foundation
import LoggingInterfaces
import LoggingTypes
import RepositoryInterfaces

/// Extension for RepositoryServiceImpl that adds maintenance functionality
extension RepositoryServiceImpl {
    /// Performs maintenance on a repository.
    ///
    /// - Parameters:
    ///   - identifier: The repository identifier.
    ///   - readData: Whether to read all data during maintenance.
    ///   - checkUnused: Whether to check for unused data.
    /// - Returns: Repository statistics after maintenance.
    /// - Throws: `RepositoryError.notFound` if the repository is not found,
    ///           or other repository errors if maintenance fails.
    public func performMaintenance(
        on identifier: String, 
        readData: Bool, 
        checkUnused: Bool
    ) async throws -> RepositoryStatistics {
        let metadata = LogMetadata([
            "repository_id": identifier,
            "read_data": String(describing: readData),
            "check_unused": String(describing: checkUnused)
        ])
        
        await logger.info("Performing maintenance on repository", metadata: metadata)
        
        guard let repository = repositories[identifier] as? RepositoryMaintenanceProtocol else {
            await logger.error("Repository not found or does not support maintenance", metadata: metadata)
            throw RepositoryError.notFound
        }
        
        do {
            let stats = try await repository.check(readData: readData, checkUnused: checkUnused)
            await logger.info("Repository maintenance completed successfully", metadata: metadata)
            return stats
        } catch {
            await logger.error(
                "Repository maintenance failed: \(error.localizedDescription)",
                metadata: metadata
            )
            throw RepositoryError.maintenanceFailed
        }
    }
    
    /// Repairs a repository.
    ///
    /// - Parameter identifier: The repository identifier.
    /// - Returns: `true` if repairs were made, `false` if no repairs were needed.
    /// - Throws: `RepositoryError.notFound` if the repository is not found,
    ///           or other repository errors if repair fails.
    public func repairRepository(identifier: String) async throws -> Bool {
        let metadata = LogMetadata(["repository_id": identifier])
        
        await logger.info("Repairing repository", metadata: metadata)
        
        guard let repository = repositories[identifier] as? RepositoryMaintenanceProtocol else {
            await logger.error("Repository not found or does not support maintenance", metadata: metadata)
            throw RepositoryError.notFound
        }
        
        do {
            let repaired = try await repository.repair()
            await logger.info("Repository repair result: \(repaired)", metadata: metadata)
            return repaired
        } catch {
            await logger.error(
                "Repository repair failed: \(error.localizedDescription)",
                metadata: metadata
            )
            throw RepositoryError.maintenanceFailed
        }
    }
    
    /// Prunes unused data from a repository.
    ///
    /// - Parameter identifier: The repository identifier.
    /// - Throws: `RepositoryError.notFound` if the repository is not found,
    ///           or other repository errors if pruning fails.
    public func pruneRepository(identifier: String) async throws {
        let metadata = LogMetadata(["repository_id": identifier])
        
        await logger.info("Pruning repository", metadata: metadata)
        
        guard let repository = repositories[identifier] as? RepositoryMaintenanceProtocol else {
            await logger.error("Repository not found or does not support maintenance", metadata: metadata)
            throw RepositoryError.notFound
        }
        
        do {
            try await repository.prune()
            await logger.info("Repository pruned successfully", metadata: metadata)
        } catch {
            await logger.error(
                "Repository pruning failed: \(error.localizedDescription)",
                metadata: metadata
            )
            throw RepositoryError.maintenanceFailed
        }
    }
    
    /// Rebuilds the index for a repository.
    ///
    /// - Parameter identifier: The repository identifier.
    /// - Throws: `RepositoryError.notFound` if the repository is not found,
    ///           or other repository errors if index rebuilding fails.
    public func rebuildRepositoryIndex(identifier: String) async throws {
        let metadata = LogMetadata(["repository_id": identifier])
        
        await logger.info("Rebuilding repository index", metadata: metadata)
        
        guard let repository = repositories[identifier] as? RepositoryMaintenanceProtocol else {
            await logger.error("Repository not found or does not support maintenance", metadata: metadata)
            throw RepositoryError.notFound
        }
        
        do {
            try await repository.rebuildIndex()
            await logger.info("Repository index rebuilt successfully", metadata: metadata)
        } catch {
            await logger.error(
                "Repository index rebuild failed: \(error.localizedDescription)",
                metadata: metadata
            )
            throw RepositoryError.maintenanceFailed
        }
    }
}
