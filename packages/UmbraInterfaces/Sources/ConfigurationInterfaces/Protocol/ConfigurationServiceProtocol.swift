import Foundation
import CoreDTOs

/**
 Protocol defining the configuration service operations.
 
 This protocol provides a comprehensive interface for all configuration
 operations, supporting different sources and formats.
 */
public protocol ConfigurationServiceProtocol {
    /**
     Loads configuration from a specific source.
     
     - Parameters:
        - source: The source from which to load the configuration
        - options: Additional options for loading
     - Returns: The loaded configuration
     - Throws: ConfigurationError if loading fails
     */
    func loadConfiguration(
        from source: ConfigSourceDTO,
        options: ConfigLoadOptionsDTO
    ) async throws -> ConfigurationDTO
    
    /**
     Validates a configuration against a schema or rules.
     
     - Parameters:
        - configuration: The configuration to validate
        - schema: Optional schema to validate against
     - Returns: Validation results indicating any issues
     - Throws: ConfigurationError if validation fails
     */
    func validateConfiguration(
        configuration: ConfigurationDTO,
        schema: ConfigSchemaDTO?
    ) async throws -> ConfigValidationResultDTO
    
    /**
     Saves configuration to a specific destination.
     
     - Parameters:
        - configuration: The configuration to save
        - destination: Where to save the configuration
        - options: Additional options for saving
     - Returns: Success indicator with metadata
     - Throws: ConfigurationError if saving fails
     */
    func saveConfiguration(
        configuration: ConfigurationDTO,
        to destination: ConfigSourceDTO,
        options: ConfigSaveOptionsDTO
    ) async throws -> ConfigSaveResultDTO
    
    /**
     Updates specific values in the active configuration.
     
     - Parameters:
        - updates: The configuration values to update
        - options: Options for how to apply the updates
     - Returns: The updated configuration
     - Throws: ConfigurationError if update fails
     */
    func updateConfiguration(
        updates: [String: ConfigValueDTO],
        options: ConfigUpdateOptionsDTO
    ) async throws -> ConfigurationDTO
    
    /**
     Gets a specific configuration value by path.
     
     - Parameters:
        - path: The dot-notation path to the configuration value
        - defaultValue: Optional default value if path not found
     - Returns: The configuration value if found
     - Throws: ConfigurationError.keyNotFound if path doesn't exist and no default is provided
     */
    func getConfigValue<T>(
        at path: String,
        defaultValue: T?
    ) async throws -> T
    
    /**
     Exports configuration to a specific format.
     
     - Parameters:
        - format: The format to export to (JSON, YAML, PLIST, etc.)
        - options: Additional export options
     - Returns: The exported configuration data
     - Throws: ConfigurationError if export fails
     */
    func exportConfiguration(
        to format: ConfigFormatType,
        options: ConfigExportOptionsDTO
    ) async throws -> Data
    
    /**
     Imports configuration from external data.
     
     - Parameters:
        - data: The configuration data to import
        - format: The format of the data (JSON, YAML, PLIST, etc.)
        - options: Additional import options
     - Returns: The imported configuration
     - Throws: ConfigurationError if import fails
     */
    func importConfiguration(
        from data: Data,
        format: ConfigFormatType,
        options: ConfigImportOptionsDTO
    ) async throws -> ConfigurationDTO
    
    /**
     Gets the current active configuration.
     
     - Returns: The current active configuration
     - Throws: ConfigurationError if no active configuration exists
     */
    func getActiveConfiguration() async throws -> ConfigurationDTO
    
    /**
     Sets the active configuration.
     
     - Parameters:
        - configuration: The configuration to set as active
        - options: Options for setting the active configuration
     - Returns: Success indicator
     - Throws: ConfigurationError if setting active configuration fails
     */
    func setActiveConfiguration(
        configuration: ConfigurationDTO,
        options: ConfigActivateOptionsDTO
    ) async throws -> Bool
}
