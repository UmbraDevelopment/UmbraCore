import Foundation
import SchedulingTypes

/**
 Options for configuring log operations.
 
 These DTOs provide controlled parameters for various logging operations
 such as adding destinations, rotating logs, and exporting logs.
 */

/**
 Options for adding a log destination.
 */
public struct AddDestinationOptionsDTO: Codable, Equatable, Sendable {
    /// Whether to validate the destination configuration
    public let validateConfiguration: Bool
    
    /// Whether to test writing to the destination
    public let testDestination: Bool
    
    /// Whether to add the destination even if it already exists
    public let overwriteExisting: Bool
    
    /**
     Initialises add destination options.
     
     - Parameters:
        - validateConfiguration: Whether to validate the destination configuration
        - testDestination: Whether to test writing to the destination
        - overwriteExisting: Whether to add the destination even if it already exists
     */
    public init(
        validateConfiguration: Bool = true,
        testDestination: Bool = true,
        overwriteExisting: Bool = false
    ) {
        self.validateConfiguration = validateConfiguration
        self.testDestination = testDestination
        self.overwriteExisting = overwriteExisting
    }
    
    /// Default options for adding a destination
    public static let `default` = AddDestinationOptionsDTO()
}

/**
 Options for removing a log destination.
 */
public struct RemoveDestinationOptionsDTO: Codable, Equatable, Sendable {
    /// Whether to flush pending logs before removal
    public let flushBeforeRemoval: Bool
    
    /// Whether to archive logs from the destination
    public let archiveLogs: Bool
    
    /// Path to save archived logs to (if archiving)
    public let archivePath: String?
    
    /**
     Initialises remove destination options.
     
     - Parameters:
        - flushBeforeRemoval: Whether to flush pending logs before removal
        - archiveLogs: Whether to archive logs from the destination
        - archivePath: Path to save archived logs to (if archiving)
     */
    public init(
        flushBeforeRemoval: Bool = true,
        archiveLogs: Bool = false,
        archivePath: String? = nil
    ) {
        self.flushBeforeRemoval = flushBeforeRemoval
        self.archiveLogs = archiveLogs
        self.archivePath = archivePath
    }
    
    /// Default options for removing a destination
    public static let `default` = RemoveDestinationOptionsDTO()
}

/**
 Options for updating a log destination.
 */
public struct UpdateDestinationOptionsDTO: Codable, Equatable, Sendable {
    /// Whether to validate the updated configuration
    public let validateConfiguration: Bool
    
    /// Whether to test the updated destination
    public let testUpdatedDestination: Bool
    
    /// Whether to restart the destination after update
    public let restartDestination: Bool
    
    /**
     Initialises update destination options.
     
     - Parameters:
        - validateConfiguration: Whether to validate the updated configuration
        - testUpdatedDestination: Whether to test the updated destination
        - restartDestination: Whether to restart the destination after update
     */
    public init(
        validateConfiguration: Bool = true,
        testUpdatedDestination: Bool = true,
        restartDestination: Bool = true
    ) {
        self.validateConfiguration = validateConfiguration
        self.testUpdatedDestination = testUpdatedDestination
        self.restartDestination = restartDestination
    }
    
    /// Default options for updating a destination
    public static let `default` = UpdateDestinationOptionsDTO()
}

/**
 Options for rotating logs.
 */
public struct RotateLogsOptionsDTO: Codable, Equatable, Sendable {
    /// Whether to force rotation even if threshold not reached
    public let forceRotation: Bool
    
    /// Compress rotated logs
    public let compressRotatedLogs: Bool
    
    /// Maximum number of rotated logs to keep
    public let maxRotatedLogs: Int?
    
    /// Custom filename pattern for rotated logs
    public let rotatedFilePattern: String?
    
