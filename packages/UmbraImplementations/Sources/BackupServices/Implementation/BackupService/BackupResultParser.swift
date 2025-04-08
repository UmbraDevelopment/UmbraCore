import BackupInterfaces
import Foundation
import UmbraErrors

/// Responsible for parsing the output of Restic commands for backup operations
///
/// This struct centralises the parsing logic for backup-related operations,
/// converting Restic command outputs into domain models.
public struct BackupResultParser {
  /// Parses the result of a backup operation
  /// - Parameters:
  ///   - output: The command output to parse
  ///   - sources: The source paths used in the backup
  /// - Returns: A backup result with details about the operation
  /// - Throws: BackupError if parsing fails
  public func parseBackupResult(output: String, sources: [URL]) throws -> BackupResult {
    guard !output.isEmpty else {
      throw BackupError.parsingError(details: "Empty output from backup command")
    }

    let decoder=JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase

    // Split output by newlines to handle multiple JSON objects
    let lines=output.components(separatedBy: .newlines)
      .filter { !$0.isEmpty }

    // Parse the last line for the final summary
    guard let lastLine=lines.last else {
      throw BackupError.parsingError(details: "No data in backup output")
    }

    do {
      let resticResult=try decoder.decode(ResticBackupResult.self, from: Data(lastLine.utf8))

      // Extract snapshot data
      let snapshotID=resticResult.snapshotID

      // Create the backup result
      return BackupResult(
        snapshotID: snapshotID,
        creationTime: Date(),
        totalSize: resticResult.summary.bytesProcessed,
        fileCount: resticResult.summary.filesProcessed,
        addedSize: resticResult.summary.bytesAdded,
        duration: 0, // Duration is not returned in the JSON output
        tags: [], // Tags are not returned in the backup result JSON
        includedPaths: sources,
        excludedPaths: []
      )
    } catch {
      throw BackupError
        .parsingError(details: "Failed to parse backup result: \(error.localizedDescription)")
    }
  }

  /// Parses the output of a restore command into a RestoreResult
  /// - Parameters:
  ///   - output: Command output to parse
  ///   - targetPath: Path where files were restored
  /// - Returns: A RestoreResult object
  /// - Throws: BackupError if parsing fails
  public func parseRestoreResult(output: String, targetPath: URL) throws -> RestoreResult {
    // Simple parsing - look for file restoration lines
    let lines=output.components(separatedBy: .newlines)

    // Check for errors
    let hasErrors=lines.contains { $0.contains("error") || $0.contains("failed") }
    if hasErrors {
      throw BackupError.parsingError(details: "Errors detected during restore")
    }

    // Count restored files
    let fileLines=lines
      .filter { $0.contains("restoring") }

    return RestoreResult(
      snapshotID: "unknown", // We don't get this from the output
      restoreTime: Date(),
      totalSize: 0, // Not available in simple output
      fileCount: fileLines.count,
      duration: 0, // Not returned in the output
      targetPath: targetPath
    )
  }

  /// Parses the result of a maintenance operation
  /// - Parameters:
  ///   - output: The command output to parse
  ///   - type: The type of maintenance that was performed
  /// - Returns: A maintenance result with details about the operation
  /// - Throws: BackupError if parsing fails
  public func parseMaintenanceResult(
    output: String,
    type: MaintenanceType
  ) throws -> MaintenanceResult {
    // Check for errors in the output
    let outputLower=output.lowercased()
    let hasErrors=outputLower.contains("error") || outputLower.contains("fatal") || outputLower
      .contains("failed")

    // For check operations, we can potentially parse more details
    if type == .check || type == .full {
      return try parseCheckResult(output: output, type: type)
    }

    // For prune operations, attempt to parse space reclaimed
    if type == .prune {
      return try parsePruneResult(output: output)
    }

    // Basic result for other operation types
    return MaintenanceResult(
      maintenanceType: type,
      maintenanceTime: Date(),
      successful: !hasErrors,
      spaceOptimised: nil,
      duration: 0,
      issuesFound: hasErrors ? ["Errors detected in maintenance output"] : [],
      issuesFixed: []
    )
  }

