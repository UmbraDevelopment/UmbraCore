// Standard modules
import Foundation

/// Deprecated: Use CompleteRepository typealias from RepositoryProtocols.swift instead.
///
/// A complete repository that implements all repository functionality.
public typealias Repository=RepositoryCore & RepositoryLocking & RepositoryMaintenance &
  RepositoryStats

/// Repository statistics data structure.
public struct RepositoryStatistics: RepositoryStats, Codable, Equatable, Sendable {
  /// The total size of the repository in bytes.
  public let storedTotalSize: UInt64

  /// The number of snapshots in the repository.
  public let snapshotCount: UInt

  /// The time of the last check operation.
  public let lastCheck: Date

  /// Number of files backed up in the repository
  public let totalFileCount: Int

  /// Number of blobs in the repository
  public let totalBlobCount: Int

  /// Repository size in bytes if blobs were uncompressed
  public let totalUncompressedSize: Int64

  /// Factor by which the already compressed data has shrunk due to compression
  public let compressionRatio: Double

  /// Percentage of already compressed data
  public let compressionProgress: Double

  /// Overall space saving due to compression
  public let compressionSpaceSaving: Double

  /// Creates a new repository statistics instance.
  /// - Parameters:
  ///   - totalSize: Total size in bytes
  ///   - snapshotCount: Number of snapshots
  ///   - lastCheck: Time of last check
  ///   - totalFileCount: Number of files backed up
  ///   - totalBlobCount: Number of blobs
  ///   - totalUncompressedSize: Uncompressed size in bytes
  ///   - compressionRatio: Compression ratio
  ///   - compressionProgress: Compression progress percentage
  ///   - compressionSpaceSaving: Space saving percentage
  public init(
    totalSize: UInt64,
    snapshotCount: UInt,
    lastCheck: Date,
    totalFileCount: Int=0,
    totalBlobCount: Int=0,
    totalUncompressedSize: Int64=0,
    compressionRatio: Double=1.0,
    compressionProgress: Double=0.0,
    compressionSpaceSaving: Double=0.0
  ) {
    storedTotalSize=totalSize
    self.snapshotCount=snapshotCount
    self.lastCheck=lastCheck
    self.totalFileCount=totalFileCount
    self.totalBlobCount=totalBlobCount
    self.totalUncompressedSize=totalUncompressedSize
    self.compressionRatio=compressionRatio
    self.compressionProgress=compressionProgress
    self.compressionSpaceSaving=compressionSpaceSaving
  }

  // MARK: - RepositoryStats Protocol Conformance

  public var snapshotsCount: Int {
    Int(snapshotCount)
  }

  public var totalSize: Int64 {
    Int64(storedTotalSize)
  }

  // MARK: - Codable Implementation

  private enum CodingKeys: String, CodingKey {
    case storedTotalSize="totalSize"
    case snapshotCount
    case lastCheck
    case totalFileCount
    case totalBlobCount
    case totalUncompressedSize
    case compressionRatio
    case compressionProgress
    case compressionSpaceSaving
  }
}
