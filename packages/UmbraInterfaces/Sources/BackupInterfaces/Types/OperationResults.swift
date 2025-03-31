import Foundation

/**
 * Represents the result of a snapshot copy operation.
 */
public struct BackupCopyResult: Sendable, Equatable {
  /// ID of the copied snapshot in the target repository
  public let targetSnapshotID: String

  /// Time when the copy was completed
  public let completionTime: Date

  /// Total size of the transferred data in bytes
  public let transferredBytes: UInt64

  /**
   * Initialises a new copy result.
   *
   * - Parameters:
   *   - targetSnapshotID: ID of the copied snapshot in the target repository
   *   - completionTime: Time when the copy was completed
   *   - transferredBytes: Total size of the transferred data in bytes
   */
  public init(
    targetSnapshotID: String,
    completionTime: Date=Date(),
    transferredBytes: UInt64
  ) {
    self.targetSnapshotID=targetSnapshotID
    self.completionTime=completionTime
    self.transferredBytes=transferredBytes
  }
}

/**
 * Represents the result of a snapshot delete operation.
 */
public struct BackupDeleteResult: Sendable, Equatable {
  /// ID of the deleted snapshot
  public let snapshotID: String

  /// Time when the deletion was completed
  public let completionTime: Date

  /// Amount of space reclaimed in bytes
  public let reclaimedBytes: UInt64

  /// Whether the repository was pruned after deletion
  public let pruned: Bool

  /**
   * Initialises a new delete result.
   *
   * - Parameters:
   *   - snapshotID: ID of the deleted snapshot
   *   - completionTime: Time when the deletion was completed
   *   - reclaimedBytes: Amount of space reclaimed in bytes
   *   - pruned: Whether the repository was pruned after deletion
   */
  public init(
    snapshotID: String,
    completionTime: Date=Date(),
    reclaimedBytes: UInt64,
    pruned: Bool
  ) {
    self.snapshotID=snapshotID
    self.completionTime=completionTime
    self.reclaimedBytes=reclaimedBytes
    self.pruned=pruned
  }
}

/**
 * Defines the format for snapshot exports.
 */
public enum BackupExportFormat: String, Sendable, Equatable {
  /// Archive format (e.g., tar)
  case archive

  /// Raw format (direct copy of repository structure)
  case raw
}

/**
 * Represents the result of a snapshot export operation.
 */
public struct BackupExportResult: Sendable, Equatable {
  /// ID of the exported snapshot
  public let snapshotID: String

  /// Destination path of the export
  public let destinationPath: URL

  /// Format used for the export
  public let format: BackupExportFormat

  /// Time when the export was completed
  public let completionTime: Date

  /// Total size of the exported data in bytes
  public let exportedBytes: UInt64

  /**
   * Initialises a new export result.
   *
   * - Parameters:
   *   - snapshotID: ID of the exported snapshot
   *   - destinationPath: Destination path of the export
   *   - format: Format used for the export
   *   - completionTime: Time when the export was completed
   *   - exportedBytes: Total size of the exported data in bytes
   */
  public init(
    snapshotID: String,
    destinationPath: URL,
    format: BackupExportFormat,
    completionTime: Date=Date(),
    exportedBytes: UInt64
  ) {
    self.snapshotID=snapshotID
    self.destinationPath=destinationPath
    self.format=format
    self.completionTime=completionTime
    self.exportedBytes=exportedBytes
  }
}

/**
 * Defines the format for snapshot imports.
 */
public enum BackupImportFormat: String, Sendable, Equatable {
  /// Archive format (e.g., tar)
  case archive

  /// Raw format (direct copy of repository structure)
  case raw
}

/**
 * Represents the result of a snapshot import operation.
 */
public struct BackupImportResult: Sendable, Equatable {
  /// ID of the imported snapshot
  public let snapshotID: String

  /// Source path of the import
  public let sourcePath: URL

  /// Format used for the import
  public let format: BackupImportFormat

  /// Time when the import was completed
  public let completionTime: Date

  /// Total size of the imported data in bytes
  public let importedBytes: UInt64

  /**
   * Initialises a new import result.
   *
   * - Parameters:
   *   - snapshotID: ID of the imported snapshot
   *   - sourcePath: Source path of the import
   *   - format: Format used for the import
   *   - completionTime: Time when the import was completed
   *   - importedBytes: Total size of the imported data in bytes
   */
  public init(
    snapshotID: String,
    sourcePath: URL,
    format: BackupImportFormat,
    completionTime: Date=Date(),
    importedBytes: UInt64
  ) {
    self.snapshotID=snapshotID
    self.sourcePath=sourcePath
    self.format=format
    self.completionTime=completionTime
    self.importedBytes=importedBytes
  }
}

/**
 * Represents a comparison between two snapshots.
 */
public struct BackupSnapshotComparisonResult: Sendable, Equatable {
  /// Files that were added in the newer snapshot
  public let addedFiles: [FileInfo]

  /// Files that were modified between snapshots
  public let modifiedFiles: [FileInfo]

  /// Files that were removed in the newer snapshot
  public let removedFiles: [FileInfo]

  /// Files that remained unchanged between snapshots
  public let unchangedFiles: [FileInfo]

  /// Total number of changes between snapshots
  public let totalChangeCount: Int

  /// When the comparison was performed
  public let comparisonDate: Date

  /**
   * Initialises a new snapshot comparison result.
   *
   * - Parameters:
   *   - addedFiles: Files that were added in the newer snapshot
   *   - modifiedFiles: Files that were modified between snapshots
   *   - removedFiles: Files that were removed in the newer snapshot
   *   - unchangedFiles: Files that remained unchanged between snapshots
   *   - totalChangeCount: Total number of changes between snapshots
   *   - comparisonDate: When the comparison was performed
   */
  public init(
    addedFiles: [FileInfo],
    modifiedFiles: [FileInfo],
    removedFiles: [FileInfo],
    unchangedFiles: [FileInfo],
    totalChangeCount: Int,
    comparisonDate: Date=Date()
  ) {
    self.addedFiles=addedFiles
    self.modifiedFiles=modifiedFiles
    self.removedFiles=removedFiles
    self.unchangedFiles=unchangedFiles
    self.totalChangeCount=totalChangeCount
    self.comparisonDate=comparisonDate
  }
}
