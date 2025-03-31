import Foundation

/// Represents the format for exporting snapshots
public enum SOpExportFormat: String, Sendable, Codable, Equatable {
  /// Standard archive format
  case standard

  /// Compressed archive format
  case compressed

  /// Raw format (direct file copy)
  case raw
}

/// Represents the result of an export operation
public struct SOpExportResult: Sendable, Equatable {
  /// The path where the export was written
  public let outputPath: URL

  /// The number of files exported
  public let fileCount: Int

  /// The total size of the exported data
  public let totalBytes: UInt64

  /// Time taken for the export operation
  public let duration: TimeInterval

  /// Creates a new export result
  /// - Parameters:
  ///   - outputPath: The path where the export was written
  ///   - fileCount: The number of files exported
  ///   - totalBytes: The total size of the exported data
  ///   - duration: Time taken for the export operation
  public init(outputPath: URL, fileCount: Int, totalBytes: UInt64, duration: TimeInterval) {
    self.outputPath=outputPath
    self.fileCount=fileCount
    self.totalBytes=totalBytes
    self.duration=duration
  }
}

/// Represents the format for importing snapshots
public enum SOpImportFormat: String, Sendable, Codable, Equatable {
  /// Standard archive format
  case standard

  /// Compressed archive format
  case compressed

  /// Raw format (direct file copy)
  case raw
}

/// Represents the result of an import operation
public struct SOpImportResult: Sendable, Equatable {
  /// The ID of the imported snapshot
  public let snapshotID: String

  /// The number of files imported
  public let fileCount: Int

  /// The total size of the imported data
  public let totalBytes: UInt64

  /// Time taken for the import operation
  public let duration: TimeInterval

  /// Creates a new import result
  /// - Parameters:
  ///   - snapshotID: The ID of the imported snapshot
  ///   - fileCount: The number of files imported
  ///   - totalBytes: The total size of the imported data
  ///   - duration: Time taken for the import operation
  public init(snapshotID: String, fileCount: Int, totalBytes: UInt64, duration: TimeInterval) {
    self.snapshotID=snapshotID
    self.fileCount=fileCount
    self.totalBytes=totalBytes
    self.duration=duration
  }
}

/// Represents the level of verification to perform
public enum SOpVerificationLevel: String, Sendable, Codable, Equatable {
  /// Quick verification (metadata only)
  case quick

  /// Standard verification (metadata + critical data)
  case standard

  /// Full verification (all data)
  case full

  /// Exhaustive verification (metadata, data, and cross-references)
  case exhaustive
}

/// Represents the result of a copy operation
public struct SOpCopyResult: Sendable, Equatable {
  /// The ID of the source snapshot
  public let sourceSnapshotID: String

  /// The ID of the copied snapshot
  public let targetSnapshotID: String

  /// The ID of the target repository
  public let targetRepositoryID: String

  /// The number of files copied
  public let fileCount: Int

  /// The total size of the copied data
  public let totalBytes: UInt64

  /// Time taken for the copy operation
  public let duration: TimeInterval

  /// Creates a new copy result
  /// - Parameters:
  ///   - sourceSnapshotID: The ID of the source snapshot
  ///   - targetSnapshotID: The ID of the copied snapshot
  ///   - targetRepositoryID: The ID of the target repository
  ///   - fileCount: The number of files copied
  ///   - totalBytes: The total size of the copied data
  ///   - duration: Time taken for the copy operation
  public init(
    sourceSnapshotID: String,
    targetSnapshotID: String,
    targetRepositoryID: String,
    fileCount: Int,
    totalBytes: UInt64,
    duration: TimeInterval
  ) {
    self.sourceSnapshotID=sourceSnapshotID
    self.targetSnapshotID=targetSnapshotID
    self.targetRepositoryID=targetRepositoryID
    self.fileCount=fileCount
    self.totalBytes=totalBytes
    self.duration=duration
  }
}

// FileContent has been moved to a dedicated file for better separation of concerns

// FileInfo has been moved to a dedicated file for better separation of concerns
