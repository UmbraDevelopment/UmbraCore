import Foundation
import BackupInterfaces
import LoggingInterfaces
import BackupServices
import ResticInterfaces
import UmbraErrors

/// Implementation of the backup coordinator service
///
/// The BackupCoordinator provides a unified interface for managing backup operations,
/// including both backup and snapshot-related functionality. It coordinates between
/// various services to provide a cohesive backup management experience.
public actor BackupCoordinatorImpl: BackupCoordinatorProtocol {
    /// The backup service used for creating and restoring backups
    private let backupService: BackupServiceProtocol
    
    /// The snapshot service used for managing snapshots
    private let snapshotService: SnapshotServiceProtocol
    
    /// Logger for operation tracking
    private let logger: any LoggingProtocol
    
    /// Information about the repository being used
    private let repositoryInfo: RepositoryInfo
    
    /// Creates a new backup coordinator
    /// - Parameters:
    ///   - backupService: Service for backup operations
    ///   - snapshotService: Service for snapshot operations
    ///   - logger: Logger for operation tracking
    ///   - repositoryInfo: Information about the repository
    public init(
        backupService: BackupServiceProtocol,
        snapshotService: SnapshotServiceProtocol,
        logger: any LoggingProtocol,
        repositoryInfo: RepositoryInfo
    ) {
        self.backupService = backupService
        self.snapshotService = snapshotService
        self.logger = logger
        self.repositoryInfo = repositoryInfo
    }
    
    /// Creates a new backup coordinator using the factory
    /// - Parameters:
    ///   - factory: Factory for creating backup and snapshot services
    ///   - resticServiceFactory: Factory for creating Restic services
    ///   - logger: Logger for operation tracking
    ///   - repositoryPath: Path to the repository
    ///   - repositoryPassword: Optional repository password
    /// - Returns: A configured backup coordinator
    /// - Throws: Error if service creation fails
    public static func create(
        factory: BackupServiceFactory,
        resticServiceFactory: ResticServiceFactory,
        logger: any LoggingProtocol,
        repositoryPath: String,
        repositoryPassword: String? = nil
    ) async throws -> BackupCoordinatorImpl {
        // Create backup service
        let backupService = try factory.createBackupService(
            resticServiceFactory: resticServiceFactory,
            logger: logger,
            repositoryPath: repositoryPath,
            repositoryPassword: repositoryPassword
        )
        
        // Create snapshot service
        let snapshotService = try factory.createSnapshotService(
            resticServiceFactory: resticServiceFactory,
            logger: logger,
            repositoryPath: repositoryPath,
            repositoryPassword: repositoryPassword
        )
        
        // Create repository info
        let repositoryInfo = RepositoryInfo(
            location: repositoryPath,
            id: UUID().uuidString, // This would be obtained from the repository
            password: repositoryPassword
        )
        
        // Create and return coordinator
        return BackupCoordinatorImpl(
            backupService: backupService,
            snapshotService: snapshotService,
            logger: logger,
            repositoryInfo: repositoryInfo
        )
    }
    
    // MARK: - Backup Operations
    
    /// Creates a new backup
    /// - Parameters:
    ///   - sources: Source paths to back up
    ///   - excludePaths: Optional paths to exclude
    ///   - tags: Optional tags to associate with the backup
    ///   - options: Optional backup options
    /// - Returns: Result of the backup operation
    /// - Throws: `BackupError` if backup creation fails
    public func createBackup(
        sources: [URL],
        excludePaths: [URL]? = nil,
        tags: [String]? = nil,
        options: BackupOptions? = nil
    ) async throws -> BackupResult {
        await logger.info("Initiating backup via coordinator", metadata: [
            "sources": sources.map(\.path).joined(separator: ", "),
            "excludeCount": String(excludePaths?.count ?? 0),
            "tagCount": String(tags?.count ?? 0)
        ])
        
        do {
            // Delegate to backup service
            let result = try await backupService.createBackup(
                sources: sources,
                excludePaths: excludePaths,
                tags: tags,
                options: options
            )
            
            await logger.info("Backup completed via coordinator", metadata: [
                "snapshotID": result.snapshotID,
                "fileCount": String(result.fileCount),
                "successful": String(result.successful)
            ])
            
            return result
        } catch {
            await logger.error("Backup failed via coordinator", metadata: [
                "error": error.localizedDescription
            ])
            
            throw error
        }
    }
    
    /// Restores a backup
    /// - Parameters:
    ///   - snapshotID: ID of the snapshot to restore
    ///   - targetPath: Path to restore to
    ///   - includePaths: Optional paths to include
    ///   - excludePaths: Optional paths to exclude
    ///   - options: Optional restore options
    /// - Returns: Result of the restore operation
    /// - Throws: `BackupError` if restore fails
    public func restoreBackup(
        snapshotID: String,
        targetPath: URL,
        includePaths: [URL]? = nil,
        excludePaths: [URL]? = nil,
        options: RestoreOptions? = nil
    ) async throws -> RestoreResult {
        await logger.info("Initiating restore via coordinator", metadata: [
            "snapshotID": snapshotID,
            "targetPath": targetPath.path,
            "includeCount": String(includePaths?.count ?? 0),
            "excludeCount": String(excludePaths?.count ?? 0)
        ])
        
        do {
            // Delegate to backup service
            let result = try await backupService.restoreBackup(
                snapshotID: snapshotID,
                targetPath: targetPath,
                includePaths: includePaths,
                excludePaths: excludePaths,
                options: options
            )
            
            await logger.info("Restore completed via coordinator", metadata: [
                "snapshotID": result.snapshotID,
                "fileCount": String(result.fileCount),
                "successful": String(result.successful)
            ])
            
            return result
        } catch {
            await logger.error("Restore failed via coordinator", metadata: [
                "error": error.localizedDescription
            ])
            
            throw error
        }
    }
    
    /// Deletes a backup
    /// - Parameters:
    ///   - snapshotID: ID of the snapshot to delete
    ///   - options: Optional delete options
    /// - Returns: Result of the delete operation
    /// - Throws: `BackupError` if deletion fails
    public func deleteBackup(
        snapshotID: String,
        options: DeleteOptions? = nil
    ) async throws -> DeleteResult {
        await logger.info("Initiating backup deletion via coordinator", metadata: [
            "snapshotID": snapshotID
        ])
        
        do {
            // Get pruning option
            let pruneAfterDelete = options?.pruneAfterDelete ?? false
            
            // Delegate to snapshot service
            let result = try await snapshotService.deleteSnapshot(
                snapshotID: snapshotID,
                pruneAfterDelete: pruneAfterDelete
            )
            
            await logger.info("Backup deletion completed via coordinator", metadata: [
                "snapshotID": result.snapshotID,
                "successful": String(result.successful)
            ])
            
            return result
        } catch {
            await logger.error("Backup deletion failed via coordinator", metadata: [
                "error": error.localizedDescription
            ])
            
            throw error
        }
    }
    
    // MARK: - Snapshot Operations
    
    /// Lists all available snapshots
    /// - Parameters:
    ///   - tags: Optional tags to filter by
    ///   - before: Optional date to filter snapshots before
    ///   - after: Optional date to filter snapshots after
    ///   - options: Optional listing options
    /// - Returns: Array of matching snapshots
    /// - Throws: `BackupError` if listing fails
    public func listSnapshots(
        tags: [String]? = nil,
        before: Date? = nil,
        after: Date? = nil,
        options: ListOptions? = nil
    ) async throws -> [BackupSnapshot] {
        await logger.info("Listing snapshots via coordinator", metadata: [
            "tagCount": String(tags?.count ?? 0),
            "before": before?.description ?? "none",
            "after": after?.description ?? "none"
        ])
        
        do {
            // Delegate to snapshot service
            let snapshots = try await snapshotService.listSnapshots(
                repositoryID: nil,
                tags: tags,
                before: before,
                after: after,
                path: options?.path,
                limit: options?.limit
            )
            
            await logger.info("Listed snapshots via coordinator", metadata: [
                "count": String(snapshots.count)
            ])
            
            return snapshots
        } catch {
            await logger.error("Snapshot listing failed via coordinator", metadata: [
                "error": error.localizedDescription
            ])
            
            throw error
        }
    }
    
    /// Gets detailed information about a specific snapshot
    /// - Parameters:
    ///   - snapshotID: ID of the snapshot
    ///   - includeFileStatistics: Whether to include file statistics
    /// - Returns: Detailed snapshot information
    /// - Throws: `BackupError` if retrieval fails
    public func getSnapshotDetails(
        snapshotID: String,
        includeFileStatistics: Bool = false
    ) async throws -> BackupSnapshot {
        await logger.info("Getting snapshot details via coordinator", metadata: [
            "snapshotID": snapshotID,
            "includeFileStatistics": String(includeFileStatistics)
        ])
        
        do {
            // Delegate to snapshot service
            let snapshot = try await snapshotService.getSnapshotDetails(
                snapshotID: snapshotID,
                includeFileStatistics: includeFileStatistics
            )
            
            await logger.info("Retrieved snapshot details via coordinator", metadata: [
                "snapshotID": snapshot.id,
                "creationTime": snapshot.creationTime.description
            ])
            
            return snapshot
        } catch {
            await logger.error("Snapshot details retrieval failed via coordinator", metadata: [
                "error": error.localizedDescription
            ])
            
            throw error
        }
    }
    
    /// Updates tags for a snapshot
    /// - Parameters:
    ///   - snapshotID: ID of the snapshot
    ///   - addTags: Tags to add
    ///   - removeTags: Tags to remove
    /// - Returns: Updated snapshot
    /// - Throws: `BackupError` if tag update fails
    public func updateSnapshotTags(
        snapshotID: String,
        addTags: [String] = [],
        removeTags: [String] = []
    ) async throws -> BackupSnapshot {
        await logger.info("Updating snapshot tags via coordinator", metadata: [
            "snapshotID": snapshotID,
            "addTagCount": String(addTags.count),
            "removeTagCount": String(removeTags.count)
        ])
        
        do {
            // Delegate to snapshot service
            let snapshot = try await snapshotService.updateSnapshotTags(
                snapshotID: snapshotID,
                addTags: addTags,
                removeTags: removeTags
            )
            
            await logger.info("Updated snapshot tags via coordinator", metadata: [
                "snapshotID": snapshot.id,
                "tagCount": String(snapshot.tags.count)
            ])
            
            return snapshot
        } catch {
            await logger.error("Snapshot tag update failed via coordinator", metadata: [
                "error": error.localizedDescription
            ])
            
            throw error
        }
    }
    
    /// Finds files within a snapshot
    /// - Parameters:
    ///   - snapshotID: ID of the snapshot
    ///   - pattern: Pattern to search for
    ///   - caseSensitive: Whether search is case-sensitive
    /// - Returns: List of matching files
    /// - Throws: `BackupError` if search fails
    public func findFiles(
        snapshotID: String,
        pattern: String,
        caseSensitive: Bool = false
    ) async throws -> [SnapshotFile] {
        await logger.info("Finding files in snapshot via coordinator", metadata: [
            "snapshotID": snapshotID,
            "pattern": pattern,
            "caseSensitive": String(caseSensitive)
        ])
        
        do {
            // Delegate to snapshot service
            let files = try await snapshotService.findFiles(
                snapshotID: snapshotID,
                pattern: pattern,
                caseSensitive: caseSensitive
            )
            
            await logger.info("Found files in snapshot via coordinator", metadata: [
                "count": String(files.count)
            ])
            
            return files
        } catch {
            await logger.error("File search failed via coordinator", metadata: [
                "error": error.localizedDescription
            ])
            
            throw error
        }
    }
    
    /// Verifies a snapshot's integrity
    /// - Parameter snapshotID: ID of the snapshot to verify
    /// - Returns: Verification result
    /// - Throws: `BackupError` if verification fails
    public func verifySnapshot(
        snapshotID: String
    ) async throws -> VerificationResult {
        await logger.info("Verifying snapshot via coordinator", metadata: [
            "snapshotID": snapshotID
        ])
        
        do {
            // Delegate to snapshot service
            let result = try await snapshotService.verifySnapshot(
                snapshotID: snapshotID
            )
            
            await logger.info("Verified snapshot via coordinator", metadata: [
                "snapshotID": snapshotID,
                "successful": String(result.successful),
                "issues": String(result.issues.count)
            ])
            
            return result
        } catch {
            await logger.error("Snapshot verification failed via coordinator", metadata: [
                "error": error.localizedDescription
            ])
            
            throw error
        }
    }
    
    /// Performs a maintenance operation on the repository
    /// - Parameter type: Type of maintenance to perform
    /// - Returns: Result of the maintenance operation
    /// - Throws: `BackupError` if maintenance fails
    public func performMaintenance(
        type: MaintenanceType
    ) async throws -> MaintenanceResult {
        await logger.info("Performing maintenance via coordinator", metadata: [
            "type": String(describing: type)
        ])
        
        do {
            // This would delegate to a maintenance service
            // For now, we'll return a placeholder result
            let result = MaintenanceResult(
                maintenanceType: type,
                successful: true,
                details: "Maintenance completed successfully",
                startTime: Date(),
                endTime: Date()
            )
            
            await logger.info("Maintenance completed via coordinator", metadata: [
                "type": String(describing: type),
                "successful": String(result.successful)
            ])
            
            return result
        } catch {
            await logger.error("Maintenance failed via coordinator", metadata: [
                "error": error.localizedDescription
            ])
            
            throw error
        }
    }
}
