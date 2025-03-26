import Foundation
import ResticTypes

/// Represents a snapshot in the repository
public struct SnapshotInfo: Codable, Sendable {
  /// Timestamp of when the backup was started
  public let time: Date

  /// ID of the parent snapshot
  public let parent: String?

  /// ID of the root tree blob
  public let tree: String

  /// List of paths included in the backup
  public let paths: [String]

  /// Hostname of the backed up machine
  public let hostname: String

  /// Username the backup command was run as
  public let username: String

  /// ID of owner
  public let uid: Int

  /// ID of group
  public let gid: Int

  /// List of paths and globs excluded from the backup
  public let excludes: [String]?

  /// List of tags for the snapshot
  public let tags: [String]?

  /// Restic version used to create snapshot
  public let programVersion: String

  /// Snapshot statistics
  public let summary: SnapshotSummary?

  /// Snapshot ID
  public let id: String

  /// Snapshot ID, short form
  public let shortID: String

  private enum CodingKeys: String, CodingKey {
    case time
    case parent
    case tree
    case paths
    case hostname
    case username
    case uid
    case gid
    case excludes
    case tags
    case programVersion="program_version"
    case summary
    case id
    case shortID="short_id"
  }

  @preconcurrency
  @available(*, deprecated, message: "Will need to be refactored for Swift 6")
  public init(from decoder: Decoder) throws {
    let container=try decoder.container(keyedBy: CodingKeys.self)

    // Custom date decoding for ISO8601 format with fractional seconds
    let timeString=try container.decode(String.self, forKey: .time)
    let formatter=ISO8601DateFormatter()

    // Try with fractional seconds first
    formatter.formatOptions=[.withInternetDateTime, .withFractionalSeconds]
    if let timeDate=formatter.date(from: timeString) {
      time=timeDate
    } else {
      // Try without fractional seconds
      formatter.formatOptions=[.withInternetDateTime]
      guard let timeDate=formatter.date(from: timeString) else {
        throw DecodingError.dataCorruptedError(
          forKey: .time,
          in: container,
          debugDescription: "Invalid date format"
        )
      }
      time=timeDate
    }

    // Decode other properties
    parent=try container.decodeIfPresent(String.self, forKey: .parent)
    tree=try container.decode(String.self, forKey: .tree)
    paths=try container.decode([String].self, forKey: .paths)
    hostname=try container.decode(String.self, forKey: .hostname)
    username=try container.decode(String.self, forKey: .username)
    uid=try container.decode(Int.self, forKey: .uid)
    gid=try container.decode(Int.self, forKey: .gid)
    excludes=try container.decodeIfPresent([String].self, forKey: .excludes)
    tags=try container.decodeIfPresent([String].self, forKey: .tags)
    programVersion=try container.decode(String.self, forKey: .programVersion)
    summary=try container.decodeIfPresent(SnapshotSummary.self, forKey: .summary)
    id=try container.decode(String.self, forKey: .id)
    shortID=try container.decode(String.self, forKey: .shortID)
  }
}

/// Statistics for a snapshot
public struct SnapshotSummary: Codable, Sendable {
  /// Time at which the backup was started
  public let backupStart: Date

  /// Time at which the backup was completed
  public let backupEnd: Date

  /// Number of new files
  public let filesNew: Int

  /// Number of files that changed
  public let filesChanged: Int

  /// Number of files that did not change
  public let filesUnmodified: Int

  /// Number of new directories
  public let dirsNew: Int

  /// Number of directories that changed
  public let dirsChanged: Int

  /// Number of directories that did not change
  public let dirsUnmodified: Int

  /// Number of data blobs added
  public let dataBlobs: Int

  /// Number of tree blobs added
  public let treeBlobs: Int

  /// Amount of (uncompressed) data added, in bytes
  public let dataAdded: Int64

  /// Amount of data added (after compression), in bytes
  public let dataAddedPacked: Int64

