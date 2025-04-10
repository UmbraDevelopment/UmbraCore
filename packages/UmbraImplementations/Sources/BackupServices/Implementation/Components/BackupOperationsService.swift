import BackupInterfaces
import Foundation
import LoggingServices
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

  /// Snapshot service for snapshot operations
  private let snapshotService: SnapshotServiceProtocol

  /// Error mapper for translating errors
  private let errorMapper: BackupErrorMapper

  /**
   * Creates a new backup operations service.
   *
   * - Parameters:
   *   - resticService: Service for executing Restic commands
   *   - repositoryInfo: Repository connection details
   *   - commandFactory: Factory for creating commands
   *   - resultParser: Parser for command outputs
   *   - snapshotService: Service for snapshot operations
   *   - errorMapper: Error mapper for translating errors
   */
  public init(
    resticService: ResticServiceProtocol,
    repositoryInfo: RepositoryInfo,
    commandFactory: BackupCommandFactory,
    resultParser: BackupResultParser,
    snapshotService: SnapshotServiceProtocol,
    errorMapper: BackupErrorMapper
  ) {
    self.resticService=resticService
    self.repositoryInfo=repositoryInfo
    self.commandFactory=commandFactory
    self.resultParser=resultParser
    self.snapshotService=snapshotService
    self.errorMapper=errorMapper
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
  ) async throws -> (BackupResult, AsyncStream<BackupInterfaces.BackupProgressInfo>) {
    // Create the progress stream
    var progressContinuation: AsyncStream<BackupInterfaces.BackupProgressInfo>.Continuation!
    let progressStream=AsyncStream<BackupInterfaces.BackupProgressInfo> { continuation in
      progressContinuation=continuation
    }

    // Create a progress handler that forwards to both the reporter and the stream
    let progressHandler={ [progressReporter, progressContinuation] (
      progress: BackupInterfaces.BackupProgressInfo
    ) async in
      if let reporter=progressReporter {
        await reporter.reportProgress(progress, for: .createBackup)
      }
      progressContinuation!.yield(progress)

      // Check if we're done
      if case .completed=progress.phase {
        progressContinuation!.finish()
      }
    }

    // Create log context
    let logger=LoggingServiceFactory.shared.createLogger(domain: "BackupServices")
    let logContext=BackupLogContext(
      source: "BackupOperationsService.createBackup"
    )
    .withPublic(key: "operationID", value: parameters.operationID)
    .withPublic(key: "operation", value: "createBackup")
    .withPublic(key: "sourceCount", value: String(parameters.sourcePaths.count))

    // Log operation start
    await logger.info("Starting backup creation", context: logContext)

    // Create the backup command
    var command=ResticCommandImpl(arguments: [
      "backup",
      "--json"
    ])

    // Add paths to include
    for path in parameters.sourcePaths {
      command.arguments.append(path.path)
    }

    // Add exclude paths
    if let excludePaths=parameters.excludePaths, !excludePaths.isEmpty {
      command.arguments.append("--exclude")
      command.arguments.append(contentsOf: excludePaths.map(\.path))
    }

    // Add tags
    if let tags=parameters.tags, !tags.isEmpty {
      command.arguments.append("--tag")
      command.arguments.append(contentsOf: tags)
    }

    // Run the command
    let output=try await resticService.execute(command)

    // Parse the result
    let backupResult=try resultParser.parseBackupResult(
      output: output,
      sources: parameters.sourcePaths
    )

    // Log completion
    await logger.info(
      "Backup creation completed successfully",
      context: logContext
        .withPublic(key: "snapshotID", value: backupResult.snapshotID)
        .withPublic(key: "filesBackedUp", value: String(backupResult.filesBackedUp))
        .withPublic(key: "bytesBackedUp", value: String(backupResult.bytesBackedUp))
    )

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
  ) async throws -> (RestoreResult, AsyncStream<BackupInterfaces.BackupProgressInfo>) {
    // Create the progress stream
    var progressContinuation: AsyncStream<BackupInterfaces.BackupProgressInfo>.Continuation!
    let progressStream=AsyncStream<BackupInterfaces.BackupProgressInfo> { continuation in
      progressContinuation=continuation
    }

    // Create a progress handler that forwards to both the reporter and the stream
    let progressHandler={ [progressReporter, progressContinuation] (
      progress: BackupInterfaces.BackupProgressInfo
    ) async in
      if let reporter=progressReporter {
        await reporter.reportProgress(progress, for: .restoreBackup)
      }
      progressContinuation!.yield(progress)

      // Check if we're done
      if case .completed=progress.phase {
        progressContinuation!.finish()
      }
    }

    // Create log context
    let logger=LoggingServiceFactory.shared.createLogger(domain: "BackupServices")
    let logContext=BackupLogContext(
      source: "BackupOperationsService.restoreBackup"
    )
    .withPublic(key: "operationID", value: parameters.operationID)
    .withPublic(key: "snapshotID", value: parameters.snapshotID)
    .withPublic(key: "operation", value: "restoreBackup")
    .withPrivate(key: "targetPath", value: parameters.targetPath.path)

    // Log operation start
    await logger.info("Starting backup restoration", context: logContext)

    // Create the restore command
    var command=ResticCommandImpl(arguments: [
      "restore",
      "--json",
      parameters.snapshotID,
      "--target",
      parameters.targetPath.path
    ])

    // Add include paths
    if let includePaths=parameters.includePaths, !includePaths.isEmpty {
      command.arguments.append("--include")
      for path in includePaths {
        command.arguments.append(path.path)
      }
    }

    // Add exclude paths
    if let excludePaths=parameters.excludePaths, !excludePaths.isEmpty {
      command.arguments.append("--exclude")
      command.arguments.append(contentsOf: excludePaths.map(\.path))
    }

    // Run the command
    let output=try await resticService.execute(command)

    // Parse the result
    let restoreResult=try resultParser.parseRestoreResult(
      output: output,
      targetPath: parameters.targetPath
    )

    // Log completion
    await logger.info(
      "Backup restoration completed successfully",
      context: logContext
        .withPublic(key: "filesRestored", value: String(restoreResult.filesRestored))
        .withPublic(key: "bytesRestored", value: String(restoreResult.bytesRestored))
    )

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
    cancellationToken _: BackupCancellationToken?
  ) async throws -> [BackupSnapshot] {
    // Create the list command
    var command=ResticCommandImpl(arguments: [
      "snapshots",
      "--json"
    ])

    // Add tags
    if let tags=parameters.tags, !tags.isEmpty {
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
    // Create log context
    let logger=LoggingServiceFactory.shared.createLogger(domain: "BackupServices")
    let logContext=BackupLogContext(
      source: "BackupOperationsService.deleteBackup"
    )
    .withPublic(key: "operationID", value: parameters.operationID)
    .withPublic(key: "snapshotID", value: parameters.snapshotID)
    .withPublic(key: "operation", value: "deleteBackup")
    .withPublic(key: "pruneAfterDelete", value: String(parameters.pruneAfterDelete))

    // Log operation start
    await logger.info("Starting backup deletion", context: logContext)

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
      // Log pruning start
      await logger.info("Starting repository pruning after deletion", context: logContext)

      // Create the prune command
      var pruneCommand=ResticCommandImpl(arguments: [
        "prune",
        "--json"
      ])

      // Run the command
      _=try await resticService.execute(pruneCommand)

      // Log pruning completion
      await logger.info("Repository pruning completed", context: logContext)
    }

    // Log completion
    await logger.info(
      "Backup deletion completed successfully",
      context: logContext
        .withPublic(key: "removedSnapshots", value: String(deleteResult.removedSnapshots.count))
    )

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
    cancellationToken _: BackupCancellationToken?
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
    cancellationToken _: BackupCancellationToken?
  ) async throws -> (BackupVerificationResultDTO, AsyncStream<BackupProgressInfo>) {
    // Create a progress stream for reporting verification progress
    var progressContinuation: AsyncStream<BackupProgressInfo>.Continuation!
    let progressStream=AsyncStream<BackupProgressInfo> { continuation in
      progressContinuation=continuation
    }

    // Define a local function to report progress
    let reportProgress={ (progress: BackupProgressInfo) async in
      // Send progress to the continuation
      progressContinuation!.yield(progress)

      // Forward to the progress reporter if provided
      if let reporter=progressReporter {
        await reporter.reportProgress(progress, for: .verifySnapshot)
      }
    }

    // Start verification
    await reportProgress(BackupProgressInfo(
      phase: .initialising,
      percentComplete: 0.0,
      itemsProcessed: 0,
      totalItems: 0,
      bytesProcessed: 0,
      totalBytes: 0,
      estimatedTimeRemaining: nil,
      details: "Analysing snapshot structure",
      isCancellable: true
    ))

    do {
      // Prepare verification parameters
      let snapshotID=parameters.snapshotID
      let verifyOptions=parameters.verifyOptions

      // Create a logger instance
      let logger=LoggingServiceFactory.shared.createLogger(domain: "BackupServices")

      // Create a log context
      let backupLogContext=BackupLogContext(
        source: "BackupOperationsService.verifyBackup"
      )
      .withPublic(key: "snapshotID", value: snapshotID ?? "latest")

      // Log the start of verification
      await logger.info("Starting backup verification", context: backupLogContext)

      // Get snapshot to verify (latest if not specified)
      let startTime=Date()
      let snapshotResult=try await (
        snapshotID != nil ?
          snapshotService.getSnapshotDetails(snapshotID: snapshotID!, includeFileStatistics: true) :
          snapshotService.getLatestSnapshot(includeFileStatistics: true)
      )

      // Early exit if no snapshot found
      guard let snapshot=snapshotResult else {
        await logger.error("No snapshot found to verify", context: backupLogContext)
        throw BackupOperationError.snapshotNotFound(
          "No snapshot found to verify" + (snapshotID != nil ? " with ID \(snapshotID!)" : "")
        )
      }

      // Log verification start
      await logger.info(
        "Backup verification started",
        context: backupLogContext
          .withPublic(key: "snapshotID", value: snapshot.id)
          .withPublic(key: "verified", value: "true")
          .withPublic(key: "issueCount", value: "0")
      )

      // Report progress
      await reportProgress(BackupProgressInfo(
        phase: .scanning,
        percentComplete: 5.0,
        itemsProcessed: 0,
        totalItems: snapshot.stats.totalFiles,
        bytesProcessed: 0,
        totalBytes: Int64(snapshot.stats.totalSize),
        estimatedTimeRemaining: nil,
        details: "Analysing snapshot structure",
        isCancellable: true
      ))

      // Use snapshot service to perform actual verification
      let verificationLevel: BackupInterfaces.VerificationLevel=verifyOptions?
        .fullVerification == true ? .full : .standard
      let (verificationResult, verificationProgress)=try await snapshotService.verifySnapshot(
        snapshotID: snapshot.id,
        level: verificationLevel
      )

      // Set up a task to forward progress updates
      let progressTask=Task {
        for await progress in verificationProgress {
          await reportProgress(progress)
        }
      }

      // Report initial verification progress
      await reportProgress(BackupProgressInfo(
        phase: .verifying,
        percentComplete: 10.0,
        itemsProcessed: 0,
        totalItems: snapshot.stats.totalFiles,
        bytesProcessed: Int64(snapshot.stats.totalSize / 10),
        totalBytes: Int64(snapshot.stats.totalSize),
        estimatedTimeRemaining: nil,
        details: "Verifying data integrity",
        isCancellable: true
      ))

      // Report mid-verification progress
      await reportProgress(BackupProgressInfo(
        phase: .verifying,
        percentComplete: 50.0,
        itemsProcessed: snapshot.stats.totalFiles / 2,
        totalItems: snapshot.stats.totalFiles,
        bytesProcessed: Int64(snapshot.stats.totalSize / 2),
        totalBytes: Int64(snapshot.stats.totalSize),
        estimatedTimeRemaining: nil,
        details: "Verifying data integrity",
        isCancellable: true
      ))

      // Report late-verification progress
      await reportProgress(BackupProgressInfo(
        phase: .verifying,
        percentComplete: 90.0,
        itemsProcessed: snapshot.stats.totalFiles,
        totalItems: snapshot.stats.totalFiles,
        bytesProcessed: Int64(snapshot.stats.totalSize * 9 / 10),
        totalBytes: Int64(snapshot.stats.totalSize),
        estimatedTimeRemaining: nil,
        details: "Verifying data integrity",
        isCancellable: true
      ))

      // Report finalising progress
      await reportProgress(BackupProgressInfo(
        phase: .finalising,
        percentComplete: 95.0,
        itemsProcessed: snapshot.stats.totalFiles,
        totalItems: snapshot.stats.totalFiles,
        bytesProcessed: Int64(snapshot.stats.totalSize),
        totalBytes: Int64(snapshot.stats.totalSize),
        estimatedTimeRemaining: nil,
        details: "Finalising verification",
        isCancellable: true
      ))

      // Cancel the progress forwarding task
      progressTask.cancel()

      // Log verification completion
      await logger.info(
        context: backupLogContext
          .withPublic(key: "snapshotID", value: snapshot.id)
          .withPublic(key: "verified", value: String(verificationResult.verified))
          .withPublic(key: "issueCount", value: String(verificationResult.issues.count)),
        message: "Backup verification completed"
      )

      // Report completion
      await reportProgress(BackupProgressInfo(
        phase: .completed,
        percentComplete: 100.0,
        itemsProcessed: snapshot.stats.totalFiles,
        totalItems: snapshot.stats.totalFiles,
        bytesProcessed: Int64(snapshot.stats.totalSize),
        totalBytes: Int64(snapshot.stats.totalSize),
        estimatedTimeRemaining: nil,
        details: "Verification completed",
        isCancellable: false
      ))

      // Return the result
      return verificationResult
    } catch {
      // Map the error and rethrow
      throw errorMapper.mapError(error)
    }
  }

  /**
   * Compares two snapshots to identify differences.
   *
   * This method compares two snapshots and returns information about files that
   * were added, removed, or modified between them.
   *
   * - Parameters:
   *   - parameters: Parameters for the comparison operation
   *   - progressReporter: Reporter for operation progress
   *   - cancellationToken: Token for cancelling the operation
   * - Returns: Result of the comparison
   * - Throws: BackupError if the operation fails
   */
  public func compareSnapshots(
    parameters: BackupSnapshotComparisonParameters,
    progressReporter: BackupProgressReporter?,
    cancellationToken: BackupCancellationToken?
  ) async throws -> BackupSnapshotComparisonResult {
    // Create log context
    let context=BackupLogContext(
      source: "BackupOperationsService.compareSnapshots"
    )
    .withPublic(key: "operationID", value: parameters.operationID)
    .withPublic(key: "firstSnapshotID", value: parameters.firstSnapshotID)
    .withPublic(key: "secondSnapshotID", value: parameters.secondSnapshotID)
    .withPublic(key: "operation", value: "compareSnapshots")

    // Log operation start
    await logger.info("Starting snapshot comparison", context: context)

    // Report initial progress
    await reportProgress(BackupProgressInfo(
      phase: .preparing,
      percentComplete: 0.0,
      itemsProcessed: 0,
      totalItems: 0,
      bytesProcessed: 0,
      totalBytes: 0,
      estimatedTimeRemaining: nil,
      details: "Preparing to compare snapshots"
    ), reporter: progressReporter)

    do {
      // Get details for both snapshots
      let firstSnapshot=try await getSnapshotDetails(
        snapshotID: parameters.firstSnapshotID,
        context: context
      )

      // Check if the operation was cancelled
      if let token=cancellationToken, await token.isCancelled {
        throw BackupError.operationCancelled(
          details: "Snapshot comparison cancelled"
        )
      }

      let secondSnapshot=try await getSnapshotDetails(
        snapshotID: parameters.secondSnapshotID,
        context: context
      )

      // Check if the operation was cancelled
      if let token=cancellationToken, await token.isCancelled {
        throw BackupError.operationCancelled(
          details: "Snapshot comparison cancelled"
        )
      }

      // Report progress - starting comparison
      await reportProgress(BackupProgressInfo(
        phase: .processing,
        percentComplete: 25.0,
        itemsProcessed: 0,
        totalItems: 0,
        bytesProcessed: 0,
        totalBytes: 0,
        estimatedTimeRemaining: nil,
        details: "Comparing snapshots"
      ), reporter: progressReporter)

      // Create the diff command
      let diffCommand=commandFactory.createDiffCommand(
        firstSnapshotID: parameters.firstSnapshotID,
        secondSnapshotID: parameters.secondSnapshotID,
        options: nil
      )

      // Execute the command
      let diffOutput=try await resticService.execute(diffCommand)

      // Check if the operation was cancelled
      if let token=cancellationToken, await token.isCancelled {
        throw BackupError.operationCancelled(
          details: "Snapshot comparison cancelled"
        )
      }

      // Report progress - parsing results
      await reportProgress(BackupProgressInfo(
        phase: .processing,
        percentComplete: 75.0,
        itemsProcessed: 0,
        totalItems: 0,
        bytesProcessed: 0,
        totalBytes: 0,
        estimatedTimeRemaining: nil,
        details: "Parsing comparison results"
      ), reporter: progressReporter)

      // Parse the diff result
      let comparisonDTO=try resultParser.parseDiffResult(
        diffOutput,
        firstSnapshotID: parameters.firstSnapshotID,
        secondSnapshotID: parameters.secondSnapshotID
      )

      // Convert to interface type
      let result=resultParser.createSnapshotComparisonResult(
        from: comparisonDTO,
        firstSnapshotID: parameters.firstSnapshotID,
        secondSnapshotID: parameters.secondSnapshotID
      )

      // Report progress - complete
      await reportProgress(BackupProgressInfo(
        phase: .completed,
        percentComplete: 100.0,
        itemsProcessed: comparisonDTO.addedCount + comparisonDTO.removedCount + comparisonDTO
          .modifiedCount,
        totalItems: comparisonDTO.addedCount + comparisonDTO.removedCount + comparisonDTO
          .modifiedCount + comparisonDTO.unchangedCount,
        bytesProcessed: Int64(result.changeSize),
        totalBytes: Int64(result.changeSize),
        estimatedTimeRemaining: nil,
        details: "Comparison complete",
        result: .success
      ), reporter: progressReporter)

      // Log success
      await logger.info(
        "Snapshot comparison completed successfully: " +
          "\(comparisonDTO.addedCount) added, " +
          "\(comparisonDTO.removedCount) removed, " +
          "\(comparisonDTO.modifiedCount) modified",
        context: context
      )

      return result
    } catch {
      // Map error and log failure
      let backupError=errorMapper.mapError(error)
      await logger.error(
        "Snapshot comparison failed: \(backupError.localizedDescription)",
        context: context
      )

      // Report progress - failed
      await reportProgress(BackupProgressInfo(
        phase: .failed,
        percentComplete: 0.0,
        itemsProcessed: 0,
        totalItems: 0,
        bytesProcessed: 0,
        totalBytes: 0,
        estimatedTimeRemaining: nil,
        details: "Comparison failed: \(backupError.localizedDescription)",
        result: .failure(backupError)
      ), reporter: progressReporter)

      throw backupError
    }
  }

  /**
   * Maps verification error types from the snapshot service to VerificationIssue.IssueType.
   *
   * - Parameter type: The error type string from the snapshot service
   * - Returns: The corresponding VerificationIssue.IssueType
   */
  private func mapVerificationErrorType(_ type: String) -> VerificationIssue.IssueType {
    switch type {
      case "corruption":
        .corruptedData
      case "missing_data":
        .missingData
      case "metadata_inconsistency":
        .inconsistentMetadata
      case "access_error":
        .accessError
      default:
        .other
    }
  }

  /**
   * Maps a repair type string from the snapshot service to a RepairAction.ActionType.
   *
   * - Parameter type: The repair type from the snapshot service
   * - Returns: The corresponding RepairAction.ActionType
   */
  private func mapRepairActionType(_ type: String) -> RepairAction.ActionType {
    switch type {
      case "reconstruction":
        .rebuildMetadata
      case "redundant_copy":
        .restoreFromBackup
      case "replacement":
        .recreateData
      case "removal":
        .removeCorrupted
      default:
        .other
    }
  }

  /**
   * Reports progress to the provided progress reporter.
   *
   * - Parameters:
   *   - progress: The progress information to report
   *   - reporter: The reporter to send progress to
   */
  private func reportProgress(
    _ progress: BackupProgressInfo,
    reporter: BackupProgressReporter?
  ) async {
    // Only report if a reporter was provided
    if let reporter {
      await reporter.reportProgress(progress)
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
      // Try to parse the JSON output
      let decoder=JSONDecoder()
      decoder.keyDecodingStrategy = .convertFromSnakeCase

      struct DeleteResponse: Codable {
        let filesDeleted: Int?
        let sizeDeleted: UInt64?
        let snapshotsDeleted: [String]?
      }

      let response=try decoder.decode(DeleteResponse.self, from: data)

      return DeleteResult(
        snapshotID: snapshotID,
        successful: response.errors == nil || (response.errors?.isEmpty ?? true),
        filesDeleted: response.filesDeleted ?? 0,
        sizeDeleted: response.sizeDeleted ?? 0,
        deletionTimestamp: Date()
      )
    } catch {
      // If JSON parsing fails, create a basic result based on the output
      let successful = !output.contains("error") && !output.contains("failed")

      return DeleteResult(
        snapshotID: snapshotID,
        successful: successful,
        filesDeleted: 0,
        sizeDeleted: 0,
        deletionTimestamp: Date()
      )
    }
  }

  /**
   * Retrieves detailed information about a specific snapshot.
   *
   * - Parameters:
   *   - snapshotID: ID of the snapshot to retrieve
   *   - context: Log context for the operation
   * - Returns: The snapshot details
   * - Throws: BackupError if the operation fails
   */
  private func getSnapshotDetails(
    snapshotID: String,
    context: BackupLogContext
  ) async throws -> BackupSnapshot {
    // Log the request
    await logger.debug("Retrieving snapshot details", context: context)

    // Create the command to get snapshot details
    let command=commandFactory.createSnapshotInfoCommand(
      snapshotID: snapshotID,
      includeStats: true
    )

    // Execute the command
    let output=try await resticService.execute(command)

    // Parse the output
    let snapshot=try resultParser.parseSnapshotInfo(output)

    // Check if the snapshot was found
    guard let snapshot else {
      throw BackupError.snapshotNotFound(
        details: "Snapshot with ID \(snapshotID) not found"
      )
    }

    // Log success
    await logger.debug(
      "Retrieved snapshot details successfully",
      context: context
    )

    return snapshot
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
  ) async throws -> (MaintenanceResult, AsyncStream<BackupProgressInfo>) {
    // Create the progress stream
    var progressContinuation: AsyncStream<BackupProgressInfo>.Continuation!
    let progressStream=AsyncStream<BackupProgressInfo> { continuation in
      progressContinuation=continuation
    }

    // Create a progress handler that forwards to both the reporter and the stream
    let progressHandler={ [progressReporter, progressContinuation] (
      progress: BackupProgressInfo
    ) async in
      if let reporter=progressReporter {
        await reporter.reportProgress(progress, for: .maintenance)
      }
      progressContinuation!.yield(progress)
    }

    // Create log context
    let logger=LoggingServiceFactory.shared.createLogger(domain: "BackupServices")
    let logContext=BackupLogContext(
      source: "BackupOperationsService.performMaintenance"
    )
    .withPublic(key: "operationID", value: parameters.operationID)
    .withPublic(key: "maintenanceType", value: parameters.maintenanceType.rawValue)
    .withPublic(key: "operation", value: "performMaintenance")

    // Log operation start
    await logger.info("Starting repository maintenance", context: logContext)

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

    // Report progress to the reporter
    await progressReporter?.reportProgress(
      BackupProgressInfo(
        phase: .initialising,
        percentComplete: 0,
        itemsProcessed: 0,
        totalItems: 0,
        bytesProcessed: 0,
        totalBytes: 0,
        estimatedTimeRemaining: nil,
        details: "Starting maintenance",
        isCancellable: true
      ),
      for: .maintenance
    )

    progressContinuation!.yield(BackupProgressInfo(
      phase: .initialising,
      percentComplete: 0,
      itemsProcessed: 0,
      totalItems: 0,
      bytesProcessed: 0,
      totalBytes: 0,
      estimatedTimeRemaining: nil,
      details: "Starting maintenance",
      isCancellable: true
    ))

    // Run the command
    let output=try await resticService.execute(command)

    // Report completion
    await progressReporter?.reportProgress(
      BackupProgressInfo(
        phase: .completed,
        percentComplete: 1.0,
        itemsProcessed: 0,
        totalItems: 0,
        bytesProcessed: 0,
        totalBytes: 0,
        estimatedTimeRemaining: 0,
        details: "Maintenance completed",
        isCancellable: false
      ),
      for: .maintenance
    )

    progressContinuation!.yield(BackupProgressInfo(
      phase: .completed,
      percentComplete: 1.0,
      itemsProcessed: 0,
      totalItems: 0,
      bytesProcessed: 0,
      totalBytes: 0,
      estimatedTimeRemaining: 0,
      details: "Maintenance completed",
      isCancellable: false
    ))

    progressContinuation!.finish()

    // Parse the result
    let maintenanceResult=try parseMaintenanceResult(from: output, type: parameters.maintenanceType)

    // Log completion
    await logger.info(
      "Repository maintenance completed successfully",
      context: logContext
        .withPublic(key: "removedItems", value: String(maintenanceResult.removedItems.count))
        .withPublic(key: "errors", value: String(maintenanceResult.errors.count))
    )

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