    /**
     Initialises rotate logs options.
     
     - Parameters:
        - forceRotation: Whether to force rotation even if threshold not reached
        - compressRotatedLogs: Compress rotated logs
        - maxRotatedLogs: Maximum number of rotated logs to keep
        - rotatedFilePattern: Custom filename pattern for rotated logs
     */
    public init(
        forceRotation: Bool = false,
        compressRotatedLogs: Bool = true,
        maxRotatedLogs: Int? = nil,
        rotatedFilePattern: String? = nil
    ) {
        self.forceRotation = forceRotation
        self.compressRotatedLogs = compressRotatedLogs
        self.maxRotatedLogs = maxRotatedLogs
        self.rotatedFilePattern = rotatedFilePattern
    }
    
    /// Default options for rotating logs
    public static let `default` = RotateLogsOptionsDTO()
}

/**
 Options for exporting logs.
 */
public struct ExportLogsOptionsDTO: Codable, Equatable, Sendable {
    /// Format for exported logs
    public let format: ExportFormat
    
    /// Whether to include metadata
    public let includeMetadata: Bool
    
    /// Whether to apply redaction rules
    public let applyRedactionRules: Bool
    
    /// Filter criteria for logs to export
    public let filterCriteria: [LogFilterRuleDTO]?
    
    /// Maximum number of log entries to export
    public let maxEntries: Int?
    
    /// Sorting options for exported logs
    public let sortOrder: SortOrder
    
    /**
     Export format options.
     */
    public enum ExportFormat: String, Codable, Sendable {
        /// JSON format
        case json
        /// CSV format
        case csv
        /// Plain text format
        case text
        /// XML format
        case xml
        /// HTML report format
        case html
    }
    
    /**
     Sorting options for exported logs.
     */
    public enum SortOrder: String, Codable, Sendable {
        /// Newest logs first
        case newestFirst
        /// Oldest logs first
        case oldestFirst
        /// Sorted by log level (most severe first)
        case byLevelDescending
        /// Sorted by log level (least severe first)
        case byLevelAscending
        /// Sorted by category
        case byCategory
    }
    
    /**
     Initialises export logs options.
     
     - Parameters:
        - format: Format for exported logs
        - includeMetadata: Whether to include metadata
        - applyRedactionRules: Whether to apply redaction rules
        - filterCriteria: Filter criteria for logs to export
        - maxEntries: Maximum number of log entries to export
        - sortOrder: Sorting options for exported logs
     */
    public init(
        format: ExportFormat = .json,
        includeMetadata: Bool = true,
        applyRedactionRules: Bool = true,
        filterCriteria: [LogFilterRuleDTO]? = nil,
        maxEntries: Int? = nil,
        sortOrder: SortOrder = .newestFirst
    ) {
        self.format = format
        self.includeMetadata = includeMetadata
        self.applyRedactionRules = applyRedactionRules
        self.filterCriteria = filterCriteria
        self.maxEntries = maxEntries
        self.sortOrder = sortOrder
    }
    
    /// Default options for exporting logs
    public static let `default` = ExportLogsOptionsDTO()
}

/**
 Options for querying logs.
 */
public struct QueryLogsOptionsDTO: Codable, Equatable, Sendable {
    /// Filter criteria for logs to retrieve
    public let filterCriteria: [LogFilterRuleDTO]?
    
    /// Maximum number of log entries to retrieve
    public let maxEntries: Int?
    
    /// Sorting options for retrieved logs
    public let sortOrder: ExportLogsOptionsDTO.SortOrder
    
    /// Whether to include metadata
    public let includeMetadata: Bool
    
    /// Pagination offset (skip this many entries)
    public let offset: Int
    
    /// Whether to apply redaction rules
    public let applyRedactionRules: Bool
    
