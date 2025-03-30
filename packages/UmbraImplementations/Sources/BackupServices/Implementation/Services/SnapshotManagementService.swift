import Foundation
import BackupInterfaces
import LoggingInterfaces
import LoggingTypes
import ResticInterfaces
import ResticServices

/**
 * Provides snapshot management capabilities such as updating, deleting, and copying snapshots.
 *
 * This actor-based implementation follows the Alpha Dot Five architecture principles:
 * - Uses Swift actors for thread safety
 * - Implements privacy-aware error handling and logging
 * - Structured concurrency with async/await
 * - Type-safe interfaces
 */
public actor SnapshotManagementService {
    /// Restic service for backend operations
    private let resticService: ResticServiceProtocol
    
    /// Factory for creating Restic commands
    private let commandFactory: ResticCommandFactory
    
    /// Parser for Restic command results
    private let resultParser: SnapshotResultParser
    
    /// Executor for operations
    private let operationExecutor: SnapshotOperationExecutor
    
    /// Operations service for getting snapshot details
    private let operationsService: SnapshotOperationsService
    
    /**
     * Creates a new snapshot management service.
     *
     * - Parameters:
     *   - resticService: Service for Restic operations
     *   - operationExecutor: Executor for operations
     *   - operationsService: Service for basic snapshot operations
     */
    public init(
        resticService: ResticServiceProtocol,
        operationExecutor: SnapshotOperationExecutor,
        operationsService: SnapshotOperationsService
    ) {
        self.resticService = resticService
        self.operationExecutor = operationExecutor
        self.operationsService = operationsService
        self.commandFactory = ResticCommandFactory()
        self.resultParser = SnapshotResultParser()
    }
    
    /**
     * Updates the tags for a snapshot.
     *
     * - Parameters:
     *   - parameters: Parameters for the update tags operation
     *   - progressReporter: Optional reporter for tracking operation progress
     *   - cancellationToken: Optional token for cancelling the operation
     * - Returns: The updated snapshot
     * - Throws: BackupError if the operation fails
     */
    public func updateSnapshotTags(
        parameters: SnapshotUpdateTagsParameters,
        progressReporter: BackupProgressReporter?,
        cancellationToken: AlphaDotFiveCancellationToken?
    ) async throws -> BackupSnapshot {
        return try await operationExecutor.execute(
            parameters: parameters,
            progressReporter: progressReporter,
            cancellationToken: cancellationToken
        ) {
            // Create command
            let command = try self.commandFactory.createUpdateTagsCommand(
                snapshotID: parameters.snapshotID,
                addTags: parameters.addTags,
                removeTags: parameters.removeTags
            )
            
            // Update progress
            if let reporter = progressReporter {
                let progress = BackupProgress(
                    phase: .processing,
                    percentComplete: 0.3,
                    currentItem: "Updating snapshot tags",
                    processedItems: 0,
                    totalItems: 0,
                    processedBytes: 0,
                    totalBytes: 0,
                    estimatedTimeRemaining: nil,
                    bytesPerSecond: nil,
                    error: nil
                )
                await reporter.reportProgress(progress, for: .updateSnapshot)
            }
            
            // Execute command
            _ = try await self.operationExecutor.executeResticCommand(
                command: command,
                parser: { _ in true },  // Parse result not needed - just check for success
                resticService: self.resticService,
                cancellationToken: cancellationToken
            )
            
            // Update progress
            if let reporter = progressReporter {
                let progress = BackupProgress(
                    phase: .processing,
                    percentComplete: 0.7,
                    currentItem: "Retrieving updated snapshot",
                    processedItems: 0,
                    totalItems: 0,
                    processedBytes: 0,
                    totalBytes: 0,
                    estimatedTimeRemaining: nil,
                    bytesPerSecond: nil,
                    error: nil
                )
                await reporter.reportProgress(progress, for: .updateSnapshot)
            }
            
            // Fetch the updated snapshot
            return try await self.operationsService.getSnapshot(
                parameters: SnapshotGetParameters(
                    snapshotID: parameters.snapshotID,
                    includeFileStatistics: false
                ),
                progressReporter: nil,  // Don't need progress for this sub-operation
                cancellationToken: cancellationToken
            )
        }
    }
    
    /**
     * Updates the description for a snapshot.
     *
     * - Parameters:
     *   - parameters: Parameters for the update description operation
     *   - progressReporter: Optional reporter for tracking operation progress
     *   - cancellationToken: Optional token for cancelling the operation
     * - Returns: The updated snapshot
     * - Throws: BackupError if the operation fails
     */
    public func updateSnapshotDescription(
        parameters: SnapshotUpdateDescriptionParameters,
        progressReporter: BackupProgressReporter?,
        cancellationToken: AlphaDotFiveCancellationToken?
    ) async throws -> BackupSnapshot {
        return try await operationExecutor.execute(
            parameters: parameters,
            progressReporter: progressReporter,
            cancellationToken: cancellationToken
        ) {
            // Create command
            let command = try self.commandFactory.createUpdateDescriptionCommand(
                snapshotID: parameters.snapshotID,
                description: parameters.description
            )
            
            // Update progress
            if let reporter = progressReporter {
                let progress = BackupProgress(
                    phase: .processing,
                    percentComplete: 0.3,
                    currentItem: "Updating snapshot description",
                    processedItems: 0,
                    totalItems: 0,
                    processedBytes: 0,
                    totalBytes: 0,
                    estimatedTimeRemaining: nil,
                    bytesPerSecond: nil,
                    error: nil
                )
                await reporter.reportProgress(progress, for: .updateSnapshot)
            }
            
            // Execute command
            _ = try await self.operationExecutor.executeResticCommand(
                command: command,
                parser: { _ in true },  // Parse result not needed - just check for success
                resticService: self.resticService,
                cancellationToken: cancellationToken
            )
            
            // Update progress
            if let reporter = progressReporter {
                let progress = BackupProgress(
                    phase: .processing,
                    percentComplete: 0.7,
                    currentItem: "Retrieving updated snapshot",
                    processedItems: 0,
                    totalItems: 0,
                    processedBytes: 0,
                    totalBytes: 0,
                    estimatedTimeRemaining: nil,
                    bytesPerSecond: nil,
                    error: nil
                )
                await reporter.reportProgress(progress, for: .updateSnapshot)
            }
            
            // Fetch the updated snapshot
            return try await self.operationsService.getSnapshot(
                parameters: SnapshotGetParameters(
                    snapshotID: parameters.snapshotID,
                    includeFileStatistics: false
                ),
                progressReporter: nil,  // Don't need progress for this sub-operation
                cancellationToken: cancellationToken
            )
        }
    }
    
    /**
     * Deletes a snapshot.
     *
     * - Parameters:
     *   - parameters: Parameters for the delete operation
     *   - progressReporter: Optional reporter for tracking operation progress
     *   - cancellationToken: Optional token for cancelling the operation
     * - Throws: BackupError if the operation fails
     */
    public func deleteSnapshot(
        parameters: SnapshotDeleteParameters,
        progressReporter: BackupProgressReporter?,
        cancellationToken: AlphaDotFiveCancellationToken?
    ) async throws {
        try await operationExecutor.execute(
            parameters: parameters,
            progressReporter: progressReporter,
            cancellationToken: cancellationToken,
            operation: { params, progressReporter, token in
                // Create command
                let command = try self.commandFactory.createDeleteCommand(
                    snapshotID: params.snapshotID,
                    pruneAfterDelete: params.pruneAfterDelete
                )
                
                // Update progress
                if let reporter = progressReporter {
                    let progress = BackupProgress(
                        phase: .processing,
                        percentComplete: 0.3,
                        currentItem: "Deleting snapshot",
                        processedItems: 0,
                        totalItems: 0,
                        processedBytes: 0,
                        totalBytes: 0,
                        estimatedTimeRemaining: nil,
                        bytesPerSecond: nil,
                        error: nil
                    )
                    await reporter.reportProgress(progress, for: .deleteBackup)
                }
                
                // Execute command
                let output = try await self.resticService.execute(command)
                
                // Verify success
                if output.contains("error") {
                    throw BackupError.snapshotFailure(
                        id: params.snapshotID, 
                        reason: "Failed to delete: \(output)"
                    )
                }
                
                // Return empty result as the method is void
                return ()
            }
        )
    }
    
    /**
     * Copies a snapshot to another repository.
     *
     * - Parameters:
     *   - parameters: Parameters for the copy operation
     *   - progressReporter: Optional reporter for tracking operation progress
     *   - cancellationToken: Optional token for cancelling the operation
     * - Returns: ID of the new snapshot
     * - Throws: BackupError if the operation fails
     */
    public func copySnapshot(
        parameters: SnapshotCopyParameters,
        progressReporter: BackupProgressReporter?,
        cancellationToken: AlphaDotFiveCancellationToken?
    ) async throws -> String {
        return try await operationExecutor.execute(
            parameters: parameters,
            progressReporter: progressReporter,
            cancellationToken: cancellationToken,
            operation: { params, progressReporter, token in
                // Create command
                let command = try self.commandFactory.createCopyCommand(
                    snapshotID: params.snapshotID,
                    targetRepositoryID: params.targetRepositoryID
                )
                
                // Update progress
                if let reporter = progressReporter {
                    let progress = BackupProgress(
                        phase: .processing,
                        percentComplete: 0.3,
                        currentItem: "Copying snapshot",
                        processedItems: 0,
                        totalItems: 0,
                        processedBytes: 0,
                        totalBytes: 0,
                        estimatedTimeRemaining: nil,
                        bytesPerSecond: nil,
                        error: nil
                    )
                    await reporter.reportProgress(progress, for: .compareSnapshots)
                }
                
                // Execute command
                let output = try await self.resticService.execute(command)
                
                // Parse the new snapshot ID from output
                // Sample successful output: "copy d3ef123 to f8ec456 successful"
                guard let newIDMatch = output.range(of: "to ([a-f0-9]+) successful", options: .regularExpression),
                      let idStart = output[newIDMatch].range(of: "to ")?.upperBound,
                      let idEnd = output[newIDMatch].range(of: " successful")?.lowerBound else {
                    throw BackupError.snapshotFailure(
                        id: params.snapshotID,
                        reason: "Failed to extract new snapshot ID from: \(output)"
                    )
                }
                
                let newID = String(output[idStart..<idEnd])
                return newID
            }
        )
    }
    
    /**
     * Locks a snapshot to prevent modifications.
     *
     * - Parameters:
     *   - parameters: Parameters for the lock operation
     *   - progressReporter: Optional reporter for tracking operation progress
     *   - cancellationToken: Optional token for cancelling the operation
     * - Throws: BackupError if the operation fails
     */
    public func lockSnapshot(
        parameters: SnapshotLockParameters,
        progressReporter: BackupProgressReporter?,
        cancellationToken: AlphaDotFiveCancellationToken?
    ) async throws {
        try await operationExecutor.execute(
            parameters: parameters,
            progressReporter: progressReporter,
            cancellationToken: cancellationToken,
            operation: { params, progressReporter, token in
                // Create a lock command
                let command = ResticCommandImpl(arguments: ["lock", "--id", params.snapshotID, "--json"])
                
                // Update progress
                if let reporter = progressReporter {
                    let progress = BackupProgress(
                        phase: .processing,
                        percentComplete: 0.3,
                        currentItem: "Locking snapshot",
                        processedItems: 0,
                        totalItems: 0,
                        processedBytes: 0,
                        totalBytes: 0,
                        estimatedTimeRemaining: nil,
                        bytesPerSecond: nil,
                        error: nil
                    )
                    await reporter.reportProgress(progress, for: .updateSnapshot)
                }
                
                // Execute command
                let output = try await self.resticService.execute(command)
                
                // Verify success
                if output.contains("error") {
                    throw BackupError.lockingError(reason: "Failed to lock snapshot: \(output)")
                }
                
                // Return empty result as the method is void
                return ()
            }
        )
    }
    
    /**
     * Unlocks a snapshot to allow modifications.
     *
     * - Parameters:
     *   - parameters: Parameters for the unlock operation
     *   - progressReporter: Optional reporter for tracking operation progress
     *   - cancellationToken: Optional token for cancelling the operation
     * - Throws: BackupError if the operation fails
     */
    public func unlockSnapshot(
        parameters: SnapshotUnlockParameters,
        progressReporter: BackupProgressReporter?,
        cancellationToken: AlphaDotFiveCancellationToken?
    ) async throws {
        try await operationExecutor.execute(
            parameters: parameters,
            progressReporter: progressReporter,
            cancellationToken: cancellationToken,
            operation: { params, progressReporter, token in
                // Create an unlock command
                let command = ResticCommandImpl(arguments: ["unlock", "--id", params.snapshotID, "--json"])
                
                // Update progress
                if let reporter = progressReporter {
                    let progress = BackupProgress(
                        phase: .processing,
                        percentComplete: 0.3,
                        currentItem: "Unlocking snapshot",
                        processedItems: 0,
                        totalItems: 0,
                        processedBytes: 0,
                        totalBytes: 0,
                        estimatedTimeRemaining: nil,
                        bytesPerSecond: nil,
                        error: nil
                    )
                    await reporter.reportProgress(progress, for: .updateSnapshot)
                }
                
                // Execute command
                let output = try await self.resticService.execute(command)
                
                // Verify success
                if output.contains("error") {
                    throw BackupError.lockingError(reason: "Failed to unlock snapshot: \(output)")
                }
                
                // Return empty result as the method is void
                return ()
            }
        )
    }
}
