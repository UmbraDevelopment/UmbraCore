import Foundation
import LoggingTypes
import LoggingInterfaces

/**
 Factory for creating logging commands.
 
 This class centralises the creation of logging commands,
 ensuring consistent initialisation and dependencies.
 */
public class LogCommandFactory {
    /// Logger instance for logging operations
    private let logger: LoggingInterfaces.PrivacyAwareLoggingProtocol
    
    /// Map of providers by destination type
    private let providers: [LoggingInterfaces.LogDestinationType: LoggingProviderProtocol]
    
    /// Reference to the LoggingServicesActor
    private let loggingServicesActor: LoggingServicesActor
    
    /**
     Initialises a new logging command factory.
     
     - Parameters:
        - providers: Map of providers by destination type
        - logger: Logger instance for logging operations
        - loggingServicesActor: Reference to the LoggingServicesActor
     */
    public init(
        providers: [LoggingInterfaces.LogDestinationType: LoggingProviderProtocol],
        logger: LoggingInterfaces.PrivacyAwareLoggingProtocol,
        loggingServicesActor: LoggingServicesActor
    ) {
        self.providers = providers
        self.logger = logger
        self.loggingServicesActor = loggingServicesActor
    }
    
    /**
     Creates a write log command for a destination.
     
     - Parameters:
        - entry: The log entry to write
        - destination: The destination to write to
     - Returns: A configured WriteLogCommand instance
     - Throws: LoggingError if no suitable provider is available
     */
    public func makeWriteLogCommand(
        entry: LoggingInterfaces.LogEntryDTO,
        destination: LoggingInterfaces.LogDestinationDTO
    ) throws -> WriteLogCommand {
        // Get the provider for this destination type
        guard let provider = providerFor(destinationType: destination.type) else {
            throw LoggingTypes.LoggingError.invalidDestinationConfig("No provider available for destination type: \(destination.type.rawValue)")
        }
        
        return WriteLogCommand(
            entry: entry,
            destination: destination,
            provider: provider,
            loggingServices: loggingServicesActor
        )
    }
    
    /**
     Creates an add destination command.
     
     - Parameters:
        - destination: The destination to add
        - options: Options for adding the destination
     - Returns: A configured AddDestinationCommand instance
     - Throws: LoggingError if no suitable provider is available
     */
    public func makeAddDestinationCommand(
        destination: LoggingInterfaces.LogDestinationDTO,
        options: LoggingInterfaces.AddDestinationOptionsDTO = .default
    ) throws -> AddDestinationCommand {
        guard let provider = providerFor(destinationType: destination.type) else {
            throw LoggingTypes.LoggingError.invalidDestinationConfig("No provider available for destination type: \(destination.type.rawValue)")
        }
        
        return AddDestinationCommand(
            destination: destination,
            options: options,
            provider: provider,
            loggingServices: loggingServicesActor
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
        options: LoggingInterfaces.RemoveDestinationOptionsDTO = .default
    ) throws -> RemoveDestinationCommand {
        // Use default provider for removing destinations
        guard let provider = defaultProvider() else {
            throw LoggingInterfaces.LoggingError.initialisationFailed("No default provider available")
        }
        
        return RemoveDestinationCommand(
            destinationId: destinationId,
            options: options,
            provider: provider,
            loggingServices: loggingServicesActor
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
        options: LoggingInterfaces.RotateLogsOptionsDTO = .default
    ) throws -> RotateLogsCommand {
        guard let provider = defaultProvider() else {
            throw LoggingInterfaces.LoggingError.initialisationFailed("No default provider available")
        }
        
        return RotateLogsCommand(
            destinationId: destinationId,
            options: options,
            provider: provider,
            loggingServices: loggingServicesActor
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
        options: LoggingInterfaces.ExportLogsOptionsDTO = .default
    ) throws -> ExportLogsCommand {
        guard let provider = defaultProvider() else {
            throw LoggingInterfaces.LoggingError.initialisationFailed("No default provider available")
        }
        
        return ExportLogsCommand(
            destinationId: destinationId,
            options: options,
            provider: provider,
            loggingServices: loggingServicesActor
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
        options: LoggingInterfaces.QueryLogsOptionsDTO = .default
    ) throws -> QueryLogsCommand {
        guard let provider = defaultProvider() else {
            throw LoggingInterfaces.LoggingError.initialisationFailed("No default provider available")
        }
        
        return QueryLogsCommand(
            destinationId: destinationId,
            options: options,
            provider: provider,
            loggingServices: loggingServicesActor
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
        options: LoggingInterfaces.ArchiveLogsOptionsDTO
    ) throws -> ArchiveLogsCommand {
        guard let provider = defaultProvider() else {
            throw LoggingInterfaces.LoggingError.initialisationFailed("No default provider available")
        }
        
        return ArchiveLogsCommand(
            destinationId: destinationId,
            options: options,
            provider: provider,
            loggingServices: loggingServicesActor
        )
    }
    
    /**
     Creates a purge logs command.
     
     - Parameters:
        - destinationId: The ID of the destination to purge logs from (optional)
        - options: Options for purging logs
     - Returns: The created command
     - Throws: LoggingError if no provider is available
     */
    public func createPurgeLogsCommand(
        destinationId: String? = nil,
        options: LoggingInterfaces.PurgeLogsOptionsDTO = .default
    ) throws -> PurgeLogsCommand {
        guard let provider = defaultProvider() else {
            throw LoggingInterfaces.LoggingError.initialisationFailed("No default provider available")
        }
        
        return PurgeLogsCommand(
            destinationId: destinationId,
            options: options,
            provider: provider,
            loggingServices: loggingServicesActor
        )
    }
    
    // MARK: - Private Methods
    
    /**
     Gets a provider for a specific destination type.
     
     - Parameter destinationType: The destination type to get a provider for
     - Returns: The provider if available, nil otherwise
     */
    private func providerFor(destinationType: LoggingInterfaces.LogDestinationType) -> LoggingProviderProtocol? {
        return providers[destinationType]
    }
    
    /**
     Gets the default provider.
     
     - Returns: The default provider if available, nil otherwise
     */
    private func defaultProvider() -> LoggingProviderProtocol? {
        // Use file provider as default if available
        if let fileProvider = providers[.file] {
            return fileProvider
        }
        
        // Otherwise, use the first available provider
        return providers.first?.value
    }
    
    /**
     Gets a destination by ID.
     
     This delegates to the logging services actor to get the destination.
     
     - Parameter id: The ID of the destination to get
     - Returns: The destination if found, nil otherwise
     */
    private func getDestination(id: String) -> LoggingInterfaces.LogDestinationDTO? {
        // Since this is asynchronous, we can't directly call it from this method
        // Callers will need to handle this asynchronously
        return nil
    }
}
