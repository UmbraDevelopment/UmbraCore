import Foundation
import ConfigurationInterfaces
import LoggingInterfaces
import LoggingTypes
import CoreDTOs

/**
 Command for updating values in a configuration.
 
 This command encapsulates the logic for applying updates to configuration data,
 following the command pattern architecture.
 */
public class UpdateConfigurationCommand: BaseConfigCommand, ConfigCommand {
    /// The result type for this command
    public typealias ResultType = ConfigurationDTO
    
    /// Configuration to update
    private let configuration: ConfigurationDTO
    
    /// Updates to apply
    private let updates: [String: ConfigValueDTO]
    
    /// Options for updating
    private let options: ConfigUpdateOptionsDTO
    
    /**
     Initialises a new update configuration command.
     
     - Parameters:
        - configuration: Configuration to update
        - updates: Updates to apply
        - options: Options for updating
        - provider: Provider for configuration operations
        - logger: Logger instance for configuration operations
     */
    public init(
        configuration: ConfigurationDTO,
        updates: [String: ConfigValueDTO],
        options: ConfigUpdateOptionsDTO,
        provider: ConfigurationProviderProtocol,
        logger: PrivacyAwareLoggingProtocol
    ) {
        self.configuration = configuration
        self.updates = updates
        self.options = options
        
        super.init(provider: provider, logger: logger)
    }
    
    /**
     Executes the update configuration command.
     
     - Parameters:
        - context: The logging context for the operation
     - Returns: The updated configuration
     - Throws: ConfigurationError if updating fails
     */
    public func execute(context: LogContextDTO) async throws -> ConfigurationDTO {
        // Create a log context for this specific operation
        let operationContext = createLogContext(
            operation: "updateConfiguration",
            configId: configuration.id,
            additionalMetadata: [
                "configName": (value: configuration.name, privacyLevel: .public),
                "updateCount": (value: String(updates.count), privacyLevel: .public),
                "saveAfterUpdate": (value: String(options.saveAfterUpdate), privacyLevel: .public),
                "validateAfterUpdate": (value: String(options.validateAfterUpdate), privacyLevel: .public),
                "trackHistory": (value: String(options.trackHistory), privacyLevel: .public)
            ]
        )
        
        // Log operation start
        await logOperationStart(operation: "updateConfiguration", context: operationContext)
        
        do {
            // Apply updates to the configuration
            let updatedConfig = applyUpdates(context: operationContext)
            
            // Validate if requested
            if options.validateAfterUpdate {
                await logger.log(
                    .debug,
                    "Validating configuration after update",
                    context: operationContext
                )
                
                let validateCommand = ValidateConfigurationCommand(
                    configuration: updatedConfig,
                    schema: nil, // No schema validation at this stage
                    provider: provider,
                    logger: logger
                )
                
                let validationResult = try await validateCommand.execute(context: operationContext)
                
                if !validationResult.isValid {
                    throw ConfigurationError.validationFailed(
                        "Post-update validation failed with \(validationResult.issues.count) issues"
                    )
                }
            }
            
            // Save if requested
            if options.saveAfterUpdate {
                let destination = options.saveDestination ?? destination(for: updatedConfig)
                
                await logger.log(
                    .debug,
                    "Saving configuration after update",
                    context: operationContext.withMetadata(
                        LogMetadataDTOCollection().withProtected(
                            key: "saveDestination",
                            value: destination.location
                        )
                    )
                )
                
                let saveCommand = SaveConfigurationCommand(
                    configuration: updatedConfig,
                    destination: destination,
                    options: ConfigSaveOptionsDTO.default,
                    provider: provider,
                    logger: logger
                )
                
                _ = try await saveCommand.execute(context: operationContext)
            }
            
            // Track update history if requested
            if options.trackHistory {
                await trackUpdateHistory(for: updatedConfig, context: operationContext)
            }
            
            // Notify observers if requested
            if options.notifyObservers {
                await notifyObservers(for: updatedConfig, context: operationContext)
            }
            
            // Update active configuration if this is the active one
            if let activeConfig = getActiveConfiguration(), activeConfig.id == configuration.id {
                setActiveConfiguration(updatedConfig)
            }
            
            // Log success
            await logOperationSuccess(
                operation: "updateConfiguration",
                context: operationContext,
                additionalMetadata: [
                    "configVersion": (value: updatedConfig.version, privacyLevel: .public),
                    "updatedAt": (value: "\(updatedConfig.updatedAt)", privacyLevel: .public)
                ]
            )
            
            return updatedConfig
            
        } catch let error as ConfigurationError {
            // Log failure
            await logOperationFailure(
                operation: "updateConfiguration",
                error: error,
                context: operationContext
            )
            
            throw error
            
        } catch {
            // Map unknown error to ConfigurationError
            let configError = ConfigurationError.general(error.localizedDescription)
            
            // Log failure
            await logOperationFailure(
                operation: "updateConfiguration",
                error: configError,
                context: operationContext
            )
            
            throw configError
        }
    }
    
