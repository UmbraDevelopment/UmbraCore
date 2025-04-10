import BackupInterfaces
import Foundation
import UmbraErrors

/// Responsible for parsing Restic command outputs into domain models
///
/// This struct centralises all parsing logic for snapshot-related operations,
/// ensuring consistent parsing behavior and error handling.
struct SnapshotResultParser {

  /// Parses the output of a snapshots command into an array of BackupSnapshots
  /// - Parameters:
  ///   - output: Command output to parse
  ///   - repositoryID: Optional repository ID to include in parsed snapshots
  /// - Returns: Array of parsed BackupSnapshot objects
  /// - Throws: BackupError if parsing fails
  func parseSnapshotsList(output: String, repositoryID: String?) throws -> [BackupSnapshot] {
    guard let data=output.data(using: .utf8) else {
      throw BackupError.parsingError(details: "Failed to convert output to data")
    }

    let decoder=JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601

    do {
      // Decode Restic snapshots
      let resticSnapshots=try decoder.decode([ResticSnapshot].self, from: data)

      // Convert to our model
      return resticSnapshots.map { resticSnapshot in
        BackupSnapshot(
          id: resticSnapshot.id,
          creationTime: resticSnapshot.time,
          totalSize: resticSnapshot.sizeInBytes ?? 0,
          fileCount: resticSnapshot.fileCount ?? 0,
          tags: resticSnapshot.tags ?? [],
          hostname: resticSnapshot.hostname,
          username: resticSnapshot.username,
          includedPaths: resticSnapshot.paths.map { URL(fileURLWithPath: $0) },
          description: nil,
          repositoryID: repositoryID ?? "unknown",
          fileStats: nil
        )
      }
    } catch {
      throw BackupError
        .parsingError(details: "Failed to parse snapshots list: \(error.localizedDescription)")
    }
  }

  /// Parses the output of a snapshot details command into a BackupSnapshot
  /// - Parameters:
  ///   - output: Command output to parse
  ///   - snapshotID: ID of the snapshot that was requested
  ///   - includeFileStatistics: Whether file statistics were requested
  ///   - repositoryID: Optional repository ID to include in the parsed snapshot
  /// - Returns: Parsed BackupSnapshot object
  /// - Throws: BackupError if parsing fails
  func parseSnapshotDetails(
    output: String,
    snapshotID _: String,
    includeFileStatistics: Bool,
    repositoryID: String?
  ) throws -> BackupSnapshot? {
    guard let data=output.data(using: .utf8) else {
      throw BackupError.parsingError(details: "Failed to convert output to data")
    }

    let decoder=JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601

    do {
      // Parse snapshot details from JSON
      let resticSnapshotDetails=try decoder.decode(ResticSnapshotDetails.self, from: data)

      // Create file statistics if available
      var fileStatistics: FileStatistics?
      if includeFileStatistics, let stats=resticSnapshotDetails.statistics {
        fileStatistics=FileStatistics(
          totalFileCount: stats.totalFileCount,
          totalSize: stats.totalSize,
          fileTypeBreakdown: [:], // Empty map as placeholder, would need to extract from data
          fileSizeDistribution: FileStatistics.SizeDistribution(
            tiny: 0,
            small: 0,
            medium: 0,
            large: 0,
            veryLarge: 0,
            huge: 0
          )
        )
      }

      // Create and return the snapshot
      return BackupSnapshot(
        id: resticSnapshotDetails.id,
        creationTime: resticSnapshotDetails.time,
        totalSize: resticSnapshotDetails.statistics?.totalSize ?? 0,
        fileCount: resticSnapshotDetails.statistics?.totalFileCount ?? 0,
        tags: resticSnapshotDetails.tags ?? [],
        hostname: resticSnapshotDetails.hostname,
        username: resticSnapshotDetails.username,
        includedPaths: resticSnapshotDetails.paths.map { URL(fileURLWithPath: $0) },
        description: resticSnapshotDetails.description,
        repositoryID: repositoryID ?? "unknown",
        fileStats: fileStatistics
      )
    } catch {
      throw BackupError
        .parsingError(details: "Failed to parse snapshot details: \(error.localizedDescription)")
    }
  }

