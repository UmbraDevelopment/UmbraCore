import Foundation
import ResticTypes

/// Statistics about a repository
public struct RepositoryStats: Repositories.RepositoryStats, Codable {
  /// Repository size in bytes
  public let totalSize: Int64

  /// Number of files backed up in the repository
  public let totalFileCount: Int

  /// Number of blobs in the repository
  public let totalBlobCount: Int

  /// Number of processed snapshots
  public let snapshotsCount: Int

  /// Repository size in bytes if blobs were uncompressed
  public let totalUncompressedSize: Int64

  /// Factor by which the already compressed data has shrunk due to compression
  public let compressionRatio: Double

  /// Percentage of already compressed data
  public let compressionProgress: Double

  /// Overall space saving due to compression
  public let compressionSpaceSaving: Double

  private enum CodingKeys: String, CodingKey {
    case totalSize="total_size"
    case totalFileCount="total_file_count"
    case totalBlobCount="total_blob_count"
    case snapshotsCount="snapshots_count"
    case totalUncompressedSize="total_uncompressed_size"
    case compressionRatio="compression_ratio"
    case compressionProgress="compression_progress"
    case compressionSpaceSaving="compression_space_saving"
  }
}
