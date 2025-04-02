import Foundation

/// Result of a backup operation
public struct BackupResult: Sendable, Equatable {
  /// Unique identifier for the created snapshot
  public let snapshotID: String

  /// Time when the backup was created
  public let creationTime: Date

  /// Total size of the backup in bytes
  public let totalSize: UInt64

  /// Number of files included in the backup
  public let fileCount: Int

  /// Size of the added data after deduplication
  public let addedSize: UInt64

  /// Duration of the backup operation in seconds
  public let duration: TimeInterval

  /// Tags associated with the backup
  public let tags: [String]

  /// Paths included in the backup
  public let includedPaths: [URL]

  /// Paths excluded from the backup
  public let excludedPaths: [URL]
  
  /// Whether the operation was successful
  public let successful: Bool

  /// Creates a new backup result
  /// - Parameters:
  ///   - snapshotID: ID of the created snapshot
  ///   - creationTime: Time the backup was created
  ///   - totalSize: Total size in bytes
  ///   - fileCount: Number of files included
  ///   - addedSize: Size of added data after deduplication
  ///   - duration: Duration of the operation in seconds
  ///   - tags: Tags associated with the backup
  ///   - includedPaths: Paths included in the backup
  ///   - excludedPaths: Paths excluded from the backup
  ///   - successful: Whether the operation was successful
  public init(
    snapshotID: String,
    creationTime: Date = Date(),
    totalSize: UInt64,
    fileCount: Int,
    addedSize: UInt64,
    duration: TimeInterval,
    tags: [String] = [],
    includedPaths: [URL] = [],
    excludedPaths: [URL] = [],
    successful: Bool = true
  ) {
    self.snapshotID = snapshotID
    self.creationTime = creationTime
    self.totalSize = totalSize
    self.fileCount = fileCount
    self.addedSize = addedSize
    self.duration = duration
    self.tags = tags
    self.includedPaths = includedPaths
    self.excludedPaths = excludedPaths
    self.successful = successful
  }
}

/// Type alias for backup creation result
/// This is the result returned when creating a new backup
public typealias BackupCreateResult = BackupResult

/// Type alias for backup restore result
/// This is the result returned when restoring from a backup
public typealias BackupRestoreResult = RestoreResult

/// Result of a restore operation
public struct RestoreResult: Sendable, Equatable {
  /// Unique identifier of the snapshot used for restoration
  public let snapshotID: String

  /// Time when the restore was performed
  public let restoreTime: Date

  /// Total size of the restored data in bytes
  public let totalSize: UInt64

  /// Number of files restored
  public let fileCount: Int

  /// Duration of the restore operation in seconds
  public let duration: TimeInterval

  /// Target path where files were restored
  public let targetPath: URL

  /// Creates a new restore result
  /// - Parameters:
  ///   - snapshotID: ID of the snapshot used
  ///   - restoreTime: Time of restoration
  ///   - totalSize: Total size in bytes
  ///   - fileCount: Number of files restored
  ///   - duration: Duration of operation in seconds
  ///   - targetPath: Path where files were restored
  public init(
    snapshotID: String,
    restoreTime: Date,
    totalSize: UInt64,
    fileCount: Int,
    duration: TimeInterval,
    targetPath: URL
  ) {
    self.snapshotID = snapshotID
    self.restoreTime = restoreTime
    self.totalSize = totalSize
    self.fileCount = fileCount
    self.duration = duration
    self.targetPath = targetPath
  }
}

/// Result of a delete operation
public struct BRDeleteResult: Sendable, Equatable {
  /// Unique identifier of the deleted snapshot
  public let snapshotID: String

  /// Time when the deletion was performed
  public let deletionTime: Date

  /// Whether the snapshot was successfully deleted
  public let successful: Bool

  /// Space freed by the deletion in bytes
  public let spaceSaved: UInt64?

  /// Creates a new delete result
  /// - Parameters:
  ///   - snapshotID: ID of the deleted snapshot
  ///   - deletionTime: Time of deletion
  ///   - successful: Whether deletion was successful
  ///   - spaceSaved: Space freed in bytes
  public init(
    snapshotID: String,
    deletionTime: Date,
    successful: Bool,
    spaceSaved: UInt64? = nil
  ) {
    self.snapshotID = snapshotID
    self.deletionTime = deletionTime
    self.successful = successful
    self.spaceSaved = spaceSaved
  }
}

/// Result of a maintenance operation
public struct MaintenanceResult: Sendable, Equatable {
  /// Type of maintenance performed
  public let maintenanceType: MaintenanceType

  /// Time when maintenance was performed
  public let maintenanceTime: Date

  /// Whether the maintenance was successful
  public let successful: Bool

  /// Space optimised by the maintenance in bytes
  public let spaceOptimised: UInt64?

  /// Duration of the maintenance operation in seconds
  public let duration: TimeInterval

  /// Issues found during maintenance
  public let issuesFound: [String]

  /// Issues fixed during maintenance
  public let issuesFixed: [String]

  /// Creates a new maintenance result
  /// - Parameters:
  ///   - maintenanceType: Type of maintenance performed
  ///   - maintenanceTime: Time of maintenance
  ///   - successful: Whether maintenance was successful
  ///   - spaceOptimised: Space optimised in bytes
  ///   - duration: Duration of operation in seconds
  ///   - issuesFound: Issues found during maintenance
  ///   - issuesFixed: Issues fixed during maintenance
  public init(
    maintenanceType: MaintenanceType,
    maintenanceTime: Date,
    successful: Bool,
    spaceOptimised: UInt64? = nil,
    duration: TimeInterval,
    issuesFound: [String] = [],
    issuesFixed: [String] = []
  ) {
    self.maintenanceType = maintenanceType
    self.maintenanceTime = maintenanceTime
    self.successful = successful
    self.spaceOptimised = spaceOptimised
    self.duration = duration
    self.issuesFound = issuesFound
    self.issuesFixed = issuesFixed
  }
}
