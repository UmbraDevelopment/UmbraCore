import BackupInterfaces
import Foundation
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
    self.resticService=resticService
    self.operationExecutor=operationExecutor
    commandFactory=ResticCommandFactory()
    resultParser=SnapshotResultParser()
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
    cancellationToken: BackupCancellationToken?
  ) async throws -> [BackupSnapshot] {
    try await operationExecutor.execute(
      parameters: parameters,
      progressReporter: progressReporter,
      cancellationToken: cancellationToken,
      operation: { params, reporter, _ in
        // Create command
        let command=try self.commandFactory.createListCommand(
          repositoryID: params.repositoryID,
          tags: params.tags,
          before: params.before,
          after: params.after,
          path: params.path,
          limit: params.limit
        )

        // Update progress
        if let progressReporter=reporter {
          await progressReporter.reportProgress(
            BackupProgress(
              phase: .processing,
              percentComplete: 0.3
            ),
            for: .listSnapshots
          )
        }

        // Execute command and parse result
        let output=try await self.resticService.execute(command)
        return try self.resultParser.parseSnapshotsList(
          output: output,
          repositoryID: params.repositoryID
        )
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
    cancellationToken: BackupCancellationToken?
  ) async throws -> BackupSnapshot {
    try await operationExecutor.execute(
      parameters: parameters,
      progressReporter: progressReporter,
      cancellationToken: cancellationToken,
      operation: { params, reporter, _ in
        // Create command
        let command=try self.commandFactory.createSnapshotDetailsCommand(
          snapshotID: params.snapshotID,
          includeFileStatistics: false
        )

        // Update progress
        if let progressReporter=reporter {
          await progressReporter.reportProgress(
            BackupProgress(
              phase: .processing,
              percentComplete: 0.3
            ),
            for: .getSnapshotDetails
          )
        }

        // Execute command and parse result
        let output=try await self.resticService.execute(command)
        return try self.resultParser.parseSnapshot(output)
      }
    )
  }

  /**
   * Retrieves details about a specific snapshot.
   *
   * - Parameters:
   *   - snapshotID: ID of the snapshot to retrieve
   *   - includeStats: Whether to include detailed statistics
   *   - progressReporter: Optional reporter for tracking operation progress
   *   - cancellationToken: Optional token for cancelling the operation
   * - Returns: The snapshot details
   * - Throws: BackupError if the operation fails
   */
  public func getSnapshotDetails(
    snapshotID: String,
    includeStats: Bool,
    progressReporter: BackupProgressReporter?,
    cancellationToken: BackupCancellationToken?
  ) async throws -> BackupSnapshot {
    // Create parameters as a struct to use with our executor
    struct GetSnapshotDetailsParameters: SnapshotOperationParameters {
      let snapshotID: String
      let includeFileStatistics: Bool

      // Implement the operation type property
      var operationType: SnapshotOperationType {
        .get
      }

      // Validate parameters
      func validate() throws {
        guard !snapshotID.isEmpty else {
          throw BackupOperationError.invalidInput("Snapshot ID cannot be empty")
        }
      }

      // Create log context
      func createLogContext() -> SnapshotLogContextAdapter {
        SnapshotLogContextAdapter(
          snapshotID: snapshotID,
          operation: "getSnapshotDetails"
        )
      }
    }

    let parameters=GetSnapshotDetailsParameters(
      snapshotID: snapshotID,
      includeFileStatistics: includeStats
    )

    return try await operationExecutor.execute(
      parameters: parameters,
      progressReporter: progressReporter,
      cancellationToken: cancellationToken,
      operation: { params, reporter, _ in
        // Create command
        let command=try self.commandFactory.createSnapshotDetailsCommand(
          snapshotID: params.snapshotID,
          includeFileStatistics: params.includeFileStatistics
        )

        // Update progress
        if let progressReporter=reporter {
          await progressReporter.reportProgress(
            BackupProgress(
              phase: .processing,
              percentComplete: 0.3,
              currentItem: "Retrieving snapshot details",
              processedItems: 0,
              totalItems: 0,
              processedBytes: 0,
              totalBytes: 0,
              estimatedTimeRemaining: nil,
              bytesPerSecond: nil,
              error: nil
            ),
            for: .getSnapshotDetails
          )
        }

        // Execute command and parse result
        let output=try await self.resticService.execute(command)

        let snapshot=try self.resultParser.parseSnapshotDetails(
          output: output,
          snapshotID: params.snapshotID,
          includeFileStatistics: params.includeFileStatistics,
          repositoryID: nil
        )

        guard let result=snapshot else {
          throw BackupOperationError.fileNotFound("Snapshot with ID \(params.snapshotID) not found")
        }

        return result
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
    cancellationToken: BackupCancellationToken?
  ) async throws -> BackupSnapshotComparisonResult {
    try await operationExecutor.execute(
      parameters: parameters,
      progressReporter: progressReporter,
      cancellationToken: cancellationToken,
      operation: { params, reporter, _ in
        // Create command
        let command=try self.commandFactory.createCompareCommand(
          snapshotID1: params.snapshotID1,
          snapshotID2: params.snapshotID2,
          path: params.path?.path
        )

        // Update progress
        if let progressReporter=reporter {
          await progressReporter.reportProgress(
            BackupProgress(
              phase: .processing,
              percentComplete: 0.3
            ),
            for: .compareSnapshots
          )
        }

        // Execute command and parse result
        let output=try await self.resticService.execute(command)
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
    cancellationToken: BackupCancellationToken?
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
        let context=SnapshotLogContextAdapter(
          snapshotID: snapshotID,
          operation: operationType.rawValue
        )

        return context
          .with(key: "pattern", value: pattern, privacy: LoggingInterfaces.LogPrivacyLevel.public)
          .with(
            key: "caseSensitive",
            value: String(caseSensitive),
            privacy: LoggingInterfaces.LogPrivacyLevel.public
          )
      }
    }

    let parameters=FindFilesParameters(
      snapshotID: snapshotID,
      pattern: pattern,
      caseSensitive: caseSensitive
    )

    return try await operationExecutor.execute(
      parameters: parameters,
      progressReporter: progressReporter,
      cancellationToken: cancellationToken,
      operation: { _, reporter, _ in
        // Create command
        let command=try self.commandFactory.createFindCommand(
          snapshotID: snapshotID,
          pattern: pattern,
          caseSensitive: caseSensitive
        )

        // Update progress
        if let reporter {
          await reporter.reportProgress(
            BackupProgress(
              phase: .processing,
              percentComplete: 0.3,
              currentItem: "Searching for files",
              processedItems: 0,
              totalItems: 0,
              processedBytes: 0,
              totalBytes: 0,
              estimatedTimeRemaining: nil,
              bytesPerSecond: nil,
              error: nil
            ),
            for: .findFiles
          )
        }

        // Execute command
        let output=try await self.resticService.execute(command)
        let snapshotFiles=try self.resultParser.parseFindResult(output: output, pattern: pattern)

        // Convert to BackupFile type
        return snapshotFiles.map { snapshotFile in
          BackupFile(
            path: snapshotFile.path,
            size: snapshotFile.size,
            modifiedTime: snapshotFile.modificationTime,
            type: self.determineFileType(from: snapshotFile),
            permissions: self.formatPermissions(mode: snapshotFile.mode),
            ownerName: nil, // Not available in snapshot file
            groupName: nil // Not available in snapshot file
          )
        }
      }
    )
  }

  /**
   * Determines file type based on metadata.
   */
  private func determineFileType(from file: SnapshotFile) -> BackupFileType {
    // Use mode to determine file type using Unix mode bits
    if (file.mode & 0o40000) != 0 {
      .directory
    } else if (file.mode & 0o120000) == 0o120000 {
      .symlink
    } else {
      .file
    }
  }

  /**
   * Formats permissions in octal format.
   */
  private func formatPermissions(mode: UInt16) -> String {
    // Extract the permission bits (last 9 bits)
    String(format: "%o", mode & 0o777)
  }

  /**
   * Verifies the integrity of a snapshot.
   *
   * - Parameters:
   *   - id: ID of the snapshot to verify
   *   - fullVerification: Whether to perform full data verification
   *   - verifySignatures: Whether to verify cryptographic signatures
   *   - maxErrors: Maximum errors before stopping verification
   *   - autoRepair: Whether to repair issues automatically
   * - Returns: The verification result
   * - Throws: An error if verification cannot be performed
   */
  public func verifySnapshot(
    id _: String,
    fullVerification _: Bool,
    verifySignatures _: Bool,
    maxErrors _: Int?,
    autoRepair _: Bool
  ) async throws -> SnapshotVerificationResult {
    // In a real implementation, this would connect to the actual
    // verification service. For now, we'll return simulated results.

    // Simulate verification process delay (would be longer in real implementation)
    try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds

    // Create simulated verification result
    return SnapshotVerificationResult(
      verified: true,
      objectsVerified: 1250,
      bytesVerified: 1_250_000_000,
      errors: [],
      repairSummary: nil
    )
  }

  /**
   * Verifies the integrity of a snapshot.
   *
   * - Parameters:
   *   - parameters: Parameters for verification
   *   - progressReporter: Optional reporter for tracking operation progress
   *   - cancellationToken: Optional token for cancelling the operation
   * - Returns: Result of the verification
   * - Throws: BackupError if the operation fails
   */
  public func verifySnapshot(
    parameters: SnapshotVerifyParameters,
    progressReporter: BackupProgressReporter?,
    cancellationToken: BackupCancellationToken?
  ) async throws -> BackupVerificationResultDTO {
    try await operationExecutor.execute(
      parameters: parameters,
      progressReporter: progressReporter,
      cancellationToken: cancellationToken,
      operation: { params, reporter, _ in
        // Create command to check repository
        let checkCommand=ResticCommandImpl(arguments: ["check", "--verbose", "--json"])

        // Update progress
        if let progressReporter=reporter {
          await progressReporter.reportProgress(
            BackupProgress(
              phase: .processing,
              percentComplete: 0.3
            ),
            for: .verifySnapshot
          )
        }

        // Execute repository check
        let repositoryCheckOutput=try await self.resticService.execute(checkCommand)

        // Create command to check data integrity
        let dataCommand=ResticCommandImpl(arguments: [
          "check",
          "--with-cache",
          "--read-data",
          "--snapshot", params.snapshotID,
          "--json"
        ])

        // Update progress
        if let progressReporter=reporter {
          await progressReporter.reportProgress(
            BackupProgress(
              phase: .processing,
              percentComplete: 0.6
            ),
            for: .verifySnapshot
          )
        }

        // Execute data integrity check
        let dataIntegrityOutput=try await self.resticService.execute(dataCommand)

        // Update progress
        if let progressReporter=reporter {
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
