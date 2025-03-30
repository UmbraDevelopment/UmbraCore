import Foundation
import BackupInterfaces
import ResticInterfaces
import LoggingTypes

/**
 * Provides core backup operations using the Restic backend.
 *
 * This service implements the operations required for backup creation, restoration,
 * and management following the Alpha Dot Five architecture principles.
 */
public actor BackupOperationsService {
    /// The Restic service used for backend operations
    private let resticService: ResticServiceProtocol
    
    /// Repository connection information
    private let repositoryInfo: RepositoryInfo
    
    /// Factory for creating backup commands
    private let commandFactory: BackupCommandFactory
    
    /// Parser for command results
    private let resultParser: BackupResultParser
    
    /**
     * Creates a new backup operations service.
     *
     * - Parameters:
     *   - resticService: Service for executing Restic commands
     *   - repositoryInfo: Repository connection details
     *   - commandFactory: Factory for creating commands
     *   - resultParser: Parser for command outputs
     */
    public init(
        resticService: ResticServiceProtocol,
        repositoryInfo: RepositoryInfo,
        commandFactory: BackupCommandFactory,
        resultParser: BackupResultParser
    ) {
        self.resticService = resticService
        self.repositoryInfo = repositoryInfo
        self.commandFactory = commandFactory
        self.resultParser = resultParser
    }
    
    /**
     * Creates a new backup with the specified sources, exclusions, and tags.
     *
     * - Parameters:
     *   - parameters: Parameters for the backup creation
     *   - progressReporter: Reporter for tracking operation progress
     *   - cancellationToken: Optional token for cancelling the operation
     * - Returns: A tuple containing the result and a progress stream
     * - Throws: BackupError if backup creation fails
     */
    public func createBackup(
        parameters: BackupCreateParameters,
        progressReporter: BackupProgressReporter?,
        cancellationToken: CancellationToken?
    ) async throws -> (BackupResult, AsyncStream<BackupInterfaces.BackupProgress>) {
        // Create the progress stream
        var progressContinuation: AsyncStream<BackupInterfaces.BackupProgress>.Continuation!
        let progressStream = AsyncStream<BackupInterfaces.BackupProgress> { continuation in
            progressContinuation = continuation
        }
        
        // Create a progress handler that forwards to both the reporter and the stream
        let progressHandler = { (progress: BackupInterfaces.BackupProgress) in
            progressReporter?.report(progress: progress)
            progressContinuation.yield(progress)
            
            // Check if we're done
            if case .completed = progress.status {
                progressContinuation.finish()
            }
        }
        
        // Create the backup command
        let command = commandFactory.createBackupCommand(
            sources: parameters.sources,
            excludePaths: parameters.excludePaths,
            tags: parameters.tags,
            options: parameters.options
        )
        
        // Run the command
        let result = try await resticService.executeWithOutput(
            command: command,
            repository: repositoryInfo,
            progressHandler: progressHandler,
            cancellationToken: cancellationToken
        )
        
        // Parse the result
        let backupResult = try resultParser.parseBackupResult(output: result.output)
        
        // Return the result and the progress stream
        return (backupResult, progressStream)
    }
    
    /**
     * Restores a backup.
     *
     * - Parameters:
     *   - parameters: Parameters for the backup restoration
     *   - progressReporter: Reporter for tracking operation progress
     *   - cancellationToken: Optional token for cancelling the operation
     * - Returns: A tuple containing the result and a progress stream
     * - Throws: BackupError if restore fails
     */
    public func restoreBackup(
        parameters: BackupRestoreParameters,
        progressReporter: BackupProgressReporter?,
        cancellationToken: CancellationToken?
    ) async throws -> (RestoreResult, AsyncStream<BackupInterfaces.BackupProgress>) {
        // Create the progress stream
        var progressContinuation: AsyncStream<BackupInterfaces.BackupProgress>.Continuation!
        let progressStream = AsyncStream<BackupInterfaces.BackupProgress> { continuation in
            progressContinuation = continuation
        }
        
        // Create a progress handler that forwards to both the reporter and the stream
        let progressHandler = { (progress: BackupInterfaces.BackupProgress) in
            progressReporter?.report(progress: progress)
            progressContinuation.yield(progress)
            
            // Check if we're done
            if case .completed = progress.status {
                progressContinuation.finish()
            }
        }
        
        // Create the restore command
        let command = commandFactory.createRestoreCommand(
            snapshotID: parameters.snapshotID,
            targetPath: parameters.targetPath,
            includePaths: parameters.includePaths,
            excludePaths: parameters.excludePaths,
            options: parameters.options
        )
        
        // Run the command
        let result = try await resticService.executeWithOutput(
            command: command,
            repository: repositoryInfo,
            progressHandler: progressHandler,
            cancellationToken: cancellationToken
        )
        
        // Parse the result
        let restoreResult = try resultParser.parseRestoreResult(output: result.output)
        
        // Return the result and the progress stream
        return (restoreResult, progressStream)
    }
    
    /**
     * Lists available backups.
     *
     * - Parameters:
     *   - parameters: Parameters for listing backups
     *   - cancellationToken: Optional token for cancelling the operation
     * - Returns: Array of backup snapshots
     * - Throws: BackupError if listing fails
     */
    public func listBackups(
        parameters: BackupListParameters,
        cancellationToken: CancellationToken?
    ) async throws -> [BackupSnapshot] {
        // Create the list command
        let command = commandFactory.createListCommand(
            tags: parameters.tags,
            before: parameters.before,
            after: parameters.after,
            host: parameters.host,
            path: parameters.path
        )
        
        // Run the command
        let result = try await resticService.executeWithOutput(
            command: command,
            repository: repositoryInfo,
            cancellationToken: cancellationToken
        )
        
        // Parse the result
        return try resultParser.parseSnapshots(output: result.output)
    }
    
    /**
     * Deletes a backup.
     *
     * - Parameters:
     *   - parameters: Parameters for deleting a backup
     *   - cancellationToken: Optional token for cancelling the operation
     * - Returns: Result of the delete operation
     * - Throws: BackupError if deletion fails
     */
    public func deleteBackup(
        parameters: BackupDeleteParameters,
        cancellationToken: CancellationToken?
    ) async throws -> DeleteResult {
        // Create the delete command
        let command = commandFactory.createDeleteCommand(
            snapshotID: parameters.snapshotID
        )
        
        // Run the command
        let result = try await resticService.executeWithOutput(
            command: command,
            repository: repositoryInfo,
            cancellationToken: cancellationToken
        )
        
        // Parse the result
        let deleteResult = try resultParser.parseDeleteResult(output: result.output)
        
        // If pruning is requested, run that too
        if parameters.pruneAfterDelete {
            // Create the prune command
            let pruneCommand = commandFactory.createMaintenanceCommand(
                type: .prune,
                options: nil
            )
            
            // Run the command
            _ = try await resticService.executeWithOutput(
                command: pruneCommand,
                repository: repositoryInfo,
                cancellationToken: cancellationToken
            )
        }
        
        return deleteResult
    }
    
    /**
     * Finds files in a snapshot matching specified criteria.
     *
     * - Parameters:
     *   - snapshotID: ID of the snapshot to search
     *   - path: Optional path pattern to filter by
     *   - pattern: Optional filename pattern to filter by
     *   - progressReporter: Reporter for tracking operation progress
     *   - cancellationToken: Optional token for cancelling the operation
     * - Returns: Array of matching file entries
     * - Throws: BackupError if search fails
     */
    public func findFiles(
        snapshotID: String,
        path: String? = nil,
        pattern: String? = nil,
        progressReporter: BackupProgressReporter?,
        cancellationToken: CancellationToken?
    ) async throws -> [SnapshotFileEntry] {
        // Create the find command
        let command = commandFactory.createFindCommand(
            snapshotID: snapshotID,
            path: path,
            pattern: pattern
        )
        
        // Run the command
        let result = try await resticService.executeWithOutput(
            command: command,
            repository: repositoryInfo,
            cancellationToken: cancellationToken
        )
        
        // Parse the result
        return try resultParser.parseFileEntries(output: result.output)
    }
    
    /**
     * Performs repository maintenance.
     *
     * - Parameters:
     *   - parameters: Parameters for the maintenance operation
     *   - progressReporter: Reporter for tracking operation progress
     *   - cancellationToken: Optional token for cancelling the operation
     * - Returns: A tuple containing the result and a progress stream
     * - Throws: BackupError if maintenance fails
     */
    public func performMaintenance(
        parameters: BackupMaintenanceParameters,
        progressReporter: BackupProgressReporter?,
        cancellationToken: CancellationToken?
    ) async throws -> (MaintenanceResult, AsyncStream<BackupInterfaces.BackupProgress>) {
        // Create the progress stream
        var progressContinuation: AsyncStream<BackupInterfaces.BackupProgress>.Continuation!
        let progressStream = AsyncStream<BackupInterfaces.BackupProgress> { continuation in
            progressContinuation = continuation
        }
        
        // Create a progress handler that forwards to both the reporter and the stream
        let progressHandler = { (progress: BackupInterfaces.BackupProgress) in
            progressReporter?.report(progress: progress)
            progressContinuation.yield(progress)
            
            // Check if we're done
            if case .completed = progress.status {
                progressContinuation.finish()
            }
        }
        
        // Create the maintenance command
        let command = commandFactory.createMaintenanceCommand(
            type: parameters.maintenanceType,
            options: parameters.options
        )
        
        // Run the command
        let result = try await resticService.executeWithOutput(
            command: command,
            repository: repositoryInfo,
            progressHandler: progressHandler,
            cancellationToken: cancellationToken
        )
        
        // Parse the result
        let maintenanceResult = try resultParser.parseMaintenanceResult(
            output: result.output,
            type: parameters.maintenanceType
        )
        
        // Return the result and the progress stream
        return (maintenanceResult, progressStream)
    }
}
