import Foundation
import BackupInterfaces

/**
 * Options for restoring data from a backup snapshot.
 * Defines settings that control the behaviour of restore operations.
 */
public struct BackupRestoreOptions {
    /// Whether to overwrite existing files during restore
    public let overwriteExisting: Bool
    
    /// Whether to preserve original file permissions
    public let preservePermissions: Bool
    
    /// Initializes restore options with specified settings
    public init(overwriteExisting: Bool = false, preservePermissions: Bool = true) {
        self.overwriteExisting = overwriteExisting
        self.preservePermissions = preservePermissions
    }
}

/**
 * Parameters for restoring from a snapshot.
 * Used to configure a restore operation.
 */
public extension RestoreSnapshotParameters {
    /// Access the overwrite setting for existing files
    var overwriteExisting: Bool {
        return parameters["overwriteExisting"] as? Bool ?? false
    }
    
    /// Access the preserve permissions setting
    var preservePermissions: Bool {
        return parameters["preservePermissions"] as? Bool ?? true
    }
    
    /// Convert to BackupRestoreOptions
    func toBackupRestoreOptions() -> BackupRestoreOptions {
        return BackupRestoreOptions(
            overwriteExisting: overwriteExisting,
            preservePermissions: preservePermissions
        )
    }
}

/**
 * Parameters for snapshot creation.
 * Used with the BackupServiceProtocol to create new snapshots.
 */
public struct BackupSnapshotParameters {
    /// Paths to include in the snapshot
    public let paths: [URL]
    
    /// Tags to associate with the snapshot
    public let tags: [String]
    
    /// Whether this is a complete backup
    public let isComplete: Bool
    
    /// Optional description for the snapshot
    public let description: String?
    
    /// Initializes snapshot parameters with specified settings
    public init(
        paths: [URL],
        tags: [String] = [],
        isComplete: Bool = true,
        description: String? = nil
    ) {
        self.paths = paths
        self.tags = tags
        self.isComplete = isComplete
        self.description = description
    }
}

/**
 * Custom result type for restore operations.
 * Provides information about the restore process.
 */
public struct BackupRestoreResult {
    /// Number of files that were restored
    public let filesRestored: Int
    
    /// Total size of all restored files in bytes
    public let totalSize: UInt64
    
    /// Total time taken for the restore operation
    public let duration: TimeInterval
    
    /// Status of the restore operation
    public let status: RestoreStatus
    
    public init(
        filesRestored: Int,
        totalSize: UInt64,
        duration: TimeInterval,
        status: RestoreStatus
    ) {
        self.filesRestored = filesRestored
        self.totalSize = totalSize
        self.duration = duration
        self.status = status
    }
}

/// Status of a restore operation
public enum RestoreStatus {
    case completed
    case failed
    case partial
}

/// Extension to convert RestoreResult to our custom format
public extension RestoreResult {
    /// Convert to API-friendly result format
    func toAPIRestoreResult() -> BackupRestoreResult {
        return BackupRestoreResult(
            filesRestored: fileCount,
            totalSize: totalSize,
            duration: duration,
            status: .completed
        )
    }
}
