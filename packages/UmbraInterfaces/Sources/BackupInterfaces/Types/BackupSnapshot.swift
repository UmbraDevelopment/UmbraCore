import Foundation

/// Represents a backup snapshot point-in-time
public struct BackupSnapshot: Sendable, Equatable, Identifiable {
    /// Unique identifier for the snapshot
    public let id: String
    
    /// Time when the snapshot was created
    public let creationTime: Date
    
    /// Total size of the snapshot in bytes
    public let totalSize: UInt64
    
    /// Number of files in the snapshot
    public let fileCount: Int
    
    /// Tags associated with this snapshot
    public let tags: [String]
    
    /// Host where the snapshot was created
    public let hostname: String
    
    /// Username who created the snapshot
    public let username: String
    
    /// Paths included in the snapshot
    public let includedPaths: [URL]
    
    /// Brief description of the snapshot
    public let description: String?
    
    /// Whether this snapshot is a complete backup or incremental
    public let isComplete: Bool
    
    /// Parent snapshot ID if this is an incremental backup
    public let parentSnapshotID: String?
    
    /// Repository identifier this snapshot belongs to
    public let repositoryID: String
    
    /// Optional detailed file statistics
    public let fileStats: FileStatistics?
    
    /// Creates a new backup snapshot
    /// - Parameters:
    ///   - id: Unique identifier
    ///   - creationTime: Creation time
    ///   - totalSize: Total size in bytes
    ///   - fileCount: Number of files
    ///   - tags: Associated tags
    ///   - hostname: Host where created
    ///   - username: User who created
    ///   - includedPaths: Included paths
    ///   - description: Optional description
    ///   - isComplete: Whether complete or incremental
    ///   - parentSnapshotID: Parent snapshot if incremental
    ///   - repositoryID: Repository identifier
    ///   - fileStats: Optional file statistics
    public init(
        id: String,
        creationTime: Date,
        totalSize: UInt64,
        fileCount: Int,
        tags: [String],
        hostname: String,
        username: String,
        includedPaths: [URL],
        description: String? = nil,
        isComplete: Bool = true,
        parentSnapshotID: String? = nil,
        repositoryID: String,
        fileStats: FileStatistics? = nil
    ) {
        self.id = id
        self.creationTime = creationTime
        self.totalSize = totalSize
        self.fileCount = fileCount
        self.tags = tags
        self.hostname = hostname
        self.username = username
        self.includedPaths = includedPaths
        self.description = description
        self.isComplete = isComplete
        self.parentSnapshotID = parentSnapshotID
        self.repositoryID = repositoryID
        self.fileStats = fileStats
    }
}

/// Statistics about data deduplication
public struct DeduplicationStatistics: Sendable, Equatable {
    /// Total size of unique blocks in bytes
    public let uniqueSize: UInt64
    
    /// Total size of deduplicated data in bytes
    public let dedupSize: UInt64
    
    /// Deduplication ratio (total size / unique size)
    public var ratio: Double {
        guard uniqueSize > 0 else { return 1.0 }
        return Double(uniqueSize + dedupSize) / Double(uniqueSize)
    }
    
    /// Creates new deduplication statistics
    /// - Parameters:
    ///   - uniqueSize: Size of unique data in bytes
    ///   - dedupSize: Size of deduplicated data in bytes
    public init(
        uniqueSize: UInt64,
        dedupSize: UInt64
    ) {
        self.uniqueSize = uniqueSize
        self.dedupSize = dedupSize
    }
}
