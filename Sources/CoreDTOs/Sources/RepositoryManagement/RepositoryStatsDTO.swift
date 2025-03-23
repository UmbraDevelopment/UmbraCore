import UmbraCoreTypes

/// FoundationIndependent representation of repository statistics.
/// This data transfer object encapsulates statistics about a backup repository
/// without using any Foundation types.
public struct RepositoryStatsDTO: Sendable, Equatable {
  // MARK: - Properties

  /// Total size of all data in the repository (bytes)
  public let totalSize: UInt64

  /// Total size after compression (bytes)
  public let compressedSize: UInt64

  /// Total size after deduplication (bytes)
  public let deduplicated: UInt64

  /// Number of snapshots in the repository
  public let snapshotCount: Int

  /// Timestamp of the oldest snapshot (Unix timestamp - seconds since epoch)
  public let oldestSnapshot: UInt64?

  /// Timestamp of the newest snapshot (Unix timestamp - seconds since epoch)
  public let newestSnapshot: UInt64?

  // MARK: - Initializers

  /// Full initializer with all repository statistics
  /// - Parameters:
  ///   - totalSize: Total size of all data in the repository (bytes)
  ///   - compressedSize: Total size after compression (bytes)
  ///   - deduplicated: Total size after deduplication (bytes)
  ///   - snapshotCount: Number of snapshots in the repository
  ///   - oldestSnapshot: Timestamp of the oldest snapshot (Unix timestamp - seconds since epoch)
  ///   - newestSnapshot: Timestamp of the newest snapshot (Unix timestamp - seconds since epoch)
  public init(
    totalSize: UInt64,
    compressedSize: UInt64,
    deduplicated: UInt64,
    snapshotCount: Int,
    oldestSnapshot: UInt64?=nil,
    newestSnapshot: UInt64?=nil
  ) {
    self.totalSize=totalSize
    self.compressedSize=compressedSize
    self.deduplicated=deduplicated
    self.snapshotCount=snapshotCount
    self.oldestSnapshot=oldestSnapshot
    self.newestSnapshot=newestSnapshot
  }

  // MARK: - Factory Methods

  /// Create an empty repository stats object
  /// - Returns: A RepositoryStatsDTO with zero values
  public static func empty() -> RepositoryStatsDTO {
    RepositoryStatsDTO(
      totalSize: 0,
      compressedSize: 0,
      deduplicated: 0,
      snapshotCount: 0,
      oldestSnapshot: nil,
      newestSnapshot: nil
    )
  }

  // MARK: - Computed Properties

  /// Compression ratio as a value between 0 and 1
  /// A value of 0.5 means the data is compressed to 50% of its original size
  /// - Returns: Compression ratio or 1.0 if no compression
  public var compressionRatio: Double {
    if totalSize == 0 { return 1.0 }
    return Double(compressedSize) / Double(totalSize)
  }

  /// Deduplication ratio as a value between 0 and 1
  /// A value of 0.5 means the data is deduplicated to 50% of its compressed size
  /// - Returns: Deduplication ratio or 1.0 if no deduplication
  public var deduplicationRatio: Double {
    if compressedSize == 0 { return 1.0 }
    return Double(deduplicated) / Double(compressedSize)
  }

  /// Total space saving ratio as a value between 0 and 1
  /// A value of 0.3 means the data uses 30% of its original size
  /// - Returns: Total space saving ratio or 1.0 if no savings
  public var totalSpaceSavingRatio: Double {
    if totalSize == 0 { return 1.0 }
    return Double(deduplicated) / Double(totalSize)
  }

  /// Space saved in bytes compared to raw data
  /// - Returns: Number of bytes saved
  public var spacesSaved: UInt64 {
    if totalSize < deduplicated { return 0 }
    return totalSize - deduplicated
  }

  // MARK: - Utility Methods

