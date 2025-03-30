import Foundation
import BackupInterfaces
import LoggingInterfaces
import LoggingTypes
import ResticInterfaces
import ResticServices

/**
 * Provides core snapshot operation capabilities with privacy-aware logging and error handling.
 *
 * This actor-based implementation follows the Alpha Dot Five architecture principles:
 * - Uses Swift actors for thread safety
 * - Implements privacy-aware error handling and logging
 * - Structured concurrency with async/await
 * - Type-safe interfaces
 */
public actor SnapshotOperationsService {
    /// Restic service for backend operations
    private let resticService: ResticServiceProtocol
    
    /// Factory for creating Restic commands
    private let commandFactory: ResticCommandFactory
    
    /// Parser for Restic command results
    private let resultParser: SnapshotResultParser
    
    /// Executor for operations
    private let operationExecutor: SnapshotOperationExecutor
    
    /**
     * Creates a new snapshot operations service.
     *
     * - Parameters:
     *   - resticService: Service for Restic operations
     *   - operationExecutor: Executor for operations
     */
    public init(
        resticService: ResticServiceProtocol,
        operationExecutor: SnapshotOperationExecutor
    ) {
        self.resticService = resticService
        self.operationExecutor = operationExecutor
        self.commandFactory = ResticCommandFactory()
        self.resultParser = SnapshotResultParser()
    }
    
    /**
     * Retrieves a list of snapshots with optional filtering.
     *
     * - Parameters:
     *   - parameters: Parameters for the list operation
     *   - progressReporter: Optional reporter for tracking operation progress
     *   - cancellationToken: Optional token for cancelling the operation
     * - Returns: Array of matching snapshots
     * - Throws: BackupError if the operation fails
     */
    public func listSnapshots(
        parameters: SnapshotListParameters,
        progressReporter: BackupProgressReporter?,
        cancellationToken: AlphaDotFiveCancellationToken?
    ) async throws -> [BackupSnapshot] {
        return try await operationExecutor.execute(
            parameters: parameters,
            progressReporter: progressReporter,
            cancellationToken: cancellationToken,
            operation: { params, reporter, token in
                // Create command
                let command = try self.commandFactory.createListCommand(
                    repositoryID: params.repositoryID,
                    tags: params.tags,
                    before: params.before,
                    after: params.after,
                    path: params.path,
                    limit: params.limit
                )
                
                // Update progress
                if let progressReporter = reporter {
                    progressReporter.reportProgress(
                        BackupProgress(
                            phase: .processing,
                            percentComplete: 0.3
                        ),
                        for: .listSnapshots
                    )
                }
                
                // Execute command and parse result
                let output = try await self.resticService.execute(command)
                return try self.resultParser.parseSnapshots(output)
            }
        )
    }
    
    /**
     * Retrieves a specific snapshot by ID.
     *
     * - Parameters:
     *   - parameters: Parameters for the operation
     *   - progressReporter: Optional reporter for tracking operation progress
     *   - cancellationToken: Optional token for cancelling the operation
     * - Returns: The snapshot details
     * - Throws: BackupError if the operation fails
     */
    public func getSnapshot(
        parameters: SnapshotGetParameters,
        progressReporter: BackupProgressReporter?,
        cancellationToken: AlphaDotFiveCancellationToken?
    ) async throws -> BackupSnapshot {
        return try await operationExecutor.execute(
            parameters: parameters,
            progressReporter: progressReporter,
            cancellationToken: cancellationToken,
            operation: { params, reporter, token in
                // Create command
                let command = try self.commandFactory.createSnapshotDetailsCommand(
                    snapshotID: params.snapshotID,
                    includeFileStatistics: false
                )
                
                // Update progress
                if let progressReporter = reporter {
                    progressReporter.reportProgress(
                        BackupProgress(
                            phase: .processing,
                            percentComplete: 0.3
                        ),
                        for: .getSnapshotDetails
                    )
                }
                
                // Execute command and parse result
                let output = try await self.resticService.execute(command)
                return try self.resultParser.parseSnapshot(output)
            }
        )
    }
    
    /**
     * Compares two snapshots to identify differences.
     *
     * - Parameters:
     *   - parameters: Parameters for the comparison
     *   - progressReporter: Optional reporter for tracking operation progress
     *   - cancellationToken: Optional token for cancelling the operation
     * - Returns: Comparison result with differences
     * - Throws: BackupError if the operation fails
     */
    public func compareSnapshots(
        parameters: SnapshotCompareParameters,
        progressReporter: BackupProgressReporter?,
        cancellationToken: AlphaDotFiveCancellationToken?
    ) async throws -> SnapshotComparisonResult {
        return try await operationExecutor.execute(
            parameters: parameters,
            progressReporter: progressReporter,
            cancellationToken: cancellationToken,
            operation: { params, reporter, token in
                // Create command
                let command = try self.commandFactory.createCompareCommand(
                    snapshotID1: params.snapshotID1,
                    snapshotID2: params.snapshotID2,
                    path: params.path?.path
                )
                
                // Update progress
                if let progressReporter = reporter {
                    progressReporter.reportProgress(
                        BackupProgress(
                            phase: .processing,
                            percentComplete: 0.3
                        ),
                        for: .compareSnapshots
                    )
                }
                
                // Execute command and parse result
                let output = try await self.resticService.execute(command)
                return try self.resultParser.parseComparison(output)
            }
        )
    }
    
    /**
     * Finds files in a snapshot matching a pattern.
     *
     * - Parameters:
     *   - snapshotID: ID of the snapshot to search
     *   - pattern: Pattern to search for
     *   - caseSensitive: Whether the search is case-sensitive
     *   - progressReporter: Optional reporter for tracking operation progress
     *   - cancellationToken: Optional token for cancelling the operation
     * - Returns: Array of matching files
     * - Throws: BackupError if the operation fails
     */
    public func findFiles(
        snapshotID: String,
        pattern: String,
        caseSensitive: Bool,
        progressReporter: BackupProgressReporter?,
        cancellationToken: AlphaDotFiveCancellationToken?
    ) async throws -> [BackupFile] {
        // Create parameters as a struct to use with our executor
        struct FindFilesParameters: SnapshotOperationParameters {
            let snapshotID: String
            let pattern: String
            let caseSensitive: Bool
            let operationType: SnapshotOperationType = .find
            
            func validate() throws {
                if snapshotID.isEmpty {
                    throw BackupError.invalidConfiguration(details: "Snapshot ID cannot be empty")
                }
                if pattern.isEmpty {
                    throw BackupError.invalidConfiguration(details: "Search pattern cannot be empty")
                }
            }
            
            func createLogContext() -> SnapshotLogContextAdapter {
                let context = SnapshotLogContextAdapter(
                    snapshotID: snapshotID,
                    operation: operationType.rawValue
                )
                
                return context
                    .with(key: "pattern", value: pattern, privacy: LoggingInterfaces.LogPrivacyLevel.public)
                    .with(key: "caseSensitive", value: String(caseSensitive), privacy: LoggingInterfaces.LogPrivacyLevel.public)
            }
        }
        
        let parameters = FindFilesParameters(
            snapshotID: snapshotID,
            pattern: pattern,
            caseSensitive: caseSensitive
        )
        
        return try await operationExecutor.execute(
            parameters: parameters,
            progressReporter: progressReporter,
            cancellationToken: cancellationToken
        ) {
            // Create command
            let command = try self.commandFactory.createFindCommand(
                snapshotID: snapshotID,
                pattern: pattern,
                caseSensitive: caseSensitive
            )
            
            // Update progress
            if let reporter = progressReporter {
                await reporter.reportProgress(
                    BackupProgress(
                        phase: .processing,
                        percentComplete: 0.3,
                        message: "Searching for files"
                    ),
                    for: .findFiles
                )
            }
            
            // Execute command
            return try await self.operationExecutor.executeResticCommand(
                command: command,
                parser: self.resultParser.parseFiles,
                resticService: self.resticService,
                cancellationToken: cancellationToken
            )
        }
    }
    
    /**
     * Verifies the integrity of a snapshot.
     *
     * - Parameters:
     *   - parameters: Parameters for the verification
     *   - progressReporter: Optional reporter for tracking operation progress
     *   - cancellationToken: Optional token for cancelling the operation
     * - Returns: Result of the verification
     * - Throws: BackupError if the operation fails
     */
    public func verifySnapshot(
        parameters: SnapshotVerifyParameters,
        progressReporter: BackupProgressReporter?,
        cancellationToken: AlphaDotFiveCancellationToken?
    ) async throws -> VerificationResult {
        return try await operationExecutor.execute(
            parameters: parameters,
            progressReporter: progressReporter,
            cancellationToken: cancellationToken,
            operation: { params, reporter, token in
                // Create command to check repository
                let checkCommand = ResticCommandImpl(arguments: ["check", "--verbose", "--json"])
                
                // Update progress
                if let progressReporter = reporter {
                    await progressReporter.reportProgress(
                        BackupProgress(
                            phase: .processing,
                            percentComplete: 0.3
                        ),
                        for: .verifySnapshot
                    )
                }
                
                // Execute repository check
                let repositoryCheckOutput = try await self.resticService.execute(checkCommand)
                
                // Create command to check data integrity
                let dataCommand = ResticCommandImpl(arguments: [
                    "check",
                    "--with-cache",
                    "--read-data",
                    "--snapshot", params.snapshotID,
                    "--json"
                ])
                
                // Update progress
                if let progressReporter = reporter {
                    await progressReporter.reportProgress(
                        BackupProgress(
                            phase: .processing,
                            percentComplete: 0.6
                        ),
                        for: .verifySnapshot
                    )
                }
                
                // Execute data integrity check
                let dataIntegrityOutput = try await self.resticService.execute(dataCommand)
                
                // Update progress
                if let progressReporter = reporter {
                    await progressReporter.reportProgress(
                        BackupProgress(
                            phase: .completed,
                            percentComplete: 1.0
                        ),
                        for: .verifySnapshot
                    )
                }
                
                // Parse results
                return try self.resultParser.parseVerificationResult(
                    repositoryCheck: repositoryCheckOutput,
                    dataIntegrityCheck: dataIntegrityOutput
                )
            }
        )
    }
}