  /// Total number of files processed
  public let totalFilesProcessed: Int

  /// Total bytes processed
  public let totalBytesProcessed: Int64

  private enum CodingKeys: String, CodingKey {
    case backupStart="backup_start"
    case backupEnd="backup_end"
    case filesNew="files_new"
    case filesChanged="files_changed"
    case filesUnmodified="files_unmodified"
    case dirsNew="dirs_new"
    case dirsChanged="dirs_changed"
    case dirsUnmodified="dirs_unmodified"
    case dataBlobs="data_blobs"
    case treeBlobs="tree_blobs"
    case dataAdded="data_added"
    case dataAddedPacked="data_added_packed"
    case totalFilesProcessed="total_files_processed"
    case totalBytesProcessed="total_bytes_processed"
  }

  @preconcurrency
  @available(*, deprecated, message: "Will need to be refactored for Swift 6")
  public init(from decoder: Decoder) throws {
    let container=try decoder.container(keyedBy: CodingKeys.self)

    // Custom date decoding for ISO8601 format with fractional seconds
    let formatter=ISO8601DateFormatter()

    let startString=try container.decode(String.self, forKey: .backupStart)
    // Try with fractional seconds first
    formatter.formatOptions=[.withInternetDateTime, .withFractionalSeconds]
    if let startDate=formatter.date(from: startString) {
      backupStart=startDate
    } else {
      // Try without fractional seconds
      formatter.formatOptions=[.withInternetDateTime]
      guard let startDate=formatter.date(from: startString) else {
        throw DecodingError.dataCorruptedError(
          forKey: .backupStart,
          in: container,
          debugDescription: "Invalid date format"
        )
      }
      backupStart=startDate
    }

    let endString=try container.decode(String.self, forKey: .backupEnd)
    // Try with fractional seconds first
    formatter.formatOptions=[.withInternetDateTime, .withFractionalSeconds]
    if let endDate=formatter.date(from: endString) {
      backupEnd=endDate
    } else {
      // Try without fractional seconds
      formatter.formatOptions=[.withInternetDateTime]
      guard let endDate=formatter.date(from: endString) else {
        throw DecodingError.dataCorruptedError(
          forKey: .backupEnd,
          in: container,
          debugDescription: "Invalid date format"
        )
      }
      backupEnd=endDate
    }

    // Decode other properties
    filesNew=try container.decode(Int.self, forKey: .filesNew)
    filesChanged=try container.decode(Int.self, forKey: .filesChanged)
    filesUnmodified=try container.decode(Int.self, forKey: .filesUnmodified)
    dirsNew=try container.decode(Int.self, forKey: .dirsNew)
    dirsChanged=try container.decode(Int.self, forKey: .dirsChanged)
    dirsUnmodified=try container.decode(Int.self, forKey: .dirsUnmodified)
    dataBlobs=try container.decode(Int.self, forKey: .dataBlobs)
    treeBlobs=try container.decode(Int.self, forKey: .treeBlobs)
    dataAdded=try container.decode(Int64.self, forKey: .dataAdded)
    dataAddedPacked=try container.decode(Int64.self, forKey: .dataAddedPacked)
    totalFilesProcessed=try container.decode(Int.self, forKey: .totalFilesProcessed)
    totalBytesProcessed=try container.decode(Int64.self, forKey: .totalBytesProcessed)
  }
}

extension SnapshotInfo {
  /// Decode a list of snapshots from JSON output
  /// - Parameter jsonString: JSON string containing snapshot list
  /// - Returns: Array of decoded snapshots
  /// - Throws: DecodingError if JSON is invalid
  public static func decodeList(from jsonString: String) throws -> [SnapshotInfo] {
    let decoder=JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601

    guard let data=jsonString.data(using: .utf8) else {
      throw ResticError.invalidData("Failed to convert string to data")
    }

    return try decoder.decode([SnapshotInfo].self, from: data)
  }
}
