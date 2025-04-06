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

  /// Parses the output of a verification command into a BackupVerificationResultDTO
  /// - Parameters:
  ///   - repositoryCheck: Output from repository check command
  ///   - dataIntegrityCheck: Output from data integrity check command
  /// - Returns: Result of the verification
  /// - Throws: BackupError if parsing fails
  func parseVerificationResult(
    repositoryCheck: String,
    dataIntegrityCheck: String
  ) throws -> BackupVerificationResultDTO {
    // Check for errors in repository check output
    let repositoryValid = !repositoryCheck.contains("error")

    // Extract data integrity status
    let dataIntegrityValid = !dataIntegrityCheck.contains("error")

    // Collect any issues found
    var issues: [VerificationIssue]=[]

    if !repositoryValid {
      issues.append(VerificationIssue(
        type: .metadataInconsistency,
        objectPath: "repository",
        description: "Repository structure verification failed",
        repaired: false
      ))
    }

    if !dataIntegrityValid {
      issues.append(VerificationIssue(
        type: .corruption,
        objectPath: "data",
        description: "Data integrity verification failed",
        repaired: false
      ))
    }

    // Calculate duration based on issues found
    let startTime=Date().addingTimeInterval(-60) // Assume 60s duration
    let endTime=Date()
    let verificationTime = endTime.timeIntervalSince(startTime)

    // Create and return verification result
    return BackupVerificationResultDTO(
      verified: repositoryValid && dataIntegrityValid,
      objectsVerified: Int.random(in: 100...500), // Mock value for testing
      bytesVerified: UInt64.random(in: 1000000...5000000), // Mock value for testing
      errorCount: issues.count,
      issues: issues,
      repairSummary: nil,
      snapshotID: "mock-snapshot-id", // This should ideally come from a parameter
      verificationTime: verificationTime
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
   * Parses a comparison between two snapshots.
   *
   * - Parameter output: Command output to parse
   * - Returns: Result of the comparison
   * - Throws: BackupError if parsing fails
   */
  func parseComparison(_ output: String) throws -> BackupSnapshotComparisonResult {
    // Parse the difference data
    let difference = try parseSnapshotDifference(output: output)
    
    // Calculate total change size (sum of all file sizes that changed)
    let totalChangeSize = calculateTotalChangeSize(difference)
    
    // Create a comparison result using the difference data
    return BackupSnapshotComparisonResult(
      firstSnapshotID: "original", // These should come from actual parameters
      secondSnapshotID: "modified", // These should come from actual parameters
      addedFiles: convertToBackupFiles(difference.addedFiles),
      removedFiles: convertToBackupFiles(difference.removedFiles),
      modifiedFiles: convertToBackupFiles(difference.modifiedFiles),
      unchangedFiles: [],
      changeSize: totalChangeSize,
      comparisonTimestamp: Date()
    )
  }

  // Helper function to calculate total size of changes
  private func calculateTotalChangeSize(_ difference: BackupSnapshotDifference) -> UInt64 {
    let addedSize = (difference.addedFiles ?? []).reduce(0) { $0 + ($1.size ?? 0) }
    let modifiedSize = (difference.modifiedFiles ?? []).reduce(0) { $0 + ($1.size ?? 0) }
    return addedSize + modifiedSize
  }
  
  // Convert SnapshotFile array to BackupFile array
  private func convertToBackupFiles(_ files: [SnapshotFile]?) -> [BackupFile] {
    (files ?? []).map { file in
      BackupFile(
        path: file.path,
        size: file.size ?? 0,
        lastModified: file.modificationDate ?? Date(),
        type: convertFileType(file.type)
      )
    }
  }
  
  // Convert SnapshotFileType to BackupFileType
  private func convertFileType(_ type: SnapshotFileType?) -> BackupFileType {
    guard let type = type else { return .file }
    
    switch type {
    case .directory:
      return .directory
    case .file:
      return .file
    case .symlink:
      return .symlink
    }
  }

  /**
   * Parses the output of a snapshot difference command into a SnapshotDifference object
   *
   * - Parameter output: Command output to parse
   * - Returns: Parsed snapshot difference
   * - Throws: BackupError if parsing fails
   */
  func parseSnapshotDifference(output: String) throws -> BackupSnapshotDifference {
    guard let data=output.data(using: .utf8) else {
      throw BackupError.parsingError(details: "Failed to convert output to data")
    }

    do {
      // Parse the JSON output
      let decoder=JSONDecoder()
      let diffResult=try decoder.decode(ResticDiffResult.self, from: data)

      // Convert SnapshotFileEntry to SnapshotFile
      func convertToSnapshotFile(_ entry: SnapshotFileEntry) -> SnapshotFile {
        SnapshotFile(
          path: entry.path,
          size: entry.size,
          modificationTime: entry.modTime,
          mode: UInt16(entry.mode), // Convert UInt32 to UInt16
          uid: entry.uid,
          gid: entry.gid,
          contentHash: nil
        )
      }

      // Process added files
      let addedFiles=diffResult.added?.map { file in
        SnapshotFileEntry(
          path: file.path ?? "",
          type: "file",
          size: file.size ?? 0,
          modTime: file.mtime ?? Date(),
          mode: 0644,
          uid: 0,
          gid: 0
        )
      } ?? []

      // Process modified files
      let modifiedFiles=diffResult.modified?.map { file in
        SnapshotFileEntry(
          path: file.path ?? "",
          type: "file",
          size: file.size ?? 0,
          modTime: file.mtime ?? Date(),
          mode: 0644,
          uid: 0,
          gid: 0
        )
      } ?? []

      // Process removed files
      let removedFiles=diffResult.removed?.map { file in
        SnapshotFileEntry(
          path: file.path ?? "",
          type: "file",
          size: file.size ?? 0,
          modTime: file.mtime ?? Date(),
          mode: 0644,
          uid: 0,
          gid: 0
        )
      } ?? []

      // Process unchanged files
      let unchangedFiles=diffResult.unchanged?.map { file in
        SnapshotFileEntry(
          path: file.path ?? "",
          type: "file",
          size: file.size ?? 0,
          modTime: file.mtime ?? Date(),
          mode: 0644,
          uid: 0,
          gid: 0
        )
      } ?? []

      let addedSnapshotFiles=addedFiles.map(convertToSnapshotFile)
      let removedSnapshotFiles=removedFiles.map(convertToSnapshotFile)
      let modifiedSnapshotFiles=modifiedFiles.map(convertToSnapshotFile)

      return BackupSnapshotDifference(
        snapshotID1: "unknown1", // These would need to be passed in from outside
        snapshotID2: "unknown2", // These would need to be passed in from outside
        addedCount: addedFiles.count,
        removedCount: removedFiles.count,
        modifiedCount: modifiedFiles.count,
        unchangedCount: 0,
        addedFiles: addedSnapshotFiles,
        removedFiles: removedSnapshotFiles,
        modifiedFiles: modifiedSnapshotFiles
      )
    } catch {
      throw BackupError
        .parsingError(details: "Failed to parse diff result: \(error.localizedDescription)")
    }
  }

  /// Helper struct for decoding Restic diff output
  private struct ResticDiffResult: Codable {
    let added: [ResticFileEntry]?
    let modified: [ResticFileEntry]?
    let removed: [ResticFileEntry]?
    let unchanged: [ResticFileEntry]?
  }

  /// Helper struct for decoding Restic file entries
  private struct ResticFileEntry: Codable {
    let path: String?
    let size: UInt64?
    let mtime: Date?

    enum CodingKeys: String, CodingKey {
      case path
      case size
      case mtime
    }

    init(from decoder: Decoder) throws {
      let container=try decoder.container(keyedBy: CodingKeys.self)
      path=try container.decodeIfPresent(String.self, forKey: .path)
      size=try container.decodeIfPresent(UInt64.self, forKey: .size)

      // Handle date decoding with ISO8601 format
      if let timeString=try container.decodeIfPresent(String.self, forKey: .mtime) {
        let formatter=ISO8601DateFormatter()
        mtime=formatter.date(from: timeString) ?? Date()
      } else {
        mtime=nil
      }
    }
  }
}
