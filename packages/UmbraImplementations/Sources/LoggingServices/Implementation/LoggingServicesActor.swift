import Foundation
import LoggingInterfaces
import LoggingTypes
import CoreDTOs

/**
 Actor implementation of the logging service.
 
 This actor provides a thread-safe implementation of the PrivacyAwareLoggingProtocol
 using the command pattern to handle all operations.
 */
public actor LoggingServicesActor: PrivacyAwareLoggingProtocol {
    /// Factory for creating logging commands
    private let commandFactory: LogCommandFactory
    
    /// Default log destinations when none are specified
    private var defaultDestinationIds: [String] = []
    
    /// Active log destinations
    private var activeDestinations: [String: LogDestinationDTO] = [:]
    
    /// Minimum log level to record
    private var minimumLogLevel: LogLevel = .info
    
    /**
     Initialises a new logging services actor.
     
     - Parameters:
        - commandFactory: Factory for creating logging commands
        - minimumLogLevel: Minimum log level to record
     */
    public init(
        commandFactory: LogCommandFactory,
        minimumLogLevel: LogLevel = .info
    ) {
        self.commandFactory = commandFactory
        self.minimumLogLevel = minimumLogLevel
    }
    
    /**
     Logs a message with the specified level and context.
     
     - Parameters:
        - level: The severity level of the log message
        - message: The message to log
        - context: Additional context for the log entry
        - file: The file where the log call originated
        - function: The function where the log call originated
        - line: The line where the log call originated
     */
    public func log(
        _ level: LogLevel,
        _ message: String,
        context: LogContextDTO,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) async {
        // Skip logging if below minimum level
        guard level.rawValue >= minimumLogLevel.rawValue else {
            return
        }
        
        // Create source location from file, function, and line
        let sourceLocation = SourceLocationDTO(
            file: file,
            function: function,
            line: line
        )
        
        // Create log entry
        let entry = LogEntryDTO(
            level: level,
            category: context.category,
            message: message,
            metadata: context.metadata,
            sourceLocation: sourceLocation
        )
        
        // Determine destinations to write to
        let destinationIds = defaultDestinationIds
        
        do {
            // Create and execute write command
            let writeCommand = try commandFactory.createWriteCommand(
                entry: entry,
                destinationIds: destinationIds
            )
            
            // Execute write asynchronously
            Task {
                do {
                    _ = try await writeCommand.execute(context: context)
                } catch {
                    // Cannot log this error, as it would cause infinite recursion
                    // In a real implementation, we might have a separate error reporting mechanism
                    print("Error writing log entry: \(error.localizedDescription)")
                }
            }
        } catch {
            // Cannot log this error, as it would cause infinite recursion
            print("Error creating write command: \(error.localizedDescription)")
        }
    }
    
    /**
     Adds a log destination.
     
     - Parameters:
        - destination: The destination to add
        - options: Options for adding the destination
     - Returns: Whether the operation was successful
     - Throws: LoggingError if the operation fails
     */
    public func addDestination(
        _ destination: LogDestinationDTO,
        options: AddDestinationOptionsDTO = .default
    ) async throws -> Bool {
        let command = try commandFactory.createAddDestinationCommand(
            destination: destination,
            options: options
        )
        
        let context = LogContextDTO(
            operation: "addDestination",
            category: "LoggingSystem",
            metadata: LogMetadataDTOCollection()
                .withPublic(key: "destinationType", value: destination.type.rawValue)
                .withPublic(key: "destinationName", value: destination.name)
        )
        
        let success = try await command.execute(context: context)
        
        if success {
            // Update active destinations and default destinations
            activeDestinations[destination.id] = destination
            
            // Add to default destinations if this is the first one
            if defaultDestinationIds.isEmpty {
                defaultDestinationIds.append(destination.id)
            }
        }
        
        return success
    }
    
    /**
     Removes a log destination.
     
     - Parameters:
        - destinationId: The ID of the destination to remove
        - options: Options for removing the destination
     - Returns: Whether the operation was successful
     - Throws: LoggingError if the operation fails
     */
    public func removeDestination(
        withId destinationId: String,
        options: RemoveDestinationOptionsDTO = .default
    ) async throws -> Bool {
        let command = try commandFactory.createRemoveDestinationCommand(
            destinationId: destinationId,
            options: options
        )
        
        let context = LogContextDTO(
            operation: "removeDestination",
            category: "LoggingSystem",
            metadata: LogMetadataDTOCollection()
                .withPublic(key: "destinationId", value: destinationId)
        )
        
        let success = try await command.execute(context: context)
        
        if success {
            // Update active destinations and default destinations
            activeDestinations.removeValue(forKey: destinationId)
            defaultDestinationIds.removeAll { $0 == destinationId }
        }
        
        return success
    }
    
    /**
     Updates the minimum log level.
     
     - Parameters:
        - level: The new minimum log level
     */
    public func setMinimumLogLevel(_ level: LogLevel) async {
        self.minimumLogLevel = level
    }
    
    /**
     Gets the current minimum log level.
     
     - Returns: The current minimum log level
     */
    public func getMinimumLogLevel() async -> LogLevel {
        return minimumLogLevel
    }
    
    /**
     Sets the default destinations to write to when none are specified.
     
     - Parameters:
        - destinationIds: The IDs of the destinations to use by default
     */
    public func setDefaultDestinations(_ destinationIds: [String]) async {
        self.defaultDestinationIds = destinationIds
    }
    
    /**
     Gets the current default destinations.
     
     - Returns: The IDs of the current default destinations
     */
    public func getDefaultDestinations() async -> [String] {
        return defaultDestinationIds
    }
    
    /**
     Gets all active log destinations.
     
     - Returns: All active log destinations
     */
    public func getActiveDestinations() async -> [LogDestinationDTO] {
        return Array(activeDestinations.values)
    }
    
    /**
     Rotates logs for a destination.
     
     - Parameters:
        - destinationId: The ID of the destination to rotate logs for
        - options: Options for rotating logs
     - Returns: The result of the rotation operation
     - Throws: LoggingError if the operation fails
     */
    public func rotateLogs(
        forDestination destinationId: String,
        options: RotateLogsOptionsDTO = .default
    ) async throws -> LogRotationResultDTO {
        let command = try commandFactory.createRotateLogsCommand(
            destinationId: destinationId,
            options: options
        )
        
        let context = LogContextDTO(
            operation: "rotateLogs",
            category: "LoggingSystem",
            metadata: LogMetadataDTOCollection()
                .withPublic(key: "destinationId", value: destinationId)
        )
        
        return try await command.execute(context: context)
    }
    
    /**
     Exports logs from a destination.
     
     - Parameters:
        - destinationId: The ID of the destination to export logs from
        - options: Options for exporting logs
     - Returns: The exported log data
     - Throws: LoggingError if the operation fails
     */
    public func exportLogs(
        fromDestination destinationId: String,
        options: ExportLogsOptionsDTO = .default
    ) async throws -> Data {
        let command = try commandFactory.createExportLogsCommand(
            destinationId: destinationId,
            options: options
        )
        
        let context = LogContextDTO(
            operation: "exportLogs",
            category: "LoggingSystem",
            metadata: LogMetadataDTOCollection()
                .withPublic(key: "destinationId", value: destinationId)
                .withPublic(key: "exportFormat", value: options.format.rawValue)
        )
        
        return try await command.execute(context: context)
    }
    
    /**
     Queries logs from a destination.
     
     - Parameters:
        - destinationId: The ID of the destination to query logs from
        - options: Options for querying logs
     - Returns: The matching log entries
     - Throws: LoggingError if the operation fails
     */
    public func queryLogs(
        fromDestination destinationId: String,
        options: QueryLogsOptionsDTO = .default
    ) async throws -> [LogEntryDTO] {
        let command = try commandFactory.createQueryLogsCommand(
            destinationId: destinationId,
            options: options
        )
        
        let context = LogContextDTO(
            operation: "queryLogs",
            category: "LoggingSystem",
            metadata: LogMetadataDTOCollection()
                .withPublic(key: "destinationId", value: destinationId)
        )
        
        return try await command.execute(context: context)
    }
    
    /**
     Archives logs from a destination.
     
     - Parameters:
        - destinationId: The ID of the destination to archive logs from
        - options: Options for archiving logs
     - Returns: The result of the archive operation
     - Throws: LoggingError if the operation fails
     */
    public func archiveLogs(
        fromDestination destinationId: String,
        options: ArchiveLogsOptionsDTO
    ) async throws -> LogArchiveResultDTO {
        let command = try commandFactory.createArchiveLogsCommand(
            destinationId: destinationId,
            options: options
        )
        
        let context = LogContextDTO(
            operation: "archiveLogs",
            category: "LoggingSystem",
            metadata: LogMetadataDTOCollection()
                .withPublic(key: "destinationId", value: destinationId)
                .withProtected(key: "destinationPath", value: options.destinationPath)
        )
        
        return try await command.execute(context: context)
    }
    
    /**
     Purges logs from destinations.
     
     - Parameters:
        - destinationId: The ID of the destination to purge logs from, or nil for all destinations
        - options: Options for purging logs
     - Returns: The result of the purge operation
     - Throws: LoggingError if the operation fails
     */
    public func purgeLogs(
        fromDestination destinationId: String? = nil,
        options: PurgeLogsOptionsDTO = .default
    ) async throws -> LogPurgeResultDTO {
        let command = try commandFactory.createPurgeLogsCommand(
            destinationId: destinationId,
            options: options
        )
        
        let context = LogContextDTO(
            operation: "purgeLogs",
            category: "LoggingSystem",
            metadata: LogMetadataDTOCollection()
                .withPublic(key: "destinationId", value: destinationId ?? "all")
                .withPublic(key: "dryRun", value: String(options.dryRun))
        )
        
        return try await command.execute(context: context)
    }
}
