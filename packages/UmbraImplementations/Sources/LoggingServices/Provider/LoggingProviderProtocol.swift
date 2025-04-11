import Foundation
import LoggingInterfaces
import LoggingTypes
import SchedulingTypes

/**
 Protocol defining the logging provider operations.
 
 This protocol serves as the internal interface for different logging
 provider implementations (file, console, network, etc.)
 */
public protocol LoggingProviderProtocol {
    /**
     Writes a log entry to a destination.
     
     - Parameters:
        - entry: The log entry to write
        - destination: The destination to write to
     - Returns: Success indicator
     - Throws: LoggingError if writing fails
     */
    func writeLog(
        entry: LogEntryDTO,
        to destination: LogDestinationDTO
    ) async throws -> Bool
    
    /**
     Rotates logs for a destination.
     
     - Parameters:
        - destination: The destination to rotate logs for
        - options: Options for log rotation
     - Returns: Success indicator with metadata
     - Throws: LoggingError if rotation fails
     */
    func rotateLogs(
        for destination: LogDestinationDTO,
        options: RotateLogsOptionsDTO
    ) async throws -> LogRotationResultDTO
    
    /**
     Flushes pending logs for a destination.
     
     - Parameters:
        - destination: The destination to flush logs for
     - Returns: Success indicator
     - Throws: LoggingError if flushing fails
     */
    func flushLogs(
        for destination: LogDestinationDTO
    ) async throws -> Bool
    
    /**
     Exports logs from a destination.
     
     - Parameters:
        - destination: The destination to export logs from
        - options: Options for log export
     - Returns: The exported logs data
     - Throws: LoggingError if export fails
     */
    func exportLogs(
        from destination: LogDestinationDTO,
        options: ExportLogsOptionsDTO
    ) async throws -> Data
    
    /**
     Queries logs from a destination.
     
     - Parameters:
        - destination: The destination to query logs from
        - options: Options for log query
     - Returns: The matching log entries
     - Throws: LoggingError if query fails
     */
    func queryLogs(
        from destination: LogDestinationDTO,
        options: QueryLogsOptionsDTO
    ) async throws -> [LogEntryDTO]
    
    /**
     Archives logs from a destination.
     
     - Parameters:
        - destination: The destination to archive logs from
        - options: Options for log archiving
     - Returns: Success indicator with metadata
     - Throws: LoggingError if archiving fails
     */
    func archiveLogs(
        from destination: LogDestinationDTO,
        options: ArchiveLogsOptionsDTO
    ) async throws -> LogArchiveResultDTO
    
    /**
     Purges logs from a destination.
     
     - Parameters:
        - destination: The destination to purge logs from
        - options: Options for log purging
     - Returns: Success indicator with metadata
     - Throws: LoggingError if purging fails
     */
    func purgeLogs(
        from destination: LogDestinationDTO,
        options: PurgeLogsOptionsDTO
    ) async throws -> LogPurgeResultDTO
    
    /**
     Gets the destination type that this provider can handle.
     
     - Returns: The type of log destination this provider can handle
     */
    func canHandleDestinationType() -> LogDestinationType
}

/**
 Result of rotating logs.
 
 Contains information about the rotation operation result.
 */
public struct LogRotationResultDTO: Codable, Equatable, Sendable {
    /// Whether the rotation was successful
    public let success: Bool
    
    /// Path where rotated logs were stored
    public let rotatedFilePath: String?
    
    /// Timestamp when the rotation occurred
    public let timestamp: Date
    
    /// Size of the rotated logs in bytes
    public let rotatedSizeBytes: UInt64?
    
    /// Number of entries in the rotated logs
    public let rotatedEntryCount: Int?
    
    /// Additional result metadata
    public let metadata: [String: String]
    
    /**
     Initialises a log rotation result.
     
     - Parameters:
        - success: Whether the rotation was successful
        - rotatedFilePath: Path where rotated logs were stored
        - timestamp: Timestamp when the rotation occurred
        - rotatedSizeBytes: Size of the rotated logs in bytes
        - rotatedEntryCount: Number of entries in the rotated logs
        - metadata: Additional result metadata
     */
    public init(
        success: Bool,
        rotatedFilePath: String? = nil,
        timestamp: Date = Date(),
        rotatedSizeBytes: UInt64? = nil,
        rotatedEntryCount: Int? = nil,
        metadata: [String: String] = [:]
    ) {
        self.success = success
        self.rotatedFilePath = rotatedFilePath
        self.timestamp = timestamp
        self.rotatedSizeBytes = rotatedSizeBytes
        self.rotatedEntryCount = rotatedEntryCount
        self.metadata = metadata
    }
    
    /// Returns a successful rotation result
    public static func success(path: String) -> LogRotationResultDTO {
        return LogRotationResultDTO(success: true, rotatedFilePath: path)
    }
    