    /**
     Initialises query logs options.
     
     - Parameters:
        - filterCriteria: Filter criteria for logs to retrieve
        - maxEntries: Maximum number of log entries to retrieve
        - sortOrder: Sorting options for retrieved logs
        - includeMetadata: Whether to include metadata
        - offset: Pagination offset (skip this many entries)
        - applyRedactionRules: Whether to apply redaction rules
     */
    public init(
        filterCriteria: [LogFilterRuleDTO]? = nil,
        maxEntries: Int? = 100,
        sortOrder: ExportLogsOptionsDTO.SortOrder = .newestFirst,
        includeMetadata: Bool = true,
        offset: Int = 0,
        applyRedactionRules: Bool = true
    ) {
        self.filterCriteria = filterCriteria
        self.maxEntries = maxEntries
        self.sortOrder = sortOrder
        self.includeMetadata = includeMetadata
        self.offset = offset
        self.applyRedactionRules = applyRedactionRules
    }
    
    /// Default options for querying logs
    public static let `default` = QueryLogsOptionsDTO()
}

/**
 Options for archiving logs.
 */
public struct ArchiveLogsOptionsDTO: Codable, Equatable, Sendable {
    /// Destination path for the archive
    public let destinationPath: String
    
    /// Whether to compress the archive
    public let compress: Bool
    
    /// Format for the archive
    public let format: ArchiveFormat
    
    /// Filter criteria for logs to archive
    public let filterCriteria: [LogFilterRuleDTO]?
    
    /// Whether to delete logs after archiving
    public let deleteAfterArchiving: Bool
    
    /// Password for encrypted archives
    public let encryptionPassword: String?
    
    /**
     Archive format options.
     */
    public enum ArchiveFormat: String, Codable, Sendable {
        /// ZIP archive format
        case zip
        /// TAR archive format
        case tar
        /// TAR.GZ compressed archive format
        case tarGz
        /// Custom archive format
        case custom
    }
    
    /**
     Initialises archive logs options.
     
     - Parameters:
        - destinationPath: Destination path for the archive
        - compress: Whether to compress the archive
        - format: Format for the archive
        - filterCriteria: Filter criteria for logs to archive
        - deleteAfterArchiving: Whether to delete logs after archiving
        - encryptionPassword: Password for encrypted archives
     */
    public init(
        destinationPath: String,
        compress: Bool = true,
        format: ArchiveFormat = .zip,
        filterCriteria: [LogFilterRuleDTO]? = nil,
        deleteAfterArchiving: Bool = false,
        encryptionPassword: String? = nil
    ) {
        self.destinationPath = destinationPath
        self.compress = compress
        self.format = format
        self.filterCriteria = filterCriteria
        self.deleteAfterArchiving = deleteAfterArchiving
        self.encryptionPassword = encryptionPassword
    }
}

/**
 Options for purging logs.
 */
public struct PurgeLogsOptionsDTO: Codable, Equatable, Sendable {
    /// Whether to create a backup before purging
    public let createBackup: Bool
    
    /// Path for backup (if creating one)
    public let backupPath: String?
    
    /// Filter criteria for logs to purge
    public let filterCriteria: [LogFilterRuleDTO]?
    
    /// Whether this is a dry run (no actual deletion)
    public let dryRun: Bool
    
    /// Log destinations to purge (empty means all)
    public let destinationIds: [String]
    
    /**
     Initialises purge logs options.
     
     - Parameters:
        - createBackup: Whether to create a backup before purging
        - backupPath: Path for backup (if creating one)
        - filterCriteria: Filter criteria for logs to purge
        - dryRun: Whether this is a dry run (no actual deletion)
        - destinationIds: Log destinations to purge
     */
    public init(
        createBackup: Bool = true,
        backupPath: String? = nil,
        filterCriteria: [LogFilterRuleDTO]? = nil,
        dryRun: Bool = false,
        destinationIds: [String] = []
    ) {
        self.createBackup = createBackup
        self.backupPath = backupPath
        self.filterCriteria = filterCriteria
        self.dryRun = dryRun
        self.destinationIds = destinationIds
    }
    
    /// Default options for purging logs
    public static let `default` = PurgeLogsOptionsDTO()
}
