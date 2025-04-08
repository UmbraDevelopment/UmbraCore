import Foundation

/**
 * Parameters for listing backups.
 *
 * This struct encapsulates all the parameters needed to list backups,
 * including filters for tags, host, path, and time ranges.
 */
public struct ListParameters: Sendable {
  /// Tags to filter by
  public let tags: [String]?

  /// Host to filter by
  public let host: String?

  /// Path to filter by
  public let path: String?

  /// Date to filter snapshots before
  public let before: Date?

  /// Date to filter snapshots after
  public let after: Date?

  /// Additional options for the list operation
  public let options: ListOptions?

  /**
   * Creates a new set of list parameters.
   *
   * - Parameters:
   *   - tags: Tags to filter by
   *   - host: Host to filter by
   *   - path: Path to filter by
   *   - before: Date to filter snapshots before
   *   - after: Date to filter snapshots after
   *   - options: Additional options for the list operation
   */
  public init(
    tags: [String]?=nil,
    host: String?=nil,
    path: String?=nil,
    before: Date?=nil,
    after: Date?=nil,
    options: ListOptions?=nil
  ) {
    self.tags=tags
    self.host=host
    self.path=path
    self.before=before
    self.after=after
    self.options=options
  }
}

// Implement Equatable conformance manually
extension ListParameters: Equatable {
  public static func == (lhs: ListParameters, rhs: ListParameters) -> Bool {
    lhs.tags == rhs.tags &&
      lhs.host == rhs.host &&
      lhs.path == rhs.path &&
      lhs.before == rhs.before &&
      lhs.after == rhs.after &&
      lhs.options == rhs.options
  }
}