  /// Parses the result of a repository check operation
  /// - Parameter output: The command output to parse
  /// - Returns: A maintenance result with check details
  /// - Throws: BackupError if parsing fails
  private func parseCheckResult(output: String, type: MaintenanceType) throws -> MaintenanceResult {
    let decoder=JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase

    // Try to parse as structured JSON
    do {
      let checkResult=try decoder.decode(ResticCheckResult.self, from: Data(output.utf8))

      return MaintenanceResult(
        maintenanceType: type,
        maintenanceTime: Date(),
        successful: checkResult.success,
        spaceOptimised: nil,
        duration: 0,
        issuesFound: checkResult.errors ?? [],
        issuesFixed: []
      )
    } catch {
      // Fall back to basic parsing if JSON decode fails
      let outputLower=output.lowercased()
      let hasErrors=outputLower.contains("error") || outputLower.contains("fatal") || outputLower
        .contains("failed")

      // Extract errors by looking for error-related lines
      let errorLines=output.components(separatedBy: .newlines)
        .filter {
          let line=$0.lowercased()
          return line.contains("error") || line.contains("fatal") || line.contains("failed")
        }

      return MaintenanceResult(
        maintenanceType: type,
        maintenanceTime: Date(),
        successful: !hasErrors,
        spaceOptimised: nil,
        duration: 0,
        issuesFound: errorLines,
        issuesFixed: []
      )
    }
  }

  /// Parses the result of a prune operation
  /// - Parameter output: The command output to parse
  /// - Returns: A maintenance result with prune details
  /// - Throws: BackupError if parsing fails
  private func parsePruneResult(output: String) throws -> MaintenanceResult {
    // Check for errors
    let outputLower=output.lowercased()
    let hasErrors=outputLower.contains("error") || outputLower.contains("fatal") || outputLower
      .contains("failed")

    // Try to extract space reclaimed information
    var spaceReclaimed: UInt64?

    // Look for lines containing reclaiming space information
    let reclaimLines=output.components(separatedBy: .newlines)
      .filter { $0.contains("reclaiming") && $0.contains("bytes") }

    // Extract the numeric value if available
    if
      let reclaimLine=reclaimLines.first,
      let bytesRange=reclaimLine.range(of: "\\d+", options: .regularExpression)
    {
      let bytesString=String(reclaimLine[bytesRange])
      spaceReclaimed=UInt64(bytesString)
    }

    return MaintenanceResult(
      maintenanceType: .prune,
      maintenanceTime: Date(),
      successful: !hasErrors,
      spaceOptimised: spaceReclaimed,
      duration: 0,
      issuesFound: hasErrors ? ["Errors detected in prune output"] : [],
      issuesFixed: []
    )
  }

  /// Parses the result of a repository initialization
  /// - Parameter output: The command output to parse
  /// - Returns: A boolean indicating success
  /// - Throws: BackupError if parsing fails
  public func parseInitResult(output: String) throws -> Bool {
    // Check for errors
    let outputLower=output.lowercased()
    let hasErrors=outputLower.contains("error") || outputLower.contains("fatal") || outputLower
      .contains("failed")

    // Look for success indicators
    let success=output.contains("created restic repository") ||
      output.contains("successfully initialized")

    return success && !hasErrors
  }

  /// Parses the result of a snapshot listing operation
  /// - Parameters:
  ///   - output: The command output to parse
  ///   - sources: Optional source paths for context
  /// - Returns: An array of backup snapshots
  /// - Throws: BackupError if parsing fails
  public func parseSnapshotsList(output: String, sources: [URL]) throws -> [BackupSnapshot] {
    guard !output.isEmpty else {
      throw BackupError.parsingError(details: "Empty output from snapshots command")
    }

    do {
      let decoder=JSONDecoder()
      decoder.keyDecodingStrategy = .convertFromSnakeCase
      decoder.dateDecodingStrategy = .iso8601

      // Structure matching Restic snapshot JSON format
      struct ResticSnapshot: Decodable {
        let id: String
        let time: Date
        let hostname: String?
        let paths: [String]?
        let tags: [String]?
        let excludes: [String]?
        let fileCount: Int?
        let totalSize: UInt64?
        let description: String?
      }

      // Parse multiple snapshots from JSON array
      let data=output.data(using: .utf8)!
      let resticSnapshots=try decoder.decode([ResticSnapshot].self, from: data)

      // Convert to our domain model
      return resticSnapshots.map { resticSnapshot in
        BackupSnapshot(
          id: resticSnapshot.id,
          creationTime: resticSnapshot.time,
          totalSize: resticSnapshot.totalSize ?? 0,
          fileCount: resticSnapshot.fileCount ?? 0,
          tags: resticSnapshot.tags ?? [],
          hostname: resticSnapshot.hostname ?? "unknown",
          username: "system", // Default since not available in Restic output
          includedPaths: (resticSnapshot.paths ?? sources.map(\.path))
            .map { URL(fileURLWithPath: $0) },
          description: resticSnapshot.description,
          isComplete: true, // Assuming complete backups
          parentSnapshotID: nil, // Not available in basic listing
          repositoryID: "default", // Using default since not available
          fileStats: nil // Not available in basic listing
        )
      }
    } catch {
      throw BackupError
        .parsingError(details: "Failed to parse snapshots: \(error.localizedDescription)")
    }
  }

