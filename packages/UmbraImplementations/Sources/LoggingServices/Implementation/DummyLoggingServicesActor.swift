import Foundation
import LoggingTypes
import LoggingInterfaces

/**
 A dummy implementation of LoggingServicesProtocol used only for initialization.
 
 This actor provides no-op implementations of all required methods to avoid
 circular references during the initialization of the real LoggingServicesActor.
 */
public actor DummyLoggingServicesActor: PrivacyAwareLoggingProtocol {
    /// Provider dictionary for logging operations
    private var providers: [LogDestinationType: LoggingProviderProtocol]
    
    /// Logging actor for this service
    public nonisolated var loggingActor: LoggingActor {
        return LoggingActor(destinations: [])
    }
    
    /**
     Initialises a new dummy logging services actor.
     */
    public init(
        providers: [LogDestinationType: LoggingProviderProtocol] = [:]
    ) {
        self.providers = providers
    }
    
    /**
     No-op implementation for log method.
     */
    public func log(
        _ level: LogLevel,
        _ message: PrivacyString,
        context: LogContextDTO
    ) async {
        // No-op implementation
    }
    
    /**
     No-op implementation for log method with string.
     */
    public func logString(
        _ level: LogLevel,
        _ message: String,
        context: LogContextDTO
    ) async {
        // No-op implementation
    }
    
    /**
     No-op implementation for logging sensitive data.
     */
    public func logSensitive(
        _ level: LogLevel,
        _ message: String,
        sensitiveValues: LoggingTypes.LogMetadata,
        context: LogContextDTO
    ) async {
        // No-op implementation
    }
    
    /**
     No-op implementation for logging errors.
     */
    public func logError(
        _ error: Error,
        privacyLevel: LogPrivacyLevel,
        context: LogContextDTO
    ) async {
        // No-op implementation
    }
    
    /**
     No-op implementation for log method for LoggingProtocol conformance.
     */
    public func log(
        _ level: LogLevel,
        _ message: String,
        context: LogContextDTO
    ) async {
        // No-op implementation
    }
    
    // Stub implementation of validateDestination for LoggingServicesProtocol conformance
    public func validateDestination(
        _ destination: LoggingInterfaces.LogDestinationDTO,
        for provider: LoggingInterfaces.LoggingProviderProtocol
    ) async -> LoggingInterfaces.LogDestinationValidationResultDTO {
        return LogDestinationValidationResultDTO(
            isValid: true,
            errors: [],
            validationMessages: []
        )
    }
}
