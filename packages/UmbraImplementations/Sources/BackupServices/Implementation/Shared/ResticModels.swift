import Foundation

/// Models representing Restic command output formats
///
/// These structures match the JSON output format of Restic commands
/// and are used for decoding responses before mapping to domain models.

/// Represents a basic snapshot from Restic output
struct ResticSnapshot: Decodable {
  /// Unique ID of the snapshot
  let id: String

  /// Creation time of the snapshot
  let time: Date

  /// Tags associated with the snapshot
  let tags: [String]?

  /// Paths included in the snapshot
  let paths: [String]

  /// Hostname where the snapshot was created
  let hostname: String

  /// Username who created the snapshot
  let username: String

  /// Paths excluded from the snapshot
  let excludes: [String]?

  /// Paths explicitly included in the snapshot
  let includes: [String]?

  /// Total size of the snapshot in bytes
  let sizeInBytes: UInt64?

  /// Number of files in the snapshot
  let fileCount: Int?
}

/// Represents detailed snapshot information including statistics
struct ResticSnapshotDetails: Decodable {
  /// Unique ID of the snapshot
  let id: String

  /// Creation time of the snapshot
  let time: Date

  /// Tags associated with the snapshot
  let tags: [String]?

  /// Paths included in the snapshot
  let paths: [String]

  /// Hostname where the snapshot was created
  let hostname: String

  /// Username who created the snapshot
  let username: String

  /// User-provided description of the snapshot
  let description: String?

  /// Parent snapshot ID if this is an incremental backup
  let parentID: String?

  /// Detailed statistics about the snapshot contents
  let statistics: ResticStatistics?

  /// Paths excluded from the snapshot
  let excludes: [String]?

  /// Paths explicitly included in the snapshot
  let includes: [String]?
}

/// Statistics about a snapshot
struct ResticStatistics: Decodable {
  /// Total size of all files in bytes
  let totalSize: UInt64

  /// Total number of files
  let totalFileCount: Int

  /// Total number of directories
  let totalDirectoryCount: Int

  /// Breakdown of file types
  let typeBreakdown: TypeCounts?

  /// Breakdown of file counts by type
  struct TypeCounts: Decodable {
    /// Number of files
    let files: Int

    /// Number of directories
    let dirs: Int

    /// Number of symlinks
    let symlinks: Int?

    /// Number of other types
    let others: Int?
  }
}

/// Deduplication statistics
struct ResticDeduplicationStats: Decodable {
  /// Number of new files
  let newFiles: Int

  /// Number of unchanged files
  let unchangedFiles: Int

  /// Size of new data in bytes
  let newDataSize: UInt64

  /// Size of unchanged data in bytes
  let unchangedDataSize: UInt64
}

/// Result of a repository check operation
struct ResticCheckResult: Decodable {
  /// Whether the check was successful
  let success: Bool

  /// List of errors encountered
  let errors: [String]?
}

/// Result of a backup operation
struct ResticBackupResult: Decodable {
  /// Snapshot ID created
  let snapshotID: String

  /// Summary of files processed
  let summary: ResticSummary

  /// Files added/changed/unchanged
  struct ResticSummary: Decodable {
    /// Number of files processed
    let filesProcessed: Int

    /// Number of bytes processed
    let bytesProcessed: UInt64

    /// Number of files added
    let filesAdded: Int

    /// Number of bytes added
    let bytesAdded: UInt64
  }
}
