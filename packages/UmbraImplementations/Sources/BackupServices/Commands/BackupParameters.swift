import BackupInterfaces
import Foundation

/**
 Parameters for backup creation operations.

 This struct encapsulates all parameters required for creating a new backup.
 */
public struct BackupCreateParameters {
  /// Unique identifier for this operation
  public let operationID: String

  /// Source paths to include in the backup
  public let sources: [URL]

  /// Optional paths to exclude from the backup
  public let excludePaths: [URL]?

  /// Optional tags to associate with the backup
  public let tags: [String]?

  /// Additional options for the backup operation
  public let options: BackupOptions?

  /**
   Initialises a new set of backup creation parameters.

   - Parameters:
      - operationID: Unique identifier for this operation
      - sources: Source paths to include in the backup
      - excludePaths: Optional paths to exclude from the backup
      - tags: Optional tags to associate with the backup
      - options: Additional options for the backup operation
   */
  public init(
    operationID: String,
    sources: [URL],
    excludePaths: [URL]?=nil,
    tags: [String]?=nil,
    options: BackupOptions?=nil
  ) {
    self.operationID=operationID
    self.sources=sources
    self.excludePaths=excludePaths
    self.tags=tags
    self.options=options
  }
}

/**
 Parameters for backup restoration operations.

 This struct encapsulates all parameters required for restoring a backup.
 */
public struct BackupRestoreParameters {
  /// Unique identifier for this operation
  public let operationID: String

  /// ID of the snapshot to restore from
  public let snapshotID: String

  /// Target path to restore files to
  public let targetPath: URL

  /// Optional specific paths to include in the restoration
  public let includePaths: [URL]?

  /// Optional paths to exclude from the restoration
  public let excludePaths: [URL]?

  /// Additional options for the restore operation
  public let options: RestoreOptions?

  /**
   Initialises a new set of backup restoration parameters.

   - Parameters:
      - operationID: Unique identifier for this operation
      - snapshotID: ID of the snapshot to restore from
      - targetPath: Target path to restore files to
      - includePaths: Optional specific paths to include in the restoration
      - excludePaths: Optional paths to exclude from the restoration
      - options: Additional options for the restore operation
   */
  public init(
    operationID: String,
    snapshotID: String,
    targetPath: URL,
    includePaths: [URL]?=nil,
    excludePaths: [URL]?=nil,
    options: RestoreOptions?=nil
  ) {
    self.operationID=operationID
    self.snapshotID=snapshotID
    self.targetPath=targetPath
    self.includePaths=includePaths
    self.excludePaths=excludePaths
    self.options=options
  }
}

/**
 Parameters for listing backup snapshots.

 This struct encapsulates all parameters required for listing snapshots.
 */
public struct BackupListSnapshotsParameters {
  /// Unique identifier for this operation
  public let operationID: String

  /// Optional path to filter snapshots by
  public let path: String?

  /// Optional tags to filter snapshots by
  public let tags: [String]?

  /// Optional host to filter snapshots by
  public let host: String?

  /**
   Initialises a new set of snapshot listing parameters.

   - Parameters:
      - operationID: Unique identifier for this operation
      - path: Optional path to filter snapshots by
      - tags: Optional tags to filter snapshots by
      - host: Optional host to filter snapshots by
   */
  public init(
    operationID: String,
    path: String?=nil,
    tags: [String]?=nil,
    host: String?=nil
  ) {
    self.operationID=operationID
    self.path=path
    self.tags=tags
    self.host=host
  }
}

/**
 Parameters for deleting backup snapshots.

 This struct encapsulates all parameters required for deleting snapshots.
 */
public struct BackupDeleteParameters {
  /// Unique identifier for this operation
  public let operationID: String

  /// Optional specific snapshot ID to delete
  public let snapshotID: String?

  /// Optional tags to match snapshots for deletion
  public let tags: [String]?

  /// Optional host to match snapshots for deletion
  public let host: String?

  /// Additional options for the delete operation
  public let options: DeleteOptions?

  /**
   Initialises a new set of backup deletion parameters.

   - Parameters:
      - operationID: Unique identifier for this operation
      - snapshotID: Optional specific snapshot ID to delete
      - tags: Optional tags to match snapshots for deletion
      - host: Optional host to match snapshots for deletion
      - options: Additional options for the delete operation
   */
  public init(
    operationID: String,
    snapshotID: String?=nil,
    tags: [String]?=nil,
    host: String?=nil,
    options: DeleteOptions?=nil
  ) {
    self.operationID=operationID
    self.snapshotID=snapshotID
    self.tags=tags
    self.host=host
    self.options=options
  }
}

/**
 Parameters for maintenance operations on a backup repository.

 This struct encapsulates all parameters required for maintenance operations.
 */
public struct BackupMaintenanceParameters {
  /// Unique identifier for this operation
  public let operationID: String

  /// Type of maintenance to perform
  public let type: MaintenanceType

  /// Additional options for the maintenance operation
  public let options: MaintenanceOptions?

  /**
   Initialises a new set of maintenance parameters.

   - Parameters:
      - operationID: Unique identifier for this operation
      - type: Type of maintenance to perform
      - options: Additional options for the maintenance operation
   */
  public init(
    operationID: String,
    type: MaintenanceType,
    options: MaintenanceOptions?=nil
  ) {
    self.operationID=operationID
    self.type=type
    self.options=options
  }
}

/**
 Parameters for verifying a backup snapshot.

 This struct encapsulates all parameters required for verifying a snapshot.
 */
public struct BackupVerificationParameters {
  /// Unique identifier for this operation
  public let operationID: String

  /// ID of the snapshot to verify
  public let snapshotID: String

  /// Additional options for the verification operation
  public let verifyOptions: VerifyOptions?

  /**
   Initialises a new set of verification parameters.

   - Parameters:
      - operationID: Unique identifier for this operation
      - snapshotID: ID of the snapshot to verify
      - verifyOptions: Additional options for the verification operation
   */
  public init(
    operationID: String,
    snapshotID: String,
    verifyOptions: VerifyOptions?=nil
  ) {
    self.operationID=operationID
    self.snapshotID=snapshotID
    self.verifyOptions=verifyOptions
  }
}
