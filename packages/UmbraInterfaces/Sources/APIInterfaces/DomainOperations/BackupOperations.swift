/**
 # Backup API Operations

 Defines operations related to backup and snapshot management in the Umbra system.
 These operations follow the Alpha Dot Five architecture principles with
 strict typing and clear domain boundaries.
 */

/**
 Base protocol for all backup-related API operations.
 */
public protocol BackupAPIOperation: DomainAPIOperation {}

/// Default domain for backup operations
extension BackupAPIOperation {
  public static var domain: APIDomain {
    .backup
  }
}

/**
 Operation to list all snapshots with optional filtering.
 */
public struct ListSnapshotsOperation: BackupAPIOperation {
  /// The operation result type
  public typealias ResultType=[SnapshotInfo]

  /// The repository identifier
  public let repositoryID: String

  /// Optional filter by tags
  public let tagFilter: [String]?

  /// Optional filter by path
  public let pathFilter: String?

  /// Optional filter for snapshots before a specific date
  public let beforeDate: String?

  /// Optional filter for snapshots after a specific date
  public let afterDate: String?

  /// Maximum number of snapshots to return
  public let limit: Int?

  /**
   Initialises a new list snapshots operation.

   - Parameters:
      - repositoryID: The repository identifier
      - tagFilter: Optional filter by tags
      - pathFilter: Optional filter by path
      - beforeDate: Optional filter for snapshots before a date
      - afterDate: Optional filter for snapshots after a date
      - limit: Maximum number of snapshots to return
   */
  public init(
    repositoryID: String,
    tagFilter: [String]?=nil,
    pathFilter: String?=nil,
    beforeDate: String?=nil,
    afterDate: String?=nil,
    limit: Int?=nil
  ) {
    self.repositoryID=repositoryID
    self.tagFilter=tagFilter
    self.pathFilter=pathFilter
    self.beforeDate=beforeDate
    self.afterDate=afterDate
    self.limit=limit
  }
}

/**
 Operation to get detailed information about a specific snapshot.
 */
public struct GetSnapshotOperation: BackupAPIOperation {
  /// The operation result type
  public typealias ResultType=SnapshotDetails

  /// The repository identifier
  public let repositoryID: String

  /// The snapshot identifier
  public let snapshotID: String

  /// Whether to include file listings
  public let includeFiles: Bool

  /**
   Initialises a new get snapshot operation.

   - Parameters:
      - repositoryID: The repository identifier
      - snapshotID: The snapshot identifier
      - includeFiles: Whether to include file listings
   */
  public init(
    repositoryID: String,
    snapshotID: String,
    includeFiles: Bool=false
  ) {
    self.repositoryID=repositoryID
    self.snapshotID=snapshotID
    self.includeFiles=includeFiles
  }
}

/**
 Operation to create a new snapshot.
 */
public struct CreateSnapshotOperation: BackupAPIOperation {
  /// The operation result type
  public typealias ResultType=SnapshotInfo

  /// The repository identifier
  public let repositoryID: String

  /// The snapshot creation parameters
  public let parameters: SnapshotCreationParameters

  /**
   Initialises a new create snapshot operation.

   - Parameters:
      - repositoryID: The repository identifier
      - parameters: The snapshot creation parameters
   */
  public init(
    repositoryID: String,
    parameters: SnapshotCreationParameters
  ) {
    self.repositoryID=repositoryID
    self.parameters=parameters
  }
}

/**
 Operation to update snapshot metadata.
 */
public struct UpdateSnapshotOperation: BackupAPIOperation {
  /// The operation result type
  public typealias ResultType=SnapshotInfo

  /// The repository identifier
  public let repositoryID: String

  /// The snapshot identifier
  public let snapshotID: String

  /// The snapshot update parameters
  public let parameters: SnapshotUpdateParameters