    /// Returns a failed rotation result
    public static func failure(reason: String) -> LogRotationResultDTO {
        return LogRotationResultDTO(
            success: false,
            metadata: ["error": reason]
        )
    }
}

/**
 Result of archiving logs.
 
 Contains information about the archive operation result.
 */
public struct LogArchiveResultDTO: Codable, Equatable, Sendable {
    /// Whether the archive operation was successful
    public let success: Bool
    
    /// Path where the archive was stored
    public let archivePath: String?
    
    /// Timestamp when the archive was created
    public let timestamp: Date
    
    /// Size of the archive in bytes
    public let archiveSizeBytes: UInt64?
    
    /// Number of entries in the archive
    public let archivedEntryCount: Int?
    
    /// Whether the archive is compressed
    public let isCompressed: Bool
    
    /// Whether the archive is encrypted
    public let isEncrypted: Bool
    
    /// Additional result metadata
    public let metadata: [String: String]
    
    /**
     Initialises a log archive result.
     
     - Parameters:
        - success: Whether the archive operation was successful
        - archivePath: Path where the archive was stored
        - timestamp: Timestamp when the archive was created
        - archiveSizeBytes: Size of the archive in bytes
        - archivedEntryCount: Number of entries in the archive
        - isCompressed: Whether the archive is compressed
        - isEncrypted: Whether the archive is encrypted
        - metadata: Additional result metadata
     */
    public init(
        success: Bool,
        archivePath: String? = nil,
        timestamp: Date = Date(),
        archiveSizeBytes: UInt64? = nil,
        archivedEntryCount: Int? = nil,
        isCompressed: Bool = false,
        isEncrypted: Bool = false,
        metadata: [String: String] = [:]
    ) {
        self.success = success
        self.archivePath = archivePath
        self.timestamp = timestamp
        self.archiveSizeBytes = archiveSizeBytes
        self.archivedEntryCount = archivedEntryCount
        self.isCompressed = isCompressed
        self.isEncrypted = isEncrypted
        self.metadata = metadata
    }
    
    /// Returns a successful archive result
    public static func success(path: String) -> LogArchiveResultDTO {
        return LogArchiveResultDTO(success: true, archivePath: path)
    }
    
    /// Returns a failed archive result
    public static func failure(reason: String) -> LogArchiveResultDTO {
        return LogArchiveResultDTO(
            success: false,
            metadata: ["error": reason]
        )
    }
}

/**
 Result of purging logs.
 
 Contains information about the purge operation result.
 */
public struct LogPurgeResultDTO: Codable, Equatable, Sendable {
    /// Whether the purge operation was successful
    public let success: Bool
    
    /// Timestamp when the purge occurred
    public let timestamp: Date
    
    /// Number of entries that were purged
    public let purgedEntryCount: Int?
    
    /// Size of purged data in bytes
    public let purgedSizeBytes: UInt64?
    
    /// Path to backup if one was created
    public let backupPath: String?
    
    /// Whether this was a dry run
    public let wasDryRun: Bool
    
    /// Additional result metadata
    public let metadata: [String: String]
    
    /**
     Initialises a log purge result.
     
     - Parameters:
        - success: Whether the purge operation was successful
        - timestamp: Timestamp when the purge occurred
        - purgedEntryCount: Number of entries that were purged
        - purgedSizeBytes: Size of purged data in bytes
        - backupPath: Path to backup if one was created
        - wasDryRun: Whether this was a dry run
        - metadata: Additional result metadata
     */
    public init(
        success: Bool,
        timestamp: Date = Date(),
        purgedEntryCount: Int? = nil,
        purgedSizeBytes: UInt64? = nil,
        backupPath: String? = nil,
        wasDryRun: Bool = false,
        metadata: [String: String] = [:]
    ) {
        self.success = success
        self.timestamp = timestamp
        self.purgedEntryCount = purgedEntryCount
        self.purgedSizeBytes = purgedSizeBytes
        self.backupPath = backupPath
        self.wasDryRun = wasDryRun
        self.metadata = metadata
    }
    
    /// Returns a successful purge result
    public static func success(entryCount: Int) -> LogPurgeResultDTO {
        return LogPurgeResultDTO(success: true, purgedEntryCount: entryCount)
    }
    
    /// Returns a successful dry run result
    public static func dryRun(entryCount: Int) -> LogPurgeResultDTO {
        return LogPurgeResultDTO(success: true, purgedEntryCount: entryCount, wasDryRun: true)
    }
    
    /// Returns a failed purge result
    public static func failure(reason: String) -> LogPurgeResultDTO {
        return LogPurgeResultDTO(
            success: false,
            metadata: ["error": reason]
        )
    }
}
