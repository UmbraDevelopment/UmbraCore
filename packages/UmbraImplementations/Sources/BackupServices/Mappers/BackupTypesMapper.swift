import BackupInterfaces
import Foundation

/**
 * Provides mapping functionality between BackupInterfaces types and BackupServices types.
 *
 * This mapper helps with the conversion of types across module boundaries, ensuring
 * proper separation of concerns while maintaining type safety.
 */
public enum BackupTypesMapper {

  // MARK: - VerificationIssue Mapping

  /**
   * Converts a BackupServices VerificationIssue.IssueType to a BackupInterfaces VerificationIssue.IssueType.
   *
   * - Parameter type: The BackupServices issue type to convert
   * - Returns: The corresponding BackupInterfaces issue type
   */
  public static func toInterfaceIssueType(
    _ type: VerificationIssueDTO
      .IssueType
  ) -> BackupInterfaces.VerificationIssue.IssueType {
    switch type {
      case .missingData:
        .missingData
      case .corruption:
        .corruption
      case .metadataInconsistency:
        .metadataInconsistency
      case .checksumMismatch:
        .checksumMismatch
      case .integrityViolation:
        .integrityViolation
      case .other:
        .other
    }
  }

  /**
   * Converts a BackupServices VerificationIssue to a BackupInterfaces VerificationIssue.
   *
   * - Parameter issue: The BackupServices issue to convert
   * - Returns: The converted issue compatible with the interfaces module
   */
  public static func toInterfaceVerificationIssue(_ issue: VerificationIssueDTO) -> BackupInterfaces
  .VerificationIssue {
    BackupInterfaces.VerificationIssue(
      type: toInterfaceIssueType(issue.type),
      path: issue.path,
      description: issue.description,
      resolution: issue.resolution
    )
  }

  /**
   * Converts an array of BackupServices VerificationIssues to an array of BackupInterfaces VerificationIssues.
   *
   * - Parameter issues: The array of BackupServices issues to convert
   * - Returns: An array of converted issues compatible with the interfaces module
   */
  public static func toInterfaceVerificationIssues(_ issues: [VerificationIssueDTO])
  -> [BackupInterfaces.VerificationIssue] {
    issues.map(toInterfaceVerificationIssue)
  }

  // MARK: - RepairSummary Mapping

  /**
   * Converts a BackupServices RepairSummary to a BackupInterfaces RepairSummary.
   *
   * - Parameter summary: The BackupServices repair summary to convert
   * - Returns: The converted repair summary compatible with the interfaces module
   */
  public static func toInterfaceRepairSummary(_ summary: RepairSummaryDTO) -> BackupInterfaces
  .RepairSummary {
    BackupInterfaces.RepairSummary(
      repairedCount: summary.repairedCount,
      unrepairedCount: summary.unrepairedCount,
      actions: summary.actions.map(toInterfaceRepairAction)
    )
  }

  /**
   * Converts a BackupServices RepairAction to a BackupInterfaces RepairAction.
   *
   * - Parameter action: The BackupServices repair action to convert
   * - Returns: The converted repair action compatible with the interfaces module
   */
  public static func toInterfaceRepairAction(_ action: RepairActionDTO) -> BackupInterfaces
  .RepairAction {
    BackupInterfaces.RepairAction(
      type: toInterfaceRepairActionType(action.type),
      path: action.path,
      description: action.description,
      successful: action.successful
    )
  }

  /**
   * Converts a BackupServices RepairAction.ActionType to a BackupInterfaces RepairAction.ActionType.
   *
   * - Parameter type: The BackupServices action type to convert
   * - Returns: The corresponding BackupInterfaces action type
   */
  public static func toInterfaceRepairActionType(
    _ type: RepairActionDTO
      .ActionType
  ) -> BackupInterfaces.RepairAction.ActionType {
    switch type {
      case .recreateData:
        .recreateData
      case .restoreFromBackup:
        .restoreFromBackup
      case .rebuildMetadata:
        .rebuildMetadata
      case .removeCorrupted:
        .removeCorrupted
      case .other:
        .other
    }
  }

  // MARK: - File Type Mapping

  /**
   * Converts a string file type to a BackupInterfaces.FileType.
   *
   * - Parameter type: The source file type as a string
   * - Returns: A converted file type compatible with the interfaces module
   */
  public static func toInterfaceFileType(_ type: String?) -> BackupInterfaces.FileType {
    guard let type else { return .regular }

    switch type.lowercased() {
      case "dir", "directory":
        return .directory
      case "symlink", "link":
        return .symlink
      default:
        return .regular
    }
  }

