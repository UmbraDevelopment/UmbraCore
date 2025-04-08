import Foundation

/**
 * Parameters for creating a backup.
 *
 * This struct encapsulates all the parameters needed to create a new backup,
 * including sources, exclusions, tags, and options.
 */
public struct BackupParameters: Sendable {
  /// Paths to include in the backup
  public let sources: [String]

  /// Paths to exclude from the backup
  public let excludePaths: [String]?

  /// Tags to apply to the backup
  public let tags: [String]?

  /// Additional options for the backup operation
  public let options: BackupOptions?

  /**
   * Creates a new set of backup parameters.
   *
   * - Parameters:
   *   - sources: Paths to include in the backup
   *   - excludePaths: Paths to exclude from the backup
   *   - tags: Tags to apply to the backup
   *   - options: Additional options for the backup operation
   */
  public init(
    sources: [String],
    excludePaths: [String]?=nil,
    tags: [String]?=nil,
    options: BackupOptions?=nil
  ) {
    self.sources=sources
    self.excludePaths=excludePaths
    self.tags=tags
    self.options=options
  }
}

// Implement Equatable conformance manually
extension BackupParameters: Equatable {
  public static func == (lhs: BackupParameters, rhs: BackupParameters) -> Bool {
    lhs.sources == rhs.sources &&
      lhs.excludePaths == rhs.excludePaths &&
      lhs.tags == rhs.tags &&
      lhs.options == rhs.options
  }
}
