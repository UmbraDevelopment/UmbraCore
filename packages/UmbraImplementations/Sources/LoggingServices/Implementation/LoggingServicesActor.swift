import Foundation
import LoggingInterfaces
import LoggingTypes
import SchedulingTypes

/**
 Primary implementation of the logging services actor.
 
 This actor provides a thread-safe implementation of the PrivacyAwareLoggingProtocol
 using the command pattern to handle all operations.
 */
public actor LoggingServicesActor: PrivacyAwareLoggingProtocol {
    /// Factory for creating logging commands
    private let commandFactory: LogCommandFactory
    
    /// The configured log providers, keyed by destination type
    private let providers: [LogDestinationType: LoggingProviderProtocol]
    
    /// The logging actor required by LoggingProtocol
    public nonisolated var loggingActor: LoggingActor {
        return .init(destinations: [])
    }
    
    /// Default log destinations when none are specified
    private var defaultDestinationIds: [String] = []
    
    /// Current minimum log level
    private var minimumLogLevel: LogLevel = .info
    
    /// Active log destinations by ID
    private var activeDestinations: [String: LogDestinationDTO] = [:]
    
    /**
     Initializes a new logging services actor.
     
     - Parameters:
        - providers: Provider implementations by destination type
        - commandFactory: Optional command factory to use
     */
    public init(
        providers: [LogDestinationType: LoggingProviderProtocol] = [:],
        commandFactory: LogCommandFactory? = nil
    ) {
        self.providers = providers
        
        // Create a dummy logger to bootstrap the command factory
        let bootstrapLogger = self
        
        // Initialize the command factory with the bootstrap logger
        self.commandFactory = commandFactory ?? LogCommandFactory(
            providers: providers,
            logger: bootstrapLogger
        )
    }
    
    // MARK: - PrivacyAwareLoggingProtocol Methods
    
    /**
     Logs a message with standard privacy controls.
     
     - Parameters:
        - level: The log level
        - message: The message to log
        - context: The logging context
     */
    public func log(
        _ level: LogLevel,
        _ message: String,
        context: any LogContextDTO
    ) async {
        // Skip if below minimum level
        if level.rawValue < minimumLogLevel.rawValue {
            return
        }
        
        // Create a log entry with the provided information
        let entry = LogEntryDTO(
            level: level,
            message: message,
            category: context.category,
            metadata: context.metadata,
            source: context.source ?? ""
        )
        
        // Log to all active destinations
        for (_, destination) in activeDestinations {
            if destination.isEnabled && level.rawValue >= destination.minimumLevel.rawValue {
                // Get provider for this destination type
                if let provider = providers[destination.type] {
                    do {
                        // Write log entry to destination
                        _ = try await provider.writeLogEntry(entry, to: destination)
                    } catch {
                        // Silently ignore provider errors for now
                        // In a real implementation, we'd want to handle these more gracefully
                        print("Error writing log entry: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
    /**
     Logs a message with privacy annotations.
     
     - Parameters:
        - level: The log level
        - message: The privacy-annotated message
        - context: The logging context
     */
    public func log(
        _ level: LogLevel,
        _ message: PrivacyString,
        context: LogContextDTO
    ) async {
        // Create a new context with privacy metadata
        var enrichedMetadata = context.metadata
        
        // Add privacy annotations
        enrichedMetadata = enrichedMetadata.withPrivate(
            key: "__privacy_annotation", 
            value: message.privacy.description
        )
        
        // Create updated context with privacy information
        let privacyContext = BaseLogContextDTO(
            domainName: context.domainName,
            operation: context.operation,
            category: context.category,
            source: context.source,
            metadata: enrichedMetadata,
            correlationID: context.correlationID
        )
        
        // Log the message using the standard log method
        await log(level, message.content, context: privacyContext)
    }
    
    /**
     Logs a message with string value.
     
     - Parameters:
        - level: The log level
        - message: The message string
        - context: The logging context
     */
    public func log(_ level: LogLevel, _ message: String, context: any LogContextDTO) async {
        // Convert to privacy string and use privacy-aware logging
        let privacyString = PrivacyString(stringLiteral: message)
        await log(level, privacyString, context: context)
    }
    
    /**
     Logs a message with privacy annotations function.
     
     - Parameters:
        - level: The log level
        - privacyScope: Function that returns a privacy-annotated string
        - context: The logging context
     */
    public func logPrivacy(
        _ level: LogLevel,
        _ privacyScope: () -> PrivacyAnnotatedString,
        context: any LogContextDTO
    ) async {
        let annotatedString = privacyScope()
        await log(level, PrivacyString(stringLiteral: annotatedString.stringValue), context: context) 
    }
    
    /**
     Logs sensitive values with proper privacy handling.
     
     - Parameters:
        - level: The log level
        - message: The log message
        - sensitiveValues: Privacy-sensitive metadata
        - context: The logging context
     */
    public func logSensitive(
        _ level: LogLevel,
        _ message: String,
        sensitiveValues: LoggingTypes.LogMetadata,
        context: any LogContextDTO
    ) async {
        // Create a privacy string for the message
        let privacyString = PrivacyString(stringLiteral: message)
        
        // Create a metadata collection with sensitive values
        var metadataCollection = context.metadata
        for (key, value) in sensitiveValues {
            metadataCollection = metadataCollection.withSensitive(key: key, value: String(describing: value))
        }
        
        // Create a new context with the updated metadata
        let sensitiveContext = BaseLogContextDTO(
            domainName: context.domainName,
            operation: context.operation,
            category: context.category,
            source: context.source,
            metadata: metadataCollection,
            correlationID: context.correlationID
        )
        
        // Log the message with the updated context
        await log(level, privacyString, context: sensitiveContext)
    }
    
    /**
     Logs an error with appropriate privacy handling.
     
     - Parameters:
        - error: The error to log
        - privacyLevel: The privacy level to use
        - context: The logging context
     */
    public func logError(
        _ error: Error,
        privacyLevel: LogPrivacyLevel,
        context: any LogContextDTO
    ) async {
        // Create privacy string from error
        let errorMessage = PrivacyString(stringLiteral: "Error: \(error.localizedDescription)")
        
        // Add error to metadata
        var metadataCollection = context.metadata
        
        // Add error information to metadata with appropriate privacy level
        switch privacyLevel {
        case .public:
            metadataCollection = metadataCollection.withPublic(key: "error_description", value: error.localizedDescription)
        case .private:
            metadataCollection = metadataCollection.withPrivate(key: "error_description", value: error.localizedDescription)
        case .sensitive:
            metadataCollection = metadataCollection.withSensitive(key: "error_description", value: error.localizedDescription)
        case .hash:
            metadataCollection = metadataCollection.withHashed(key: "error_description", value: error.localizedDescription)
        }
        
        // Create new context with error metadata
        let errorContext = BaseLogContextDTO(
            domainName: context.domainName,
            operation: context.operation,
            category: context.category,
            source: context.source,
            metadata: metadataCollection,
            correlationID: context.correlationID
        )
        
        // Log error
        await log(.error, errorMessage, context: errorContext)
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
        // Simple implementation during refactoring
        activeDestinations[destination.id] = destination
        
        // Add to default destinations if this is the first one
        if defaultDestinationIds.isEmpty {
            defaultDestinationIds.append(destination.id)
        }
        
        return true
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
        activeDestinations.removeValue(forKey: destinationId)
        defaultDestinationIds.removeAll { $0 == destinationId }
        return true
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
     Writes a log entry to specific destinations.
     
     - Parameters:
        - entry: The log entry to write
        - destinationIds: The destination IDs to write to
     - Returns: The results of the write operations
     - Throws: LoggingError if an error occurs
     */
    public func writeLogEntry(
        entry: LogEntryDTO,
        destinationIds: [String]
    ) async throws -> [LogWriteResultDTO] {
        var results: [LogWriteResultDTO] = []
        
        for destinationId in destinationIds {
            // Simply record success for each destination during refactoring
            let result = LogWriteResultDTO.success(destinationId: destinationId)
            results.append(result)
        }
        
        return results
    }
}

/// Implementation of a logging actor for bootstrap purposes
/// Provides a minimal implementation to satisfy protocol requirements
public actor DummyLoggingActor: LoggingActorProtocol {
    /// The minimum log level for this actor
    private var minimumLogLevel: UmbraLogLevel = .info
    
    /// The destinations for this actor
    private var destinations: [any ActorLogDestination] = []
    
    /// Initialize with no destinations
    public init(destinations: [any ActorLogDestination] = [], minimumLogLevel: UmbraLogLevel = .info) {
        self.minimumLogLevel = minimumLogLevel
        self.destinations = destinations
    }
    
    /// Simple log method that just prints to console
    public func log(_ level: UmbraLogLevel, _ message: String, metadata: LogMetadataDTOCollection, source: String?) async {
        // Print to console during bootstrap
        print("[\(level.rawValue)] \(message)")
    }
}
