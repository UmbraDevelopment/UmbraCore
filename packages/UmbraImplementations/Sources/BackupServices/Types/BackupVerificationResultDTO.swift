import BackupInterfaces
import Foundation

/**
 * Data Transfer Object for backup verification results.
 *
 * This DTO encapsulates the results of a backup verification operation,
 * including any issues found during verification.
 */
public struct BackupVerificationResultDTO: Sendable, Equatable {
  /// Whether the verification completed successfully
  public let verified: Bool

  /// Number of objects verified
  public let objectsVerified: Int

  /// Number of bytes verified
  public let bytesVerified: Int64

  /// Number of errors encountered
  public let errorCount: Int

  /// List of verification issues
  public let issues: [VerificationIssue]

  /// Summary of repair actions if applicable
  public let repairSummary: RepairSummary?

  /// ID of the snapshot that was verified
  public let snapshotID: String

  /// Time taken for verification in seconds
  public let verificationTime: TimeInterval

  /**
   * Creates a new verification result DTO.
   *
   * - Parameters:
   *   - verified: Whether the verification completed successfully
   *   - objectsVerified: Number of objects verified
   *   - bytesVerified: Number of bytes verified
   *   - errorCount: Number of errors encountered
   *   - issues: List of verification issues
   *   - repairSummary: Summary of repair actions if applicable
   *   - snapshotID: ID of the snapshot that was verified
   *   - verificationTime: Time taken for verification in seconds
   */
  public init(
    verified: Bool,
    objectsVerified: Int,
    bytesVerified: Int64,
    errorCount: Int,
    issues: [VerificationIssue],
    repairSummary: RepairSummary?=nil,
    snapshotID: String,
    verificationTime: TimeInterval
  ) {
    self.verified=verified
    self.objectsVerified=objectsVerified
    self.bytesVerified=bytesVerified
    self.errorCount=errorCount
    self.issues=issues
    self.repairSummary=repairSummary
    self.snapshotID=snapshotID
    self.verificationTime=verificationTime
  }

  /**
   * Convert to BackupInterfaces.BackupVerificationResultDTO
   */
  public func toBackupVerificationResultDTO() -> BackupInterfaces.BackupVerificationResultDTO {
    // Map our issues to the interface's issue type
    let mappedIssues=issues.map { issue -> BackupInterfaces.BackupVerificationIssueDTO in
      let issueType: BackupInterfaces.BackupVerificationIssueDTO.IssueType=switch issue.type {
        case .missingData:
          .missingData
        case .corruptedData:
          .corruptedData
        case .inconsistentMetadata:
          .inconsistentMetadata
        case .accessError:
          .accessError
        case .other:
          .other
      }

      return BackupInterfaces.BackupVerificationIssueDTO(
        type: issueType,
        path: issue.path,
        description: issue.description,
        resolution: issue.resolution
      )
    }

    // Create result with start/end time based on verification time
    let now=Date()
    let startTime=now.addingTimeInterval(-verificationTime)

    return BackupInterfaces.BackupVerificationResultDTO(
      successful: verified,
      issues: mappedIssues,
      startTime: startTime,
      endTime: now
    )
  }

  /**
   * Create from BackupInterfaces.BackupVerificationResultDTO
   */
  public static func from(
    dto: BackupInterfaces.BackupVerificationResultDTO
  ) -> BackupVerificationResultDTO {
    // Map the interface's issues to our issue type
    let mappedIssues=dto.issues.map { issue -> VerificationIssue in
      let issueType: VerificationIssue.IssueType=switch issue.type {
        case .missingData:
          .missingData
        case .corruptedData:
          .corruptedData
        case .inconsistentMetadata:
          .inconsistentMetadata
        case .accessError:
          .accessError
        case .other:
          .other
      }

      return VerificationIssue(
        type: issueType,
        path: issue.path,
        description: issue.description,
        resolution: issue.resolution
      )
    }

    return BackupVerificationResultDTO(
      verified: dto.successful,
      objectsVerified: 0, // Not available in the interface
      bytesVerified: 0, // Not available in the interface
      errorCount: dto.issues.count,
      issues: mappedIssues,
      repairSummary: nil, // Not available in the interface
      snapshotID: "", // Not available in the interface
      verificationTime: dto.duration
    )
  }
}

/**
 * Represents an issue found during verification.
 */
public struct VerificationIssue: Sendable, Equatable {
  /**
   * Type of verification issue.
   */
  public enum IssueType: String, Sendable, Equatable {
    /// Missing data in the repository
    case missingData

    /// Corrupted data in the repository
    case corruptedData

    /// Inconsistent metadata in the repository
    case inconsistentMetadata

    /// Access error when attempting to verify
    case accessError

    /// Other unspecified issue
    case other
  }

  /// Type of the issue
  public let type: IssueType

  /// Path to the affected file or component
  public let path: String?

  /// Description of the issue
  public let description: String

  /// Potential resolution for the issue
  public let resolution: String?

  /**
   * Creates a new verification issue.
   *
   * - Parameters:
   *   - type: Type of the issue
   *   - path: Path to the affected file or component
   *   - description: Description of the issue
   *   - resolution: Potential resolution for the issue
   */
  public init(
    type: IssueType,
    path: String?=nil,
    description: String,
    resolution: String?=nil
  ) {
    self.type=type
    self.path=path
    self.description=description
    self.resolution=resolution
  }
}

/**
 * Summary of repair actions taken during verification.
 */
public struct RepairSummary: Sendable, Equatable {
  /// Whether repairs were successful
  public let successful: Bool

  /// Number of issues repaired
  public let repairedCount: Int

  /// Number of issues that could not be repaired
  public let unrepairedCount: Int

  /// List of repair actions taken
  public let actions: [RepairAction]

  /**
   * Creates a new repair summary.
   *
   * - Parameters:
   *   - successful: Whether repairs were successful
   *   - repairedCount: Number of issues repaired
   *   - unrepairedCount: Number of issues that could not be repaired
   *   - actions: List of repair actions taken
   */
  public init(
    successful: Bool,
    repairedCount: Int,
    unrepairedCount: Int,
    actions: [RepairAction]
  ) {
    self.successful=successful
    self.repairedCount=repairedCount
    self.unrepairedCount=unrepairedCount
    self.actions=actions
  }
}

/**
 * Represents a repair action taken during verification.
 */
public struct RepairAction: Sendable, Equatable {
  /**
   * Type of repair action.
   */
  public enum ActionType: String, Sendable, Equatable {
    /// Recreated missing data
    case recreateData

    /// Restored from backup copy
    case restoreFromBackup

    /// Rebuilt metadata
    case rebuildMetadata

    /// Removed corrupted data
    case removeCorrupted

    /// Other repair action
    case other
  }

  /// Type of the action
  public let type: ActionType

  /// Path to the affected file or component
  public let path: String?

  /// Description of the action
  public let description: String

  /// Whether the action was successful
  public let successful: Bool

  /**
   * Creates a new repair action.
   *
   * - Parameters:
   *   - type: Type of the action
   *   - path: Path to the affected file or component
   *   - description: Description of the action
   *   - successful: Whether the action was successful
   */
  public init(
    type: ActionType,
    path: String?=nil,
    description: String,
    successful: Bool
  ) {
    self.type=type
    self.path=path
    self.description=description
    self.successful=successful
  }
}
