import BackupInterfaces
import Foundation
import LoggingInterfaces
import LoggingTypes
import ResticInterfaces
import ResticServices
import UmbraErrors

/**
 # Modern Backup Service Implementation
 
 This implementation utilises Swift's modern concurrency features:
 - AsyncStream for progress reporting
 - Swift's built-in task cancellation
 - Integration with privacy-aware logging
 
 It follows the Alpha Dot Five architecture principles with proper British
 spelling in documentation while maintaining required code conventions.
 */
public actor ModernBackupServiceImpl: BackupServiceProtocol {
    /// The Restic service used for backend operations
    private let resticService: ResticServiceProtocol

    /// Logger for operation tracking
    private let logger: any LoggingProtocol
    
    /// Privacy-aware logging adapter for structured logging
    private let backupLogging: BackupLoggingAdapter

    /// Repository information
    private let repositoryInfo: RepositoryInfo

    /// Factory for creating Restic commands
    private let commandFactory: BackupCommandFactory

    /// Parser for Restic command outputs
    private let resultParser: BackupResultParser

    /// Error mapper for converting Restic errors to backup errors
    private let errorMapper: ErrorMapper
    
    /// Progress reporter
    private let progressReporter: AsyncProgressReporter

    /// Creates a new backup service implementation
    /// - Parameters:
    ///   - resticService: Restic service for backend operations
    ///   - logger: Logger for operation tracking
    ///   - repositoryInfo: Repository connection details
    public init(
        resticService: ResticServiceProtocol,
        logger: any LoggingProtocol,
        repositoryInfo: RepositoryInfo
    ) {
        self.resticService = resticService
        self.logger = logger
        self.backupLogging = BackupLoggingAdapter(logger: logger)
        self.repositoryInfo = repositoryInfo
        self.commandFactory = BackupCommandFactory()
        self.resultParser = BackupResultParser()
        self.errorMapper = ErrorMapper()
        self.progressReporter = AsyncProgressReporter()
    }

    /// Creates a backup from the provided sources
    /// - Parameters:
    ///   - sources: Paths to include in the backup
    ///   - excludePaths: Optional paths to exclude
    ///   - tags: Optional tags to associate with the backup
    ///   - options: Additional options for the backup
    /// - Returns: Result of the backup operation and a progress sequence
    /// - Throws: `BackupError` if the backup fails
    public func createBackup(
        sources: [URL],
        excludePaths: [URL]?,
        tags: [String]?,
        options: BackupOptions?
    ) async throws -> (BackupResult, AsyncStream<BackupProgress>) {
        // Create a log context with privacy-aware metadata
        let logContext = BackupLogContext()
            .with(sources: sources.map(\.path), privacy: .public)
            .with(excludePaths: excludePaths?.map(\.path), privacy: .public)
            .with(tags: tags, privacy: .public)
            .with(key: "compressionLevel", value: String(options?.compressionLevel ?? 0), privacy: .public)
            .with(key: "verifyAfterBackup", value: String(options?.verifyAfterBackup ?? false), privacy: .public)
            .with(operation: "createBackup")

        // Create a progress stream
        let operation = BackupOperation.createBackup
        let progressStream = progressReporter.progressStream(for: operation)
        
        // Log operation start
        await backupLogging.logOperationStart(logContext: logContext)
        progressReporter.reportProgress(.initialising(description: "Preparing backup..."), for: operation)
        
        let startTime = Date()
        
        do {
            // Create backup command
            let command = try commandFactory.createBackupCommand(
                sources: sources,
                excludePaths: excludePaths,
                tags: tags,
                options: options
            )
            
            // Check for task cancellation
            try Task.checkCancellation()
            progressReporter.reportProgress(.processing(phase: "Backing up files", percentComplete: 0.2), for: operation)
            
            // Execute backup command
            let output = try await resticService.execute(command)
            progressReporter.reportProgress(.processing(phase: "Processing backup results", percentComplete: 0.8), for: operation)
            
            // Parse the output to obtain the backup result
            let backupResult = try resultParser.parseBackupResult(
                output: output,
                startTime: startTime,
                endTime: Date(),
                sources: sources,
                repositoryInfo: repositoryInfo
            )
            
            // Perform verification if requested
            if options?.verifyAfterBackup == true {
                progressReporter.reportProgress(.processing(phase: "Verifying backup", percentComplete: 0.9), for: operation)
                try await verifyBackup(snapshotID: backupResult.snapshotID)
            }
            
            // Log successful completion
            let resultContext = logContext
                .with(key: "snapshotID", value: backupResult.snapshotID, privacy: .public)
                .with(key: "filesAdded", value: String(backupResult.filesAdded), privacy: .public)
                .with(key: "filesChanged", value: String(backupResult.filesChanged), privacy: .public)
                .with(key: "bytesAdded", value: String(backupResult.bytesAdded), privacy: .public)
                .with(key: "duration", value: String(format: "%.2f", backupResult.duration), privacy: .public)
                
            await backupLogging.logOperationSuccess(logContext: resultContext)
            progressReporter.reportProgress(.completed, for: operation)
            progressReporter.completeOperation(operation)
            
            return (backupResult, progressStream)
        } catch is CancellationError {
            await backupLogging.logOperationCancelled(logContext: logContext)
            progressReporter.reportProgress(.cancelled, for: operation)
            progressReporter.completeOperation(operation)
            
            throw BackupError.operationCancelled(
                "Backup operation was cancelled",
                context: errorMapper.createErrorContext(from: logContext)
            )
        } catch {
            // Map and log error
            let mappedError = errorMapper.mapError(error, context: logContext)
            await backupLogging.logOperationFailure(error: mappedError, logContext: logContext)
            
            progressReporter.reportProgress(.failed(error: mappedError), for: operation)
            progressReporter.completeOperation(operation)
            
            throw mappedError
        }
    }

    /// Restores a backup to the target location
    /// - Parameters:
    ///   - snapshotID: ID of the snapshot to restore
    ///   - targetPath: Path to restore to
    ///   - includePaths: Optional paths to include
    ///   - excludePaths: Optional paths to exclude
    ///   - options: Optional restore options
    /// - Returns: Result of the restore operation and a progress sequence
    /// - Throws: `BackupError` if restore fails
    public func restoreBackup(
        snapshotID: String,
        targetPath: URL,
        includePaths: [URL]?,
        excludePaths: [URL]?,
        options: RestoreOptions?
    ) async throws -> (RestoreResult, AsyncStream<BackupProgress>) {
        // Create a log context with privacy-aware metadata
        let logContext = BackupLogContext()
            .with(key: "snapshotID", value: snapshotID, privacy: .public)
            .with(key: "targetPath", value: targetPath.path, privacy: .public)
            .with(includePaths: includePaths?.map(\.path), privacy: .public)
            .with(excludePaths: excludePaths?.map(\.path), privacy: .public)
            .with(key: "overwriteExisting", value: String(options?.overwriteExisting ?? false), privacy: .public)
            .with(operation: "restoreBackup")
            
        // Create a progress stream
        let operation = BackupOperation.restoreBackup
        let progressStream = progressReporter.progressStream(for: operation)
        
        // Log operation start
        await backupLogging.logOperationStart(logContext: logContext)
        progressReporter.reportProgress(.initialising(description: "Preparing restore..."), for: operation)
        
        let startTime = Date()
        
        do {
            // Create restore command
            let command = try commandFactory.createRestoreCommand(
                snapshotID: snapshotID,
                targetPath: targetPath,
                includePaths: includePaths,
                excludePaths: excludePaths,
                options: options
            )
            
            // Check for task cancellation
            try Task.checkCancellation()
            progressReporter.reportProgress(.processing(phase: "Restoring files", percentComplete: 0.2), for: operation)
            
            // Execute restore command
            let output = try await resticService.execute(command)
            progressReporter.reportProgress(.processing(phase: "Processing restore results", percentComplete: 0.8), for: operation)
            
            // Parse the output to obtain the restore result
            let restoreResult = try resultParser.parseRestoreResult(
                output: output,
                startTime: startTime,
                endTime: Date(),
                snapshotID: snapshotID,
                targetPath: targetPath
            )
            
            // Log successful completion
            let resultContext = logContext
                .with(key: "filesRestored", value: String(restoreResult.filesRestored), privacy: .public)
                .with(key: "bytesRestored", value: String(restoreResult.bytesRestored), privacy: .public)
                .with(key: "duration", value: String(format: "%.2f", restoreResult.duration), privacy: .public)
                
            await backupLogging.logOperationSuccess(logContext: resultContext)
            progressReporter.reportProgress(.completed, for: operation)
            progressReporter.completeOperation(operation)
            
            return (restoreResult, progressStream)
        } catch is CancellationError {
            await backupLogging.logOperationCancelled(logContext: logContext)
            progressReporter.reportProgress(.cancelled, for: operation)
            progressReporter.completeOperation(operation)
            
            throw BackupError.operationCancelled(
                "Restore operation was cancelled",
                context: errorMapper.createErrorContext(from: logContext)
            )
        } catch {
            // Map and log error
            let mappedError = errorMapper.mapError(error, context: logContext)
            await backupLogging.logOperationFailure(error: mappedError, logContext: logContext)
            
            progressReporter.reportProgress(.failed(error: mappedError), for: operation)
            progressReporter.completeOperation(operation)
            
            throw mappedError
        }
    }

    /// Lists available snapshots
    /// - Parameters:
    ///   - tags: Optional tags to filter by
    ///   - before: Optional date to filter snapshots before
    ///   - after: Optional date to filter snapshots after
    ///   - options: Optional listing options
    /// - Returns: Array of matching snapshots
    /// - Throws: `BackupError` if listing fails
    public func listSnapshots(
        tags: [String]?,
        before: Date?,
        after: Date?,
        options: ListOptions?
    ) async throws -> [BackupSnapshot] {
        // Create a log context with privacy-aware metadata
        let logContext = BackupLogContext()
            .with(tags: tags, privacy: .public)
            .with(key: "before", value: before?.description ?? "any", privacy: .public)
            .with(key: "after", value: after?.description ?? "any", privacy: .public)
            .with(key: "limit", value: options?.limit != nil ? String(options!.limit) : "none", privacy: .public)
            .with(operation: "listSnapshots")
            
        // Log operation start
        await backupLogging.logOperationStart(logContext: logContext)
        
        do {
            // Create list command
            let command = try commandFactory.createListCommand(
                tags: tags,
                before: before,
                after: after,
                options: options
            )
            
            // Check for task cancellation
            try Task.checkCancellation()
            
            // Execute list command
            let output = try await resticService.execute(command)
            
            // Parse the output to obtain snapshots
            let snapshots = try resultParser.parseSnapshotsList(
                output: output,
                repositoryID: repositoryInfo.id
            )
            
            // Log successful completion
            let resultContext = logContext
                .with(key: "count", value: String(snapshots.count), privacy: .public)
                
            await backupLogging.logOperationSuccess(logContext: resultContext)
            
            return snapshots
        } catch is CancellationError {
            await backupLogging.logOperationCancelled(logContext: logContext)
            
            throw BackupError.operationCancelled(
                "List snapshots operation was cancelled",
                context: errorMapper.createErrorContext(from: logContext)
            )
        } catch {
            // Map and log error
            let mappedError = errorMapper.mapError(error, context: logContext)
            await backupLogging.logOperationFailure(error: mappedError, logContext: logContext)
            
            throw mappedError
        }
    }
    
    /// Deletes a backup
    /// - Parameters:
    ///   - snapshotID: ID of the snapshot to delete
    ///   - options: Optional delete options
    /// - Returns: Result of the delete operation and a progress sequence
    /// - Throws: `BackupError` if deletion fails
    public func deleteBackup(
        snapshotID: String,
        options: DeleteOptions?
    ) async throws -> (DeleteResult, AsyncStream<BackupProgress>) {
        // Create a log context with privacy-aware metadata
        let logContext = BackupLogContext()
            .with(key: "snapshotID", value: snapshotID, privacy: .public)
            .with(key: "prune", value: String(options?.prune ?? false), privacy: .public)
            .with(operation: "deleteBackup")
            
        // Create a progress stream
        let operation = BackupOperation.deleteBackup
        let progressStream = progressReporter.progressStream(for: operation)
        
        // Log operation start
        await backupLogging.logOperationStart(logContext: logContext)
        progressReporter.reportProgress(.initialising(description: "Preparing deletion..."), for: operation)
        
        do {
            // Create delete command
            let command = try commandFactory.createForgetCommand(
                snapshotID: snapshotID,
                prune: options?.prune ?? false
            )
            
            // Check for task cancellation
            try Task.checkCancellation()
            progressReporter.reportProgress(.processing(phase: "Deleting snapshot", percentComplete: 0.3), for: operation)
            
            // Execute delete command
            let output = try await resticService.execute(command)
            progressReporter.reportProgress(.processing(phase: "Processing deletion results", percentComplete: 0.7), for: operation)
            
            // Parse the output to obtain delete result
            let deleteResult = try resultParser.parseDeleteResult(output: output)
            
            // Log successful completion
            let resultContext = logContext
                .with(key: "deletedSnapshots", value: String(deleteResult.deletedSnapshots), privacy: .public)
                .with(key: "deletedBlobs", value: String(deleteResult.deletedBlobs), privacy: .public)
                .with(key: "freedSpace", value: deleteResult.freedSpace.description, privacy: .public)
                
            await backupLogging.logOperationSuccess(logContext: resultContext)
            progressReporter.reportProgress(.completed, for: operation)
            progressReporter.completeOperation(operation)
            
            return (deleteResult, progressStream)
        } catch is CancellationError {
            await backupLogging.logOperationCancelled(logContext: logContext)
            progressReporter.reportProgress(.cancelled, for: operation)
            progressReporter.completeOperation(operation)
            
            throw BackupError.operationCancelled(
                "Delete operation was cancelled",
                context: errorMapper.createErrorContext(from: logContext)
            )
        } catch {
            // Map and log error
            let mappedError = errorMapper.mapError(error, context: logContext)
            await backupLogging.logOperationFailure(error: mappedError, logContext: logContext)
            
            progressReporter.reportProgress(.failed(error: mappedError), for: operation)
            progressReporter.completeOperation(operation)
            
            throw mappedError
        }
    }
    
    /// Performs maintenance on the backup repository
    /// - Parameters:
    ///   - type: Type of maintenance to perform
    ///   - options: Optional maintenance options
    /// - Returns: Result of the maintenance operation and a progress sequence
    /// - Throws: `BackupError` if maintenance fails
    public func performMaintenance(
        type: MaintenanceType,
        options: MaintenanceOptions?
    ) async throws -> (MaintenanceResult, AsyncStream<BackupProgress>) {
        // Create a log context with privacy-aware metadata
        let logContext = BackupLogContext()
            .with(key: "type", value: String(describing: type), privacy: .public)
            .with(key: "dryRun", value: String(options?.dryRun ?? false), privacy: .public)
            .with(operation: "performMaintenance")
            
        // Create a progress stream
        let (progressStream, updateProgress, completeProgress) = BackupProgress.createProgressStream()
        
        // Log operation start
        await backupLogging.logOperationStart(logContext: logContext)
        updateProgress(.initialising(description: "Preparing maintenance..."))
        
        let startTime = Date()
        
        do {
            // Create maintenance command based on type
            let command = try commandFactory.createMaintenanceCommand(
                type: type,
                options: options
            )
            
            // Check for task cancellation
            try Task.checkCancellation()
            updateProgress(.processing(phase: "Performing \(type) maintenance", percentComplete: 0.3))
            
            // Execute maintenance command
            let output = try await resticService.execute(command)
            updateProgress(.processing(phase: "Processing maintenance results", percentComplete: 0.8))
            
            // Parse the output to obtain maintenance result
            let maintenanceResult = try resultParser.parseMaintenanceResult(
                output: output,
                type: type,
                startTime: startTime,
                endTime: Date()
            )
            
            // Log successful completion
            let resultContext = logContext
                .with(key: "processedItems", value: String(maintenanceResult.processedItems), privacy: .public)
                .with(key: "duration", value: String(format: "%.2f", maintenanceResult.duration), privacy: .public)
                
            await backupLogging.logOperationSuccess(logContext: resultContext)
            updateProgress(.completed)
            completeProgress()
            
            return (maintenanceResult, progressStream)
        } catch is CancellationError {
            await backupLogging.logOperationCancelled(logContext: logContext)
            updateProgress(.cancelled)
            completeProgress()
            
            throw BackupError.operationCancelled(
                "Maintenance operation was cancelled",
                context: errorMapper.createErrorContext(from: logContext)
            )
        } catch {
            // Map and log error
            let mappedError = errorMapper.mapError(error, context: logContext)
            await backupLogging.logOperationFailure(error: mappedError, logContext: logContext)
            
            updateProgress(.failed(error: mappedError))
            completeProgress()
            
            throw mappedError
        }
    }
    
    // MARK: - Private Helpers
    
    /// Verifies a backup snapshot
    /// - Parameter snapshotID: ID of the snapshot to verify
    /// - Throws: BackupError if verification fails
    private func verifyBackup(snapshotID: String) async throws {
        let logContext = BackupLogContext()
            .with(key: "snapshotID", value: snapshotID, privacy: .public)
            .with(operation: "verifyBackup")
            
        await backupLogging.logOperationStart(logContext: logContext)
        
        do {
            // Create verify command
            let command = try commandFactory.createVerifyCommand(snapshotID: snapshotID)
            
            // Execute verify command
            let _ = try await resticService.execute(command)
            
            // Log successful verification
            await backupLogging.logOperationSuccess(logContext: logContext)
        } catch {
            let mappedError = errorMapper.mapError(error, context: logContext)
            await backupLogging.logOperationFailure(error: mappedError, logContext: logContext)
            throw mappedError
        }
    }
}