  /**
   * Converts a permissions string to FilePermissions.
   *
   * - Parameter permissionsString: The permissions string to convert (e.g., "rwxr-xr--")
   * - Returns: The converted FilePermissions object
   */
  public static func toInterfaceFilePermissions(_ permissionsString: String?) -> BackupInterfaces
  .FilePermissions? {
    guard let permissionsString else { return nil }

    // Convert the permissions string to a mode value
    var mode: UInt16=0

    // Owner permissions
    if
      !permissionsString
        .isEmpty && permissionsString[permissionsString.startIndex] == "r" { mode |= 0o400 }
    if
      permissionsString.count > 1 && permissionsString[permissionsString.index(
        permissionsString.startIndex,
        offsetBy: 1
      )] == "w" { mode |= 0o200 }
    if
      permissionsString.count > 2 && permissionsString[permissionsString.index(
        permissionsString.startIndex,
        offsetBy: 2
      )] == "x" { mode |= 0o100 }

    // Group permissions
    if
      permissionsString.count > 3 && permissionsString[permissionsString.index(
        permissionsString.startIndex,
        offsetBy: 3
      )] == "r" { mode |= 0o040 }
    if
      permissionsString.count > 4 && permissionsString[permissionsString.index(
        permissionsString.startIndex,
        offsetBy: 4
      )] == "w" { mode |= 0o020 }
    if
      permissionsString.count > 5 && permissionsString[permissionsString.index(
        permissionsString.startIndex,
        offsetBy: 5
      )] == "x" { mode |= 0o010 }

    // Others permissions
    if
      permissionsString.count > 6 && permissionsString[permissionsString.index(
        permissionsString.startIndex,
        offsetBy: 6
      )] == "r" { mode |= 0o004 }
    if
      permissionsString.count > 7 && permissionsString[permissionsString.index(
        permissionsString.startIndex,
        offsetBy: 7
      )] == "w" { mode |= 0o002 }
    if
      permissionsString.count > 8 && permissionsString[permissionsString.index(
        permissionsString.startIndex,
        offsetBy: 8
      )] == "x" { mode |= 0o001 }

    return BackupInterfaces.FilePermissions(mode: mode)
  }

  // MARK: - SnapshotFile Mapping

  /**
   * Converts a BackupServices.SnapshotFile to a BackupInterfaces.SnapshotFileEntry.
   *
   * - Parameter file: The source snapshot file to convert
   * - Returns: A converted snapshot file entry compatible with the interfaces module
   */
  public static func toInterfaceSnapshotFileEntry(
    _ file: BackupServices
      .SnapshotFile
  ) -> BackupInterfaces.SnapshotFileEntry {
    BackupInterfaces.SnapshotFileEntry(
      path: file.path ?? "",
      size: file.size ?? 0,
      modificationTime: file.modificationTime ?? Date(),
      type: toInterfaceFileType(file.type),
      permissions: toInterfaceFilePermissions(file.permissions),
      owner: file.owner ?? "",
      group: file.group ?? "",
      contentHash: file.contentHash
    )
  }

  /**
   * Converts an array of BackupServices.SnapshotFile to an array of BackupInterfaces.SnapshotFileEntry.
   *
   * - Parameter files: The source snapshot files to convert
   * - Returns: An array of converted snapshot file entries compatible with the interfaces module
   */
  public static func toInterfaceSnapshotFileEntries(_ files: [BackupServices.SnapshotFile]?)
  -> [BackupInterfaces.SnapshotFileEntry]? {
    guard let files else { return nil }
    return files.map(toInterfaceSnapshotFileEntry)
  }

  // MARK: - Verification Result Mapping

  /**
   * Converts a BackupServices verification result to a BackupInterfaces.BackupVerificationResult.
   *
   * - Parameters:
   *   - verified: Whether the verification was successful
   *   - objectsVerified: Number of objects verified
   *   - bytesVerified: Number of bytes verified
   *   - errorCount: Number of errors found
   *   - issues: Array of verification issues
   *   - repairSummary: Optional repair summary
   * - Returns: A converted verification result compatible with the interfaces module
   */
  public static func toInterfaceVerificationResult(
    verified: Bool,
    objectsVerified: Int,
    bytesVerified: UInt64,
    errorCount: Int,
    issues: [VerificationIssueDTO],
    repairSummary: RepairSummaryDTO?
  ) -> BackupInterfaces.BackupVerificationResult {
    BackupInterfaces.BackupVerificationResult(
      verified: verified,
      objectsVerified: objectsVerified,
      bytesVerified: Int64(bytesVerified),
      errorCount: errorCount,
      issues: toInterfaceVerificationIssues(issues),
      repairSummary: repairSummary.map(toInterfaceRepairSummary)
    )
  }
}