  /// Parses the result of a diff operation between two snapshots
  /// - Parameters:
  ///   - output: The command output to parse
  ///   - firstSnapshotID: ID of the first snapshot compared
  ///   - secondSnapshotID: ID of the second snapshot compared
  /// - Returns: A snapshot comparison DTO with details about the differences
  /// - Throws: BackupError if parsing fails
  public func parseDiffResult(
    output: String,
    firstSnapshotID: String,
    secondSnapshotID: String
  ) throws -> SnapshotComparisonDTO {
    guard !output.isEmpty else {
      throw BackupError.parsingError(details: "Empty output from diff command")
    }

    let decoder=JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    decoder.dateDecodingStrategy = .iso8601

    // Split output by newlines to handle multiple JSON objects
    let lines=output.components(separatedBy: .newlines)
      .filter { !$0.isEmpty }

    // Parse the summary line for counts
    guard let summaryLine=lines.first(where: { $0.contains("\"summary\"") }) else {
      throw BackupError.parsingError(details: "No summary data in diff output")
    }

    do {
      // Parse the summary data
      let summaryData=try decoder.decode(ResticDiffSummary.self, from: Data(summaryLine.utf8))

      // Extract file lists if available
      var addedFiles: [SnapshotFileDTO]?
      var removedFiles: [SnapshotFileDTO]?
      var modifiedFiles: [SnapshotFileDTO]?

      // Parse added files
      let addedLines=lines.filter { $0.contains("\"added\":true") }
      if !addedLines.isEmpty {
        addedFiles=try parseFileEntries(lines: addedLines, decoder: decoder)
      }

      // Parse removed files
      let removedLines=lines.filter { $0.contains("\"removed\":true") }
      if !removedLines.isEmpty {
        removedFiles=try parseFileEntries(lines: removedLines, decoder: decoder)
      }

      // Parse modified files
      let modifiedLines=lines.filter { $0.contains("\"modified\":true") }
      if !modifiedLines.isEmpty {
        modifiedFiles=try parseFileEntries(lines: modifiedLines, decoder: decoder)
      }

      // Create the comparison result
      return SnapshotComparisonDTO(
        snapshotID1: firstSnapshotID,
        snapshotID2: secondSnapshotID,
        addedCount: summaryData.summary.added,
        removedCount: summaryData.summary.removed,
        modifiedCount: summaryData.summary.modified,
        unchangedCount: summaryData.summary.unchanged,
        addedFiles: addedFiles,
        removedFiles: removedFiles,
        modifiedFiles: modifiedFiles
      )
    } catch {
      throw BackupError
        .parsingError(details: "Failed to parse diff output: \(error.localizedDescription)")
    }
  }

  /// Parses file entries from diff output lines
  /// - Parameters:
  ///   - lines: The lines containing file entries
  ///   - decoder: The JSON decoder to use
  /// - Returns: An array of snapshot file DTOs
  /// - Throws: Error if parsing fails
  private func parseFileEntries(
    lines: [String],
    decoder: JSONDecoder
  ) throws -> [SnapshotFileDTO] {
    var files: [SnapshotFileDTO]=[]

    for line in lines {
      do {
        let fileEntry=try decoder.decode(ResticDiffFileEntry.self, from: Data(line.utf8))

        // Create a snapshot file DTO from the entry
        let fileDTO=SnapshotFileDTO(
          path: fileEntry.path,
          size: UInt64(fileEntry.size),
          modificationTime: fileEntry.mtime,
          type: fileEntry.type ?? "file",
          permissions: fileEntry.permissions,
          owner: fileEntry.user,
          group: fileEntry.group,
          contentHash: fileEntry.hash
        )

        files.append(fileDTO)
      } catch {
        // Skip entries that can't be parsed
        continue
      }
    }

    return files
  }

  /// Represents the summary of a diff operation from Restic
  private struct ResticDiffSummary: Codable {
    struct Summary: Codable {
      let added: Int
      let removed: Int
      let modified: Int
      let unchanged: Int
    }

    let summary: Summary
  }

  /// Represents a file entry in a diff operation from Restic
  private struct ResticDiffFileEntry: Codable {
    let path: String
    let size: Int64
    let mtime: Date
    let type: String?
    let permissions: String?
    let user: String?
    let group: String?
    let hash: String?
    let added: Bool?
    let removed: Bool?
    let modified: Bool?
  }
}
