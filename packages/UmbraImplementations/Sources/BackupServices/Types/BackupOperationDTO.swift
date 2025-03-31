import BackupInterfaces
import Foundation

/**
 * Base protocol for all backup operation parameter DTOs.
 *
 * This follows the Alpha Dot Five architecture by providing type-safe
 * operation parameters with validation.
 */
public protocol BackupOperationParameters {
  /// The type of operation being performed
  var operationType: String { get }

  /// Validates that the parameters are complete and consistent
  func validate() throws
}

/**
 * Parameters for creating a backup.
 */
public struct BackupCreateParameters: BackupOperationParameters {
  /// Source paths to include in the backup
  public let sources: [URL]

  /// Optional paths to exclude from the backup
  public let excludePaths: [URL]?

  /// Optional tags to apply to the backup
  public let tags: [String]?

  /// Optional backup options
  public let options: BackupOptions?

  /// The operation type
  public var operationType: String { "createBackup" }

  /**
   * Initialises a new set of backup creation parameters.
   *
   * - Parameters:
   *   - sources: Source paths to include
   *   - excludePaths: Optional paths to exclude
   *   - tags: Optional tags to apply
   *   - options: Optional backup options
   */
  public init(
    sources: [URL],
    excludePaths: [URL]?=nil,
    tags: [String]?=nil,
    options: BackupOptions?=nil
  ) {
    self.sources=sources
    self.excludePaths=excludePaths
    self.tags=tags
    self.options=options
  }

  /**
   * Validates that the parameters are complete and consistent.
   *
   * - Throws: BackupError if validation fails
   */
  public func validate() throws {
    // Ensure we have at least one source
    guard !sources.isEmpty else {
      throw BackupError.invalidConfiguration(
        details: "No source paths specified for backup"
      )
    }

    // Ensure all source paths are valid
    for source in sources {
      guard source.isFileURL else {
        throw BackupError.invalidConfiguration(
          details: "Source path is not a file URL: \(source.path)"
        )
      }
    }

    // Ensure all exclude paths are valid if provided
    if let excludePaths {
      for excludePath in excludePaths {
        guard excludePath.isFileURL else {
          throw BackupError.invalidConfiguration(
            details: "Exclude path is not a file URL: \(excludePath.path)"
          )
        }
      }
    }
  }
}

/**
 * Parameters for restoring a backup.
 */
public struct BackupRestoreParameters: BackupOperationParameters {
  /// ID of the snapshot to restore
  public let snapshotID: String

  /// Target path for restoration
  public let targetPath: URL

  /// Optional paths to include in the restore
  public let includePaths: [URL]?

  /// Optional paths to exclude from the restore
  public let excludePaths: [URL]?

  /// Optional restore options
  public let options: RestoreOptions?

  /// The operation type
  public var operationType: String { "restoreBackup" }

  /**
   * Initialises a new set of backup restore parameters.
   *
   * - Parameters:
   *   - snapshotID: ID of the snapshot to restore
   *   - targetPath: Target path for restoration
   *   - includePaths: Optional paths to include
   *   - excludePaths: Optional paths to exclude
   *   - options: Optional restore options
   */
  public init(
    snapshotID: String,
    targetPath: URL,
    includePaths: [URL]?=nil,
    excludePaths: [URL]?=nil,
    options: RestoreOptions?=nil
  ) {
    self.snapshotID=snapshotID
    self.targetPath=targetPath
    self.includePaths=includePaths
    self.excludePaths=excludePaths
    self.options=options
  }