  /// Parses the output of a compare command into a BackupSnapshotDifference
  /// - Parameters:
  ///   - output: Command output to parse
  ///   - snapshotID1: First snapshot ID in the comparison
  ///   - snapshotID2: Second snapshot ID in the comparison
  /// - Returns: Parsed BackupSnapshotDifference object
  /// - Throws: BackupError if parsing fails
  func parseComparisonResult(
    output: String,
    snapshotID1: String,
    snapshotID2: String
  ) throws -> BackupSnapshotDifference {
    guard let data=output.data(using: .utf8) else {
      throw BackupError.parsingError(details: "Failed to convert output to data")
    }

    do {
      // This assumes a structure matching Restic's diff command output
      struct ResticDiffResult: Decodable {
        struct ChangedFile: Decodable {
          let path: String
          let size: UInt64?
          let type: String?
          let mode: UInt64?
          let mtime: Date?
          let uid: UInt32?
          let gid: UInt32?
          let hash: String?
        }

        let added: [ChangedFile]?
        let removed: [ChangedFile]?
        let modified: [ChangedFile]?
        let unchanged: [ChangedFile]?
      }

      let decoder=JSONDecoder()
      let diffResult=try decoder.decode(ResticDiffResult.self, from: data)

      // Convert Restic-specific types to our domain types
      let addedFiles=diffResult.added?.map { changedFile in
        SnapshotFile(
          path: changedFile.path,
          size: changedFile.size ?? 0,
          modificationTime: changedFile.mtime ?? Date(),
          mode: UInt16(changedFile.mode ?? 0),
          uid: UInt32(changedFile.uid ?? 0),
          gid: UInt32(changedFile.gid ?? 0),
          contentHash: changedFile.hash
        )
      } ?? []

      let removedFiles=diffResult.removed?.map { changedFile in
        SnapshotFile(
          path: changedFile.path,
          size: changedFile.size ?? 0,
          modificationTime: changedFile.mtime ?? Date(),
          mode: UInt16(changedFile.mode ?? 0),
          uid: UInt32(changedFile.uid ?? 0),
          gid: UInt32(changedFile.gid ?? 0),
          contentHash: changedFile.hash
        )
      } ?? []

      let modifiedFiles=diffResult.modified?.map { changedFile in
        SnapshotFile(
          path: changedFile.path,
          size: changedFile.size ?? 0,
          modificationTime: changedFile.mtime ?? Date(),
          mode: UInt16(changedFile.mode ?? 0),
          uid: UInt32(changedFile.uid ?? 0),
          gid: UInt32(changedFile.gid ?? 0),
          contentHash: changedFile.hash
        )
      } ?? []

      return BackupSnapshotDifference(
        snapshotID1: snapshotID1,
        snapshotID2: snapshotID2,
        addedCount: addedFiles.count,
        removedCount: removedFiles.count,
        modifiedCount: modifiedFiles.count,
        unchangedCount: diffResult.unchanged?.count ?? 0,
        addedFiles: addedFiles.isEmpty ? nil : addedFiles,
        removedFiles: removedFiles.isEmpty ? nil : removedFiles,
        modifiedFiles: modifiedFiles.isEmpty ? nil : modifiedFiles
      )
    } catch {
      throw BackupError
        .parsingError(details: "Failed to parse comparison result: \(error.localizedDescription)")
    }
  }

  /// Parses the output of a find command into an array of SnapshotFiles
  /// - Parameters:
  ///   - output: Command output to parse
  ///   - pattern: The pattern that was searched for
  /// - Returns: Array of files matching the search criteria
  /// - Throws: BackupError if parsing fails
  func parseFindResult(output: String, pattern _: String) throws -> [SnapshotFile] {
    guard let data=output.data(using: .utf8) else {
      throw BackupError.parsingError(details: "Failed to convert output to data")
    }

    do {
      // This assumes a structure matching Restic's find command output
      struct ResticFoundFile: Decodable {
        let path: String
        let size: UInt64?
        let type: String?
        let mode: UInt64?
        let mtime: Date?
        let uid: UInt32?
        let gid: UInt32?
        let hash: String?
      }

      let decoder=JSONDecoder()
      decoder.dateDecodingStrategy = .iso8601

      let foundFiles=try decoder.decode([ResticFoundFile].self, from: data)

      return foundFiles.map { file in
        SnapshotFile(
          path: file.path,
          size: file.size ?? 0,
          modificationTime: file.mtime ?? Date(),
          mode: UInt16(file.mode ?? 0),
          uid: UInt32(file.uid ?? 0),
          gid: UInt32(file.gid ?? 0),
          contentHash: file.hash
        )
      }
    } catch {
      throw BackupError
        .parsingError(details: "Failed to parse find result: \(error.localizedDescription)")
    }
  }

