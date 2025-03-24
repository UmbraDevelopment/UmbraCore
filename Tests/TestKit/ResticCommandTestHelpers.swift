import Foundation
import ResticCLIHelper
import ResticCLIHelperCommands
import ResticTypes

/// Helpers for testing Restic commands without requiring actual files on disk
public enum ResticCommandTestHelpers {
  /// Creates a backup command with file validation disabled for testing
  /// - Parameters:
  ///   - paths: Paths to back up (don't need to exist)
  ///   - options: Common restic options
  ///   - tags: Optional tags for the backup
  ///   - hostname: Optional host name
  ///   - excludePatterns: Optional patterns to exclude
  /// - Returns: A TestableBackupCommand with file validation disabled
  public static func createTestBackupCommand(
    paths: [String],
    options: CommonOptions,
    tags: [String]=[],
    hostname: String?=nil,
    excludePatterns: [String]=[]
  ) -> TestableBackupCommand {
    let command=TestableBackupCommand(paths: paths, options: options)

    // Apply optional parameters
    var finalCommand=command
    for tag in tags {
      finalCommand=finalCommand.tag(tag)
    }

    if let hostname {
      finalCommand=finalCommand.host(hostname)
    }

    for pattern in excludePatterns {
      finalCommand=finalCommand.exclude(pattern)
    }

    return finalCommand
  }

  /// Creates a snapshot command for testing
  /// - Parameters:
  ///   - options: Common restic options
  ///   - operation: Snapshot operation type
  ///   - tags: Optional tags to filter by
  ///   - paths: Optional paths to filter by
  ///   - hostname: Optional hostname to filter by
  /// - Returns: A SnapshotCommand configured for testing
  public static func createTestSnapshotCommand(
    options: CommonOptions,
    operation: SnapshotCommand.Operation = .list,
    tags: [String]=[],
    paths: [String]=[],
    hostname: String?=nil
  ) -> SnapshotCommand {
    SnapshotCommand(
      options: options,
      operation: operation,
      paths: paths,
      tags: tags,
      host: hostname
    )
  }
}

/// A testable version of BackupCommand that implements ResticCommand directly
/// and skips file existence checks in tests
public final class TestableBackupCommand: ResticCommand {
  // Common options for the backup command
  private let _options: CommonOptions

  // Paths to backup (don't need to exist for testing)
  private let backupPaths: [String]

  // Optional parameters
  private let tags: [String]
  private let hostname: String?
  private let excludePatterns: [String]
  private let parentPID: Int?

  /// Initialize with the same parameters as BackupCommand
  public init(
    paths: [String],
    options: CommonOptions,
    tags: [String]=[],
    hostname: String?=nil,
    excludePatterns: [String]=[],
    parentPID: Int?=nil
  ) {
    _options=options
    backupPaths=paths
    self.tags=tags
    self.hostname=hostname
    self.excludePatterns=excludePatterns
    self.parentPID=parentPID
  }

  /// Add a tag to the backup command
  public func tag(_ value: String) -> TestableBackupCommand {
    var newTags=tags
    newTags.append(value)
    return TestableBackupCommand(
      paths: backupPaths,
      options: _options,
      tags: newTags,
      hostname: hostname,
      excludePatterns: excludePatterns,
      parentPID: parentPID
    )
  }

  /// Add a host to the backup command
  public func host(_ value: String) -> TestableBackupCommand {
    TestableBackupCommand(
      paths: backupPaths,
      options: _options,
      tags: tags,
      hostname: value,
      excludePatterns: excludePatterns,
      parentPID: parentPID
    )
  }

  /// Add an exclude pattern to the backup command
  public func exclude(_ pattern: String) -> TestableBackupCommand {
    var newPatterns=excludePatterns
    newPatterns.append(pattern)
    return TestableBackupCommand(
      paths: backupPaths,
      options: _options,
      tags: tags,
      hostname: hostname,
      excludePatterns: newPatterns,
      parentPID: parentPID
    )
  }

  /// Set the parent process ID
  public func setParentPID(_ pid: Int) -> TestableBackupCommand {
    TestableBackupCommand(
      paths: backupPaths,
      options: _options,
      tags: tags,
      hostname: hostname,
      excludePatterns: excludePatterns,
      parentPID: pid
    )
  }

  // MARK: - ResticCommand Protocol Conformance

  public var commandName: String {
    "backup"
  }

  public var options: CommonOptions {
    _options
  }

  public var arguments: [String] {
    var args: [String]=[]

    // Add paths to back up
    args.append(contentsOf: backupPaths)

    // Add tags if specified
    for tag in tags {
      args.append("--tag=\(tag)")
    }

    // Add hostname if specified
    if let hostname {
      args.append("--host=\(hostname)")
    }

    // Add exclude patterns if specified
    for pattern in excludePatterns {
      args.append("--exclude=\(pattern)")
    }

    // Add parent PID if specified
    if let parentPID {
      args.append("--parent=\(parentPID)")
    }

    return args
  }

  public var environment: [String: String] {
    [:]
  }

  /// Overridden validate method that skips file existence checks
  public func validate() throws {
    // Skip file validation, but still validate repository path
    if options.repository.isEmpty {
      throw ResticError.invalidParameter("Repository path cannot be empty")
    }

    // Still ensure we have at least one path
    if backupPaths.isEmpty {
      throw ResticError.missingParameter("At least one backup path must be specified")
    }

    // We don't check if the paths actually exist on the filesystem

    // Validate tags format
    for tag in tags {
      guard tag.range(of: "^[a-zA-Z0-9][a-zA-Z0-9_.-]*$", options: .regularExpression) != nil else {
        throw ResticError.invalidParameter(
          "Invalid tag format: \(tag). " +
            "Tags must start with alphanumeric and contain only alphanumeric, underscore, dot, or hyphen"
        )
      }
    }
  }

  public func run() throws {
    // In a test context, we just pretend to run the command
    // The actual BackupCommand implementation would execute a Process here
  }

  public func execute() throws -> String {
    // For testing, we return a mock successful result
    "Successfully backed up files to repository"
  }
}
