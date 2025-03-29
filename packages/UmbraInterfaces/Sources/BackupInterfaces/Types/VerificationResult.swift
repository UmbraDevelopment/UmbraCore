import Foundation

/// Represents the result of a snapshot verification operation
///
/// This type encapsulates the outcome of verifying a snapshot's integrity,
/// including overall status, any issues found, and timing information.
public struct VerificationResult: Sendable, Equatable {
  /// Indicates whether the verification was successful
  public let successful: Bool

  /// List of issues found during verification
  public let issues: [VerificationIssue]

  /// Start time of the verification
  public let startTime: Date

  /// End time of the verification
  public let endTime: Date

  /// Duration of the verification in seconds
  public var duration: TimeInterval {
    endTime.timeIntervalSince(startTime)
  }

  /// Creates a new verification result
  /// - Parameters:
  ///   - successful: Whether the verification was successful
  ///   - issues: List of issues found during verification
  ///   - startTime: Start time of the verification
  ///   - endTime: End time of the verification
  public init(
    successful: Bool,
    issues: [VerificationIssue],
    startTime: Date,
    endTime: Date
  ) {
    self.successful=successful
    self.issues=issues
    self.startTime=startTime
    self.endTime=endTime
  }
}

/// Represents an issue found during snapshot verification
public struct VerificationIssue: Sendable, Equatable {
  /// Type of verification issue
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

  /// The type of issue
  public let type: IssueType

  /// Path to the affected file or component, if applicable
  public let path: String?

  /// Detailed description of the issue
  public let description: String

  /// Potential resolution for the issue, if available
  public let resolution: String?

  /// Creates a new verification issue
  /// - Parameters:
  ///   - type: The type of issue
  ///   - path: Path to the affected file or component
  ///   - description: Detailed description of the issue
  ///   - resolution: Potential resolution for the issue
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
