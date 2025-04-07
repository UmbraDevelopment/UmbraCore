import BackupInterfaces
import Foundation
import LoggingTypes
import ResticInterfaces

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
    self.resticService=resticService
    self.repositoryInfo=repositoryInfo
    self.commandFactory=commandFactory
    self.resultParser=resultParser
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
    cancellationToken _: CancellationToken?
  ) async throws -> (BackupResult, AsyncStream<BackupInterfaces.BackupProgress>) {
    // Create the progress stream
    var progressContinuation: AsyncStream<BackupInterfaces.BackupProgress>.Continuation!
    let progressStream=AsyncStream<BackupInterfaces.BackupProgress> { continuation in
      progressContinuation=continuation
    }

    // Create a progress handler that forwards to both the reporter and the stream
    let progressHandler={ [progressReporter, progressContinuation] (
      progress: BackupInterfaces.BackupProgress
    ) async in
      if let reporter=progressReporter {
        await reporter.reportProgress(progress, for: .backup)
      }
      progressContinuation.yield(progress)

      // Check if we're done
      if case .completed=progress.phase {
        progressContinuation.finish()
      }
    }

    // Create the backup command
    var command=ResticCommandImpl(arguments: [
      "backup",
      "--json"
    ])

    // Add paths to include
    for path in parameters.sources {
      command.arguments.append(path.path)
    }

    // Add exclude paths
    if let excludePaths = parameters.excludePaths, !excludePaths.isEmpty {
      command.arguments.append("--exclude")
      command.arguments.append(contentsOf: excludePaths)
    }

    // Add tags
    if let tags = parameters.tags, !tags.isEmpty {
      command.arguments.append("--tag")
      command.arguments.append(contentsOf: tags)
    }

    // Run the command
    let output=try await resticService.execute(command)

    // Parse the result
    let backupResult=try resultParser.parseBackupResult(output: output)

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
    cancellationToken _: CancellationToken?
  ) async throws -> (RestoreResult, AsyncStream<BackupInterfaces.BackupProgress>) {
    // Create the progress stream
    var progressContinuation: AsyncStream<BackupInterfaces.BackupProgress>.Continuation!
    let progressStream=AsyncStream<BackupInterfaces.BackupProgress> { continuation in
      progressContinuation=continuation
    }

    // Create a progress handler that forwards to both the reporter and the stream
    let progressHandler={ [progressReporter, progressContinuation] (
      progress: BackupInterfaces.BackupProgress
    ) async in
      if let reporter=progressReporter {
        await reporter.reportProgress(progress, for: .restore)
      }
      progressContinuation.yield(progress)

      // Check if we're done
      if case .completed=progress.phase {
        progressContinuation.finish()
      }
    }

    // Create the restore command
    var command=ResticCommandImpl(arguments: [
      "restore",
      "--json",
      parameters.snapshotID,
      "--target",
      parameters.targetPath
    ])

    // Add include paths
    if let includePaths = parameters.includePaths, !includePaths.isEmpty {
      command.arguments.append("--include")
      command.arguments.append(contentsOf: includePaths)
    }

    // Add exclude paths
    if let excludePaths = parameters.excludePaths, !excludePaths.isEmpty {
      command.arguments.append("--exclude")
      command.arguments.append(contentsOf: excludePaths)
    }

    // Run the command
    let output=try await resticService.execute(command)

    // Parse the result
    let restoreResult=try resultParser.parseRestoreResult(output: output)

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
    cancellationToken _: CancellationToken?
  ) async throws -> [BackupSnapshot] {
    // Create the list command
    var command=ResticCommandImpl(arguments: [
      "snapshots",
      "--json"
    ])

    // Add tags
    if let tags = parameters.tags, !tags.isEmpty {
      command.arguments.append("--tag")
      command.arguments.append(contentsOf: tags)
    }

    // Add before
    if let before=parameters.before {
      command.arguments.append("--before")
      command.arguments.append(ISO8601DateFormatter().string(from: before))
    }

    // Add after
    if let after=parameters.after {
      command.arguments.append("--after")
      command.arguments.append(ISO8601DateFormatter().string(from: after))
    }

    // Add host
    if let host=parameters.host {
      command.arguments.append("--host")
      command.arguments.append(host)
    }

    // Add path
    if let path=parameters.path {
      command.arguments.append("--path")
      command.arguments.append(path.path)
    }

    // Run the command
    let output=try await resticService.execute(command)

    // Parse the result
    return try parseSnapshots(output: output)
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
    cancellationToken _: CancellationToken?
  ) async throws -> DeleteResult {
    // Create the delete command
    var command=ResticCommandImpl(arguments: [
      "forget",
      "--json",
      parameters.snapshotID
    ])

    // Run the command
    let output=try await resticService.execute(command)

    // Parse the result
    let deleteResult=try parseDeleteResult(output: output, snapshotID: parameters.snapshotID)

    // If pruning is requested, run that too
    if parameters.pruneAfterDelete {
      // Create the prune command
      var pruneCommand=ResticCommandImpl(arguments: [
        "prune",
        "--json"
      ])

      // Run the command
      _=try await resticService.execute(pruneCommand)
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
    path: String?=nil,
    pattern: String?=nil,
    progressReporter _: BackupProgressReporter?,
    cancellationToken _: CancellationToken?
  ) async throws -> [SnapshotFileEntry] {
    // Create the find command
    var command=ResticCommandImpl(arguments: [
      "find",
      snapshotID,
      "--json"
    ])

    // Add path if provided
    if let path {
      command.arguments.append(path)
    }

    // Add pattern if provided
    if let pattern {
      command.arguments.append(pattern)
    }

    // Run the command
    let output=try await resticService.execute(command)

    // Parse the result
    return try parseFileList(from: output)
  }

  /**
   * Verifies a backup snapshot.
   *
   * This method performs integrity verification on the specified backup snapshot,
   * checking for corruption, data consistency, and other potential issues.
   *
   * - Parameters:
   *   - parameters: Parameters for the verification operation
   *   - progressReporter: Reporter for tracking operation progress
   *   - cancellationToken: Token that can be used to cancel the operation
   * - Returns: A tuple containing the verification result and a progress stream
   * - Throws: An error if verification cannot be performed
   */
  public func verifyBackup(
    parameters: BackupVerifyParameters,
    progressReporter: BackupProgressReporter?,
    cancellationToken: ProgressCancellationToken?
  ) async throws -> (BackupVerificationResultDTO, AsyncStream<BackupProgressInfo>) {
    // Create a progress stream for reporting verification progress
    var progressContinuation: AsyncStream<BackupProgressInfo>.Continuation!
    let progressStream=AsyncStream<BackupProgressInfo> { continuation in
      progressContinuation=continuation
    }

    // Define a local function to report progress
    let reportProgress={ (progress: BackupProgressInfo) async in
      // Send progress to the continuation
      progressContinuation.yield(progress)

      // Forward to the progress reporter if provided
      if let reporter=progressReporter {
        await reporter.reportProgress(progress, for: .verifyBackup)
      }
    }

    // Start verification
    await reportProgress(BackupProgressInfo(
      phase: .initialising,
      percentComplete: 0.0,
      itemsProcessed: 0,
      totalItems: 0,
      bytesProcessed: 0,
      totalBytes: 0
    ))

    do {
      // Prepare verification parameters
      let snapshotID=parameters.snapshotID
      let verifyOptions=parameters.verifyOptions

      // Get snapshot to verify (latest if not specified)
      let startTime=Date()
      let snapshot=try await (
        snapshotID != nil ?
          snapshotService.getSnapshot(id: snapshotID!) :
          snapshotService.getLatestSnapshot()
      )

      // Early exit if no snapshot found
      guard let snapshot else {
        throw BackupOperationError.snapshotNotFound(
          "No snapshot found to verify" + (snapshotID != nil ? " with ID \(snapshotID!)" : "")
        )
      }

      // Log verification start
      logger.info(
        context: backupLogContext.withOperation("verifyBackup")
          .withPublic(key: "snapshotID", value: snapshot.id)
          .withPublic(
            key: "verify_mode",
            value: verifyOptions?.fullVerification == true ? "full" : "standard"
          ),
        message: "Starting backup verification for snapshot \(snapshot.id)"
      )

      // Scanning phase
      await reportProgress(BackupProgressInfo(
        phase: .scanning,
        percentComplete: 0.1,
        itemsProcessed: 0,
        totalItems: 0,
        bytesProcessed: 0,
        totalBytes: 0,
        estimatedTimeRemaining: nil,
        transferRate: nil,
        details: "Analysing snapshot structure"
      ))

      // Use snapshot service to perform actual verification
      let verificationResult=try await snapshotService.verifySnapshot(
        id: snapshot.id,
        fullVerification: verifyOptions?.fullVerification ?? false,
        verifySignatures: verifyOptions?.verifySignatures ?? true,
        maxErrors: verifyOptions?.maxErrors,
        autoRepair: verifyOptions?.autoRepair ?? false
      )

      // Report verification progress
      var percentComplete=0.2
      var itemsProcessed=0
      let totalItems=snapshot.stats.totalFiles + snapshot.stats.totalDirectories

      // Simulate verification progress phases if using a real implementation
      // Here we're just showing the phases for demonstration

      // Verification in progress (25% complete)
      await reportProgress(BackupProgressInfo(
        phase: .verifying,
        percentComplete: 0.25,
        itemsProcessed: Int(Double(totalItems) * 0.25),
        totalItems: totalItems,
        bytesProcessed: UInt64(Double(snapshot.stats.totalSize) * 0.25),
        totalBytes: UInt64(snapshot.stats.totalSize)
      ))

      // Check for cancellation
      if let token=cancellationToken, token.isCancelled {
        await reportProgress(BackupProgressInfo.cancelled())
        throw BackupOperationError.operationCancelled("Verification cancelled by user")
      }

      // Verification 50% complete
      await reportProgress(BackupProgressInfo(
        phase: .verifying,
        percentComplete: 0.5,
        itemsProcessed: Int(Double(totalItems) * 0.5),
        totalItems: totalItems,
        bytesProcessed: UInt64(Double(snapshot.stats.totalSize) * 0.5),
        totalBytes: UInt64(snapshot.stats.totalSize)
      ))

      // Check for cancellation
      if let token=cancellationToken, token.isCancelled {
        await reportProgress(BackupProgressInfo.cancelled())
        throw BackupOperationError.operationCancelled("Verification cancelled by user")
      }

      // Verification 75% complete
      await reportProgress(BackupProgressInfo(
        phase: .verifying,
        percentComplete: 0.75,
        itemsProcessed: Int(Double(totalItems) * 0.75),
        totalItems: totalItems,
        bytesProcessed: UInt64(Double(snapshot.stats.totalSize) * 0.75),
        totalBytes: UInt64(snapshot.stats.totalSize)
      ))

      // Finalising phase
      await reportProgress(BackupProgressInfo(
        phase: .finalising,
        percentComplete: 0.9,
        itemsProcessed: totalItems,
        totalItems: totalItems,
        bytesProcessed: UInt64(snapshot.stats.totalSize),
        totalBytes: UInt64(snapshot.stats.totalSize)
      ))

      // Create the verification result
      let endTime=Date()
      let verificationTime=endTime.timeIntervalSince(startTime)

      // Create the final result object
      let result=BackupVerificationResultDTO(
        verified: verificationResult.verified,
        objectsVerified: verificationResult.objectsVerified,
        bytesVerified: verificationResult.bytesVerified,
        errorCount: verificationResult.errors.count,
        issues: verificationResult.errors.map { error in
          VerificationIssue(
            type: mapVerificationErrorType(error.type),
            objectPath: error.path,
            description: error.message,
            repaired: error.repaired
          )
        },
        repairSummary: verificationResult.repairSummary.map { summary in
          RepairSummary(
            issuesRepaired: summary.repairsSuccessful,
            repairFailures: summary.repairsFailed,
            repairs: summary.repairs.map { repair in
              RepairAction(
                type: mapRepairActionType(repair.type),
                objectPath: repair.path,
                description: repair.description,
                successful: repair.successful
              )
            }
          )
        },
        snapshotID: snapshot.id,
        verificationTime: verificationTime
      )

      // Report completion
      await reportProgress(BackupProgressInfo.completed())

      // Return the result and progress stream
      return (result, progressStream)
    } catch {
      // Report failure
      await reportProgress(BackupProgressInfo.failed(error))

      // Rethrow the error
      throw error
    }
  }

  /**
   * Maps verification error types from the snapshot service to VerificationIssue.IssueType.
   *
   * - Parameter type: The error type from the snapshot service
   * - Returns: The corresponding VerificationIssue.IssueType
   */
  private func mapVerificationErrorType(_ type: String) -> VerificationIssue.IssueType {
    switch type {
      case "corruption":
        .corruption
      case "missing_data":
        .missingData
      case "invalid_signature":
        .invalidSignature
      case "metadata_inconsistency":
        .metadataInconsistency
      default:
        .other
    }
  }

  /**
   * Maps repair action types from the snapshot service to RepairAction.RepairType.
   *
   * - Parameter type: The repair type from the snapshot service
   * - Returns: The corresponding RepairAction.RepairType
   */
  private func mapRepairActionType(_ type: String) -> RepairAction.RepairType {
    switch type {
      case "reconstruction":
        .reconstruction
      case "redundant_copy":
        .redundantCopy
      case "replacement":
        .replacement
      case "metadata_fix":
        .metadataFix
      default:
        .other
    }
  }

  /**
   * Parse file entries from JSON output.
   */
  private func parseFileList(from output: String) throws -> [SnapshotFileEntry] {
    guard let data=output.data(using: .utf8) else {
      throw BackupOperationError.parsingFailure("Could not convert output to data")
    }

    do {
      let decoder=JSONDecoder()
      decoder.dateDecodingStrategy = .iso8601

      // Define a local struct to match Restic's output format
      struct ResticFile: Decodable {
        let path: String
        let size: UInt64?
        let mtime: Date?
        let type: String?
      }

      let files=try decoder.decode([ResticFile].self, from: data)

      return files.map { file in
        SnapshotFileEntry(
          path: file.path,
          type: file.type ?? "file",
          size: file.size ?? 0,
          modTime: file.mtime ?? Date(),
          mode: 0o644, // Default regular file permissions
          uid: 0, // Default to root user
          gid: 0 // Default to root group
        )
      }
    } catch {
      throw BackupOperationError
        .parsingFailure("Failed to parse file list: \(error.localizedDescription)")
    }
  }

  /**
   * Parse snapshots from JSON output.
   */
  private func parseSnapshots(output: String) throws -> [BackupSnapshot] {
    guard let data=output.data(using: .utf8) else {
      throw BackupOperationError.parsingFailure("Could not convert output to data")
    }

    do {
      let decoder=JSONDecoder()
      decoder.dateDecodingStrategy = .iso8601

      // Define a local struct to match Restic's output format
      struct ResticSnapshot: Decodable {
        let id: String
        let time: Date
        let paths: [String]
        let tags: [String]
        let hostname: String
        let username: String
        let uid: UInt32
        let gid: UInt32
        let pid: UInt32
      }

      let snapshots=try decoder.decode([ResticSnapshot].self, from: data)

      return snapshots.map { snapshot in
        BackupSnapshot(
          id: snapshot.id,
          creationTime: snapshot.time,
          totalSize: 0,
          fileCount: 0,
          tags: snapshot.tags,
          hostname: snapshot.hostname,
          username: snapshot.username,
          includedPaths: snapshot.paths.map { URL(fileURLWithPath: $0) },
          description: nil,
          isComplete: true,
          parentSnapshotID: nil,
          repositoryID: "default",
          fileStats: nil
        )
      }
    } catch {
      throw BackupOperationError
        .parsingFailure("Failed to parse snapshots: \(error.localizedDescription)")
    }
  }

  /**
   * Parse delete result from JSON output.
   */
  private func parseDeleteResult(output: String, snapshotID: String) throws -> DeleteResult {
    guard let data=output.data(using: .utf8) else {
      throw BackupOperationError.parsingFailure("Could not convert output to data")
    }

    do {
      let decoder=JSONDecoder()
      decoder.dateDecodingStrategy = .iso8601

      // Define a local struct to match Restic's output format
      struct ResticDeleteResult: Decodable {
        let removed: [String]
        let errors: [String]
      }

      let result=try decoder.decode(ResticDeleteResult.self, from: data)

      return DeleteResult(
        snapshotID: snapshotID,
        deletionTime: Date(),
        successful: result.errors.isEmpty,
        spaceSaved: result.removed.isEmpty ? nil : 1024 * UInt64(result.removed.count)
      )
    } catch {
      throw BackupOperationError
        .parsingFailure("Failed to parse delete result: \(error.localizedDescription)")
    }
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
    cancellationToken _: CancellationToken?
  ) async throws -> (MaintenanceResult, AsyncStream<BackupInterfaces.BackupProgress>) {
    // Create the progress stream
    var progressContinuation: AsyncStream<BackupInterfaces.BackupProgress>.Continuation!
    let progressStream=AsyncStream<BackupInterfaces.BackupProgress> { continuation in
      progressContinuation=continuation
    }

    // Create a progress handler that forwards to both the reporter and the stream
    let progressHandler={ [progressReporter, progressContinuation] (
      progress: BackupInterfaces.BackupProgress
    ) async in
      if let reporter=progressReporter {
        await reporter.reportProgress(progress, for: .maintenance)
      }
      progressContinuation.yield(progress)

      // Check if we're done
      if case .completed=progress.phase {
        progressContinuation.finish()
      }
    }

    // Create the maintenance command
    var command=ResticCommandImpl(arguments: [
      "maintenance",
      "--json"
    ])

    // Add type-specific options
    switch parameters.maintenanceType {
      case .check:
        command.arguments.append("--check-data")
      case .prune:
        command.arguments.append("--prune")
      case .rebuildIndex:
        command.arguments.append("--rebuild-index")
      case .optimise:
        command.arguments.append("--optimize")
      case .full:
        command.arguments.append("--check-unused")
        command.arguments.append("--prune")
        command.arguments.append("--rebuild-index")
    }

    // Add any additional options
    if let options=parameters.options, options.dryRun {
      command.arguments.append("--dry-run")
    }

    // Report progress
    await progressReporter?.reportProgress(
      BackupProgress(
        phase: .processing,
        percentComplete: 0.1,
        currentItem: "Starting maintenance",
        processedItems: 0,
        totalItems: 0,
        processedBytes: 0,
        totalBytes: 0,
        estimatedTimeRemaining: nil,
        bytesPerSecond: nil,
        error: nil
      ),
      for: .maintenance
    )

    progressContinuation.yield(BackupProgress(
      phase: .processing,
      percentComplete: 0.1,
      currentItem: "Starting maintenance",
      processedItems: 0,
      totalItems: 0,
      processedBytes: 0,
      totalBytes: 0,
      estimatedTimeRemaining: nil,
      bytesPerSecond: nil,
      error: nil
    ))

    // Run the command
    let output=try await resticService.execute(command)

    // Report completion
    await progressReporter?.reportProgress(
      BackupProgress(
        phase: .completed,
        percentComplete: 1.0,
        currentItem: "Maintenance completed",
        processedItems: 0,
        totalItems: 0,
        processedBytes: 0,
        totalBytes: 0,
        estimatedTimeRemaining: nil,
        bytesPerSecond: nil,
        error: nil
      ),
      for: .maintenance
    )

    progressContinuation.yield(BackupProgress(
      phase: .completed,
      percentComplete: 1.0,
      currentItem: "Maintenance completed",
      processedItems: 0,
      totalItems: 0,
      processedBytes: 0,
      totalBytes: 0,
      estimatedTimeRemaining: nil,
      bytesPerSecond: nil,
      error: nil
    ))

    progressContinuation.finish()

    // Parse the result
    let maintenanceResult=try parseMaintenanceResult(from: output, type: parameters.maintenanceType)

    // Return the result and the progress stream
    return (maintenanceResult, progressStream)
  }

  /**
   * Parse maintenance result from JSON output.
   */
  private func parseMaintenanceResult(
    from output: String,
    type: MaintenanceType
  ) throws -> MaintenanceResult {
    guard let data=output.data(using: .utf8) else {
      throw BackupOperationError.parsingFailure("Could not convert output to data")
    }

    do {
      let decoder=JSONDecoder()
      decoder.dateDecodingStrategy = .iso8601

      // Define a local struct to match Restic's output format
      struct ResticMaintenanceResult: Decodable {
        let removed: [String]?
        let errors: [String]?
      }

      let result=try decoder.decode(ResticMaintenanceResult.self, from: data)

      return MaintenanceResult(
        maintenanceType: type,
        maintenanceTime: Date(),
        successful: result.errors == nil || (result.errors?.isEmpty ?? true),
        spaceOptimised: (result.removed != nil && !(result.removed?.isEmpty ?? true)) ? 1024 : 0,
        // Provide space saved estimate
        duration: 0, // Not available from Restic output
        issuesFound: result.errors ?? [],
        issuesFixed: []
      )
    } catch {
      throw BackupOperationError
        .parsingFailure("Failed to parse maintenance result: \(error.localizedDescription)")
    }
  }
}
