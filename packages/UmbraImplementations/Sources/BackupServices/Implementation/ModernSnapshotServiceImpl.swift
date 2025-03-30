import BackupInterfaces
import Foundation
import LoggingInterfaces
import LoggingTypes
import ResticInterfaces
import ResticServices
import UmbraErrors

/**
 # Modern Snapshot Service Implementation
 
 This implementation demonstrates the Alpha Dot Five architecture with:
 - Component-based service architecture for clear separation of concerns
 - Task-based cancellation with structured cancellation handling
 - AsyncStream for progress reporting
 - Privacy-aware logging integrated with structured progress updates
 - Comprehensive metrics collection and telemetry
 - Type-safe parameter objects with built-in validation
 
 It follows the Alpha Dot Five architecture principles with proper British
 spelling in documentation and comments.
 */
public actor ModernSnapshotServiceImpl: SnapshotServiceProtocol {
    // MARK: - Dependencies
    
    /// The Restic service used for backend operations
    private let resticService: ResticServiceProtocol

    /// Logger for operation tracking
    private let logger: any LoggingProtocol
    
    // MARK: - Service Components
    
    /// Adapter for privacy-aware structured logging
    private let snapshotLogging: SnapshotLoggingAdapter
    
    /// Core operations service for snapshot operations
    private let operationsService: SnapshotOperationsService
    
    /// Management service for snapshot modification operations
    private let managementService: SnapshotManagementService
    
    /// Restore service for snapshot restore operations
    private let restoreService: SnapshotRestoreService
    
    /// Operation executor for consistent error handling
    private let operationExecutor: SnapshotOperationExecutor
    
    /// Handler for operation cancellation
    private let cancellationHandler: CancellationHandler
    
    /// Collector for operation metrics
    private let metricsCollector: SnapshotMetricsCollector
    
    /// Factory for creating Restic commands
    private let commandFactory: ResticCommandFactory

    /// Parser for Restic command outputs
    private let resultParser: SnapshotResultParser

    /// Error mapper for converting Restic errors to backup errors
    private let errorMapper: ErrorMapper
    
    /// Error log context mapper for creating privacy-aware error contexts
    private let errorLogContextMapper: ErrorLogContextMapper
    
    /// Progress reporter for AsyncStream-based progress reporting
    private let progressReporter: AsyncProgressReporter

    /**
     * Creates a new snapshot service implementation.
     *
     * - Parameters:
     *   - resticService: Restic service for backend operations
     *   - logger: Logger for operation tracking
     */
    public init(
        resticService: ResticServiceProtocol,
        logger: any LoggingProtocol
    ) {
        self.resticService = resticService
        self.logger = logger
        
        // Initialize adapters and factories
        self.snapshotLogging = SnapshotLoggingAdapter(logger: logger)
        self.commandFactory = ResticCommandFactory()
        self.resultParser = SnapshotResultParser()
        self.errorMapper = ErrorMapper()
        self.errorLogContextMapper = ErrorLogContextMapper()
        self.progressReporter = AsyncProgressReporter()
        
        // Initialize support components
        self.cancellationHandler = CancellationHandler()
        self.metricsCollector = SnapshotMetricsCollector()
        
        // Initialize operation executor
        self.operationExecutor = SnapshotOperationExecutor(
            logger: logger,
            cancellationHandler: cancellationHandler,
            metricsCollector: metricsCollector,
            errorLogContextMapper: errorLogContextMapper,
            errorMapper: errorMapper
        )
        
        // Initialize service components in dependency order
        self.operationsService = SnapshotOperationsService(
            resticService: resticService,
            operationExecutor: operationExecutor
        )
        
        self.managementService = SnapshotManagementService(
            resticService: resticService,
            operationExecutor: operationExecutor,
            operationsService: operationsService
        )
        
        self.restoreService = SnapshotRestoreService(
            resticService: resticService,
            operationExecutor: operationExecutor
        )
    }

    // MARK: - AsyncStream Progress API
    
    /**
     * Lists snapshots matching the given criteria.
     *
     * - Parameters:
     *   - repositoryID: Optional repository ID to filter by
     *   - tags: Optional tags to filter by
     *   - before: Optional date to filter snapshots before
     *   - after: Optional date to filter snapshots after
     *   - path: Optional path to filter by
     *   - limit: Maximum number of snapshots to return
     * - Returns: Array of backup snapshots matching the criteria
     * - Throws: `BackupError` if the listing operation fails
     */
    public func listSnapshots(
        repositoryID: String?,
        tags: [String]?,
        before: Date?,
        after: Date?,
        path: URL?,
        limit: Int?
    ) async throws -> [BackupSnapshot] {
        // Create parameters object
        let parameters = SnapshotListParameters(
            repositoryID: repositoryID,
            tags: tags,
            before: before,
            after: after,
            path: path,
            limit: limit
        )
        
        // Execute the command
        let (snapshots, _) = try await operationsService.listSnapshots(
            parameters: parameters,
            progressReporter: nil,
            cancellationToken: nil
        )
        
        return snapshots
    }
    
    /**
     * Internal implementation that provides both snapshots and progress information.
     *
     * - Parameters:
     *   - parameters: Parameters for the listing operation
     *   - progressReporter: Optional reporter for tracking progress
     *   - cancellationToken: Optional token for cancellation support
     * - Returns: Tuple with snapshots and progress stream
     * - Throws: `BackupError` if the listing operation fails
     */
    internal func listSnapshotsWithProgress(
        parameters: SnapshotListParameters,
        progressReporter: BackupProgressReporter?,
        cancellationToken: CancellationToken?
    ) async throws -> ([BackupSnapshot], AsyncStream<BackupInterfaces.BackupProgress>) {
        return try await operationsService.listSnapshots(
            parameters: parameters,
            progressReporter: progressReporter,
            cancellationToken: cancellationToken
        )
    }
    
    /**
     * Compares two snapshots and returns differences.
     *
     * - Parameters:
     *   - snapshotID1: First snapshot ID
     *   - snapshotID2: Second snapshot ID
     *   - path: Optional specific path to compare
     * - Returns: Snapshot difference result and a progress stream
     * - Throws: `BackupError` if comparison fails
     */
    public func compareSnapshots(
        snapshotID1: String,
        snapshotID2: String,
        path: URL?
    ) async throws -> (SnapshotDifference, AsyncStream<BackupInterfaces.BackupProgress>) {
        // Create parameters object
        let parameters = SnapshotCompareParameters(
            snapshotID1: snapshotID1,
            snapshotID2: snapshotID2,
            path: path
        )
        
        // Create progress reporter
        let progressReporter = AsyncProgressReporter()
        let progressStream = progressReporter.createProgressStream()
        
        // Create progress adapter
        let progressAdapter = ProgressReporterAdapter(reporter: progressReporter)
        
        // Execute the command
        let difference = try await operationsService.compareSnapshots(
            parameters: parameters,
            progressReporter: progressAdapter,
            cancellationToken: nil
        )
        
        return (difference, progressStream)
    }
    
    /**
     * Internal implementation that provides both difference result and progress information.
     *
     * - Parameters:
     *   - parameters: Parameters for the comparison operation
     *   - progressReporter: Optional reporter for tracking progress
     *   - cancellationToken: Optional token for cancellation support
     * - Returns: Tuple with difference result and progress stream
     * - Throws: `BackupError` if the comparison operation fails
     */
    internal func compareSnapshotsWithProgress(
        parameters: SnapshotCompareParameters,
        progressReporter: BackupProgressReporter?,
        cancellationToken: CancellationToken?
    ) async throws -> (SnapshotDifference, AsyncStream<BackupInterfaces.BackupProgress>) {
        return try await operationsService.compareSnapshots(
            parameters: parameters,
            progressReporter: progressReporter,
            cancellationToken: cancellationToken
        )
    }
    
    /**
     * Deletes a snapshot.
     *
     * - Parameters:
     *   - snapshotID: ID of the snapshot to delete
     *   - pruneAfterDelete: Whether to prune the repository after deletion
     * - Returns: Tuple containing the result and a progress stream
     * - Throws: `BackupError` if the operation fails
     */
    public func deleteSnapshot(
        snapshotID: String,
        pruneAfterDelete: Bool
    ) async throws -> (DeleteResult, AsyncStream<BackupInterfaces.BackupProgress>) {
        // Create parameters object
        let parameters = SnapshotDeleteParameters(
            snapshotID: snapshotID,
            pruneAfterDelete: pruneAfterDelete
        )
        
        // Create progress stream
        let progressStream = progressReporter.createProgressStream()
        
        // Create adapter from AsyncProgressReporter to BackupProgressReporter
        let progressAdapter = ProgressReporterAdapter(reporter: progressReporter)
        
        // Execute operation
        try await managementService.deleteSnapshot(
            parameters: parameters,
            progressReporter: progressAdapter,
            cancellationToken: nil // Using task-based cancellation instead
        )
        
        // Create result
        let result = DeleteResult(
            snapshotID: snapshotID,
            success: true,
            timestamp: Date()
        )
        
        return (result, progressStream)
    }
    
    /**
     * Updates tags for a snapshot.
     *
     * - Parameters:
     *   - snapshotID: ID of the snapshot to update
     *   - addTags: Tags to add to the snapshot
     *   - removeTags: Tags to remove from the snapshot
     * - Returns: Updated snapshot
     * - Throws: `BackupError` if the operation fails
     */
    public func updateSnapshotTags(
        snapshotID: String,
        addTags: [String],
        removeTags: [String]
    ) async throws -> BackupSnapshot {
        // Create parameters object
        let parameters = SnapshotUpdateTagsParameters(
            snapshotID: snapshotID,
            addTags: addTags,
            removeTags: removeTags
        )
        
        // Execute the command
        let (snapshot, _) = try await operationsService.updateSnapshotTags(
            parameters: parameters,
            progressReporter: nil,
            cancellationToken: nil
        )
        
        return snapshot
    }
    
    /**
     * Internal implementation that provides both the updated snapshot and progress information.
     *
     * - Parameters:
     *   - parameters: Parameters for the tag update operation
     *   - progressReporter: Optional reporter for tracking progress
     *   - cancellationToken: Optional token for cancellation support
     * - Returns: Tuple with updated snapshot and progress stream
     * - Throws: `BackupError` if the tag update operation fails
     */
    internal func updateSnapshotTagsWithProgress(
        parameters: SnapshotUpdateTagsParameters,
        progressReporter: BackupProgressReporter?,
        cancellationToken: CancellationToken?
    ) async throws -> (BackupSnapshot, AsyncStream<BackupInterfaces.BackupProgress>) {
        return try await operationsService.updateSnapshotTags(
            parameters: parameters,
            progressReporter: progressReporter,
            cancellationToken: cancellationToken
        )
    }
    
    /**
     * Updates the description for a snapshot.
     *
     * - Parameters:
     *   - snapshotID: ID of the snapshot to update
     *   - description: New description for the snapshot
     * - Returns: Updated snapshot
     * - Throws: `BackupError` if the operation fails
     */
    public func updateSnapshotDescription(
        snapshotID: String,
        description: String
    ) async throws -> BackupSnapshot {
        // Create parameters object
        let parameters = SnapshotUpdateDescriptionParameters(
            snapshotID: snapshotID,
            description: description
        )
        
        // Execute the command
        let (snapshot, _) = try await operationsService.updateSnapshotDescription(
            parameters: parameters,
            progressReporter: nil,
            cancellationToken: nil
        )
        
        return snapshot
    }
    
    /**
     * Internal implementation that provides both the updated snapshot and progress information.
     *
     * - Parameters:
     *   - parameters: Parameters for the description update operation
     *   - progressReporter: Optional reporter for tracking progress
     *   - cancellationToken: Optional token for cancellation support
     * - Returns: Tuple with updated snapshot and progress stream
     * - Throws: `BackupError` if the description update operation fails
     */
    internal func updateSnapshotDescriptionWithProgress(
        parameters: SnapshotUpdateDescriptionParameters,
        progressReporter: BackupProgressReporter?,
        cancellationToken: CancellationToken?
    ) async throws -> (BackupSnapshot, AsyncStream<BackupInterfaces.BackupProgress>) {
        return try await operationsService.updateSnapshotDescription(
            parameters: parameters,
            progressReporter: progressReporter,
            cancellationToken: cancellationToken
        )
    }
    
    /**
     * Restores files from a snapshot.
     *
     * - Parameters:
     *   - snapshotID: ID of the snapshot to restore from
     *   - targetPath: Path to restore files to
     *   - includePattern: Optional pattern to include files
     *   - excludePattern: Optional pattern to exclude files
     * - Returns: Progress stream for the operation
     * - Throws: `BackupError` if the operation fails
     */
    public func restoreFiles(
        snapshotID: String,
        targetPath: URL,
        includePattern: String?,
        excludePattern: String?
    ) async throws -> AsyncStream<BackupInterfaces.BackupProgress> {
        // Validate target path for safety
        try restoreService.validateRestoreTarget(targetPath)
        
        // Create parameters object
        let parameters = SnapshotRestoreParameters(
            snapshotID: snapshotID,
            targetPath: targetPath,
            includePattern: includePattern,
            excludePattern: excludePattern
        )
        
        // Create progress stream
        let progressStream = progressReporter.createProgressStream()
        
        // Create adapter from AsyncProgressReporter to BackupProgressReporter
        let progressAdapter = ProgressReporterAdapter(reporter: progressReporter)
        
        // Execute operation in a task to avoid blocking
        Task {
            do {
                try await restoreService.restoreFiles(
                    parameters: parameters,
                    progressReporter: progressAdapter,
                    cancellationToken: nil // Using task-based cancellation instead
                )
                
                // Report completion
                await progressReporter.updateProgress(1.0, message: "Restore completed successfully")
            } catch {
                // Report error
                await progressReporter.updateProgress(
                    1.0,
                    message: "Restore failed: \(error.localizedDescription)",
                    error: error
                )
            }
        }
        
        return progressStream
    }
    
    /**
     * Gets detailed information about a snapshot.
     *
     * - Parameters:
     *   - snapshotID: ID of the snapshot to get
     *   - includeFileStatistics: Whether to include file statistics
     * - Returns: Detailed snapshot information
     * - Throws: `BackupError` if the snapshot cannot be found
     */
    public func getSnapshotDetails(
        snapshotID: String,
        includeFileStatistics: Bool
    ) async throws -> BackupSnapshot {
        // Create parameters object
        let parameters = SnapshotGetParameters(
            snapshotID: snapshotID,
            includeFileStatistics: includeFileStatistics
        )
        
        // Execute the command
        let (snapshot, _) = try await operationsService.getSnapshot(
            parameters: parameters,
            progressReporter: nil,
            cancellationToken: nil
        )
        
        return snapshot
    }
    
    // MARK: - Legacy API Implementation
    
    /**
     * Lists available snapshots with optional filtering.
     *
     * - Parameters:
     *   - repositoryID: Optional repository ID to filter by
     *   - tags: Optional tags to filter snapshots by
     *   - before: Optional date to filter snapshots before
     *   - after: Optional date to filter snapshots after
     *   - path: Optional path that must be included in the snapshot
     *   - limit: Maximum number of snapshots to return
     *   - progressReporter: Optional reporter for tracking operation progress
     *   - cancellationToken: Optional token for cancelling the operation
     * - Returns: Array of matching snapshots
     * - Throws: BackupError if the operation fails
     */
    public func listSnapshots(
        repositoryID: String?,
        tags: [String]?,
        before: Date?,
        after: Date?,
        path: URL?,
        limit: Int?,
        progressReporter: BackupProgressReporter?,
        cancellationToken: CancellationToken?
    ) async throws -> [BackupSnapshot] {
        let parameters = SnapshotListParameters(
            repositoryID: repositoryID,
            tags: tags,
            before: before,
            after: after,
            path: path,
            limit: limit
        )
        
        return try await operationsService.listSnapshots(
            parameters: parameters,
            progressReporter: progressReporter,
            cancellationToken: cancellationToken
        )
    }
    
    /**
     * Retrieves a specific snapshot by ID.
     *
     * - Parameters:
     *   - snapshotID: ID of the snapshot to retrieve
     *   - includeFileStatistics: Whether to include detailed file statistics
     *   - progressReporter: Optional reporter for tracking operation progress
     *   - cancellationToken: Optional token for cancelling the operation
     * - Returns: The requested snapshot
     * - Throws: BackupError if the operation fails
     */
    public func getSnapshot(
        snapshotID: String,
        includeFileStatistics: Bool,
        progressReporter: BackupProgressReporter?,
        cancellationToken: CancellationToken?
    ) async throws -> BackupSnapshot {
        let parameters = SnapshotGetParameters(
            snapshotID: snapshotID,
            includeFileStatistics: includeFileStatistics
        )
        
        return try await operationsService.getSnapshot(
            parameters: parameters,
            progressReporter: progressReporter,
            cancellationToken: cancellationToken
        )
    }
    
    /**
     * Compares two snapshots to identify differences.
     *
     * - Parameters:
     *   - snapshotID1: First snapshot ID
     *   - snapshotID2: Second snapshot ID
     *   - path: Optional specific path to compare
     *   - progressReporter: Optional reporter for tracking operation progress
     *   - cancellationToken: Optional token for cancelling the operation
     * - Returns: Details of differences between the snapshots
     * - Throws: BackupError if the operation fails
     */
    public func compareSnapshots(
        snapshotID1: String,
        snapshotID2: String,
        path: URL?,
        progressReporter: BackupProgressReporter?,
        cancellationToken: CancellationToken?
    ) async throws -> (SnapshotDifference, AsyncStream<BackupInterfaces.BackupProgress>) {
        let parameters = SnapshotCompareParameters(
            snapshotID1: snapshotID1,
            snapshotID2: snapshotID2,
            path: path
        )
        
        return try await operationsService.compareSnapshots(
            parameters: parameters,
            progressReporter: progressReporter,
            cancellationToken: cancellationToken
        )
    }
    
    /**
     * Updates the tags for a snapshot.
     *
     * - Parameters:
     *   - snapshotID: Snapshot ID to update
     *   - addTags: Tags to add
     *   - removeTags: Tags to remove
     *   - progressReporter: Optional reporter for tracking operation progress
     *   - cancellationToken: Optional token for cancelling the operation
     * - Returns: The updated snapshot
     * - Throws: BackupError if the operation fails
     */
    public func updateSnapshotTags(
        snapshotID: String,
        addTags: [String],
        removeTags: [String],
        progressReporter: BackupProgressReporter?,
        cancellationToken: CancellationToken?
    ) async throws -> (BackupSnapshot, AsyncStream<BackupInterfaces.BackupProgress>) {
        let parameters = SnapshotUpdateTagsParameters(
            snapshotID: snapshotID,
            addTags: addTags,
            removeTags: removeTags
        )
        
        return try await managementService.updateSnapshotTags(
            parameters: parameters,
            progressReporter: progressReporter,
            cancellationToken: cancellationToken
        )
    }
    
    /**
     * Updates the description for a snapshot.
     *
     * - Parameters:
     *   - snapshotID: Snapshot ID to update
     *   - description: New description
     *   - progressReporter: Optional reporter for tracking operation progress
     *   - cancellationToken: Optional token for cancelling the operation
     * - Returns: The updated snapshot
     * - Throws: BackupError if the operation fails
     */
    public func updateSnapshotDescription(
        snapshotID: String,
        description: String,
        progressReporter: BackupProgressReporter?,
        cancellationToken: CancellationToken?
    ) async throws -> (BackupSnapshot, AsyncStream<BackupInterfaces.BackupProgress>) {
        let parameters = SnapshotUpdateDescriptionParameters(
            snapshotID: snapshotID,
            description: description
        )
        
        return try await managementService.updateSnapshotDescription(
            parameters: parameters,
            progressReporter: progressReporter,
            cancellationToken: cancellationToken
        )
    }
    
    /**
     * Deletes a snapshot.
     *
     * - Parameters:
     *   - snapshotID: Snapshot ID to delete
     *   - pruneAfterDelete: Whether to prune repository after deletion
     *   - progressReporter: Optional reporter for tracking operation progress
     *   - cancellationToken: Optional token for cancelling the operation
     * - Throws: BackupError if the operation fails
     */
    public func deleteSnapshot(
        snapshotID: String,
        pruneAfterDelete: Bool,
        progressReporter: BackupProgressReporter?,
        cancellationToken: CancellationToken?
    ) async throws -> (DeleteResult, AsyncStream<BackupInterfaces.BackupProgress>) {
        let parameters = SnapshotDeleteParameters(
            snapshotID: snapshotID,
            pruneAfterDelete: pruneAfterDelete
        )
        
        return try await managementService.deleteSnapshot(
            parameters: parameters,
            progressReporter: progressReporter,
            cancellationToken: cancellationToken
        )
    }
    
    /**
     * Copies a snapshot to another repository.
     *
     * - Parameters:
     *   - snapshotID: Snapshot ID to copy
     *   - targetRepositoryID: Target repository ID
     *   - progressReporter: Optional reporter for tracking operation progress
     *   - cancellationToken: Optional token for cancelling the operation
     * - Returns: ID of the new snapshot
     * - Throws: BackupError if the operation fails
     */
    public func copySnapshot(
        snapshotID: String,
        targetRepositoryID: String,
        progressReporter: BackupProgressReporter?,
        cancellationToken: CancellationToken?
    ) async throws -> (String, AsyncStream<BackupInterfaces.BackupProgress>) {
        return try await managementService.copySnapshot(
            snapshotID: snapshotID,
            targetRepositoryID: targetRepositoryID,
            progressReporter: progressReporter,
            cancellationToken: cancellationToken
        )
    }
    
    /**
     * Searches for files within a snapshot that match a specified pattern.
     *
     * - Parameters:
     *   - snapshotID: ID of the snapshot to search
     *   - pattern: Pattern to match against file names
     *   - path: Path to search within
     *   - caseSensitive: Whether to use case-sensitive matching
     * - Returns: Array of file entries matching the pattern
     * - Throws: `BackupError` if the search operation fails
     */
    public func findFiles(
        snapshotID: String,
        pattern: String?,
        path: String?,
        caseSensitive: Bool
    ) async throws -> [SnapshotFileEntry] {
        return try await operationsService.findFiles(
            snapshotID: snapshotID,
            pattern: pattern,
            path: path,
            caseSensitive: caseSensitive,
            progressReporter: nil,
            cancellationToken: nil
        )
    }
    
    /**
     * Restores files from a snapshot to a target location.
     *
     * - Parameters:
     *   - snapshotID: ID of the snapshot to restore from
     *   - targetPath: Path where files should be restored
     *   - includePattern: Optional pattern of files to include
     *   - excludePattern: Optional pattern of files to exclude
     *   - progressReporter: Optional reporter for tracking operation progress
     *   - cancellationToken: Optional token for cancelling the operation
     * - Throws: BackupError if the operation fails
     */
    public func restoreFiles(
        snapshotID: String,
        targetPath: URL,
        includePattern: String?,
        excludePattern: String?,
        progressReporter: BackupProgressReporter?,
        cancellationToken: CancellationToken?
    ) async throws {
        // Validate target path for safety
        try restoreService.validateRestoreTarget(targetPath)
        
        let parameters = SnapshotRestoreParameters(
            snapshotID: snapshotID,
            targetPath: targetPath,
            includePattern: includePattern,
            excludePattern: excludePattern
        )
        
        try await restoreService.restoreFiles(
            parameters: parameters,
            progressReporter: progressReporter,
            cancellationToken: cancellationToken
        )
    }
    
    /**
     * Locks a snapshot to prevent deletion.
     *
     * - Parameters:
     *   - snapshotID: Snapshot ID to lock
     *   - progressReporter: Optional reporter for tracking operation progress
     *   - cancellationToken: Optional token for cancelling the operation
     * - Throws: BackupError if locking fails
     */
    public func lockSnapshot(
        snapshotID: String,
        progressReporter: BackupProgressReporter?,
        cancellationToken: CancellationToken?
    ) async throws {
        try await managementService.lockSnapshot(
            snapshotID: snapshotID,
            progressReporter: progressReporter,
            cancellationToken: cancellationToken
        )
    }
    
    /**
     * Unlocks a previously locked snapshot.
     *
     * - Parameters:
     *   - snapshotID: Snapshot ID to unlock
     *   - progressReporter: Optional reporter for tracking operation progress
     *   - cancellationToken: Optional token for cancelling the operation
     * - Throws: BackupError if unlocking fails
     */
    public func unlockSnapshot(
        snapshotID: String,
        progressReporter: BackupProgressReporter?,
        cancellationToken: CancellationToken?
    ) async throws {
        try await managementService.unlockSnapshot(
            snapshotID: snapshotID,
            progressReporter: progressReporter,
            cancellationToken: cancellationToken
        )
    }
    
    /**
     * Verifies a snapshot's integrity.
     *
     * - Parameters:
     *   - snapshotID: ID of the snapshot to verify
     *   - level: The depth of verification to perform
     * - Returns: Verification result and a progress stream
     * - Throws: `BackupError` if verification fails
     */
    public func verifySnapshot(
        snapshotID: String,
        level: VerificationLevel
    ) async throws -> (VerificationResult, AsyncStream<BackupInterfaces.BackupProgress>) {
        // Create parameters object
        let parameters = SnapshotVerifyParameters(
            snapshotID: snapshotID,
            level: level
        )
        
        // Create progress reporter
        let progressReporter = AsyncProgressReporter()
        let progressStream = progressReporter.createProgressStream()
        
        // Create progress adapter
        let progressAdapter = ProgressReporterAdapter(reporter: progressReporter)
        
        // Execute the operation
        let result = try await operationsService.verifySnapshot(
            parameters: parameters,
            progressReporter: progressAdapter,
            cancellationToken: nil
        )
        
        return (result, progressStream)
    }
    
    /**
     * Verifies a snapshot's integrity.
     *
     * - Parameters:
     *   - snapshotID: ID of the snapshot to verify
     * - Returns: Verification result and a progress stream
     * - Throws: `BackupError` if verification fails
     */
    public func verifySnapshot(
        snapshotID: String
    ) async throws -> (VerificationResult, AsyncStream<BackupInterfaces.BackupProgress>) {
        // Create parameters object
        let parameters = SnapshotVerifyParameters(
            snapshotID: snapshotID
        )
        
        // Create progress reporter
        let progressReporter = AsyncProgressReporter()
        let progressStream = progressReporter.createProgressStream()
        
        // Create progress adapter
        let progressAdapter = ProgressReporterAdapter(reporter: progressReporter)
        
        // Execute the operation
        let result = try await operationsService.verifySnapshot(
            parameters: parameters,
            progressReporter: progressAdapter,
            cancellationToken: nil
        )
        
        return (result, progressStream)
    }
    
    /**
     * Exports a snapshot to an external location.
     *
     * - Parameters:
     *   - snapshotID: The ID of the snapshot to export
     *   - destination: The destination path for the export
     *   - format: The format for the exported snapshot
     * - Returns: Export result and a progress stream
     * - Throws: `BackupError` if export fails
     */
    public func exportSnapshot(
        snapshotID: String,
        destination: URL,
        format: ExportFormat
    ) async throws -> (ExportResult, AsyncStream<BackupInterfaces.BackupProgress>) {
        // Create parameters object
        let parameters = SnapshotExportParameters(
            snapshotID: snapshotID,
            destination: destination,
            format: format
        )
        
        // Create progress reporter
        let progressReporter = AsyncProgressReporter()
        let progressStream = progressReporter.createProgressStream()
        
        // Create progress adapter
        let progressAdapter = ProgressReporterAdapter(reporter: progressReporter)
        
        // Execute the operation
        let result = try await operationsService.exportSnapshot(
            parameters: parameters,
            progressReporter: progressAdapter,
            cancellationToken: nil
        )
        
        return (result, progressStream)
    }
    
    /**
     * Imports a snapshot from an external location.
     *
     * - Parameters:
     *   - source: The source path for the import
     *   - repositoryID: The repository ID to import to
     *   - format: The format of the snapshot to import
     * - Returns: Import result and a progress stream
     * - Throws: `BackupError` if import fails
     */
    public func importSnapshot(
        source: URL,
        repositoryID: String,
        format: ImportFormat
    ) async throws -> (ImportResult, AsyncStream<BackupInterfaces.BackupProgress>) {
        // Create parameters object
        let parameters = SnapshotImportParameters(
            source: source,
            repositoryID: repositoryID,
            format: format
        )
        
        // Create progress reporter
        let progressReporter = AsyncProgressReporter()
        let progressStream = progressReporter.createProgressStream()
        
        // Create progress adapter
        let progressAdapter = ProgressReporterAdapter(reporter: progressReporter)
        
        // Execute the operation
        let result = try await operationsService.importSnapshot(
            parameters: parameters,
            progressReporter: progressAdapter,
            cancellationToken: nil
        )
        
        return (result, progressStream)
    }
    
    /**
     * Copies a snapshot to another repository.
     *
     * - Parameters:
     *   - snapshotID: The ID of the snapshot to copy
     *   - targetRepositoryID: The target repository ID
     * - Returns: Copy result and a progress stream
     * - Throws: `BackupError` if copy fails
     */
    public func copySnapshot(
        snapshotID: String,
        targetRepositoryID: String
    ) async throws -> (CopyResult, AsyncStream<BackupInterfaces.BackupProgress>) {
        // Create parameters object
        let parameters = SnapshotCopyParameters(
            snapshotID: snapshotID,
            targetRepositoryID: targetRepositoryID
        )
        
        // Create progress reporter
        let progressReporter = AsyncProgressReporter()
        let progressStream = progressReporter.createProgressStream()
        
        // Create progress adapter
        let progressAdapter = ProgressReporterAdapter(reporter: progressReporter)
        
        // Execute the operation
        let result = try await operationsService.copySnapshot(
            parameters: parameters,
            progressReporter: progressAdapter,
            cancellationToken: nil
        )
        
        return (result, progressStream)
    }
    
    /**
     * Gets the content of a file within a snapshot.
     *
     * - Parameters:
     *   - snapshotID: The ID of the snapshot containing the file
     *   - path: The path to the file
     * - Returns: File content
     * - Throws: `BackupError` if the file cannot be accessed
     */
    public func getFileContent(
        snapshotID: String,
        path: URL
    ) async throws -> FileContent {
        // Create parameters object
        let parameters = SnapshotFileContentParameters(
            snapshotID: snapshotID,
            path: path.path
        )
        
        // Execute the operation
        return try await operationsService.getFileContent(
            parameters: parameters,
            cancellationToken: nil
        )
    }
    
    /**
     * Lists files within a directory in a snapshot.
     *
     * - Parameters:
     *   - snapshotID: ID of the snapshot
     *   - path: Path within the snapshot to list
     *   - recursive: Whether to include files in subdirectories
     * - Returns: Array of file information
     * - Throws: `BackupError` if listing fails
     */
    public func listFiles(
        snapshotID: String,
        path: URL,
        recursive: Bool
    ) async throws -> [FileInfo] {
        // Create parameters object
        let parameters = SnapshotListFilesParameters(
            snapshotID: snapshotID,
            path: path.path,
            recursive: recursive
        )
        
        // Execute the operation
        return try await operationsService.listFiles(
            parameters: parameters,
            progressReporter: nil,
            cancellationToken: nil
        )
    }
    
    // MARK: - Metrics and Diagnostics
    
    /**
     * Gets metrics about snapshot operations.
     *
     * - Returns: Dictionary with metrics information
     */
    public func getMetrics() async -> [String: Any] {
        await metricsCollector.getMetricsSummary()
    }
    
    /**
     * Gets success rates for different operations.
     *
     * - Returns: Dictionary mapping operation types to success rates (0-1)
     */
    public func getSuccessRates() async -> [String: Double] {
        await metricsCollector.getSuccessRates()
    }
    
    /**
     * Resets all collected metrics.
     */
    public func resetMetrics() async {
        await metricsCollector.resetMetrics()
    }
}

/**
 * Adapter to convert AsyncProgressReporter to BackupProgressReporter.
 */
private final class ProgressReporterAdapter: BackupProgressReporter {
    private let reporter: AsyncProgressReporter
    
    init(reporter: AsyncProgressReporter) {
        self.reporter = reporter
    }
    
    func reportProgress(_ progress: BackupInterfaces.BackupProgress, for operation: BackupOperation) async {
        reporter.reportProgress(progress)
    }
    
    func reportCancellation(for operation: BackupOperation) async {
        reporter.reportCancellation()
    }
    
    func reportFailure(_ error: Error, for operation: BackupOperation) async {
        reporter.reportFailure(error)
    }
    
    func reportCompletion(for operation: BackupOperation) async {
        reporter.reportCompletion()
    }
}

// AsyncProgressReporter has been moved to a dedicated file
