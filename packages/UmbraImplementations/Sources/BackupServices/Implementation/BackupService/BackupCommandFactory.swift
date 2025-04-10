import BackupInterfaces
import Foundation
import ResticInterfaces
import UmbraErrors

/// Responsible for creating Restic commands for backup operations
///
/// This class centralises all command creation logic for backup-related
/// operations, ensuring consistent command structure and arguments.
public struct BackupCommandFactory {

  /// Creates a backup command from the provided sources, exclusions, and tags
  /// - Parameters:
  ///   - sources: Paths to include in the backup
  ///   - excludePaths: Optional paths to exclude
  ///   - tags: Optional tags to associate with the backup
  ///   - options: Additional options for the backup
  /// - Returns: A command ready for execution
  /// - Throws: BackupError if command creation fails
  public func createBackupCommand(
    sources: [URL],
    excludePaths: [URL]?,
    tags: [String]?,
    options: BackupOptions?
  ) throws -> ResticCommand {
    // Validate inputs
    guard !sources.isEmpty else {
      throw BackupError.invalidConfiguration(details: "No source paths provided")
    }

    // Start with basic backup command
    var arguments=["backup"]

    // Add sources
    arguments.append(contentsOf: sources.map(\.path))

    // Add excludes if provided
    if let excludePaths, !excludePaths.isEmpty {
      for excludePath in excludePaths {
        arguments.append(contentsOf: ["--exclude", excludePath.path])
      }
    }

    // Add tags if provided
    if let tags, !tags.isEmpty {
      for tag in tags {
        arguments.append(contentsOf: ["--tag", tag])
      }
    }

    // Add options if provided
    if let options {
      if let compressionLevel=options.compressionLevel {
        arguments.append("--compression=\(compressionLevel)")
      }

      // Handle verification
      if options.verifyAfterBackup {
        arguments.append("--verify")
      }

      // Handle parallelisation
      if options.useParallelisation {
        arguments.append("--parallel")
      }

      // Handle priority
      switch options.priority {
        case .low:
          arguments.append("--nice=19")
        case .high:
          arguments.append("--nice=0")
        case .critical:
          arguments.append("--nice=-20")
        case .normal:
          break // Default priority
      }

      // Handle max size if specified
      if let maxSize=options.maxSize {
        arguments.append("--max-size=\(maxSize)")
      }
    }

    // Always add JSON output
    arguments.append("--json")

    return ResticCommandImpl(arguments: arguments)
  }

  /// Creates a restore command from the provided parameters
  /// - Parameters:
  ///   - snapshotID: ID of the snapshot to restore
  ///   - targetPath: Path to restore files to
  ///   - includePaths: Optional specific paths to restore
  ///   - excludePaths: Optional paths to exclude from restoration
  ///   - options: Additional options for the restore operation
  /// - Returns: A command ready for execution
  /// - Throws: BackupError if command creation fails
  public func createRestoreCommand(
    snapshotID: String,
    targetPath: URL,
    includePaths: [URL]?,
    excludePaths: [URL]?,
    options: RestoreOptions?
  ) throws -> ResticCommand {
    // Start with basic restore command
    var arguments=["restore", snapshotID, "--target", targetPath.path]

    // Add includes if provided
    if let includePaths, !includePaths.isEmpty {
      for includePath in includePaths {
        arguments.append(contentsOf: ["--include", includePath.path])
      }
    }

    // Add excludes if provided
    if let excludePaths, !excludePaths.isEmpty {
      for excludePath in excludePaths {
        arguments.append(contentsOf: ["--exclude", excludePath.path])
      }
    }

    // Add options if provided
    if let options {
      // RestoreOptions doesn't have dryRun, but we can handle the other properties

      // Handle overwrite
      if options.overwriteExisting {
        arguments.append("--force")
      }

      // Handle restore permissions
      if options.restorePermissions {
        arguments.append("--preserve-permissions")
      }

      // Handle verification
      if options.verifyAfterRestore {
        arguments.append("--verify")
      }

      // Handle parallelisation
      if options.useParallelisation {
        arguments.append("--parallel")
      }

      // Handle priority
      switch options.priority {
        case .low:
          arguments.append("--nice=19")
        case .high:
          arguments.append("--nice=0")
        case .critical:
          arguments.append("--nice=-20")
        case .normal:
          break // Default priority
      }
    }

    // Always add JSON output
    arguments.append("--json")

    return ResticCommandImpl(arguments: arguments)
  }

  /// Creates a maintenance command with the specified type and options
  /// - Parameters:
  ///   - type: Type of maintenance to perform
  ///   - options: Additional options for the maintenance operation
  /// - Returns: A command ready for execution
  /// - Throws: BackupError if command creation fails
  public func createMaintenanceCommand(
    type: MaintenanceType,
    options: MaintenanceOptions?
  ) throws -> ResticCommand {
    // Determine base command from maintenance type
    var baseCommand=switch type {
      case .check:
        "check"
      case .prune:
        "prune"
      case .rebuildIndex:
        "rebuild-index"
      case .optimise:
        "prune" // Using prune with specific options for optimization
      case .full:
        // For full maintenance, we're using check which is the most comprehensive
        "check"
    }

    // Start with base command
    var arguments=[baseCommand]

    // Add options if provided
    if let options {
      if options.dryRun {
        arguments.append("--dry-run")
      }

      if baseCommand == "check" {
        arguments.append("--verify-data")
      }
    }

    // Always add JSON output
    arguments.append("--json")

    return ResticCommandImpl(arguments: arguments)
  }