  /**
   Initialises a new update snapshot operation.

   - Parameters:
      - repositoryID: The repository identifier
      - snapshotID: The snapshot identifier
      - parameters: The snapshot update parameters
   */
  public init(
    repositoryID: String,
    snapshotID: String,
    parameters: SnapshotUpdateParameters
  ) {
    self.repositoryID=repositoryID
    self.snapshotID=snapshotID
    self.parameters=parameters
  }
}

/**
 Operation to delete a snapshot.
 */
public struct DeleteSnapshotOperation: BackupAPIOperation {
  /// The operation result type
  public typealias ResultType=Void

  /// The repository identifier
  public let repositoryID: String

  /// The snapshot identifier
  public let snapshotID: String

  /**
   Initialises a new delete snapshot operation.

   - Parameters:
      - repositoryID: The repository identifier
      - snapshotID: The snapshot identifier
   */
  public init(
    repositoryID: String,
    snapshotID: String
  ) {
    self.repositoryID=repositoryID
    self.snapshotID=snapshotID
  }
}

/**
 Operation to restore files from a snapshot.
 */
public struct RestoreSnapshotOperation: BackupAPIOperation {
  /// The operation result type
  public typealias ResultType=RestoreResult

  /// The repository identifier
  public let repositoryID: String

  /// The snapshot identifier
  public let snapshotID: String

  /// The restore parameters
  public let parameters: RestoreParameters

  /**
   Initialises a new restore snapshot operation.

   - Parameters:
      - repositoryID: The repository identifier
      - snapshotID: The snapshot identifier
      - parameters: The restore parameters
   */
  public init(
    repositoryID: String,
    snapshotID: String,
    parameters: RestoreParameters
  ) {
    self.repositoryID=repositoryID
    self.snapshotID=snapshotID
    self.parameters=parameters
  }
}

import DateTimeTypes

/**
 Basic snapshot information structure.
 */
public struct SnapshotInfo: Sendable {
  /// Unique identifier for the snapshot
  public let id: String

  /// The repository this snapshot belongs to
  public let repositoryID: String

  /// When the snapshot was created
  public let timestamp: DateTimeDTO

  /// Tags associated with the snapshot
  public let tags: [String]

  /// Human-readable summary of the snapshot contents
  public let summary: String

  /**
   Initialises a new snapshot information structure.

   - Parameters:
      - id: The snapshot identifier
      - repositoryID: The repository identifier
      - timestamp: Creation timestamp
      - tags: Associated tags
      - summary: Human-readable summary
   */
  public init(
    id: String,
    repositoryID: String,
    timestamp: DateTimeDTO,
    tags: [String],
    summary: String
  ) {
    self.id=id
    self.repositoryID=repositoryID
    self.timestamp=timestamp
    self.tags=tags
    self.summary=summary
  }

  /**
   Initialises a new snapshot information structure with a string date.
   This is provided for backward compatibility.

   - Parameters:
      - id: The snapshot identifier
      - repositoryID: The repository identifier
      - createdAt: Creation timestamp as ISO8601 string
      - tags: Associated tags
      - summary: Human-readable summary
   */
  public init(
    id: String,
    repositoryID: String,
    createdAt: String,
    tags: [String],
    summary: String
  ) {
    self.id=id
    self.repositoryID=repositoryID

    // Parse date or use current time if parsing fails
    if let timestamp=DateTimeDTO.fromISO8601String(createdAt) {
      self.timestamp=timestamp
    } else {
      timestamp=DateTimeDTO.now()
    }

    self.tags=tags
    self.summary=summary
  }
}

/**
 Detailed snapshot information structure.
 */
public struct SnapshotDetails: Sendable {
  /// Basic snapshot information
  public let info: SnapshotInfo

  /// Total size of the snapshot in bytes
  public let totalSizeBytes: UInt64

  /// Number of files in the snapshot
  public let fileCount: Int

  /// File listings, if requested
  public let files: [SnapshotFileInfo]?

