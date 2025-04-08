import Foundation

/**
 * Result of a backup verification operation.
 *
 * This struct encapsulates the results of verifying a backup,
 * including whether the verification was successful, statistics
 * about the verification, and any issues found.
 */
public struct BackupVerificationResult: Sendable, Equatable {
  /// Whether the verification was successful
  public let verified: Bool

  /// Number of objects that were verified
  public let objectsVerified: Int

  /// Total size of verified data in bytes
  public let bytesVerified: Int64

  /// Number of errors encountered during verification
  public let errorCount: Int

  /// List of issues found during verification
  public let issues: [VerificationIssue]

  /// Summary of repair actions taken (if any)
  public let repairSummary: RepairSummary?

  /**
   * Creates a new verification result.
   *
   * - Parameters:
   *   - verified: Whether the verification was successful
   *   - objectsVerified: Number of objects that were verified
   *   - bytesVerified: Total size of verified data in bytes
   *   - errorCount: Number of errors encountered during verification
   *   - issues: List of issues found during verification
   *   - repairSummary: Summary of repair actions taken (if any)
   */
  public init(
    verified: Bool,
    objectsVerified: Int,
    bytesVerified: Int64,
    errorCount: Int,
    issues: [VerificationIssue],
    repairSummary: RepairSummary?=nil
  ) {
    self.verified=verified
    self.objectsVerified=objectsVerified
    self.bytesVerified=bytesVerified
    self.errorCount=errorCount
    self.issues=issues
    self.repairSummary=repairSummary
  }
}
