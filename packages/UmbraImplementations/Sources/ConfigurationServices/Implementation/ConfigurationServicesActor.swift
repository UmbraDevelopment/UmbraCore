import Foundation
import ConfigurationInterfaces
import LoggingInterfaces
import SecurityInterfaces
import CoreDTOs

/**
 Actor implementation of the configuration service.
 
 This actor provides a thread-safe implementation of the ConfigurationServiceProtocol
 using the command pattern to handle all operations.
 */
public actor ConfigurationServicesActor: ConfigurationServiceProtocol {
    /// Factory for creating configuration commands
    private let commandFactory: ConfigCommandFactory
    
    /// Logger for configuration operations
    private let logger: PrivacyAwareLoggingProtocol
    
    /// Currently active configuration
    private var activeConfiguration: ConfigurationDTO?
    
    /// Subscribes to configuration changes
    private var observers: [UUID: ConfigObserver] = [:]
    
    /**
     Initialises a new configuration services actor.
     
     - Parameters:
        - commandFactory: Factory for creating configuration commands
        - logger: Logger for configuration operations
     */
    public init(
        commandFactory: ConfigCommandFactory,
        logger: PrivacyAwareLoggingProtocol
    ) {
        self.commandFactory = commandFactory
        self.logger = logger
    }
    
    /**
     Loads configuration from a source.
     
     - Parameters:
        - source: Source from which to load configuration
        - options: Options for loading configuration
     - Returns: The loaded configuration
     - Throws: ConfigurationError if loading fails
     */
    public func loadConfiguration(
        from source: ConfigSourceDTO,
        options: ConfigLoadOptionsDTO = .default
    ) async throws -> ConfigurationDTO {
        let context = LogContextDTO(
            operation: "loadConfiguration",
            category: "Configuration",
            metadata: LogMetadataDTOCollection()
                .withPublic(key: "sourceType", value: source.sourceType.rawValue)
                .withProtected(key: "location", value: source.location)
        )
        
        let command = try commandFactory.createLoadCommand(
            source: source,
            options: options
        )
        
        let configuration = try await command.execute(context: context)
        
        // Update active configuration if none exists
        if activeConfiguration == nil {
            activeConfiguration = configuration
        }
        
        return configuration
    }
    
    /**
     Validates a configuration against a schema or rules.
     
     - Parameters:
        - configuration: Configuration to validate
        - schema: Schema to validate against (optional)
     - Returns: The validation results
     - Throws: ConfigurationError if validation fails
     */
    public func validateConfiguration(
        configuration: ConfigurationDTO,
        schema: ConfigSchemaDTO?
    ) async throws -> ConfigValidationResultDTO {
        let context = LogContextDTO(
            operation: "validateConfiguration",
            category: "Configuration",
            metadata: LogMetadataDTOCollection()
                .withPublic(key: "configId", value: configuration.id)
                .withPublic(key: "hasSchema", value: String(schema != nil))
        )
        
        let command = try commandFactory.createValidateCommand(
            configuration: configuration,
            schema: schema
        )
        
        return try await command.execute(context: context)
    }
    
    /**
     Saves configuration to a destination.
     
     - Parameters:
        - configuration: Configuration to save
        - destination: Destination to save to
        - options: Options for saving
     - Returns: Whether saving was successful
     - Throws: ConfigurationError if saving fails
     */
    public func saveConfiguration(
        configuration: ConfigurationDTO,
        to destination: ConfigSourceDTO,
        options: ConfigSaveOptionsDTO = .default
    ) async throws -> Bool {
        let context = LogContextDTO(
            operation: "saveConfiguration",
            category: "Configuration",
            metadata: LogMetadataDTOCollection()
                .withPublic(key: "configId", value: configuration.id)
                .withPublic(key: "destinationType", value: destination.sourceType.rawValue)
                .withProtected(key: "location", value: destination.location)
        )
        
        let command = try commandFactory.createSaveCommand(
            configuration: configuration,
            destination: destination,
            options: options
        )
        
        let result = try await command.execute(context: context)
        
        return result.success
    }
    
    /**
     Updates values in a configuration.
     
     - Parameters:
        - configuration: Configuration to update
        - updates: Updates to apply
        - options: Options for updating
     - Returns: The updated configuration
     - Throws: ConfigurationError if updating fails
     */
    public func updateConfiguration(
        configuration: ConfigurationDTO,
        updates: [String: ConfigValueDTO],
        options: ConfigUpdateOptionsDTO = .default
    ) async throws -> ConfigurationDTO {
        let context = LogContextDTO(
            operation: "updateConfiguration",
            category: "Configuration",
            metadata: LogMetadataDTOCollection()
                .withPublic(key: "configId", value: configuration.id)
                .withPublic(key: "updateCount", value: String(updates.count))
        )
        
        let command = try commandFactory.createUpdateCommand(
            configuration: configuration,
            updates: updates,
            options: options
        )
        
        let updatedConfig = try await command.execute(context: context)
        
        // Update active configuration if this was the active one
        if activeConfiguration?.id == configuration.id {
            activeConfiguration = updatedConfig
            
            if options.notifyObservers {
                await notifyObservers(updatedConfig)
            }
        }
        
        return updatedConfig
    }
    
    /**
     Exports configuration to a specific format.
     
     - Parameters:
        - configuration: Configuration to export
        - format: Format to export to
        - options: Options for exporting
     - Returns: The exported configuration data
     - Throws: ConfigurationError if export fails
     */
    public func exportConfiguration(
        configuration: ConfigurationDTO,
        to format: ConfigFormatType,
        options: ConfigExportOptionsDTO = .default
    ) async throws -> Data {
        let context = LogContextDTO(
            operation: "exportConfiguration",
            category: "Configuration",
            metadata: LogMetadataDTOCollection()
                .withPublic(key: "configId", value: configuration.id)
                .withPublic(key: "exportFormat", value: format.rawValue)
        )
        
        let command = try commandFactory.createExportCommand(
            configuration: configuration,
            format: format,
            options: options
        )
        
        return try await command.execute(context: context)
    }
    
    /**
     Imports configuration from external data.
     
     - Parameters:
        - data: Data to import
        - format: Format of the data
        - options: Options for importing
     - Returns: The imported configuration
     - Throws: ConfigurationError if import fails
     */
    public func importConfiguration(
        from data: Data,
        format: ConfigFormatType,
        options: ConfigImportOptionsDTO = .default
    ) async throws -> ConfigurationDTO {
        let context = LogContextDTO(
            operation: "importConfiguration",
            category: "Configuration",
            metadata: LogMetadataDTOCollection()
                .withPublic(key: "dataSize", value: String(data.count))
                .withPublic(key: "importFormat", value: format.rawValue)
        )
        
        let command = try commandFactory.createImportCommand(
            data: data,
            format: format,
            options: options
        )
        
        let importedConfig = try await command.execute(context: context)
        
        // Set as active if requested
        if options.setActive {
            activeConfiguration = importedConfig
            
            if options.notifyObservers {
                await notifyObservers(importedConfig)
            }
        }
        
        return importedConfig
    }
    
    /**
     Gets the currently active configuration.
     
     - Returns: The active configuration
     - Throws: ConfigurationError.noActiveConfiguration if no active configuration
     */
    public func getActiveConfiguration() async throws -> ConfigurationDTO {
        guard let activeConfig = activeConfiguration else {
            throw ConfigurationError.noActiveConfiguration
        }
        
        return activeConfig
    }
    
    /**
     Sets a configuration as active.
     
     - Parameters:
        - configuration: Configuration to set as active
        - options: Options for activation
     - Returns: Whether activation was successful
     - Throws: ConfigurationError if activation fails
     */
    public func activateConfiguration(
        configuration: ConfigurationDTO,
        options: ConfigActivateOptionsDTO = .default
    ) async throws -> Bool {
        let context = LogContextDTO(
            operation: "activateConfiguration",
            category: "Configuration",
            metadata: LogMetadataDTOCollection()
                .withPublic(key: "configId", value: configuration.id)
        )
        
        let command = commandFactory.createActivateCommand(
            configuration: configuration,
            options: options
        )
        
        let result = try await command.execute(context: context)
        
        if result {
            activeConfiguration = configuration
            
            if options.notifyObservers {
                await notifyObservers(configuration)
            }
        }
        
        return result
    }
    
    /**
     Gets a specific value from the active configuration.
     
     - Parameters:
        - key: Key to retrieve
        - defaultValue: Default value if key doesn't exist
     - Returns: The configuration value or default value
     - Throws: ConfigurationError if no active configuration or key error
     */
    public func getValue<T>(
        forKey key: String,
        defaultValue: T? = nil
    ) async throws -> T {
        guard let activeConfig = activeConfiguration else {
            if let defaultValue = defaultValue {
                return defaultValue
            } else {
                throw ConfigurationError.noActiveConfiguration
            }
        }
        
        return try getValueFromConfig(activeConfig, forKey: key, defaultValue: defaultValue)
    }
    
    /**
     Sets a specific value in the active configuration.
     
     - Parameters:
        - value: Value to set
        - key: Key to set
        - saveChanges: Whether to save changes immediately
     - Returns: Whether the operation was successful
     - Throws: ConfigurationError if no active configuration or set error
     */
    public func setValue<T>(
        value: T,
        forKey key: String,
        saveChanges: Bool = false
    ) async throws -> Bool {
        guard var activeConfig = activeConfiguration else {
            throw ConfigurationError.noActiveConfiguration
        }
        
        let configValue = try convertToConfigValue(value)
        let updates = [key: configValue]
        
        let options = ConfigUpdateOptionsDTO(
            validateAfterUpdate: true,
            saveAfterUpdate: saveChanges,
            notifyObservers: true
        )
        
        let updatedConfig = try await updateConfiguration(
            configuration: activeConfig,
            updates: updates,
            options: options
        )
        
        activeConfiguration = updatedConfig
        return true
    }
    
    /**
     Registers an observer for configuration changes.
     
     - Parameters:
        - observer: Observer to notify of changes
     - Returns: Token for unregistering the observer
     */
    public func registerObserver(
        observer: @escaping (ConfigurationDTO) -> Void
    ) async -> ObserverToken {
        let id = UUID()
        observers[id] = ConfigObserver(callback: observer)
        return ObserverToken(id: id)
    }
    
    /**
     Unregisters an observer.
     
     - Parameters:
        - token: Token from registration
     - Returns: Whether unregistration was successful
     */
    public func unregisterObserver(token: ObserverToken) async -> Bool {
        guard observers[token.id] != nil else {
            return false
        }
        
        observers.removeValue(forKey: token.id)
        return true
    }
    
    // MARK: - Private Methods
    
    /**
     Notifies all registered observers of a configuration change.
     
     - Parameters:
        - configuration: The updated configuration
     */
    private func notifyObservers(_ configuration: ConfigurationDTO) async {
        for observer in observers.values {
            observer.callback(configuration)
        }
    }
    
    /**
     Gets a typed value from a configuration.
     
     - Parameters:
        - config: Configuration to retrieve from
        - key: Key to retrieve
        - defaultValue: Default value if key doesn't exist
     - Returns: The typed configuration value or default value
     - Throws: ConfigurationError if key not found or type mismatch
     */
    private func getValueFromConfig<T>(
        _ config: ConfigurationDTO,
        forKey key: String,
        defaultValue: T? = nil
    ) throws -> T {
        guard let configValue = config.values[key] else {
            if let defaultValue = defaultValue {
                return defaultValue
            } else {
                throw ConfigurationError.keyNotFound("Key not found in configuration: \(key)")
            }
        }
        
        // Handle different value types based on the expected return type
        return try convertConfigValue(configValue, to: T.self)
    }
    
    /**
     Converts a ConfigValueDTO to a specific type.
     
     - Parameters:
        - configValue: Configuration value to convert
        - type: Type to convert to
     - Returns: The converted value
     - Throws: ConfigurationError.typeMismatch if conversion fails
     */
    private func convertConfigValue<T>(
        _ configValue: ConfigValueDTO,
        to type: T.Type
    ) throws -> T {
        // Handle different types
        switch (configValue, type) {
        case (.string(let string), is String.Type),
             (.string(let string), is String?.Type):
            return string as! T
            
        case (.integer(let int), is Int.Type),
             (.integer(let int), is Int?.Type):
            return int as! T
            
        case (.integer(let int), is Double.Type),
             (.integer(let int), is Double?.Type):
            return Double(int) as! T
            
        case (.integer(let int), is Bool.Type),
             (.integer(let int), is Bool?.Type):
            return (int != 0) as! T
            
        case (.number(let double), is Double.Type),
             (.number(let double), is Double?.Type):
            return double as! T
            
        case (.number(let double), is Int.Type),
             (.number(let double), is Int?.Type):
            return Int(double) as! T
            
        case (.boolean(let bool), is Bool.Type),
             (.boolean(let bool), is Bool?.Type):
            return bool as! T
            
        case (.boolean(let bool), is Int.Type),
             (.boolean(let bool), is Int?.Type):
            return (bool ? 1 : 0) as! T
            
        case (.array(let array), is [Any].Type),
             (.array(let array), is [Any]?.Type):
            return array as! T
            
        case (.dictionary(let dict), is [String: Any].Type),
             (.dictionary(let dict), is [String: Any]?.Type):
            return dict as! T
            
        default:
            throw ConfigurationError.typeMismatch(
                "Cannot convert configuration value to type: \(String(describing: type))"
            )
        }
    }
    
    /**
     Converts a value to a ConfigValueDTO.
     
     - Parameters:
        - value: Value to convert
     - Returns: The config value representation
     - Throws: ConfigurationError.typeMismatch if conversion fails
     */
    private func convertToConfigValue<T>(_ value: T) throws -> ConfigValueDTO {
        switch value {
        case let stringValue as String:
            return .string(stringValue)
            
        case let intValue as Int:
            return .integer(intValue)
            
        case let doubleValue as Double:
            return .number(doubleValue)
            
        case let boolValue as Bool:
            return .boolean(boolValue)
            
        case let dateValue as Date:
            let formatter = ISO8601DateFormatter()
            return .string(formatter.string(from: dateValue))
            
        case let arrayValue as [ConfigValueDTO]:
            return .array(arrayValue)
            
        case let dictValue as [String: ConfigValueDTO]:
            return .dictionary(dictValue)
            
        default:
            throw ConfigurationError.typeMismatch(
                "Cannot convert value of type \(type(of: value)) to ConfigValueDTO"
            )
        }
    }
}

/**
 Observer for configuration changes.
 */
private struct ConfigObserver {
    /// Callback to invoke when configuration changes
    let callback: (ConfigurationDTO) -> Void
}
