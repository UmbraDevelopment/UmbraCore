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

  /// Parses the output of a compare command into a SnapshotDifference
  /// - Parameters:
  ///   - output: Command output to parse
  ///   - snapshotID1: First snapshot ID in the comparison
  ///   - snapshotID2: Second snapshot ID in the comparison
  /// - Returns: Parsed SnapshotDifference object
  /// - Throws: BackupError if parsing fails
  func parseComparisonResult(
    output: String,
    snapshotID1: String,
    snapshotID2: String
  ) throws -> SnapshotDifference {
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

      return SnapshotDifference(
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

  /// Parses the output of a verification command into a VerificationResult
  /// - Parameters:
  ///   - repositoryCheck: Output from repository check command
  ///   - dataIntegrityCheck: Output from data integrity check command
  /// - Returns: Result of the verification
  /// - Throws: BackupError if parsing fails
  func parseVerificationResult(
    repositoryCheck: String,
    dataIntegrityCheck: String
  ) throws -> VerificationResult {
    // Check for errors in repository check output
    let repositoryValid = !repositoryCheck.contains("error")
    
    // Extract data integrity status
    let dataIntegrityValid = !dataIntegrityCheck.contains("error")
    
    // Collect any issues found
    var issues: [VerificationIssue] = []
    
    if !repositoryValid {
      issues.append(VerificationIssue(
        type: .repositoryStructure,
        message: "Repository structure verification failed",
        severity: .critical,
        affectedPath: nil
      ))
    }
    
    if !dataIntegrityValid {
      issues.append(VerificationIssue(
        type: .dataIntegrity,
        message: "Data integrity verification failed",
        severity: .critical,
        affectedPath: nil
      ))
    }
    
    // Calculate duration based on issues found
    let startTime = Date().addingTimeInterval(-60) // Assume 60s duration
    let endTime = Date()
    
    // Create and return verification result
    return VerificationResult(
      successful: repositoryValid && dataIntegrityValid,
      issues: issues,
      startTime: startTime,
      endTime: endTime
    )
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
   * Parses a snapshot from the command output.
   *
   * - Parameter output: Command output to parse
   * - Returns: Parsed BackupSnapshot object
   * - Throws: BackupError if parsing fails
   */
  func parseSnapshot(_ output: String) throws -> BackupSnapshot {
    // Use existing parseSnapshotDetails method with default parameters
    guard let snapshot = try parseSnapshotDetails(
      output: output,
      snapshotID: "", // Not needed as it's extracted from output
      includeFileStatistics: false,
      repositoryID: nil
    ) else {
      throw BackupError.parsingError(details: "Failed to parse snapshot: no snapshot found in output")
    }
    
    return snapshot
  }
  
  /**
   * Parses a comparison between two snapshots.
   *
   * - Parameter output: Command output to parse
   * - Returns: Result of the comparison
   * - Throws: BackupError if parsing fails
   */
  func parseComparison(_ output: String) throws -> AlphaDotFiveSnapshotComparisonResult {
    // Parse the difference data
    let difference = try parseSnapshotDifference(output: output)
    
    // Create a comparison result using the difference data
    return AlphaDotFiveSnapshotComparisonResult(
      addedFiles: difference.addedFiles,
      modifiedFiles: difference.modifiedFiles,
      removedFiles: difference.removedFiles,
      unchangedFiles: difference.unchangedFiles,
      totalChangeCount: difference.addedFiles.count + difference.modifiedFiles.count + difference.removedFiles.count,
      comparisonDate: Date()
    )
  }

}
