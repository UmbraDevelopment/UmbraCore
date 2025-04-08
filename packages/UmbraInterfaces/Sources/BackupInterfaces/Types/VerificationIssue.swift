import Foundation

/**
 * Represents an issue found during backup verification.
 *
 * This struct encapsulates information about a specific issue found
 * during backup verification, including its type, location, and
 * whether it was repaired.
 */
public struct VerificationIssue: Sendable, Equatable {
  /**
   * Types of verification issues.
   */
  public enum IssueType: String, Sendable, Equatable, CaseIterable {
    /// Missing data that should be present
    case missingData

    /// Corrupted data that cannot be read or is invalid
    case corruption

    /// Inconsistency in metadata
    case metadataInconsistency

    /// Incorrect checksum
    case checksumMismatch

    /// Integrity violation
    case integrityViolation

    /// Other unspecified issue
    case other
  }

  /// Type of the issue
  public let type: IssueType

  /// Path to the affected object
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
   *   - path: Path to the affected object
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