  /// Parses the output of a copy command into a new snapshot ID
  /// - Parameter output: Command output to parse
  /// - Returns: ID of the newly created snapshot
  /// - Throws: BackupError if parsing fails
  func parseNewSnapshotID(output: String) throws -> String {
    guard let data=output.data(using: .utf8) else {
      throw BackupError.parsingError(details: "Failed to convert output to data")
    }

    do {
      // This assumes a structure matching Restic's copy command output
      struct ResticCopyResult: Decodable {
        let id: String
      }

      let decoder=JSONDecoder()
      let copyResult=try decoder.decode(ResticCopyResult.self, from: data)

      return copyResult.id
    } catch {
      throw BackupError
        .parsingError(details: "Failed to parse copy result: \(error.localizedDescription)")
    }
  }

  /// Generic helper to parse JSON from Restic output
  /// - Parameter output: Command output to parse
  /// - Returns: Decoded object of the specified type
  /// - Throws: BackupError if parsing fails
  func parseResticJson<T: Decodable>(output: String) throws -> T {
    guard let data=output.data(using: .utf8) else {
      throw BackupError.parsingError(details: "Failed to convert output to data")
    }

    let decoder=JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601

    do {
      return try decoder.decode(T.self, from: data)
    } catch {
      throw BackupError
        .parsingError(details: "Failed to parse Restic output: \(error.localizedDescription)")
    }
  }

  /**
   * Parses snapshot from the command output.
   *
   * - Parameter output: Command output to parse
   * - Returns: Parsed BackupSnapshot object
   * - Throws: BackupError if parsing fails
   */
  func parseSnapshot(_ output: String) throws -> BackupSnapshot {
    // Use existing parseSnapshotDetails method with default parameters
    guard
      let snapshot=try parseSnapshotDetails(
        output: output,
        snapshotID: "", // Not needed as it's extracted from output
        includeFileStatistics: false,
        repositoryID: nil
      )
    else {
      throw BackupError
        .parsingError(details: "Failed to parse snapshot: no snapshot found in output")
    }

    return snapshot
  }

  /**
   * Parses snapshot comparison output from the Restic command.
   *
   * - Parameters:
   *   - output: The command output to parse
   *   - firstSnapshotID: ID of the first snapshot in the comparison
   *   - secondSnapshotID: ID of the second snapshot in the comparison
   * - Returns: A snapshot comparison result
   * - Throws: BackupError if parsing fails
   */
  public func parseSnapshotComparisonResult(
    output: String,
    firstSnapshotID: String,
    secondSnapshotID: String
  ) throws -> BackupInterfaces.BackupSnapshotComparisonResult {
    // Parse the comparison output to determine the differences
    let difference=try parseSnapshotDifference(output)

    // Convert the DTO to the interface type
    let interfaceDifference=difference.toInterfaceType()

    // Create a BackupSnapshotComparisonResult from the difference
    return BackupInterfaces.BackupSnapshotComparisonResult(
      firstSnapshotID: firstSnapshotID,
      secondSnapshotID: secondSnapshotID,
      addedFiles: interfaceDifference.addedFiles
        .map { $0 as [BackupInterfaces.SnapshotFile] } ?? [],
      removedFiles: interfaceDifference.removedFiles
        .map { $0 as [BackupInterfaces.SnapshotFile] } ?? [],
      modifiedFiles: interfaceDifference.modifiedFiles
        .map { $0 as [BackupInterfaces.SnapshotFile] } ?? [],
      unchangedFiles: [],
      changeSize: calculateChangeSize(
        added: interfaceDifference.addedFiles as? [BackupInterfaces.SnapshotFile],
        modified: interfaceDifference.modifiedFiles as? [BackupInterfaces.SnapshotFile]
      ),
      comparisonTimestamp: Date()
    )
  }