  /**
   * Validates that the parameters are complete and consistent.
   *
   * - Throws: BackupError if validation fails
   */
  public func validate() throws {
    // Ensure snapshot ID is not empty
    guard !snapshotID.isEmpty else {
      throw BackupError.invalidConfiguration(
        details: "Snapshot ID cannot be empty"
      )
    }

    // Ensure target path is valid
    guard targetPath.isFileURL else {
      throw BackupError.invalidConfiguration(
        details: "Target path is not a file URL: \(targetPath.path)"
      )
    }

    // Ensure all include paths are valid if provided
    if let includePaths {
      for includePath in includePaths {
        guard includePath.isFileURL else {
          throw BackupError.invalidConfiguration(
            details: "Include path is not a file URL: \(includePath.path)"
          )
        }
      }
    }

    // Ensure all exclude paths are valid if provided
    if let excludePaths {
      for excludePath in excludePaths {
        guard excludePath.isFileURL else {
          throw BackupError.invalidConfiguration(
            details: "Exclude path is not a file URL: \(excludePath.path)"
          )
        }
      }
    }
  }
}

/**
 * Parameters for listing backups.
 */
public struct BackupListParameters: BackupOperationParameters {
  /// Optional tags to filter by
  public let tags: [String]?

  /// Optional date to filter before
  public let before: Date?

  /// Optional date to filter after
  public let after: Date?

  /// Optional host to filter by
  public let host: String?

  /// Optional path that must be included in the backup
  public let path: URL?

  /// The operation type
  public var operationType: String { "listBackups" }

  /**
   * Initialises a new set of backup listing parameters.
   *
   * - Parameters:
   *   - tags: Optional tags to filter by
   *   - before: Optional date to filter before
   *   - after: Optional date to filter after
   *   - host: Optional host to filter by
   *   - path: Optional path that must be included
   */
  public init(
    tags: [String]?=nil,
    before: Date?=nil,
    after: Date?=nil,
    host: String?=nil,
    path: URL?=nil
  ) {
    self.tags=tags
    self.before=before
    self.after=after
    self.host=host
    self.path=path
  }

  /**
   * Validates that the parameters are complete and consistent.
   *
   * - Throws: BackupError if validation fails
   */
  public func validate() throws {
    // Ensure path is a file URL if provided
    if let path {
      guard path.isFileURL else {
        throw BackupError.invalidConfiguration(
          details: "Path is not a file URL: \(path.path)"
        )
      }
    }
  }
}

/**
 * Parameters for deleting a backup.
 */
public struct BackupDeleteParameters: BackupOperationParameters {
  /// ID of the snapshot to delete
  public let snapshotID: String

  /// Whether to prune the repository after deletion
  public let pruneAfterDelete: Bool

  /// The operation type
  public var operationType: String { "deleteBackup" }

  /**
   * Initialises a new set of backup deletion parameters.
   *
   * - Parameters:
   *   - snapshotID: ID of the snapshot to delete
   *   - pruneAfterDelete: Whether to prune after deletion
   */
  public init(
    snapshotID: String,
    pruneAfterDelete: Bool=false
  ) {
    self.snapshotID=snapshotID
    self.pruneAfterDelete=pruneAfterDelete
  }

  /**
   * Validates that the parameters are complete and consistent.
   *
   * - Throws: BackupError if validation fails
   */
  public func validate() throws {
    // Ensure snapshot ID is not empty
    guard !snapshotID.isEmpty else {
      throw BackupError.invalidConfiguration(
        details: "Snapshot ID cannot be empty"
      )
    }
  }
}

/**
 * Parameters for performing repository maintenance.
 */
public struct BackupMaintenanceParameters: BackupOperationParameters {
  /// Type of maintenance to perform
  public let maintenanceType: MaintenanceType

  /// Optional maintenance options
  public let options: MaintenanceOptions?

  /// The operation type
  public var operationType: String { "maintenance" }

  /**
   * Initialises a new set of maintenance parameters.
   *
   * - Parameters:
   *   - maintenanceType: Type of maintenance to perform
   *   - options: Optional maintenance options
   */
  public init(
    maintenanceType: MaintenanceType,
    options: MaintenanceOptions?=nil
  ) {
    self.maintenanceType=maintenanceType
    self.options=options
  }

  /**
   * Validates that the parameters are complete and consistent.
   *
   * - Throws: BackupError if validation fails
   */
  public func validate() throws {
    // No validation needed for maintenance parameters
  }
}
