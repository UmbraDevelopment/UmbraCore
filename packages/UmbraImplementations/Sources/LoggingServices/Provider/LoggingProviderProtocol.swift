import Foundation
import LoggingInterfaces
import LoggingTypes

/**
 Protocol for logging provider implementations.
 
 This protocol defines the common interface for all logging providers,
 allowing different backend implementations to be used interchangeably.
 */
public protocol LoggingProviderProtocol {
    /**
     Write a log entry to a destination.
     
     - Parameters:
        - entry: The log entry to write
        - destination: The destination to write to
     - Returns: Whether the write operation was successful
     - Throws: LoggingError if writing fails
     */
    func writeLog(
        entry: LoggingInterfaces.LogEntryDTO,
        to destination: LoggingInterfaces.LogDestinationDTO
    ) async throws -> Bool
    
    /**
     Rotate logs for a destination.
     
     - Parameters:
        - destination: The destination to rotate logs for
        - options: Options controlling the rotation
     - Returns: Whether the rotation was successful
     - Throws: LoggingError if rotation fails
     */
    func rotateLogs(
        for destination: LoggingInterfaces.LogDestinationDTO,
        options: LoggingInterfaces.RotateLogsOptionsDTO
    ) async throws -> Bool
    
    /**
     Flush logs for a destination.
     
     - Parameter destination: The destination to flush logs for
     - Returns: Whether the flush was successful
     - Throws: LoggingError if flushing fails
     */
    func flushLogs(
        for destination: LoggingInterfaces.LogDestinationDTO
    ) async throws -> Bool
    
    /**
     Export logs from a destination.
     
     - Parameters:
        - destination: The destination to export logs from
        - options: Options controlling the export
     - Returns: The exported log data
     - Throws: LoggingError if export fails
     */
    func exportLogs(
        from destination: LoggingInterfaces.LogDestinationDTO,
        options: LoggingInterfaces.ExportLogsOptionsDTO
    ) async throws -> Data
    
    /**
     Query logs from a destination.
     
     - Parameters:
        - destination: The destination to query logs from
        - options: Options controlling the query
     - Returns: The log entries matching the query
     - Throws: LoggingError if query fails
     */
    func queryLogs(
        from destination: LoggingInterfaces.LogDestinationDTO,
        options: LoggingInterfaces.QueryLogsOptionsDTO
    ) async throws -> [LoggingInterfaces.LogEntryDTO]
    
    /**
     Archive logs from a destination.
     
     - Parameters:
        - destination: The destination to archive logs from
        - options: Options controlling the archiving
     - Returns: Whether the archive was successful
     - Throws: LoggingError if archiving fails
     */
    func archiveLogs(
        from destination: LoggingInterfaces.LogDestinationDTO,
        options: LoggingInterfaces.ArchiveLogsOptionsDTO
    ) async throws -> Bool
    
    /**
     Purge logs from a destination.
     
     - Parameters:
        - destination: The destination to purge logs from
        - options: Options controlling the purge
     - Returns: Whether the purge was successful
     - Throws: LoggingError if purging fails
     */
    func purgeLogs(
        from destination: LoggingInterfaces.LogDestinationDTO,
        options: LoggingInterfaces.PurgeLogsOptionsDTO
    ) async throws -> Bool
    
    /**
     Get the destination type that this provider can handle.
     
     - Returns: The type of log destination this provider can handle
     */
    func canHandleDestinationType() -> LoggingInterfaces.LogDestinationType
}

/**
 Default implementations for LoggingProviderProtocol.
 
 These implementations provide reasonable defaults for optional methods.
 */
public extension LoggingProviderProtocol {
    /**
     Default implementation of writeLogEntry that calls through to writeLog.
     
     - Parameters:
        - entry: The log entry to write
        - destination: The destination to write to
     - Returns: Whether the operation was successful
     - Throws: LoggingError if writing fails
     */
    func writeLogEntry(
        entry: LoggingInterfaces.LogEntryDTO,
        to destination: LoggingInterfaces.LogDestinationDTO
    ) async throws -> Bool {
        return try await writeLog(entry: entry, to: destination)
    }
}
