import Foundation
import LoggingInterfaces
import LoggingTypes
import CoreDTOs

/**
 Factory for creating logging commands.
 
 This class centralises the creation of logging commands,
 ensuring consistent initialisation and dependencies.
 */
public class LogCommandFactory {
    /// Logger instance for logging operations
    private let logger: PrivacyAwareLoggingProtocol
    
    /// Map of providers by destination type
    private let providers: [LogDestinationType: LoggingProviderProtocol]
    
    /**
     Initialises a new logging command factory.
     
     - Parameters:
        - providers: Map of providers by destination type
        - logger: Logger instance for logging operations
     */
    public init(
        providers: [LogDestinationType: LoggingProviderProtocol],
        logger: PrivacyAwareLoggingProtocol
    ) {
        self.providers = providers
        self.logger = logger
    }
    
    /**
     Creates a write log command.
     
     - Parameters:
        - entry: The log entry to write
        - destinationIds: The destinations to write to (empty means all registered destinations)
     - Returns: The created command
     - Throws: LoggingError if no provider is available for the destination type
     */
    public func createWriteCommand(
        entry: LogEntryDTO,
        destinationIds: [String] = []
    ) throws -> WriteLogCommand {
        // Use default provider for writing
        guard let provider = defaultProvider() else {
            throw LoggingError.general("No default provider available")
        }
        
        return WriteLogCommand(
            entry: entry,
            destinationIds: destinationIds,
            provider: provider,
            logger: logger
        )
    }
    
    /**
     Creates an add destination command.
     
     - Parameters:
        - destination: The destination to add
        - options: Options for adding the destination
     - Returns: The created command
     - Throws: LoggingError if no provider is available for the destination type
     */
    public func createAddDestinationCommand(
        destination: LogDestinationDTO,
        options: AddDestinationOptionsDTO = .default
    ) throws -> AddDestinationCommand {
        guard let provider = providerFor(destinationType: destination.type) else {
            throw LoggingError.destinationNotFound(
                "No provider available for destination type: \(destination.type.rawValue)"
            )
        }
        
        return AddDestinationCommand(
            destination: destination,
            options: options,
            provider: provider,
            logger: logger
        )
    }
    
    /**
     Creates a remove destination command.
     
     - Parameters:
        - destinationId: The ID of the destination to remove
        - options: Options for removing the destination
     - Returns: The created command
     - Throws: LoggingError if no provider is available
     */
    public func createRemoveDestinationCommand(
        destinationId: String,
        options: RemoveDestinationOptionsDTO = .default
    ) throws -> RemoveDestinationCommand {
        // Use default provider for removing destinations
        guard let provider = defaultProvider() else {
            throw LoggingError.general("No default provider available")
        }
        
        return RemoveDestinationCommand(
            destinationId: destinationId,
            options: options,
            provider: provider,
            logger: logger
        )
    }
    
    /**
     Creates a rotate logs command.
     
     - Parameters:
        - destinationId: The ID of the destination to rotate logs for
        - options: Options for rotating logs
     - Returns: The created command
     - Throws: LoggingError if no provider is available
     */
    public func createRotateLogsCommand(
        destinationId: String,
        options: RotateLogsOptionsDTO = .default
    ) throws -> RotateLogsCommand {
        // Since we need the destination type to select a provider,
        // we'll defer provider selection to the command execution
        guard let provider = defaultProvider() else {
            throw LoggingError.general("No default provider available")
        }
        
        return RotateLogsCommand(
            destinationId: destinationId,
            options: options,
            provider: provider,
            logger: logger
        )
    }
    
    /**
     Creates an export logs command.
     
     - Parameters:
        - destinationId: The ID of the destination to export logs from
        - options: Options for exporting logs
     - Returns: The created command
     - Throws: LoggingError if no provider is available
     */
    public func createExportLogsCommand(
        destinationId: String,
        options: ExportLogsOptionsDTO = .default
    ) throws -> ExportLogsCommand {
        // Since we need the destination type to select a provider,
        // we'll defer provider selection to the command execution
        guard let provider = defaultProvider() else {
            throw LoggingError.general("No default provider available")
        }
        
        return ExportLogsCommand(
            destinationId: destinationId,
            options: options,
            provider: provider,
            logger: logger
        )
    }
    
    /**
     Creates a query logs command.
     
     - Parameters:
        - destinationId: The ID of the destination to query logs from
        - options: Options for querying logs
     - Returns: The created command
     - Throws: LoggingError if no provider is available
     */
    public func createQueryLogsCommand(
        destinationId: String,
        options: QueryLogsOptionsDTO = .default
    ) throws -> QueryLogsCommand {
        // Since we need the destination type to select a provider,
        // we'll defer provider selection to the command execution
        guard let provider = defaultProvider() else {
            throw LoggingError.general("No default provider available")
        }
        
        return QueryLogsCommand(
            destinationId: destinationId,
            options: options,
            provider: provider,
            logger: logger
        )
    }
    
    /**
     Creates an archive logs command.
     
     - Parameters:
        - destinationId: The ID of the destination to archive logs from
        - options: Options for archiving logs
     - Returns: The created command
     - Throws: LoggingError if no provider is available
     */
    public func createArchiveLogsCommand(
        destinationId: String,
        options: ArchiveLogsOptionsDTO
    ) throws -> ArchiveLogsCommand {
        // Since we need the destination type to select a provider,
        // we'll defer provider selection to the command execution
        guard let provider = defaultProvider() else {
            throw LoggingError.general("No default provider available")
        }
        
        return ArchiveLogsCommand(
            destinationId: destinationId,
            options: options,
            provider: provider,
            logger: logger
        )
    }
    
    /**
     Creates a purge logs command.
     
     - Parameters:
        - destinationId: The ID of the destination to purge logs from, or nil for all destinations
        - options: Options for purging logs
     - Returns: The created command
     - Throws: LoggingError if no provider is available
     */
    public func createPurgeLogsCommand(
        destinationId: String? = nil,
        options: PurgeLogsOptionsDTO = .default
    ) throws -> PurgeLogsCommand {
        // Use default provider for purging
        guard let provider = defaultProvider() else {
            throw LoggingError.general("No default provider available")
        }
        
        return PurgeLogsCommand(
            destinationId: destinationId,
            options: options,
            provider: provider,
            logger: logger
        )
    }
    
    // MARK: - Private Methods
    
    /**
     Gets a provider for a specific destination type.
     
     - Parameters:
        - destinationType: The destination type to get a provider for
     - Returns: A provider for the destination type, or nil if none is available
     */
    private func providerFor(destinationType: LogDestinationType) -> LoggingProviderProtocol? {
        return providers[destinationType]
    }
    
    /**
     Gets the default provider.
     
     - Returns: The default provider, or nil if none is available
     */
    private func defaultProvider() -> LoggingProviderProtocol? {
        // Prefer console provider, then file provider, then any available provider
        return providers[.console] ?? providers[.file] ?? providers.values.first
    }
}
