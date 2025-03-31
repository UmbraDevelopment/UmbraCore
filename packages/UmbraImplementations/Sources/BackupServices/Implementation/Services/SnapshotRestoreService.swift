import BackupInterfaces
import Foundation
import LoggingInterfaces
import LoggingTypes
import ResticInterfaces
import ResticServices

/**
 * Provides snapshot restore capabilities with privacy-aware logging and error handling.
 *
 * This actor-based implementation follows the Alpha Dot Five architecture principles:
 * - Uses Swift actors for thread safety
 * - Implements privacy-aware error handling and logging
 * - Structured concurrency with async/await
 * - Type-safe interfaces
 */
public actor SnapshotRestoreService {
  /// Restic service for backend operations
  private let resticService: ResticServiceProtocol

  /// Factory for creating Restic commands
  private let commandFactory: ResticCommandFactory

  /// Executor for operations
  private let operationExecutor: SnapshotOperationExecutor

  /**
   * Creates a new snapshot restore service.
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
  }

  /**
   * Restores files from a snapshot to a target location.
   *
   * - Parameters:
   *   - parameters: Parameters for the restore operation
   *   - progressReporter: Optional reporter for tracking operation progress
   *   - cancellationToken: Optional token for cancelling the operation
   * - Throws: BackupError if the operation fails
   */
  public func restoreSnapshot(
    parameters: SnapshotRestoreParameters,
    progressReporter: BackupProgressReporter?,
    cancellationToken: BackupCancellationToken?
  ) async throws {
    try await operationExecutor.execute(
      parameters: parameters,
      progressReporter: progressReporter,
      cancellationToken: cancellationToken,
      operation: { params, reporter, _ in
        // Create command
        let command=try self.commandFactory.createRestoreCommand(
          snapshotID: params.snapshotID,
          targetPath: URL(fileURLWithPath: params.targetPath.path),
          includePattern: params.includePattern,
          excludePattern: params.excludePattern
        )

        // Update progress
        if let progressReporter=reporter {
          await progressReporter.reportProgress(
            BackupProgress(
              phase: .processing,
              percentComplete: 0.3
            ),
            for: .restoreBackup
          )
        }

        // Execute command - this will take time
        let output=try await self.resticService.execute(command)

        // Verify success
        if output.contains("error") {
          throw BackupError.restoreFailure(reason: "Failed to restore: \(output)")
        }

        // Return empty result as the method is void
        return ()
      }
    )
  }

  /**
   * Executes a command with periodic progress updates for long-running operations.
   *
   * - Parameters:
   *   - command: The command to execute
   *   - progressReporter: Reporter for tracking operation progress
   *   - cancellationToken: Optional token for cancelling the operation
   * - Throws: BackupError if the operation fails
   */
  private func executeWithProgressUpdates(
    command: ResticCommand,
    progressReporter: BackupProgressReporter?,
    cancellationToken: BackupCancellationToken?
  ) async throws {
    // Create a task for executing the command
    let executionTask=Task {
      try await self.resticService.execute(command)
    }

    // Create a task for updating progress periodically
    let progressTask=Task {
      var progress=0.3

      while !Task.isCancelled && progress < 0.9 {
        // Increment progress gradually
        progress += 0.05
        progress=min(progress, 0.9)

        if let reporter=progressReporter {
          await reporter.reportProgress(
            BackupProgress(
              phase: .processing,
              percentComplete: progress
            ),
            for: .restoreBackup
          )
        }

        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
      }
    }

    // Set up cancellation if token provided
    if let token=cancellationToken {
      // Use Task.init with operation to handle cancellation
      Task {
        // Check for cancellation in a loop
        while !Task.isCancelled {
          if await token.isCancelled() {
            executionTask.cancel()
            progressTask.cancel()
            if let reporter=progressReporter {
              await reporter.reportCancellation(for: .restoreBackup)
            }
            break
          }
          try? await Task.sleep(nanoseconds: 100_000_000) // 100ms
        }
      }
    }

    do {
      // Wait for execution to complete
      let result=try await executionTask.value

      // Cancel progress updates
      progressTask.cancel()

      // Verify success
      if result.contains("error") {
        throw BackupError.restoreFailure(
          reason: "Restore operation completed but reported errors: \(result)"
        )
      }
    } catch is CancellationError {
      progressTask.cancel()
      throw BackupError.operationCancelled
    } catch let error as ResticError {
      progressTask.cancel()
      throw error
    } catch {
      progressTask.cancel()
      throw BackupError.genericError(
        reason: "Unexpected error during restore: \(error.localizedDescription)"
      )
    }
  }

  /**
   * Validates that the target path exists and is writable.
   *
   * - Parameter targetPath: Path to validate
   * - Throws: BackupError if the path is invalid or not writable
   */
  private func validateRestoreTargetPath(_ targetPath: URL) throws {
    let fileManager=FileManager.default

    // Check if target directory exists
    var isDirectory: ObjCBool=false
    let exists=fileManager.fileExists(atPath: targetPath.path, isDirectory: &isDirectory)

    // Path must exist and be a directory
    if !exists {
      throw BackupError.invalidPaths(paths: [targetPath.path])
    }

    if !isDirectory.boolValue {
      throw BackupError.invalidPaths(
        paths: [targetPath.path]
      )
    }

    // Check if directory is writable
    if !fileManager.isWritableFile(atPath: targetPath.path) {
      throw BackupError.insufficientPermissions(
        path: targetPath.path
      )
    }
  }

  /**
   * Estimates the size of a restore operation before performing it.
   *
   * - Parameters:
   *   - snapshotID: ID of the snapshot to restore from
   *   - progressReporter: Optional reporter for tracking operation progress
   *   - cancellationToken: Optional token for cancelling the operation
   * - Returns: Estimated size of the restore operation in bytes
   * - Throws: BackupError if the operation fails
   */
  private func estimateRestoreSize(
    snapshotID: String,
    progressReporter: BackupProgressReporter?,
    cancellationToken: BackupCancellationToken?
  ) async throws -> UInt64 {
    let resultParser=SnapshotResultParser()

    struct EstimateSizeParameters: SnapshotOperationParameters {
      let snapshotID: String
      let operationType: SnapshotOperationType = .get

      func validate() throws {
        if snapshotID.isEmpty {
          throw BackupError.invalidConfiguration(details: "Snapshot ID cannot be empty")
        }
      }

      func createLogContext() -> SnapshotLogContextAdapter {
        SnapshotLogContextAdapter(
          snapshotID: snapshotID,
          operation: operationType.rawValue
        )
      }
    }

    let parameters=EstimateSizeParameters(snapshotID: snapshotID)

    return try await operationExecutor.execute(
      parameters: parameters,
      progressReporter: progressReporter,
      cancellationToken: cancellationToken,
      operation: { _, reporter, _ in
        // Create a command to get snapshot details with statistics
        var args=["snapshots", snapshotID, "--json", "--stats"]

        let command=ResticCommandImpl(arguments: args)

        // Update progress
        if let reporter {
          await reporter.reportProgress(
            BackupProgress(phase: .processing, percentComplete: 0.3),
            for: .getSnapshotDetails
          )
        }

        // Execute command
        let output=try await self.resticService.execute(command)

        // Parse result
        let snapshot=try resultParser.parseSnapshotsList(output: output, repositoryID: nil).first

        // Update progress
        if let reporter {
          await reporter.reportProgress(
            BackupProgress(phase: .completed, percentComplete: 1.0),
            for: .getSnapshotDetails
          )
        }

        // Return the total size or 0 if not available
        return snapshot?.totalSize ?? 0
      }
    )
  }
}
