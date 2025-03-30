import BackupInterfaces
import Foundation
import LoggingInterfaces
import LoggingTypes
import ResticInterfaces
import ResticServices
import UmbraErrors

/**
 # Modern Snapshot Service Implementation
 
 This implementation demonstrates the new Swift Concurrency pattern with:
 - Task-based cancellation instead of explicit CancellationToken
 - AsyncStream for progress reporting
 - Privacy-aware logging integrated with structured progress updates
 
 It follows the Alpha Dot Five architecture principles with proper British
 spelling in documentation and comments.
 */
public actor ModernSnapshotServiceImpl: SnapshotServiceProtocol {
    /// The Restic service used for backend operations
    private let resticService: ResticServiceProtocol

    /// Logger for operation tracking
    private let logger: any LoggingProtocol
    
    /// Privacy-aware logging adapter for structured logging
    private let snapshotLogging: SnapshotLoggingAdapter

    /// Factory for creating Restic commands
    private let commandFactory: ResticCommandFactory

    /// Parser for Restic command outputs
    private let resultParser: SnapshotResultParser

    /// Error mapper for converting Restic errors to backup errors
    private let errorMapper: ErrorMapper
    
    /// Progress reporter
    private let progressReporter: AsyncProgressReporter

    /// Creates a new snapshot service implementation
    /// - Parameters:
    ///   - resticService: Restic service for backend operations
    ///   - logger: Logger for operation tracking
    public init(
        resticService: ResticServiceProtocol,
        logger: any LoggingProtocol
    ) {
        self.resticService = resticService
        self.logger = logger
        self.snapshotLogging = SnapshotLoggingAdapter(logger: logger)
        self.commandFactory = ResticCommandFactory()
        self.resultParser = SnapshotResultParser()
        self.errorMapper = ErrorMapper()
        self.progressReporter = AsyncProgressReporter()
    }

    /// Lists available snapshots with optional filtering
    /// - Parameters:
    ///   - repositoryID: Optional repository ID to filter by
    ///   - tags: Optional tags to filter snapshots by
    ///   - before: Optional date to filter snapshots before
    ///   - after: Optional date to filter snapshots after
    ///   - path: Optional path that must be included in the snapshot
    ///   - limit: Maximum number of snapshots to return
    /// - Returns: Array of backup snapshots matching the criteria
    /// - Throws: `BackupError` if the listing operation fails
    public func listSnapshots(
        repositoryID: String?,
        tags: [String]?,
        before: Date?,
        after: Date?,
        path: URL?,
        limit: Int?
    ) async throws -> [BackupSnapshot] {
        // Create a structured log context with privacy-aware metadata
        let logContext = SnapshotLogContext()
            .with(repositoryID: repositoryID, privacy: .public)
            .with(tags: tags, privacy: .public)
            .with(beforeDate: before, privacy: .public)
            .with(afterDate: after, privacy: .public)
            .with(path: path?.path, privacy: .public)
            .with(key: "limit", value: limit != nil ? String(limit!) : "unlimited", privacy: .public)
            .with(operation: "listSnapshots")

        await snapshotLogging.logOperationStart(logContext: logContext)

        do {
            // Create command to list snapshots
            let command = try commandFactory.createListCommand(
                repositoryID: repositoryID,
                tags: tags,
                before: before,
                after: after,
                path: path,
                limit: limit
            )

            // Check for task cancellation
            try Task.checkCancellation()

            // Execute command
            let output = try await resticService.execute(command)

            // Parse snapshots
            let snapshots = try resultParser.parseSnapshotsList(output: output, repositoryID: repositoryID)

            // Log successful operation
            let resultContext = logContext.with(key: "count", value: String(snapshots.count), privacy: .public)
            await snapshotLogging.logOperationSuccess(logContext: resultContext)

            return snapshots
        } catch is CancellationError {
            await snapshotLogging.logOperationCancelled(logContext: logContext)
            throw BackupError.operationCancelled(
                "Snapshot listing operation was cancelled",
                context: errorMapper.createErrorContext(from: logContext)
            )
        } catch {
            // Map and log error
            let mappedError = errorMapper.mapError(error, context: logContext)
            await snapshotLogging.logOperationFailure(error: mappedError, logContext: logContext)
            throw mappedError
        }
    }

    /// Compares two snapshots and returns differences
    /// - Parameters:
    ///   - snapshotID1: First snapshot ID
    ///   - snapshotID2: Second snapshot ID
    ///   - path: Optional specific path to compare
    /// - Returns: Snapshot difference result and progress stream
    /// - Throws: `BackupError` if comparison fails
    public func compareSnapshots(
        snapshotID1: String,
        snapshotID2: String,
        path: URL?
    ) async throws -> (SnapshotDifference, AsyncStream<BackupProgress>) {
        // Create a structured log context with privacy-aware metadata
        let logContext = SnapshotLogContext()
            .with(key: "snapshotID1", value: snapshotID1, privacy: .public)
            .with(key: "snapshotID2", value: snapshotID2, privacy: .public)
            .with(path: path?.path, privacy: .public)
            .with(operation: "compareSnapshots")
            
        // Create a progress stream for this operation
        let (progressStream, updateProgress, completeProgress) = BackupProgress.createProgressStream()
        
        // Log operation start
        await snapshotLogging.logOperationStart(logContext: logContext)
        updateProgress(.processing(phase: "Starting comparison", percentComplete: 0.1))
        
        do {
            // Create command for snapshot comparison
            let command = try commandFactory.createDiffCommand(
                snapshotID1: snapshotID1,
                snapshotID2: snapshotID2,
                path: path
            )
            
            // Check for task cancellation
            try Task.checkCancellation()
            updateProgress(.processing(phase: "Executing comparison", percentComplete: 0.3))
            
            // Execute command
            let output = try await resticService.execute(command)
            updateProgress(.processing(phase: "Parsing results", percentComplete: 0.7))
            
            // Parse difference results
            let difference = try resultParser.parseSnapshotDifference(
                output: output,
                snapshotID1: snapshotID1,
                snapshotID2: snapshotID2
            )
            
            // Log successful operation
            let resultContext = logContext
                .with(key: "filesAdded", value: String(difference.filesAdded.count), privacy: .public)
                .with(key: "filesRemoved", value: String(difference.filesRemoved.count), privacy: .public)
                .with(key: "filesModified", value: String(difference.filesModified.count), privacy: .public)
            
            await snapshotLogging.logOperationSuccess(logContext: resultContext)
            updateProgress(.processing(phase: "Comparison complete", percentComplete: 0.9))
            
            // Complete the progress reporting
            updateProgress(.completed)
            completeProgress()
            
            return (difference, progressStream)
        } catch is CancellationError {
            await snapshotLogging.logOperationCancelled(logContext: logContext)
            updateProgress(.cancelled)
            completeProgress()
            
            throw BackupError.operationCancelled(
                "Snapshot comparison operation was cancelled",
                context: errorMapper.createErrorContext(from: logContext)
            )
        } catch {
            // Map and log error
            let mappedError = errorMapper.mapError(error, context: logContext)
            await snapshotLogging.logOperationFailure(error: mappedError, logContext: logContext)
            
            updateProgress(.failed(error: mappedError))
            completeProgress()
            
            throw mappedError
        }
    }
    
    /// Deletes a snapshot
    /// - Parameters:
    ///   - snapshotID: Snapshot ID to delete
    ///   - pruneAfterDelete: Whether to prune repository after deletion
    /// - Returns: Result of the delete operation and a progress sequence
    /// - Throws: `BackupError` if deletion fails
    public func deleteSnapshot(
        snapshotID: String,
        pruneAfterDelete: Bool
    ) async throws -> (DeleteResult, AsyncStream<BackupProgress>) {
        // Create a structured log context with privacy-aware metadata
        let logContext = SnapshotLogContext()
            .with(snapshotID: snapshotID, privacy: .public)
            .with(key: "pruneAfterDelete", value: String(pruneAfterDelete), privacy: .public)
            .with(operation: "deleteSnapshot")
            
        // Create a progress stream for this operation
        let operation = BackupOperation.deleteBackup
        let progressStream = progressReporter.progressStream(for: operation)
        
        // Report initial progress
        progressReporter.reportProgress(.initialising, for: operation)
        
        // Log operation start
        await snapshotLogging.logOperationStart(logContext: logContext)
        
        do {
            // Create command for snapshot deletion
            let command = try commandFactory.createForgetCommand(
                snapshotID: snapshotID,
                prune: pruneAfterDelete
            )
            
            // Check for task cancellation
            try Task.checkCancellation()
            progressReporter.reportProgress(.processing(phase: "Deleting snapshot", percentComplete: 0.3), for: operation)
            
            // Execute command
            let output = try await resticService.execute(command)
            progressReporter.reportProgress(.processing(phase: "Processing results", percentComplete: 0.7), for: operation)
            
            // Parse deletion results
            let result = try resultParser.parseDeleteResult(output: output)
            
            // Log successful operation
            let resultContext = logContext
                .with(key: "deletedSnapshots", value: String(result.deletedSnapshots), privacy: .public)
                .with(key: "deletedBlobs", value: String(result.deletedBlobs), privacy: .public)
                .with(key: "freedSpace", value: result.freedSpace.description, privacy: .public)
                
            await snapshotLogging.logOperationSuccess(logContext: resultContext)
            progressReporter.reportProgress(.completed, for: operation)
            
            // Mark the operation as complete
            progressReporter.completeOperation(operation)
            
            return (result, progressStream)
        } catch is CancellationError {
            await snapshotLogging.logOperationCancelled(logContext: logContext)
            progressReporter.reportProgress(.cancelled, for: operation)
            progressReporter.completeOperation(operation)
            
            throw BackupError.operationCancelled(
                "Snapshot deletion operation was cancelled",
                context: errorMapper.createErrorContext(from: logContext)
            )
        } catch {
            // Map and log error
            let mappedError = errorMapper.mapError(error, context: logContext)
            await snapshotLogging.logOperationFailure(error: mappedError, logContext: logContext)
            
            progressReporter.reportProgress(.failed(error: mappedError), for: operation)
            progressReporter.completeOperation(operation)
            
            throw mappedError
        }
    }
}
