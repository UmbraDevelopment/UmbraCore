import BackupInterfaces
import Foundation

/**
 * Result of a snapshot verification operation.
 *
 * This struct contains information about the verification process,
 * including any issues found during verification.
 */
public struct SnapshotVerificationResult: Sendable, Equatable {
  /// Whether the verification completed successfully
  public let verified: Bool

  /// The total number of objects verified
  public let objectsVerified: Int

  /// The total size of verified data in bytes
  public let bytesVerified: UInt64

  /// List of errors encountered during verification
  public let errors: [VerificationError]

  /// Summary of automatic repairs (if enabled)
  public let repairSummary: RepairSummaryResult?

  /**
   * Creates a new verification result.
   *
   * - Parameters:
   *   - verified: Whether verification completed successfully
   *   - objectsVerified: Number of objects verified
   *   - bytesVerified: Total size of verified data in bytes
   *   - errors: List of verification errors discovered
   *   - repairSummary: Summary of automatic repairs (if performed)
   */
  public init(
    verified: Bool,
    objectsVerified: Int,
    bytesVerified: UInt64,
    errors: [VerificationError],
    repairSummary: RepairSummaryResult?
  ) {
    self.verified=verified
    self.objectsVerified=objectsVerified
    self.bytesVerified=bytesVerified
    self.errors=errors
    self.repairSummary=repairSummary
  }
}

/**
 * Error found during snapshot verification.
 */
public struct VerificationError: Sendable, Equatable {
  /// Type of the error
  public let type: String

  /// Path to the affected object
  public let path: String

  /// Error message
  public let message: String

  /// Whether the error was repaired
  public let repaired: Bool

  /**
   * Creates a new verification error.
   *
   * - Parameters:
   *   - type: Type of the error
   *   - path: Path to the affected object
   *   - message: Error message
   *   - repaired: Whether the error was repaired
   */
  public init(
    type: String,
    path: String,
    message: String,
    repaired: Bool=false
  ) {
    self.type=type
    self.path=path
    self.message=message
    self.repaired=repaired
  }
}

/**
 * Summary of automatic repairs performed during verification.
 */
public struct RepairSummaryResult: Sendable, Equatable {
  /// Number of successful repairs
  public let repairsSuccessful: Int

  /// Number of failed repairs
  public let repairsFailed: Int

  /// List of repair actions
  public let repairs: [RepairResult]

  /**
   * Creates a new repair summary.
   *
   * - Parameters:
   *   - repairsSuccessful: Number of successful repairs
   *   - repairsFailed: Number of failed repairs
   *   - repairs: List of repair actions
   */
  public init(
    repairsSuccessful: Int,
    repairsFailed: Int,
    repairs: [RepairResult]
  ) {
    self.repairsSuccessful=repairsSuccessful
    self.repairsFailed=repairsFailed
    self.repairs=repairs
  }
}

/**
 * Repair action performed during verification.
 */
public struct RepairResult: Sendable, Equatable {
  /// Type of repair performed
  public let type: String

  /// Path to the repaired object
  public let path: String

  /// Description of the repair
  public let description: String

  /// Whether the repair was successful
  public let successful: Bool

  /**
   * Creates a new repair result.
   *
   * - Parameters:
   *   - type: Type of repair performed
   *   - path: Path to the repaired object
   *   - description: Description of the repair
   *   - successful: Whether the repair was successful
   */
  public init(
    type: String,
    path: String,
    description: String,
    successful: Bool
  ) {
    self.type=type
    self.path=path
    self.description=description
    self.successful=successful
  }
}