    // MARK: - Private Methods
    
    /**
     Applies updates to the configuration.
     
     - Parameters:
        - context: The logging context for the operation
     - Returns: The updated configuration
     */
    private func applyUpdates(context: LogContextDTO) -> ConfigurationDTO {
        var updatedValues = configuration.values
        
        // Track keys that are being updated for logging
        var updatedKeys: [String] = []
        
        // Apply each update
        for (key, value) in updates {
            updatedValues[key] = value
            updatedKeys.append(key)
        }
        
        // Update metadata
        var updatedMetadata = configuration.metadata
        updatedMetadata["lastUpdated"] = ISO8601DateFormatter().string(from: Date())
        updatedMetadata["updatedKeys"] = updatedKeys.joined(separator: ",")
        
        // Create updated configuration
        return ConfigurationDTO(
            id: configuration.id,
            name: configuration.name,
            version: configuration.version,
            environment: configuration.environment,
            createdAt: configuration.createdAt,
            updatedAt: Date(), // Update timestamp
            values: updatedValues,
            metadata: updatedMetadata
        )
    }
    
    /**
     Determines the appropriate destination for saving a configuration.
     
     - Parameters:
        - config: The configuration to save
     - Returns: The destination to save to
     */
    private func destination(for config: ConfigurationDTO) -> ConfigSourceDTO {
        // Use the original source if we have one
        if let sourceMetadata = config.metadata["sourceLocation"],
           let sourceTypeString = config.metadata["sourceType"],
           let sourceFormatString = config.metadata["sourceFormat"],
           let sourceType = ConfigSourceType(rawValue: sourceTypeString),
           let sourceFormat = ConfigFormatType(rawValue: sourceFormatString) {
            
            return ConfigSourceDTO(
                sourceType: sourceType,
                format: sourceFormat,
                location: sourceMetadata
            )
        }
        
        // Default to a file source with JSON format in a standard location
        let fileName = "\(config.name.lowercased().replacingOccurrences(of: " ", with: "_"))_\(config.environment).json"
        let homeDir = FileManager.default.homeDirectoryForCurrentUser.path
        let configDir = "\(homeDir)/.config/umbra"
        
        return ConfigSourceDTO(
            sourceType: .file,
            format: .json,
            location: "\(configDir)/\(fileName)"
        )
    }
    
    /**
     Tracks update history for a configuration.
     
     - Parameters:
        - config: The updated configuration
        - context: The logging context for the operation
     */
    private func trackUpdateHistory(for config: ConfigurationDTO, context: LogContextDTO) async {
        // In a real implementation, this would store history in a database or log
        // For now, we'll just log the update
        
        let updateInfo = """
        Configuration update:
        - ID: \(config.id)
        - Name: \(config.name)
        - Version: \(config.version)
        - Updated Keys: \(config.metadata["updatedKeys"] ?? "unknown")
        - Timestamp: \(ISO8601DateFormatter().string(from: config.updatedAt))
        """
        
        await logger.log(
            .info,
            "Tracked configuration update history",
            context: context.withMetadata(
                LogMetadataDTOCollection().withProtected(
                    key: "updateHistory",
                    value: updateInfo
                )
            )
        )
    }
    
    /**
     Notifies observers of configuration changes.
     
     - Parameters:
        - config: The updated configuration
        - context: The logging context for the operation
     */
    private func notifyObservers(for config: ConfigurationDTO, context: LogContextDTO) async {
        // In a real implementation, this would notify registered observers
        // For now, we'll just log the notification
        
        await logger.log(
            .info,
            "Configuration update notification: \(config.id) updated",
            context: context
        )
    }
}
