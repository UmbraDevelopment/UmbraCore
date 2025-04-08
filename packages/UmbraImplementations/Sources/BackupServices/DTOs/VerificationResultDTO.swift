import BackupInterfaces
import Foundation

/**
 * DTO for backup verification results.
 *
 * This type encapsulates the results of a backup verification operation,
 * including whether the verification was successful, counts of verified
 * objects and bytes, and any issues found.
 */
public struct VerificationResultDTO: Sendable, Equatable {
  /// Whether the verification was successful
  public let verified: Bool

  /// Number of objects verified
  public let objectsVerified: Int

  /// Number of bytes verified
  public let bytesVerified: UInt64

  /// Number of errors encountered
  public let errorCount: Int

  /// Issues found during verification
  public let issues: [VerificationIssueDTO]

  /// Summary of repair actions taken, if any
  public let repairSummary: RepairSummaryDTO?

  /**
   * Creates a new verification result DTO.
   *
   * - Parameters:
   *   - verified: Whether the verification was successful
   *   - objectsVerified: Number of objects verified
   *   - bytesVerified: Number of bytes verified
   *   - errorCount: Number of errors encountered
   *   - issues: Issues found during verification
   *   - repairSummary: Summary of repair actions taken, if any
   */
  public init(
    verified: Bool,
    objectsVerified: Int,
    bytesVerified: UInt64,
    errorCount: Int,
    issues: [VerificationIssueDTO],
    repairSummary: RepairSummaryDTO?=nil
  ) {
    self.verified=verified
    self.objectsVerified=objectsVerified
    self.bytesVerified=bytesVerified
    self.errorCount=errorCount
    self.issues=issues
    self.repairSummary=repairSummary
  }

  /**
   * Converts this DTO to a BackupInterfaces.BackupVerificationResult.
   *
   * - Returns: A BackupVerificationResult compatible with the interfaces module
   */
  public func toInterfaceType() -> BackupInterfaces.BackupVerificationResult {
    BackupInterfaces.BackupVerificationResult(
      verified: verified,
      objectsVerified: objectsVerified,
      bytesVerified: Int64(bytesVerified),
      errorCount: errorCount,
      issues: issues.map { BackupTypesMapper.toInterfaceVerificationIssue($0) },
      repairSummary: repairSummary.map { BackupTypesMapper.toInterfaceRepairSummary($0) }
    )
  }
}
