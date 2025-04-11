import Foundation
import ConfigurationInterfaces
import LoggingInterfaces
import SecurityInterfaces

/**
 Factory for creating configuration commands.
 
 This class centralises the creation of configuration commands,
 ensuring consistent initialization and dependencies.
 */
public class ConfigCommandFactory {
    /// Logger instance for configuration operations
    private let logger: PrivacyAwareLoggingProtocol
    
    /// Map of providers by source type
    private let providers: [ConfigSourceType: ConfigurationProviderProtocol]
    
    /// Security service for crypto operations
    private let securityService: CryptoServiceProtocol?
    
    /**
     Initialises a new configuration command factory.
     
     - Parameters:
        - providers: Map of providers by source type
        - logger: Logger instance for configuration operations
        - securityService: Optional security service for crypto operations
     */
    public init(
        providers: [ConfigSourceType: ConfigurationProviderProtocol],
        logger: PrivacyAwareLoggingProtocol,
        securityService: CryptoServiceProtocol? = nil
    ) {
        self.providers = providers
        self.logger = logger
        self.securityService = securityService
    }
    
    /**
     Creates a load configuration command.
     
     - Parameters:
        - source: Source from which to load configuration
        - options: Options for loading configuration
     - Returns: The created command
     - Throws: ConfigurationError if no provider is available for the source type
     */
    public func createLoadCommand(
        source: ConfigSourceDTO,
        options: ConfigLoadOptionsDTO = .default
    ) throws -> LoadConfigurationCommand {
        guard let provider = providerFor(sourceType: source.sourceType) else {
            throw ConfigurationError.sourceNotFound(
                "No provider available for source type: \(source.sourceType.rawValue)"
            )
        }
        
        return LoadConfigurationCommand(
            source: source,
            options: options,
            provider: provider,
            logger: logger
        )
    }
    
    /**
     Creates a validate configuration command.
     
     - Parameters:
        - configuration: Configuration to validate
        - schema: Schema to validate against (optional)
     - Returns: The created command
     - Throws: ConfigurationError if no provider is available
     */
    public func createValidateCommand(
        configuration: ConfigurationDTO,
        schema: ConfigSchemaDTO?
    ) throws -> ValidateConfigurationCommand {
        // Use default provider for validation
        guard let provider = defaultProvider() else {
            throw ConfigurationError.general("No default provider available")
        }
        
        return ValidateConfigurationCommand(
            configuration: configuration,
            schema: schema,
            provider: provider,
            logger: logger
        )
    }
    
    /**
     Creates a save configuration command.
     
     - Parameters:
        - configuration: Configuration to save
        - destination: Destination to save to
        - options: Options for saving
     - Returns: The created command
     - Throws: ConfigurationError if no provider is available for the destination type
     */
    public func createSaveCommand(
        configuration: ConfigurationDTO,
        destination: ConfigSourceDTO,
        options: ConfigSaveOptionsDTO = .default
    ) throws -> SaveConfigurationCommand {
        guard let provider = providerFor(sourceType: destination.sourceType) else {
            throw ConfigurationError.sourceNotFound(
                "No provider available for destination type: \(destination.sourceType.rawValue)"
            )
        }
        
        return SaveConfigurationCommand(
            configuration: configuration,
            destination: destination,
            options: options,
            provider: provider,
            logger: logger,
            securityService: securityService
        )
    }
    
    /**
     Creates an update configuration command.
     
     - Parameters:
        - configuration: Configuration to update
        - updates: Updates to apply
        - options: Options for updating
     - Returns: The created command
     - Throws: ConfigurationError if no provider is available
     */
    public func createUpdateCommand(
        configuration: ConfigurationDTO,
        updates: [String: ConfigValueDTO],
        options: ConfigUpdateOptionsDTO = .default
    ) throws -> UpdateConfigurationCommand {
        // Use default provider for updates
        guard let provider = defaultProvider() else {
            throw ConfigurationError.general("No default provider available")
        }
        
        return UpdateConfigurationCommand(
            configuration: configuration,
            updates: updates,
            options: options,
            provider: provider,
            logger: logger
        )
    }
    
    /**
     Creates an export configuration command.
     
     - Parameters:
        - configuration: Configuration to export
        - format: Format to export to
        - options: Options for exporting
     - Returns: The created command
     - Throws: ConfigurationError if no provider is available
     */
    public func createExportCommand(
        configuration: ConfigurationDTO,
        format: ConfigFormatType,
        options: ConfigExportOptionsDTO = .default
    ) throws -> ExportConfigurationCommand {
        // Use default provider for exports
        guard let provider = defaultProvider() else {
            throw ConfigurationError.general("No default provider available")
        }
        
        return ExportConfigurationCommand(
            configuration: configuration,
            format: format,
            options: options,
            provider: provider,
            logger: logger,
            securityService: securityService
        )
    }
    
    /**
     Creates an import configuration command.
     
     - Parameters:
        - data: Data to import
        - format: Format of the data
        - options: Options for importing
     - Returns: The created command
     - Throws: ConfigurationError if no provider is available
     */
    public func createImportCommand(
        data: Data,
        format: ConfigFormatType,
        options: ConfigImportOptionsDTO = .default
    ) throws -> ImportConfigurationCommand {
        // Use default provider for imports
        guard let provider = defaultProvider() else {
            throw ConfigurationError.general("No default provider available")
        }
        
        return ImportConfigurationCommand(
            data: data,
            format: format,
            options: options,
            provider: provider,
            logger: logger
        )
    }
    
    /**
     Creates an activate configuration command.
     
     - Parameters:
        - configuration: Configuration to activate
        - options: Options for activation
     - Returns: The created command
     */
    public func createActivateCommand(
        configuration: ConfigurationDTO,
        options: ConfigActivateOptionsDTO = .default
    ) -> ActivateConfigurationCommand {
        // This command doesn't require a specific provider
        // Use the default provider as a fallback
        let provider = defaultProvider() ?? providers.values.first!
        
        return ActivateConfigurationCommand(
            configuration: configuration,
            options: options,
            provider: provider,
            logger: logger
        )
    }
    
    // MARK: - Private Methods
    
    /**
     Gets a provider for a specific source type.
     
     - Parameters:
        - sourceType: The source type to get a provider for
     - Returns: A provider for the source type, or nil if none is available
     */
    private func providerFor(sourceType: ConfigSourceType) -> ConfigurationProviderProtocol? {
        return providers[sourceType]
    }
    
    /**
     Gets the default provider.
     
     - Returns: The default provider, or nil if none is available
     */
    private func defaultProvider() -> ConfigurationProviderProtocol? {
        // Prefer file provider, then memory provider, then any available provider
        return providers[.file] ?? providers[.memory] ?? providers.values.first
    }
}
