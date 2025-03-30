import Foundation

/// Represents the format for exporting snapshots
public enum ExportFormat: String, Sendable, Codable, Equatable {
    /// Standard archive format
    case standard
    
    /// Compressed archive format
    case compressed
    
    /// Raw format (direct file copy)
    case raw
}

/// Represents the result of an export operation
public struct ExportResult: Sendable, Equatable {
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
        self.outputPath = outputPath
        self.fileCount = fileCount
        self.totalBytes = totalBytes
        self.duration = duration
    }
}

/// Represents the format for importing snapshots
public enum ImportFormat: String, Sendable, Codable, Equatable {
    /// Standard archive format
    case standard
    
    /// Compressed archive format
    case compressed
    
    /// Raw format (direct file copy)
    case raw
}

/// Represents the result of an import operation
public struct ImportResult: Sendable, Equatable {
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
        self.snapshotID = snapshotID
        self.fileCount = fileCount
        self.totalBytes = totalBytes
        self.duration = duration
    }
}

/// Represents the level of verification to perform
public enum VerificationLevel: String, Sendable, Codable, Equatable {
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
public struct CopyResult: Sendable, Equatable {
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
        self.sourceSnapshotID = sourceSnapshotID
        self.targetSnapshotID = targetSnapshotID
        self.targetRepositoryID = targetRepositoryID
        self.fileCount = fileCount
        self.totalBytes = totalBytes
        self.duration = duration
    }
}

/// Represents the content of a file in a snapshot
public struct FileContent: Sendable, Equatable {
    /// The data contained in the file
    public let data: Data
    
    /// The size of the file in bytes
    public let size: UInt64
    
    /// The MIME type of the file, if known
    public let mimeType: String?
    
    /// The modification date of the file
    public let modificationDate: Date?
    
    /// Creates a new file content
    /// - Parameters:
    ///   - data: The data contained in the file
    ///   - size: The size of the file in bytes
    ///   - mimeType: The MIME type of the file, if known
    ///   - modificationDate: The modification date of the file
    public init(
        data: Data,
        size: UInt64,
        mimeType: String? = nil,
        modificationDate: Date? = nil
    ) {
        self.data = data
        self.size = size
        self.mimeType = mimeType
        self.modificationDate = modificationDate
    }
}

/// Represents information about a file in a snapshot
public struct FileInfo: Sendable, Equatable {
    /// The type of file
    public enum FileType: String, Sendable, Codable, Equatable {
        /// Regular file
        case file
        /// Directory
        case directory
        /// Symbolic link
        case symlink
        /// Special file
        case special
    }
    
    /// The path of the file
    public let path: String
    
    /// The type of the file
    public let type: FileType
    
    /// The size of the file in bytes
    public let size: UInt64
    
    /// The modification date of the file
    public let modificationDate: Date?
    
    /// The owner of the file, if available
    public let owner: String?
    
    /// The group of the file, if available
    public let group: String?
    
    /// The permissions of the file, if available
    public let permissions: String?
    
    /// Creates a new file info
    /// - Parameters:
    ///   - path: The path of the file
    ///   - type: The type of the file
    ///   - size: The size of the file in bytes
    ///   - modificationDate: The modification date of the file
    ///   - owner: The owner of the file, if available
    ///   - group: The group of the file, if available
    ///   - permissions: The permissions of the file, if available
    public init(
        path: String,
        type: FileType,
        size: UInt64,
        modificationDate: Date? = nil,
        owner: String? = nil,
        group: String? = nil,
        permissions: String? = nil
    ) {
        self.path = path
        self.type = type
        self.size = size
        self.modificationDate = modificationDate
        self.owner = owner
        self.group = group
        self.permissions = permissions
    }
}
