import Foundation

/**
 * Represents information about a file in a snapshot.
 * 
 * This type provides comprehensive metadata about files within
 * backup snapshots, facilitating efficient analysis and retrieval.
 */
public struct FileInfo: Sendable, Equatable, Hashable {
    /// Path of the file
    public let path: String
    
    /// Size of the file in bytes
    public let size: UInt64
    
    /// Last modification time
    public let modificationTime: Date
    
    /// Type of the file
    public let type: FileType
    
    /// Permissions of the file
    public let permissions: FilePermissions
    
    /// Owner of the file
    public let owner: String
    
    /// Group of the file
    public let group: String
    
    /// Hash of the file content (for integrity checks)
    public let contentHash: String?
    
    /**
     * Initialises a new file info object.
     * 
     * - Parameters:
     *   - path: Path of the file
     *   - size: Size of the file in bytes
     *   - modificationTime: Last modification time
     *   - type: Type of the file
     *   - permissions: Permissions of the file
     *   - owner: Owner of the file
     *   - group: Group of the file
     *   - contentHash: Hash of the file content
     */
    public init(
        path: String,
        size: UInt64,
        modificationTime: Date,
        type: FileType,
        permissions: FilePermissions,
        owner: String,
        group: String,
        contentHash: String? = nil
    ) {
        self.path = path
        self.size = size
        self.modificationTime = modificationTime
        self.type = type
        self.permissions = permissions
        self.owner = owner
        self.group = group
        self.contentHash = contentHash
    }
    
    /**
     * Gets the filename from the path.
     */
    public var filename: String {
        URL(fileURLWithPath: path).lastPathComponent
    }
    
    /**
     * Gets the file extension (without the dot).
     */
    public var fileExtension: String {
        URL(fileURLWithPath: path).pathExtension
    }
    
    // MARK: - Hashable
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(path)
        hasher.combine(size)
        hasher.combine(modificationTime)
        hasher.combine(type)
        hasher.combine(permissions)
        hasher.combine(owner)
        hasher.combine(group)
        hasher.combine(contentHash)
    }
    
    public static func == (lhs: FileInfo, rhs: FileInfo) -> Bool {
        return lhs.path == rhs.path &&
               lhs.size == rhs.size &&
               lhs.modificationTime == rhs.modificationTime &&
               lhs.type == rhs.type &&
               lhs.permissions == rhs.permissions &&
               lhs.owner == rhs.owner &&
               lhs.group == rhs.group &&
               lhs.contentHash == rhs.contentHash
    }
}

/**
 * Represents the type of a file.
 */
public enum FileType: String, Sendable, Equatable, Hashable {
    /// Regular file
    case regular
    
    /// Directory
    case directory
    
    /// Symbolic link
    case symlink
    
    /// Special file (e.g., device, pipe)
    case special
    
    /// Unknown file type
    case unknown
}

/**
 * Represents the permissions of a file.
 */
public struct FilePermissions: Sendable, Equatable, Hashable {
    /// Whether the file is readable by owner
    public let ownerRead: Bool
    
    /// Whether the file is writable by owner
    public let ownerWrite: Bool
    
    /// Whether the file is executable by owner
    public let ownerExecute: Bool
    
    /// Whether the file is readable by group
    public let groupRead: Bool
    
    /// Whether the file is writable by group
    public let groupWrite: Bool
    
    /// Whether the file is executable by group
    public let groupExecute: Bool
    
    /// Whether the file is readable by others
    public let othersRead: Bool
    
    /// Whether the file is writable by others
    public let othersWrite: Bool
    
    /// Whether the file is executable by others
    public let othersExecute: Bool
    
    /**
     * Initialises new file permissions.
     * 
     * - Parameters:
     *   - ownerRead: Whether the file is readable by owner
     *   - ownerWrite: Whether the file is writable by owner
     *   - ownerExecute: Whether the file is executable by owner
     *   - groupRead: Whether the file is readable by group
     *   - groupWrite: Whether the file is writable by group
     *   - groupExecute: Whether the file is executable by group
     *   - othersRead: Whether the file is readable by others
     *   - othersWrite: Whether the file is writable by others
     *   - othersExecute: Whether the file is executable by others
     */
    public init(
        ownerRead: Bool,
        ownerWrite: Bool,
        ownerExecute: Bool,
        groupRead: Bool,
        groupWrite: Bool,
        groupExecute: Bool,
        othersRead: Bool,
        othersWrite: Bool,
        othersExecute: Bool
    ) {
        self.ownerRead = ownerRead
        self.ownerWrite = ownerWrite
        self.ownerExecute = ownerExecute
        self.groupRead = groupRead
        self.groupWrite = groupWrite
        self.groupExecute = groupExecute
        self.othersRead = othersRead
        self.othersWrite = othersWrite
        self.othersExecute = othersExecute
    }
    
    /**
     * Initialises file permissions from a Unix permission mode.
     * 
     * - Parameter mode: Unix permission mode (e.g., 0644)
     */
    public init(mode: UInt16) {
        ownerRead = (mode & 0o400) != 0
        ownerWrite = (mode & 0o200) != 0
        ownerExecute = (mode & 0o100) != 0
        groupRead = (mode & 0o040) != 0
        groupWrite = (mode & 0o020) != 0
        groupExecute = (mode & 0o010) != 0
        othersRead = (mode & 0o004) != 0
        othersWrite = (mode & 0o002) != 0
        othersExecute = (mode & 0o001) != 0
    }
    
    /**
     * Gets the Unix permission mode representation.
     */
    public var unixMode: UInt16 {
        var mode: UInt16 = 0
        if ownerRead { mode |= 0o400 }
        if ownerWrite { mode |= 0o200 }
        if ownerExecute { mode |= 0o100 }
        if groupRead { mode |= 0o040 }
        if groupWrite { mode |= 0o020 }
        if groupExecute { mode |= 0o010 }
        if othersRead { mode |= 0o004 }
        if othersWrite { mode |= 0o002 }
        if othersExecute { mode |= 0o001 }
        return mode
    }
    
    /**
     * Gets the string representation of permissions (e.g., "rwxr-xr--").
     */
    public var stringRepresentation: String {
        var result = ""
        result += ownerRead ? "r" : "-"
        result += ownerWrite ? "w" : "-"
        result += ownerExecute ? "x" : "-"
        result += groupRead ? "r" : "-"
        result += groupWrite ? "w" : "-"
        result += groupExecute ? "x" : "-"
        result += othersRead ? "r" : "-"
        result += othersWrite ? "w" : "-"
        result += othersExecute ? "x" : "-"
        return result
    }
    
    // MARK: - Hashable
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(unixMode)
    }
}
