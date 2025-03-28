import Foundation

/// Options for backup creation
public struct BackupOptions: Sendable, Equatable {
    /// Compression level for backup data (0-9, where 0 is no compression and 9 is maximum)
    public let compressionLevel: Int?
    
    /// Maximum allowed size for the backup in bytes
    public let maxSize: UInt64?
    
    /// Whether to verify data after backup
    public let verifyAfterBackup: Bool
    
    /// Whether to use parallel operations for backup
    public let useParallelisation: Bool
    
    /// Priority given to the backup operation
    public let priority: BackupPriority
    
    /// Creates new backup options with the specified parameters
    /// - Parameters:
    ///   - compressionLevel: Compression level (0-9)
    ///   - maxSize: Maximum size in bytes
    ///   - verifyAfterBackup: Whether to verify after backup
    ///   - useParallelisation: Whether to use parallel operations
    ///   - priority: Priority of the backup operation
    public init(
        compressionLevel: Int? = nil,
        maxSize: UInt64? = nil,
        verifyAfterBackup: Bool = true,
        useParallelisation: Bool = true,
        priority: BackupPriority = .normal
    ) {
        self.compressionLevel = compressionLevel
        self.maxSize = maxSize
        self.verifyAfterBackup = verifyAfterBackup
        self.useParallelisation = useParallelisation
        self.priority = priority
    }
}

/// Options for restore operations
public struct RestoreOptions: Sendable, Equatable {
    /// Whether to overwrite existing files
    public let overwriteExisting: Bool
    
    /// Whether to restore file permissions
    public let restorePermissions: Bool
    
    /// Whether to verify data after restore
    public let verifyAfterRestore: Bool
    
    /// Whether to use parallel operations for restore
    public let useParallelisation: Bool
    
    /// Priority given to the restore operation
    public let priority: BackupPriority
    
    /// Creates new restore options with the specified parameters
    /// - Parameters:
    ///   - overwriteExisting: Whether to overwrite existing files
    ///   - restorePermissions: Whether to restore permissions
    ///   - verifyAfterRestore: Whether to verify after restore
    ///   - useParallelisation: Whether to use parallel operations
    ///   - priority: Priority of the restore operation
    public init(
        overwriteExisting: Bool = false,
        restorePermissions: Bool = true,
        verifyAfterRestore: Bool = true,
        useParallelisation: Bool = true,
        priority: BackupPriority = .normal
    ) {
        self.overwriteExisting = overwriteExisting
        self.restorePermissions = restorePermissions
        self.verifyAfterRestore = verifyAfterRestore
        self.useParallelisation = useParallelisation
        self.priority = priority
    }
}

/// Options for listing snapshots
public struct ListOptions: Sendable, Equatable {
    /// Maximum number of snapshots to return
    public let limit: Int?
    
    /// Include detailed file information
    public let includeFiles: Bool
    
    /// Creates new list options with the specified parameters
    /// - Parameters:
    ///   - limit: Maximum number of snapshots to return
    ///   - includeFiles: Whether to include file information
    public init(
        limit: Int? = nil,
        includeFiles: Bool = false
    ) {
        self.limit = limit
        self.includeFiles = includeFiles
    }
}

/// Options for deleting snapshots
public struct DeleteOptions: Sendable, Equatable {
    /// Whether to prune repository after deletion
    public let pruneAfterDelete: Bool
    
    /// Whether to dry run (simulate without making changes)
    public let dryRun: Bool
    
    /// Creates new delete options with the specified parameters
    /// - Parameters:
    ///   - pruneAfterDelete: Whether to prune after deletion
    ///   - dryRun: Whether to perform a dry run
    public init(
        pruneAfterDelete: Bool = false,
        dryRun: Bool = false
    ) {
        self.pruneAfterDelete = pruneAfterDelete
        self.dryRun = dryRun
    }
}

/// Options for maintenance operations
public struct MaintenanceOptions: Sendable, Equatable {
    /// Type of maintenance to perform
    public let maintenanceType: MaintenanceType
    
    /// Whether to dry run (simulate without making changes)
    public let dryRun: Bool
    
    /// Creates new maintenance options with the specified parameters
    /// - Parameters:
    ///   - maintenanceType: Type of maintenance to perform
    ///   - dryRun: Whether to perform a dry run
    public init(
        maintenanceType: MaintenanceType = .full,
        dryRun: Bool = false
    ) {
        self.maintenanceType = maintenanceType
        self.dryRun = dryRun
    }
}

/// Priority levels for backup operations
public enum BackupPriority: String, Sendable, Equatable, CaseIterable {
    /// Low priority - minimal resource usage
    case low
    /// Normal priority - balanced resource usage
    case normal
    /// High priority - preferred resource allocation
    case high
    /// Critical priority - maximum resource allocation
    case critical
}

/// Types of maintenance operations
public enum MaintenanceType: String, Sendable, Equatable, CaseIterable {
    /// Check repository integrity only
    case check
    /// Optimise repository storage
    case optimise
    /// Prune unused data
    case prune
    /// Rebuild indices
    case rebuildIndex
    /// Performs all maintenance operations
    case full
}
