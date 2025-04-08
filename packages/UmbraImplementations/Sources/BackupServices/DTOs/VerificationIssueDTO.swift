import BackupInterfaces
import Foundation

/**
 * DTO for verification issues found during backup verification.
 */
public struct VerificationIssueDTO: Sendable, Equatable {
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

    /// Permission denied when accessing data
    case permissionDenied

    /// Structural error in the repository
    case structuralError
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
   * Creates a new verification issue DTO.
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
