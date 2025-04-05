import BackupInterfaces
import Foundation

/**
 * Result of a backup verification operation.
 *
 * This struct contains information about the verification process,
 * including any issues found during verification.
 */
public struct BackupVerificationResultDTO: Sendable, Equatable {
  /// Whether the verification completed successfully
  public let verified: Bool

  /// The total number of objects verified
  public let objectsVerified: Int

  /// The total size of verified data in bytes
  public let bytesVerified: UInt64

  /// Number of errors encountered during verification
  public let errorCount: Int

  /// List of verification issues discovered
  public let issues: [VerificationIssue]

  /// Summary of automatic repairs performed (if enabled)
  public let repairSummary: RepairSummary?

  /// Snapshot ID that was verified
  public let snapshotID: String

  /// Time taken to complete verification
  public let verificationTime: TimeInterval

  /**
   * Creates a new verification result.
   *
   * - Parameters:
   *   - verified: Whether verification completed successfully
   *   - objectsVerified: Number of objects verified
   *   - bytesVerified: Total size of verified data in bytes
   *   - errorCount: Number of errors encountered
   *   - issues: List of verification issues discovered
   *   - repairSummary: Summary of automatic repairs (if performed)
   *   - snapshotID: ID of the verified snapshot
   *   - verificationTime: Time taken for verification
   */
  public init(
    verified: Bool,
    objectsVerified: Int,
    bytesVerified: UInt64,
    errorCount: Int,
    issues: [VerificationIssue],
    repairSummary: RepairSummary?,
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
}

/**
 * Describes an issue found during backup verification.
 */
public struct VerificationIssue: Sendable, Equatable {
  /// Type of verification issue
  public enum IssueType: String, Sendable, Equatable {
    /// Data corruption detected
    case corruption

    /// Missing data that should be present
    case missingData

    /// Invalid cryptographic signature
    case invalidSignature

    /// Inconsistent metadata
    case metadataInconsistency

    /// Other unspecified issue
    case other
  }

  /// The type of issue
  public let type: IssueType

  /// Path or identifier of the affected object
  public let objectPath: String

  /// Detailed description of the issue
  public let description: String

  /// Whether the issue was automatically repaired
  public let repaired: Bool

  /**
   * Creates a new verification issue.
   *
   * - Parameters:
   *   - type: Type of verification issue
   *   - objectPath: Path or ID of the affected object
   *   - description: Detailed description of the issue
   *   - repaired: Whether the issue was repaired
   */
  public init(
    type: IssueType,
    objectPath: String,
    description: String,
    repaired: Bool=false
  ) {
    self.type=type
    self.objectPath=objectPath
    self.description=description
    self.repaired=repaired
  }
}

/**
 * Summary of automatic repairs performed during verification.
 */
public struct RepairSummary: Sendable, Equatable {
  /// Number of issues that were successfully repaired
  public let issuesRepaired: Int

  /// Number of issues that failed to be repaired
  public let repairFailures: Int

  /// List of repairs performed
  public let repairs: [RepairAction]

  /**
   * Creates a new repair summary.
   *
   * - Parameters:
   *   - issuesRepaired: Number of successful repairs
   *   - repairFailures: Number of failed repairs
   *   - repairs: List of repair actions performed
   */
  public init(
    issuesRepaired: Int,
    repairFailures: Int,
    repairs: [RepairAction]
  ) {
    self.issuesRepaired=issuesRepaired
    self.repairFailures=repairFailures
    self.repairs=repairs
  }
}

/**
 * Describes a repair action performed during verification.
 */
public struct RepairAction: Sendable, Equatable {
  /// Type of repair performed
  public enum RepairType: String, Sendable, Equatable {
    /// Reconstructed missing data
    case reconstruction

    /// Restored from redundant copies
    case redundantCopy

    /// Replaced corrupted data with a known good version
    case replacement

    /// Fixed metadata inconsistency
    case metadataFix

    /// Other repair type
    case other
  }

  /// The type of repair performed
  public let type: RepairType

  /// Path or identifier of the repaired object
  public let objectPath: String

  /// Description of the repair action
  public let description: String

  /// Whether the repair was successful
  public let successful: Bool

