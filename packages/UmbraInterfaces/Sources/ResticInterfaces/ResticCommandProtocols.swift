import Foundation

/// Protocol for a command that initialises a new Restic repository
public protocol ResticInitCommand: ResticCommand {
  /// Repository location (path or URL)
  var location: String { get }
  
  /// Repository password
  var password: String { get }
  
  /// Common options for the command
  var commonOptions: ResticCommonOptions? { get }
}

/// Protocol for a command that backs up files to a Restic repository
public protocol ResticBackupCommand: ResticCommand {
  /// Paths to backup
  var paths: [String] { get }
  
  /// Optional tag for the backup
  var tag: String? { get }
  
  /// Patterns to exclude from backup
  var excludes: [String]? { get }
  
  /// Common options for the command
  var commonOptions: ResticCommonOptions? { get }
}

/// Protocol for a command that restores files from a Restic repository
public protocol ResticRestoreCommand: ResticCommand {
  /// Snapshot ID to restore from
  var snapshotID: String { get }
  
  /// Target path for restoration
  var targetPath: String { get }
  
  /// Specific paths to restore (nil for all)
  var paths: [String]? { get }
  
  /// Common options for the command
  var commonOptions: ResticCommonOptions? { get }
}

/// Protocol for a command that retrieves snapshots from a Restic repository
public protocol ResticSnapshotsCommand: ResticCommand {
  /// Optional tag to filter snapshots
  var tag: String? { get }
  
  /// Common options for the command
  var commonOptions: ResticCommonOptions? { get }
}

/// Protocol for a command that performs maintenance on a Restic repository
public protocol ResticMaintenanceCommand: ResticCommand {
  /// Type of maintenance to perform
  var maintenanceType: ResticMaintenanceType { get }
  
  /// Common options for the command
  var commonOptions: ResticCommonOptions? { get }
}

/// Protocol for a command that checks a Restic repository
public protocol ResticCheckCommand: ResticCommand {
  /// Whether to read all data blobs
  var readData: Bool { get }
  
  /// Common options for the command
  var commonOptions: ResticCommonOptions? { get }
}