  /**
   Initialises a new snapshot details structure.

   - Parameters:
      - info: Basic snapshot information
      - totalSizeBytes: Total size in bytes
      - fileCount: Number of files
      - files: Optional file listings
   */
  public init(
    info: SnapshotInfo,
    totalSizeBytes: UInt64,
    fileCount: Int,
    files: [SnapshotFileInfo]?=nil
  ) {
    self.info=info
    self.totalSizeBytes=totalSizeBytes
    self.fileCount=fileCount
    self.files=files
  }
}

/**
 Information about a file in a snapshot.
 */
public struct SnapshotFileInfo: Sendable {
  /// Path to the file, relative to the snapshot root
  public let path: String

  /// Size of the file in bytes
  public let sizeBytes: UInt64

  /// File modification time
  public let modifiedAt: String

  /**
   Initialises a new snapshot file information structure.

   - Parameters:
      - path: The file path
      - sizeBytes: The file size
      - modifiedAt: Modification timestamp
   */
  public init(
    path: String,
    sizeBytes: UInt64,
    modifiedAt: String
  ) {
    self.path=path
    self.sizeBytes=sizeBytes
    self.modifiedAt=modifiedAt
  }
}

/**
 Parameters for creating a new snapshot.
 */
public struct SnapshotCreationParameters: Sendable {
  /// Paths to include in the snapshot
  public let includePaths: [String]

  /// Paths to exclude from the snapshot
  public let excludePaths: [String]

  /// Tags to associate with the snapshot
  public let tags: [String]

  /// Whether to use compression
  public let useCompression: Bool

  /**
   Initialises new snapshot creation parameters.

   - Parameters:
      - includePaths: Paths to include
      - excludePaths: Paths to exclude
      - tags: Tags to associate
      - useCompression: Whether to use compression
   */
  public init(
    includePaths: [String],
    excludePaths: [String]=[],
    tags: [String]=[],
    useCompression: Bool=true
  ) {
    self.includePaths=includePaths
    self.excludePaths=excludePaths
    self.tags=tags
    self.useCompression=useCompression
  }
}

/**
 Parameters for updating an existing snapshot.
 */
public struct SnapshotUpdateParameters: Sendable {
  /// New tags to associate with the snapshot
  public let tags: [String]?

  /**
   Initialises new snapshot update parameters.

   - Parameter tags: New tags to associate
   */
  public init(tags: [String]?=nil) {
    self.tags=tags
  }
}

/**
 Parameters for restoring files from a snapshot.
 */
public struct RestoreParameters: Sendable {
  /// Paths to restore, relative to the snapshot root
  public let paths: [String]

  /// Target directory for the restore
  public let targetDirectory: String

  /// Whether to overwrite existing files
  public let overwriteExisting: Bool

  /**
   Initialises new restore parameters.

   - Parameters:
      - paths: Paths to restore
      - targetDirectory: Target directory
      - overwriteExisting: Whether to overwrite existing files
   */
  public init(
    paths: [String],
    targetDirectory: String,
    overwriteExisting: Bool=false
  ) {
    self.paths=paths
    self.targetDirectory=targetDirectory
    self.overwriteExisting=overwriteExisting
  }
}

/**
 Result of a restore operation.
 */
public struct RestoreResult: Sendable {
  /// Number of files restored
  public let filesRestored: Int

  /// Total size of restored files in bytes
  public let totalSizeBytes: UInt64

  /// Paths that could not be restored
  public let failedPaths: [String]

  /**
   Initialises a new restore result.

   - Parameters:
      - filesRestored: Number of files restored
      - totalSizeBytes: Total size in bytes
      - failedPaths: Paths that could not be restored
   */
  public init(
    filesRestored: Int,
    totalSizeBytes: UInt64,
    failedPaths: [String]=[]
  ) {
    self.filesRestored=filesRestored
    self.totalSizeBytes=totalSizeBytes
    self.failedPaths=failedPaths
  }
}
