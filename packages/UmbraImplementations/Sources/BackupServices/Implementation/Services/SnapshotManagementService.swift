import BackupInterfaces
import Foundation
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
 * - Result types for error handling
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
    self.resticService=resticService
    self.operationExecutor=operationExecutor
    self.operationsService=operationsService
    commandFactory=ResticCommandFactory()
    resultParser=SnapshotResultParser()
  }

  /**
   * Updates the tags for a snapshot.
   *
   * - Parameters:
   *   - parameters: Parameters for the update tags operation
   *   - progressReporter: Optional reporter for tracking operation progress
   *   - cancellationToken: Optional token for cancelling the operation
   * - Returns: The updated snapshot
   */
  public func updateSnapshotTags(
    parameters: SnapshotUpdateTagsParameters,
    progressReporter: BackupProgressReporter?,
    cancellationToken: BackupCancellationToken?
  ) async -> Result<BackupSnapshot, BackupOperationError> {
    do {
      let snapshot=try await operationExecutor.execute(
        parameters: parameters,
        progressReporter: progressReporter,
        cancellationToken: cancellationToken,
        operation: { _, reporter, token in
          // Create command
          let command=try self.commandFactory.createUpdateTagsCommand(
            snapshotID: parameters.snapshotID,
            addTags: parameters.addTags,
            removeTags: parameters.removeTags
          )

          // Update progress
          if let reporter {
            let progress=BackupProgressInfo(
              phase: .processing,
              percentComplete: 0.3,
              itemsProcessed: 0,
              totalItems: 0,
              bytesProcessed: 0,
              totalBytes: 0,
              details: "Updating snapshot tags"
            )
            await reporter.reportProgress(progress, for: .updateTags)
          }

          // Execute command
          _=try await self.resticService.execute(command)

          // Get the updated snapshot
          let snapshot=try await self.operationsService.getSnapshotDetails(
            snapshotID: parameters.snapshotID,
            includeStats: true,
            progressReporter: reporter,
            cancellationToken: token
          )

          return snapshot
        }
      )
      return .success(snapshot)
    } catch {
      if let backupError=error as? BackupOperationError {
        return .failure(backupError)
      } else {
        return .failure(
          BackupOperationError
            .unexpected("Failed to update snapshot tags: \(error.localizedDescription)")
        )
      }
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
   */
  public func updateSnapshotDescription(
    parameters: SnapshotUpdateDescriptionParameters,
    progressReporter: BackupProgressReporter?,
    cancellationToken: BackupCancellationToken?
  ) async -> Result<BackupSnapshot, BackupOperationError> {
    do {
      let snapshot=try await operationExecutor.execute(
        parameters: parameters,
        progressReporter: progressReporter,
        cancellationToken: cancellationToken,
        operation: { _, reporter, token in
          // Create command
          let command=try self.commandFactory.createUpdateDescriptionCommand(
            snapshotID: parameters.snapshotID,
            description: parameters.description
          )

          // Update progress
          if let reporter {
            let progress=BackupProgressInfo(
              phase: .processing,
              percentComplete: 0.3,
              itemsProcessed: 0,
              totalItems: 0,
              bytesProcessed: 0,
              totalBytes: 0,
              details: "Updating snapshot description"
            )
            await reporter.reportProgress(progress, for: .updateTags)
          }

          // Execute command
          _=try await self.resticService.execute(command)

          // Get the updated snapshot
          let snapshot=try await self.operationsService.getSnapshotDetails(
            snapshotID: parameters.snapshotID,
            includeStats: true,
            progressReporter: reporter,
            cancellationToken: token
          )

          return snapshot
        }
      )
      return .success(snapshot)
    } catch {
      if let backupError=error as? BackupOperationError {
        return .failure(backupError)
      } else {
        return .failure(
          BackupOperationError
            .unexpected("Failed to update snapshot description: \(error.localizedDescription)")
        )
      }
    }
  }
}