  /// Create a new stats object by merging with another stats object
  /// New snapshot timestamps take precedence over existing ones
  /// - Parameter other: Another repository stats object to merge with
  /// - Returns: A new RepositoryStatsDTO with combined statistics
  public func mergedWith(_ other: RepositoryStatsDTO) -> RepositoryStatsDTO {
    // Determine oldest and newest snapshot timestamps
    let oldestTimestamp: UInt64?=if
      let selfOldest=oldestSnapshot,
      let otherOldest=other.oldestSnapshot
    {
      min(selfOldest, otherOldest)
    } else {
      oldestSnapshot ?? other.oldestSnapshot
    }

    let newestTimestamp: UInt64?=if
      let selfNewest=newestSnapshot,
      let otherNewest=other.newestSnapshot
    {
      max(selfNewest, otherNewest)
    } else {
      newestSnapshot ?? other.newestSnapshot
    }

    return RepositoryStatsDTO(
      totalSize: totalSize + other.totalSize,
      compressedSize: compressedSize + other.compressedSize,
      deduplicated: deduplicated + other.deduplicated,
      snapshotCount: snapshotCount + other.snapshotCount,
      oldestSnapshot: oldestTimestamp,
      newestSnapshot: newestTimestamp
    )
  }

  /// Create a copy of this stats object with an updated total size
  /// - Parameter size: The new total size in bytes
  /// - Returns: A new RepositoryStatsDTO with updated total size
  public func withTotalSize(_ size: UInt64) -> RepositoryStatsDTO {
    RepositoryStatsDTO(
      totalSize: size,
      compressedSize: compressedSize,
      deduplicated: deduplicated,
      snapshotCount: snapshotCount,
      oldestSnapshot: oldestSnapshot,
      newestSnapshot: newestSnapshot
    )
  }

  /// Create a copy of this stats object with an updated compressed size
  /// - Parameter size: The new compressed size in bytes
  /// - Returns: A new RepositoryStatsDTO with updated compressed size
  public func withCompressedSize(_ size: UInt64) -> RepositoryStatsDTO {
    RepositoryStatsDTO(
      totalSize: totalSize,
      compressedSize: size,
      deduplicated: deduplicated,
      snapshotCount: snapshotCount,
      oldestSnapshot: oldestSnapshot,
      newestSnapshot: newestSnapshot
    )
  }

  /// Create a copy of this stats object with an updated deduplicated size
  /// - Parameter size: The new deduplicated size in bytes
  /// - Returns: A new RepositoryStatsDTO with updated deduplicated size
  public func withDeduplicatedSize(_ size: UInt64) -> RepositoryStatsDTO {
    RepositoryStatsDTO(
      totalSize: totalSize,
      compressedSize: compressedSize,
      deduplicated: size,
      snapshotCount: snapshotCount,
      oldestSnapshot: oldestSnapshot,
      newestSnapshot: newestSnapshot
    )
  }

  /// Create a copy of this stats object with an updated snapshot count
  /// - Parameter count: The new snapshot count
  /// - Returns: A new RepositoryStatsDTO with updated snapshot count
  public func withSnapshotCount(_ count: Int) -> RepositoryStatsDTO {
    RepositoryStatsDTO(
      totalSize: totalSize,
      compressedSize: compressedSize,
      deduplicated: deduplicated,
      snapshotCount: count,
      oldestSnapshot: oldestSnapshot,
      newestSnapshot: newestSnapshot
    )
  }

  /// Create a copy of this stats object with updated snapshot timestamps
  /// - Parameters:
  ///   - oldestTimestamp: The timestamp of the oldest snapshot
  ///   - newestTimestamp: The timestamp of the newest snapshot
  /// - Returns: A new RepositoryStatsDTO with updated snapshot timestamps
  public func withSnapshotTimestamps(
    oldest oldestTimestamp: UInt64?,
    newest newestTimestamp: UInt64?
  ) -> RepositoryStatsDTO {
    RepositoryStatsDTO(
      totalSize: totalSize,
      compressedSize: compressedSize,
      deduplicated: deduplicated,
      snapshotCount: snapshotCount,
      oldestSnapshot: oldestTimestamp,
      newestSnapshot: newestTimestamp
    )
  }
}
