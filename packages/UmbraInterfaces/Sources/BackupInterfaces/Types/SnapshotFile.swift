import Foundation

/// Represents a file within a backup snapshot
///
/// This type provides information about a specific file in a snapshot,
/// including its path, size, and modification time.
public struct SnapshotFile: Sendable, Equatable {
    /// The path of the file relative to the snapshot root
    public let path: String
    
    /// The size of the file in bytes
    public let size: UInt64
    
    /// The modification time of the file
    public let modificationTime: Date
    
    /// The mode/permissions of the file
    public let mode: UInt16
    
    /// The user ID of the file owner
    public let uid: UInt32
    
    /// The group ID of the file
    public let gid: UInt32
    
    /// Optional hash of the file contents
    public let contentHash: String?
    
    /// Creates a new snapshot file instance
    /// - Parameters:
    ///   - path: The path of the file relative to the snapshot root
    ///   - size: The size of the file in bytes
    ///   - modificationTime: The modification time of the file
    ///   - mode: The mode/permissions of the file
    ///   - uid: The user ID of the file owner
    ///   - gid: The group ID of the file
    ///   - contentHash: Optional hash of the file contents
    public init(
        path: String,
        size: UInt64,
        modificationTime: Date,
        mode: UInt16,
        uid: UInt32,
        gid: UInt32,
        contentHash: String? = nil
    ) {
        self.path = path
        self.size = size
        self.modificationTime = modificationTime
        self.mode = mode
        self.uid = uid
        self.gid = gid
        self.contentHash = contentHash
    }
    
    /// Indicates whether the file is a directory based on the mode
    public var isDirectory: Bool {
        // Check if the directory bit is set (Unix S_IFDIR)
        return (mode & 0x4000) != 0
    }
    
    /// Indicates whether the file is a regular file based on the mode
    public var isRegularFile: Bool {
        // Check if the regular file bit is set (Unix S_IFREG)
        return (mode & 0x8000) != 0
    }
    
    /// Provides a human-readable size string
    public var formattedSize: String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useAll]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(size))
    }
}