  /// Creates an initialization command for a repository
  /// - Parameters:
  ///   - location: Repository location (path or URL)
  ///   - password: Repository password
  /// - Returns: A command ready for execution
  /// - Throws: BackupError if command creation fails
  public func createInitCommand(
    location: String,
    password: String
  ) throws -> ResticCommand {
    // Environment variables including password
    var environment=ProcessInfo.processInfo.environment
    environment["RESTIC_PASSWORD"]=password

    // Init command with repository location
    let arguments=["init", "--repository", location, "--json"]

    return ResticCommandImpl(arguments: arguments, environment: environment)
  }

  /// Creates a repository check command
  /// - Parameters:
  ///   - options: Optional check options
  /// - Returns: A command ready for execution
  /// - Throws: BackupError if command creation fails
  public func createCheckCommand(options: RepositoryCheckOptions?) throws -> ResticCommand {
    var arguments=["check"]

    if let options {
      if options.readData {
        arguments.append("--read-data")
      }

      if options.checkUnused {
        arguments.append("--check-unused")
      }
    }

    // Always add JSON output
    arguments.append("--json")

    return ResticCommandImpl(arguments: arguments)
  }

  /// Creates a command to list snapshots
  /// - Parameters:
  ///   - repositoryID: ID of the repository to list snapshots from
  ///   - tags: Optional tags to filter snapshots by
  ///   - before: Optional date to filter snapshots before
  ///   - after: Optional date to filter snapshots after
  ///   - path: Optional path contained in snapshots
  ///   - limit: Optional maximum number of snapshots to return
  /// - Returns: A command ready for execution
  /// - Throws: BackupError if command creation fails
  public func createListCommand(
    repositoryID: String?,
    tags: [String]?,
    before: Date?,
    after: Date?,
    path: URL?,
    limit: Int?
  ) throws -> ResticCommand {
    var arguments=["snapshots"]

    // Add optional arguments
    if let repositoryID {
      arguments.append(contentsOf: ["--repository-id", repositoryID])
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

    // Always add JSON output
    arguments.append("--json")

    return ResticCommandImpl(arguments: arguments)
  }

  /// Creates a command to delete a snapshot
  /// - Parameters:
  ///   - snapshotID: ID of the snapshot to delete
  ///   - pruneAfterDelete: Whether to prune unreferenced data after deletion
  /// - Returns: A command ready for execution
  /// - Throws: BackupError if command creation fails
  public func createDeleteCommand(
    snapshotID: String,
    pruneAfterDelete: Bool
  ) throws -> ResticCommand {
    var arguments=["forget", snapshotID]

    // Add deletion flags
    arguments.append("--remove-data") // Actually remove data, not just the snapshot reference

    if pruneAfterDelete {
      arguments.append("--prune")
    }

    // Always add JSON output
    arguments.append("--json")

    return ResticCommandImpl(arguments: arguments)
  }

  /// Creates a command to compare two snapshots
  /// - Parameters:
  ///   - firstSnapshotID: ID of the first snapshot to compare
  ///   - secondSnapshotID: ID of the second snapshot to compare
  ///   - path: Optional path to limit the comparison to
  ///   - host: Optional host to filter by
  /// - Returns: A command ready for execution
  public func createDiffCommand(
    firstSnapshotID: String,
    secondSnapshotID: String,
    path: String?=nil,
    host: String?=nil
  ) -> ResticCommand {
    // Start with basic diff command
    var arguments=["diff", firstSnapshotID, secondSnapshotID, "--json"]

    // Add path if provided
    if let path {
      arguments.append(path)
    }

    // Add host filter if provided
    if let host {
      arguments.append(contentsOf: ["--host", host])
    }

    // Create and return the command
    return ResticCommandImpl(arguments: arguments)
  }

  /**
   * Creates a command to compare two snapshots.
   *
   * - Parameters:
   *   - firstSnapshotID: ID of the first snapshot
   *   - secondSnapshotID: ID of the second snapshot
   *   - options: Additional options for the diff command
   * - Returns: A command to compare snapshots
   */
  public func createDiffCommand(
    firstSnapshotID: String,
    secondSnapshotID: String,
    options: [String]?
  ) -> ResticCommand {
    var args=["diff", firstSnapshotID, secondSnapshotID, "--json"]

    // Add any additional options
    if let options {
      args.append(contentsOf: options)
    }

    return ResticCommandImpl(arguments: args)
  }

  /**
   * Creates a command to retrieve detailed information about a specific snapshot.
   *
   * - Parameters:
   *   - snapshotID: ID of the snapshot to retrieve information for
   *   - includeStats: Whether to include file statistics in the output
   * - Returns: A command to retrieve snapshot information
   */
  public func createSnapshotInfoCommand(
    snapshotID: String,
    includeStats: Bool=false
  ) -> ResticCommand {
    var args=["snapshot", snapshotID, "--json"]

    // Add statistics flag if requested
    if includeStats {
      args.append("--detailed")
    }

    return ResticCommandImpl(arguments: args)
  }
}