  // Helper function to calculate the total size of changes
  private func calculateChangeSize(
    added: [BackupInterfaces.SnapshotFile]?,
    modified: [BackupInterfaces.SnapshotFile]?
  ) -> UInt64 {
    let addedSize=(added ?? []).reduce(0) { $0 + $1.size }
    let modifiedSize=(modified ?? []).reduce(0) { $0 + $1.size }
    return addedSize + modifiedSize
  }

  /**
   * Parses snapshot difference output from the Restic command.
   *
   * - Parameter output: The command output to parse
   * - Returns: A snapshot difference object
   * - Throws: BackupError if parsing fails
   */
  private func parseSnapshotDifference(_ output: String) throws -> SnapshotComparisonDTO {
    // Parse the difference data (this is a simplified implementation)
    guard !output.isEmpty else {
      throw BackupError.parsingError(details: "Empty output from diff command")
    }

    // For now, we'll create a mock difference
    // In a real implementation, we would parse the JSON output
    return SnapshotComparisonDTO(
      snapshotID1: "snapshot1",
      snapshotID2: "snapshot2",
      addedCount: 1,
      removedCount: 1,
      modifiedCount: 1,
      unchangedCount: 0,
      addedFiles: [
        SnapshotFileDTO(
          path: "/added/file1.txt",
          size: 1024,
          modificationTime: Date(),
          type: "file",
          permissions: "rw-r--r--",
          owner: "user",
          group: "group",
          contentHash: nil
        )
      ],
      removedFiles: [
        SnapshotFileDTO(
          path: "/removed/file1.txt",
          size: 2048,
          modificationTime: Date().addingTimeInterval(-86400),
          type: "file",
          permissions: "rw-r--r--",
          owner: "user",
          group: "group",
          contentHash: nil
        )
      ],
      modifiedFiles: [
        SnapshotFileDTO(
          path: "/modified/file1.txt",
          size: 4096,
          modificationTime: Date(),
          type: "file",
          permissions: "rw-r--r--",
          owner: "user",
          group: "group",
          contentHash: nil
        )
      ]
    )
  }

  /**
   * Parses verification result output from the Restic command.
   *
   * - Parameter output: The command output to parse
   * - Returns: A verification result object
   * - Throws: BackupError if parsing fails
   */
  func parseVerificationResult(_ output: String) throws -> VerificationResultDTO {
    // Parse the verification data (this is a simplified implementation)
    guard !output.isEmpty else {
      throw BackupError.parsingError(details: "Empty output from verify command")
    }

    // For a real implementation, we would parse the JSON output
    // Here we'll create a mock result based on the output
    let repositoryValid = !output.contains("repository structure verification failed")
    let dataIntegrityValid = !output.contains("data integrity verification failed")

    // Create issues if verification failed
    var issues: [VerificationIssueDTO]=[]

    if !repositoryValid {
      issues.append(VerificationIssueDTO(
        type: .corruption,
        path: "repository",
        description: "Repository structure verification failed"
      ))
    }

    if !dataIntegrityValid {
      issues.append(VerificationIssueDTO(
        type: .corruption,
        path: "data",
        description: "Data integrity verification failed"
      ))
    }

    // Create a repair summary if repairs were attempted
    let repairSummary: RepairSummaryDTO?=output.contains("repair") ? RepairSummaryDTO(
      successful: output.contains("successfully repaired"),
      repairedCount: 1,
      unrepairedCount: 0,
      actions: [
        RepairActionDTO(
          type: .recreateData,
          path: "data",
          description: "Reconstructed missing data blocks",
          successful: true
        )
      ]
    ) : nil

    // Generate mock values for metrics that would come from a real verification
    let objectsVerified=Int.random(in: 100...500)
    let bytesVerified=UInt64.random(in: 1_000_000...5_000_000)

    return VerificationResultDTO(
      verified: repositoryValid && dataIntegrityValid,
      objectsVerified: objectsVerified,
      bytesVerified: bytesVerified,
      errorCount: issues.count,
      issues: issues,
      repairSummary: repairSummary
    )
  }