  /**
   * Creates a new repair action.
   *
   * - Parameters:
   *   - type: Type of repair performed
   *   - objectPath: Path or ID of the repaired object
   *   - description: Description of the repair action
   *   - successful: Whether the repair was successful
   */
  public init(
    type: RepairType,
    objectPath: String,
    description: String,
    successful: Bool
  ) {
    self.type=type
    self.objectPath=objectPath
    self.description=description
    self.successful=successful
  }
}

// MARK: - Conversion Methods

extension BackupVerificationResultDTO {
    /// Convert this DTO to a BackupInterfaces.VerificationResult
    public func toVerificationResult() -> VerificationResult {
        VerificationResult(
            verified: verified,
            objectsVerified: objectsVerified,
            bytesVerified: bytesVerified,
            errorCount: errorCount,
            issues: issues.map { $0.toVerificationIssue() },
            repairSummary: repairSummary?.toRepairSummary(),
            snapshotID: snapshotID,
            verificationTime: verificationTime
        )
    }
    
    /// Create a BackupVerificationResultDTO from a BackupInterfaces.VerificationResult
    public static func from(verificationResult: VerificationResult) -> BackupVerificationResultDTO {
        BackupVerificationResultDTO(
            verified: verificationResult.verified,
            objectsVerified: verificationResult.objectsVerified,
            bytesVerified: verificationResult.bytesVerified,
            errorCount: verificationResult.errorCount,
            issues: verificationResult.issues.map { VerificationIssue.from(issue: $0) },
            repairSummary: verificationResult.repairSummary.map { RepairSummary.from(summary: $0) },
            snapshotID: verificationResult.snapshotID,
            verificationTime: verificationResult.verificationTime
        )
    }
}

extension BackupVerificationResultDTO.VerificationIssue {
    /// Convert this DTO to a BackupInterfaces.VerificationIssue
    public func toVerificationIssue() -> VerificationResult.VerificationIssue {
        VerificationResult.VerificationIssue(
            type: VerificationResult.VerificationIssue.IssueType(rawValue: type.rawValue) ?? .unknown,
            objectID: objectPath,
            details: description,
            severity: VerificationResult.VerificationIssue.Severity(rawValue: "warning") ?? .warning,
            repairable: repaired
        )
    }
    
    /// Create a VerificationIssue from a BackupInterfaces.VerificationIssue
    public static func from(issue: VerificationResult.VerificationIssue) -> BackupVerificationResultDTO.VerificationIssue {
        BackupVerificationResultDTO.VerificationIssue(
            type: IssueType(rawValue: issue.type.rawValue) ?? .unknown,
            objectPath: issue.objectID,
            description: issue.details,
            repaired: issue.repairable
        )
    }
}

extension BackupVerificationResultDTO.RepairSummary {
    /// Convert this DTO to a BackupInterfaces.RepairSummary
    public func toRepairSummary() -> VerificationResult.RepairSummary {
        VerificationResult.RepairSummary(
            actionsPerformed: repairs.map { $0.toRepairAction() },
            repairSuccess: issuesRepaired > 0,
            objectsRepaired: issuesRepaired,
            bytesRecovered: 0,
            repairTime: 0
        )
    }
    
    /// Create a RepairSummary from a BackupInterfaces.RepairSummary
    public static func from(summary: VerificationResult.RepairSummary) -> BackupVerificationResultDTO.RepairSummary {
        BackupVerificationResultDTO.RepairSummary(
            issuesRepaired: summary.objectsRepaired,
            repairFailures: 0,
            repairs: summary.actionsPerformed.map { RepairAction.from(action: $0) }
        )
    }
}

extension BackupVerificationResultDTO.RepairAction {
    /// Convert this DTO to a BackupInterfaces.RepairAction
    public func toRepairAction() -> VerificationResult.RepairAction {
        VerificationResult.RepairAction(
            type: VerificationResult.RepairAction.RepairType(rawValue: type.rawValue) ?? .reconstruction,
            objectID: objectPath,
            details: description,
            successful: successful
        )
    }
    
    /// Create a RepairAction from a BackupInterfaces.RepairAction
    public static func from(action: VerificationResult.RepairAction) -> BackupVerificationResultDTO.RepairAction {
        BackupVerificationResultDTO.RepairAction(
            type: RepairType(rawValue: action.type.rawValue) ?? .reconstruction,
            objectPath: action.objectID,
            description: action.details,
            successful: action.successful
        )
    }
}
