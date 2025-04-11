import Foundation
import ConfigurationInterfaces
import LoggingInterfaces
import LoggingTypes
import CoreDTOs

/**
 Command for activating a configuration.
 
 This command encapsulates the logic for setting a configuration as active,
 following the command pattern architecture.
 */
public class ActivateConfigurationCommand: BaseConfigCommand, ConfigCommand {
    /// The result type for this command
    public typealias ResultType = Bool
    
    /// Configuration to activate
    private let configuration: ConfigurationDTO
    
    /// Options for activation
    private let options: ConfigActivateOptionsDTO
    
    /**
     Initialises a new activate configuration command.
     
     - Parameters:
        - configuration: Configuration to activate
        - options: Options for activation
        - provider: Provider for configuration operations
        - logger: Logger instance for configuration operations
     */
    public init(
        configuration: ConfigurationDTO,
        options: ConfigActivateOptionsDTO,
        provider: ConfigurationProviderProtocol,
        logger: PrivacyAwareLoggingProtocol
    ) {
        self.configuration = configuration
        self.options = options
        
        super.init(provider: provider, logger: logger)
    }
    
    /**
     Executes the activate configuration command.
     
     - Parameters:
        - context: The logging context for the operation
     - Returns: Whether activation was successful
     - Throws: ConfigurationError if activation fails
     */
    public func execute(context: LogContextDTO) async throws -> Bool {
        // Create a log context for this specific operation
        let operationContext = createLogContext(
            operation: "activateConfiguration",
            configId: configuration.id,
            additionalMetadata: [
                "configName": (value: configuration.name, privacyLevel: .public),
                "configVersion": (value: configuration.version, privacyLevel: .public),
                "environment": (value: configuration.environment, privacyLevel: .public),
                "validateBeforeActivating": (value: String(options.validateBeforeActivating), privacyLevel: .public),
                "notifyObservers": (value: String(options.notifyObservers), privacyLevel: .public),
                "saveActiveConfiguration": (value: String(options.saveActiveConfiguration), privacyLevel: .public)
            ]
        )
        
        // Log operation start
        await logOperationStart(operation: "activateConfiguration", context: operationContext)
        
        do {
            // Validate if requested
            if options.validateBeforeActivating {
                await logger.log(
                    .debug,
                    "Validating configuration before activating",
                    context: operationContext
                )
                
                let validateCommand = ValidateConfigurationCommand(
                    configuration: configuration,
                    schema: nil, // No schema validation at this stage
                    provider: provider,
                    logger: logger
                )
                
                let validationResult = try await validateCommand.execute(context: operationContext)
                
                if !validationResult.isValid {
                    throw ConfigurationError.validationFailed(
                        "Pre-activation validation failed with \(validationResult.issues.count) issues"
                    )
                }
            }
            
            // Set as active configuration
            let previousActiveId = getActiveConfiguration()?.id
            setActiveConfiguration(configuration)
            
            // Save active configuration if requested
            if options.saveActiveConfiguration, let destination = options.saveDestination {
                await logger.log(
                    .debug,
                    "Saving active configuration",
                    context: operationContext.withMetadata(
                        LogMetadataDTOCollection().withProtected(
                            key: "saveDestination",
                            value: destination.location
                        )
                    )
                )
                
                let saveCommand = SaveConfigurationCommand(
                    configuration: configuration,
                    destination: destination,
                    options: ConfigSaveOptionsDTO.default,
                    provider: provider,
                    logger: logger
                )
                
                _ = try await saveCommand.execute(context: operationContext)
            }
            
            // Notify observers if requested
            if options.notifyObservers {
                await notifyObservers(previousActiveId: previousActiveId, context: operationContext)
            }
            
            // Log success
            await logOperationSuccess(
                operation: "activateConfiguration",
                context: operationContext,
                additionalMetadata: [
                    "previousActiveId": (value: previousActiveId ?? "none", privacyLevel: .public)
                ]
            )
            
            return true
            
        } catch let error as ConfigurationError {
            // Log failure
            await logOperationFailure(
                operation: "activateConfiguration",
                error: error,
                context: operationContext
            )
            
            throw error
            
        } catch {
            // Map unknown error to ConfigurationError
            let configError = ConfigurationError.general(error.localizedDescription)
            
            // Log failure
            await logOperationFailure(
                operation: "activateConfiguration",
                error: configError,
                context: operationContext
            )
            
            throw configError
        }
    }
    
    // MARK: - Private Methods
    
    /**
     Notifies observers of configuration activation.
     
     - Parameters:
        - previousActiveId: ID of the previously active configuration
        - context: The logging context for the operation
     */
    private func notifyObservers(previousActiveId: String?, context: LogContextDTO) async {
        // In a real implementation, this would notify registered observers
        // For now, we'll just log the notification
        
        let message = previousActiveId != nil ?
            "Configuration activation: Changed from \(previousActiveId!) to \(configuration.id)" :
            "Configuration activation: Set \(configuration.id) as active"
        
        await logger.log(
            .info,
            message,
            context: context
        )
    }
}