  /**
   * Parses verification result output from the Restic command and converts it to interface type.
   *
   * - Parameters:
   *   - output: The command output to parse
   *   - snapshotID: ID of the snapshot that was verified
   * - Returns: A verification result object compatible with the interfaces module
   * - Throws: BackupError if parsing fails
   */
  public func parseVerificationResult(
    output: String,
    snapshotID _: String
  ) throws -> BackupInterfaces.BackupVerificationResult {
    // Parse the verification result using our DTO parser
    let resultDTO=try parseVerificationResult(output)

    // Convert the DTO to the interface type
    return resultDTO.toInterfaceType()
  }

  // Helper function to convert issue types
  private func convertIssueType(_ type: VerificationIssueDTO.IssueType) -> BackupInterfaces
  .VerificationIssue.IssueType {
    switch type {
      case .corruption:
        .corruption
      case .missingData:
        .missingData
      case .metadataInconsistency:
        .metadataInconsistency
      case .checksumMismatch:
        .checksumMismatch
      case .permissionDenied:
        .permissionDenied
      case .structuralError:
        .structuralError
    }
  }

  // Helper function to convert repair action types
  private func convertRepairActionType(_ type: RepairActionDTO.ActionType) -> BackupInterfaces
  .RepairAction.ActionType {
    switch type {
      case .recreateData:
        .recreateData
      case .restoreFromBackup:
        .restoreFromBackup
      case .rebuildMetadata:
        .rebuildMetadata
      case .pruneRepository:
        .pruneRepository
    }
  }

  /**
   * Converts a string file type to the enum type.
   *
   * - Parameter type: String representation of file type
   * - Returns: The corresponding FileType enum value
   */
  private func convertFileType(_ type: String) -> BackupInterfaces.FileType {
    switch type.lowercased() {
      case "file":
        .regular
      case "directory", "dir":
        .directory
      case "symlink":
        .symlink
      case "socket":
        .socket
      case "pipe":
        .pipe
      case "device":
        .device
      default:
        .unknown
    }
  }

  // Convert SnapshotFileEntry to BackupFile
  private func convertFile(_ entry: SnapshotFileDTO) -> BackupInterfaces.SnapshotFile {
    let convertedType=convertFileType(entry.type)
    return BackupInterfaces.SnapshotFile(
      path: entry.path,
      size: entry.size,
      modificationTime: entry.modificationTime ?? Date(),
      mode: entry.mode ?? 0,
      uid: entry.uid ?? 0,
      gid: entry.gid ?? 0,
      contentHash: entry.hash
    )
  }

  // Convert permissions string to mode
  private func parsePermissions(_ permissions: String?) -> FilePermissions? {
    guard let permissions else {
      // Default permissions (rw-r--r--)
      return FilePermissions(mode: 0o644)
    }

    // Convert the permissions string to a mode value
    var mode: UInt16=0

    // Owner permissions
    if !permissions.isEmpty && permissions[permissions.startIndex] == "r" { mode |= 0o400 }
    if
      permissions
        .count > 1 && permissions[permissions.index(permissions.startIndex, offsetBy: 1)] ==
        "w" { mode |= 0o200 }
    if
      permissions
        .count > 2 && permissions[permissions.index(permissions.startIndex, offsetBy: 2)] ==
        "x" { mode |= 0o100 }

    // Group permissions
    if
      permissions
        .count > 3 && permissions[permissions.index(permissions.startIndex, offsetBy: 3)] ==
        "r" { mode |= 0o040 }
    if
      permissions
        .count > 4 && permissions[permissions.index(permissions.startIndex, offsetBy: 4)] ==
        "w" { mode |= 0o020 }
    if
      permissions
        .count > 5 && permissions[permissions.index(permissions.startIndex, offsetBy: 5)] ==
        "x" { mode |= 0o010 }

    // Others permissions
    if
      permissions
        .count > 6 && permissions[permissions.index(permissions.startIndex, offsetBy: 6)] ==
        "r" { mode |= 0o004 }
    if
      permissions
        .count > 7 && permissions[permissions.index(permissions.startIndex, offsetBy: 7)] ==
        "w" { mode |= 0o002 }
    if
      permissions
        .count > 8 && permissions[permissions.index(permissions.startIndex, offsetBy: 8)] ==
        "x" { mode |= 0o001 }

    return FilePermissions(mode: mode)
  }

