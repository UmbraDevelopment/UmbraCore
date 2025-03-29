import BackupInterfaces
import Foundation
import ResticInterfaces
import UmbraErrors

/// Responsible for creating Restic commands for snapshot operations
///
/// This class centralises all command creation logic for snapshot-related
/// operations, ensuring consistent command structure and arguments.
struct ResticCommandFactory {

  /// Creates a command to get snapshot list with filters
  /// - Parameters:
  ///   - repositoryID: Optional repository ID to filter by
  ///   - tags: Optional tags to filter snapshots by
  ///   - before: Optional date to filter snapshots before
  ///   - after: Optional date to filter snapshots after
  ///   - path: Optional path that must be included in the snapshot
  ///   - limit: Maximum number of snapshots to return
  /// - Returns: A command ready for execution
  /// - Throws: BackupError if command creation fails
  func createListCommand(
    repositoryID: String?,
    tags: [String]?,
    before: Date?,
    after: Date?,
    path: URL?,
    limit: Int?
  ) throws -> ResticCommand {
    var arguments=["snapshots", "--json"]

    // Add filters if provided
    if let repositoryID {
      arguments.append(contentsOf: ["--repo-id", repositoryID])
    }

    if let tags, !tags.isEmpty {
      for tag in tags {
        arguments.append(contentsOf: ["--tag", tag])
      }
    }

    if let before {
      let formatter=ISO8601DateFormatter()
      arguments.append(contentsOf: ["--before", formatter.string(from: before)])
    }

    if let after {
      let formatter=ISO8601DateFormatter()
      arguments.append(contentsOf: ["--after", formatter.string(from: after)])
    }

    if let path {
      arguments.append(contentsOf: ["--path", path.path])
    }

    if let limit {
      arguments.append(contentsOf: ["--limit", String(limit)])
    }

    return ResticCommandImpl(arguments: arguments)
  }

  /// Creates a command to get snapshot details
  /// - Parameters:
  ///   - snapshotID: ID of the snapshot
  ///   - includeFileStatistics: Whether to include detailed file statistics
  /// - Returns: A command ready for execution
  /// - Throws: BackupError if command creation fails
  func createSnapshotDetailsCommand(
    snapshotID: String,
    includeFileStatistics: Bool
  ) throws -> ResticCommand {
    var arguments=["snapshots", snapshotID, "--json"]

    if includeFileStatistics {
      arguments.append("--stats")
    }

    return ResticCommandImpl(arguments: arguments)
  }

  /// Creates a command to compare snapshots
  /// - Parameters:
  ///   - snapshotID1: First snapshot ID
  ///   - snapshotID2: Second snapshot ID
  ///   - path: Optional specific path to compare
  /// - Returns: A command ready for execution
  /// - Throws: BackupError if command creation fails
  func createCompareCommand(
    snapshotID1: String,
    snapshotID2: String,
    path: URL?
  ) throws -> ResticCommand {
    var arguments=["diff", snapshotID1, snapshotID2, "--json"]

    if let path {
      arguments.append(path.path)
    }

    return ResticCommandImpl(arguments: arguments)
  }

  /// Creates a command to update snapshot tags
  /// - Parameters:
  ///   - snapshotID: Snapshot ID to update
  ///   - addTags: Tags to add
  ///   - removeTags: Tags to remove
  /// - Returns: A command ready for execution
  /// - Throws: BackupError if command creation fails
  func createUpdateTagsCommand(
    snapshotID: String,
    addTags: [String],
    removeTags: [String]
  ) throws -> ResticCommand {
    var arguments=["tag", "--id", snapshotID, "--json"]

    for tag in addTags {
      arguments.append(contentsOf: ["--add", tag])
    }

    for tag in removeTags {
      arguments.append(contentsOf: ["--remove", tag])
    }

    return ResticCommandImpl(arguments: arguments)
  }

  /// Creates a command to update snapshot description
  /// - Parameters:
  ///   - snapshotID: Snapshot ID to update
  ///   - description: New description
  /// - Returns: A command ready for execution
  /// - Throws: BackupError if command creation fails
  func createUpdateDescriptionCommand(
    snapshotID: String,
    description: String
  ) throws -> ResticCommand {
    ResticCommandImpl(arguments: [
      "meta", "set-description", "--id", snapshotID, "--description", description
    ])
  }

  /// Creates a command to delete a snapshot
  /// - Parameters:
  ///   - snapshotID: Snapshot ID to delete
  ///   - pruneAfterDelete: Whether to prune repository after deletion
  /// - Returns: A command ready for execution
  /// - Throws: BackupError if command creation fails
  func createDeleteCommand(
    snapshotID: String,
    pruneAfterDelete: Bool
  ) throws -> ResticCommand {
    var arguments=["forget", "--id", snapshotID, "--json"]

    if pruneAfterDelete {
      arguments.append("--prune")
    }

    return ResticCommandImpl(arguments: arguments)
  }

  /// Creates a command to copy a snapshot to another repository
  /// - Parameters:
  ///   - snapshotID: Snapshot ID to copy
  ///   - targetRepositoryID: Target repository ID
  /// - Returns: A command ready for execution
  /// - Throws: BackupError if command creation fails
  func createCopyCommand(
    snapshotID: String,
    targetRepositoryID: String
  ) throws -> ResticCommand {
    ResticCommandImpl(arguments: [
      "copy", "--id", snapshotID, "--repo2-id", targetRepositoryID, "--json"
    ])
  }

  /// Creates a command to find files in a snapshot
  /// - Parameters:
  ///   - snapshotID: Snapshot ID to search
  ///   - pattern: Pattern to search for
  ///   - caseSensitive: Whether the search is case-sensitive
  /// - Returns: A command ready for execution
  /// - Throws: BackupError if command creation fails
  func createFindCommand(
    snapshotID: String,
    pattern: String,
    caseSensitive: Bool
  ) throws -> ResticCommand {
    var arguments=["find", "--snapshot", snapshotID, pattern, "--json"]

    if !caseSensitive {
      arguments.append("--ignore-case")
    }

    return ResticCommandImpl(arguments: arguments)
  }

  /// Creates a command to lock a snapshot
  /// - Parameter snapshotID: Snapshot ID to lock
  /// - Returns: A command ready for execution
  /// - Throws: BackupError if command creation fails
  func createLockCommand(snapshotID: String) throws -> ResticCommand {
    ResticCommandImpl(arguments: [
      "lock", "--id", snapshotID, "--json"
    ])
  }

  /// Creates a command to unlock a snapshot
  /// - Parameter snapshotID: Snapshot ID to unlock
  /// - Returns: A command ready for execution
  /// - Throws: BackupError if command creation fails
  func createUnlockCommand(snapshotID: String) throws -> ResticCommand {
    ResticCommandImpl(arguments: [
      "unlock", "--id", snapshotID, "--json"
    ])
  }

  /// Creates a command to verify a snapshot
  /// - Parameter snapshotID: Snapshot ID to verify
  /// - Returns: A command ready for execution
  /// - Throws: BackupError if command creation fails
  func createVerifyCommand(snapshotID: String) throws -> ResticCommand {
    ResticCommandImpl(arguments: [
      "check", "--read-data", "--snapshot", snapshotID, "--json"
    ])
  }
}