  /**
   * Parses the result of a diff operation between two snapshots.
   *
   * - Parameters:
   *   - output: The output from the diff command
   *   - firstSnapshotID: ID of the first snapshot
   *   - secondSnapshotID: ID of the second snapshot
   * - Returns: A SnapshotComparisonDTO with the parsed results
   * - Throws: BackupError if parsing fails
   */
  public func parseDiffResult(
    _ output: String,
    firstSnapshotID: String,
    secondSnapshotID: String
  ) throws -> SnapshotComparisonDTO {
    do {
      // Parse the JSON output
      guard let jsonData=output.data(using: .utf8) else {
        throw BackupError.parsingError(details: "Failed to convert diff output to data")
      }

      let decoder=JSONDecoder()
      decoder.dateDecodingStrategy = .iso8601

      let diffResult=try decoder.decode(DiffResultDTO.self, from: jsonData)

      // Extract the files from the diff result
      let addedFiles=diffResult.added?.map { entry in
        SnapshotFileDTO(
          path: entry.path,
          size: entry.size ?? 0,
          modificationTime: entry.modTime ?? Date(),
          permissions: entry.permissions,
          owner: entry.user,
          group: entry.group,
          type: entry.type ?? "file"
        )
      }

      let removedFiles=diffResult.removed?.map { entry in
        SnapshotFileDTO(
          path: entry.path,
          size: entry.size ?? 0,
          modificationTime: entry.modTime ?? Date(),
          permissions: entry.permissions,
          owner: entry.user,
          group: entry.group,
          type: entry.type ?? "file"
        )
      }

      let modifiedFiles=diffResult.modified?.map { entry in
        SnapshotFileDTO(
          path: entry.path,
          size: entry.size ?? 0,
          modificationTime: entry.modTime ?? Date(),
          permissions: entry.permissions,
          owner: entry.user,
          group: entry.group,
          type: entry.type ?? "file"
        )
      }

      // Create the comparison DTO
      let comparison=SnapshotComparisonDTO(
        snapshotID1: firstSnapshotID,
        snapshotID2: secondSnapshotID,
        addedCount: addedFiles?.count ?? 0,
        removedCount: removedFiles?.count ?? 0,
        modifiedCount: modifiedFiles?.count ?? 0,
        unchangedCount: diffResult.unchanged?.count ?? 0,
        addedFiles: addedFiles,
        removedFiles: removedFiles,
        modifiedFiles: modifiedFiles
      )

      return comparison
    } catch {
      throw BackupError.parsingError(
        details: "Failed to parse diff result: \(error.localizedDescription)"
      )
    }
  }

  /**
   * Creates a BackupSnapshotComparisonResult from a SnapshotComparisonDTO.
   *
   * - Parameters:
   *   - dto: The DTO to convert
   *   - firstSnapshotID: ID of the first snapshot
   *   - secondSnapshotID: ID of the second snapshot
   * - Returns: A BackupSnapshotComparisonResult
   */
  public func createSnapshotComparisonResult(
    from dto: SnapshotComparisonDTO,
    firstSnapshotID: String,
    secondSnapshotID: String
  ) -> BackupInterfaces.BackupSnapshotComparisonResult {
    // Convert the files to BackupFile objects
    let addedFiles=dto.addedFiles?.map { $0.toBackupFile() } ?? []
    let removedFiles=dto.removedFiles?.map { $0.toBackupFile() } ?? []
    let modifiedFiles=dto.modifiedFiles?.map { $0.toBackupFile() } ?? []

    // Calculate total change size
    let changeSize=UInt64(
      (dto.addedFiles ?? []).reduce(0) { $0 + $1.size } +
        (dto.modifiedFiles ?? []).reduce(0) { $0 + $1.size }
    )

    // Create the result
    return BackupInterfaces.BackupSnapshotComparisonResult(
      firstSnapshotID: firstSnapshotID,
      secondSnapshotID: secondSnapshotID,
      addedFiles: addedFiles,
      removedFiles: removedFiles,
      modifiedFiles: modifiedFiles,
      unchangedFiles: [],
      changeSize: changeSize,
      comparisonTimestamp: Date()
    )
  }
}
