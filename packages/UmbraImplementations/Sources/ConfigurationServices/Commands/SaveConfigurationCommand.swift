import Foundation
import ConfigurationInterfaces
import LoggingInterfaces
import LoggingTypes
import CoreDTOs
import SecurityInterfaces

/**
 Command for saving configuration to a destination.
 
 This command encapsulates the logic for persisting configuration data,
 following the command pattern architecture.
 */
public class SaveConfigurationCommand: BaseConfigCommand, ConfigCommand {
    /// The result type for this command
    public typealias ResultType = ConfigSaveResultDTO
    
    /// Configuration to save
    private let configuration: ConfigurationDTO
    
    /// Destination to save to
    private let destination: ConfigSourceDTO
    
    /// Options for saving
    private let options: ConfigSaveOptionsDTO
    
    /// Security service for encrypting sensitive values
    private let securityService: CryptoServiceProtocol?
    
    /**
     Initialises a new save configuration command.
     
     - Parameters:
        - configuration: Configuration to save
        - destination: Destination to save to
        - options: Options for saving
        - provider: Provider for configuration operations
        - logger: Logger instance for configuration operations
        - securityService: Optional security service for encrypting sensitive values
     */
    public init(
        configuration: ConfigurationDTO,
        destination: ConfigSourceDTO,
        options: ConfigSaveOptionsDTO,
        provider: ConfigurationProviderProtocol,
        logger: PrivacyAwareLoggingProtocol,
        securityService: CryptoServiceProtocol? = nil
    ) {
        self.configuration = configuration
        self.destination = destination
        self.options = options
        self.securityService = securityService
        
        super.init(provider: provider, logger: logger)
    }
    
    /**
     Executes the save configuration command.
     
     - Parameters:
        - context: The logging context for the operation
     - Returns: The result of the save operation
     - Throws: ConfigurationError if saving fails
     */
    public func execute(context: LogContextDTO) async throws -> ConfigSaveResultDTO {
        // Create a log context for this specific operation
        let operationContext = createLogContext(
            operation: "saveConfiguration",
            configId: configuration.id,
            additionalMetadata: [
                "configName": (value: configuration.name, privacyLevel: .public),
                "destinationType": (value: destination.sourceType.rawValue, privacyLevel: .public),
                "destinationFormat": (value: destination.format.rawValue, privacyLevel: .public),
                "destinationLocation": (value: destination.location, privacyLevel: .protected),
                "createBackup": (value: String(options.createBackup), privacyLevel: .public),
                "encryptSensitive": (value: String(options.encryptSensitiveValues), privacyLevel: .public)
            ]
        )
        
        // Log operation start
        await logOperationStart(operation: "saveConfiguration", context: operationContext)
        
        do {
            // Validate configuration if requested
            if options.validateBeforeSaving {
                await logger.log(
                    .debug,
                    "Validating configuration before saving",
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
                        "Pre-save validation failed with \(validationResult.issues.count) issues"
                    )
                }
            }
            
            // Create a backup if requested
            if options.createBackup {
                await createBackup(context: operationContext)
            }
            
            // Process configuration (handle encryption, exclusions, etc.)
            let processedConfig = try await processConfiguration(context: operationContext)
            
            // Save the processed configuration
            let saveResult = try await provider.saveConfiguration(
                configuration: processedConfig,
                to: destination,
                context: operationContext
            )
            
            // Clear cache for this destination since we've updated it
            clearCachedConfiguration(for: destination)
            
            // If this is the active configuration, update the cache
            if let activeConfig = getActiveConfiguration(), activeConfig.id == configuration.id {
                setActiveConfiguration(configuration)
            }
            
            // Log success
            await logOperationSuccess(
                operation: "saveConfiguration",
                context: operationContext,
                additionalMetadata: [
                    "saveLocation": (value: saveResult.savedLocation, privacyLevel: .protected),
                    "timestamp": (value: "\(saveResult.timestamp)", privacyLevel: .public)
                ]
            )
            
            return saveResult
            
        } catch let error as ConfigurationError {
            // Log failure
            await logOperationFailure(
                operation: "saveConfiguration",
                error: error,
                context: operationContext
            )
            
            throw error
            
        } catch {
            // Map unknown error to ConfigurationError
            let configError = ConfigurationError.saveFailed(error.localizedDescription)
            
            // Log failure
            await logOperationFailure(
                operation: "saveConfiguration",
                error: configError,
                context: operationContext
            )
            
            throw configError
        }
    }
    
    // MARK: - Private Methods
    
    /**
     Creates a backup of the existing configuration if it exists.
     
     - Parameters:
        - context: The logging context for the operation
     */
    private func createBackup(context: LogContextDTO) async {
        // Only attempt to create a backup if we're writing to a file
        guard destination.sourceType == .file else {
            await logger.log(
                .debug,
                "Backup skipped: Not a file destination",
                context: context
            )
            return
        }
        
        do {
            // Check if file exists before backing up
            let destinationPath = destination.location
            let fileManager = FileManager.default
            
            guard fileManager.fileExists(atPath: destinationPath) else {
                await logger.log(
                    .debug,
                    "Backup skipped: File doesn't exist",
                    context: context
                )
                return
            }
            
            // Create backup filename with timestamp
            let dateFormatter = ISO8601DateFormatter()
            dateFormatter.formatOptions = [.withFullDate, .withTime, .withTimeZone]
            let timestamp = dateFormatter.string(from: Date())
            
            let backupPath = "\(destinationPath).backup.\(timestamp)"
            
            try fileManager.copyItem(atPath: destinationPath, toPath: backupPath)
            
            await logger.log(
                .info,
                "Created configuration backup",
                context: context.withMetadata(
                    LogMetadataDTOCollection().withProtected(
                        key: "backupPath",
                        value: backupPath
                    )
                )
            )
            
        } catch {
            // Log but don't fail the save operation
            await logger.log(
                .warning,
                "Failed to create backup: \(error.localizedDescription)",
                context: context
            )
        }
    }
    
    /**
     Processes the configuration before saving.
     
     This handles encryption of sensitive values and exclusion of
     sections based on options.
     
     - Parameters:
        - context: The logging context for the operation
     - Returns: The processed configuration ready for saving
     - Throws: ConfigurationError if processing fails
     */
    private func processConfiguration(context: LogContextDTO) async throws -> ConfigurationDTO {
        var processedValues = configuration.values
        
        // Apply exclusions if specified
        if !options.excludeSections.isEmpty {
            await logger.log(
                .debug,
                "Excluding \(options.excludeSections.count) sections from saved configuration",
                context: context
            )
            
            for section in options.excludeSections {
                processedValues.removeValue(forKey: section)
            }
        }
        
        // Encrypt sensitive values if requested and security service is available
        if options.encryptSensitiveValues, let securityService = securityService {
            await logger.log(
                .debug,
                "Encrypting sensitive values in configuration",
                context: context
            )
            
            processedValues = try await encryptSensitiveValues(
                processedValues,
                using: securityService,
                context: context
            )
        }
        
        // Return a copy of the configuration with processed values
        return ConfigurationDTO(
            id: configuration.id,
            name: configuration.name,
            version: configuration.version,
            environment: configuration.environment,
            createdAt: configuration.createdAt,
            updatedAt: Date(), // Update timestamp
            values: processedValues,
            metadata: configuration.metadata
        )
    }
    
    /**
     Encrypts sensitive values in a configuration.
     
     - Parameters:
        - values: The configuration values to process
        - securityService: The security service to use for encryption
        - context: The logging context for the operation
     - Returns: The configuration values with sensitive values encrypted
     - Throws: ConfigurationError if encryption fails
     */
    private func encryptSensitiveValues(
        _ values: [String: ConfigValueDTO],
        using securityService: CryptoServiceProtocol,
        context: LogContextDTO
    ) async throws -> [String: ConfigValueDTO] {
        var result = values
        
        // Find values marked as sensitive and encrypt them
        for (key, value) in values {
            switch value {
            case .string(let stringValue):
                if key.lowercased().contains("password") ||
                   key.lowercased().contains("secret") ||
                   key.lowercased().contains("key") ||
                   key.lowercased().contains("token") {
                    
                    // This is a sensitive value, encrypt it
                    do {
                        let securityConfig = SecurityConfigDTO(
                            operationType: .encrypt,
                            algorithm: .aes256,
                            keyType: .generated,
                            options: SecurityConfigOptions(
                                metadata: [
                                    "plaintext": stringValue
                                ]
                            )
                        )
                        
                        let encryptResult = try await securityService.encrypt(config: securityConfig)
                        
                        if let encryptedData = encryptResult.resultData {
                            // Store the encrypted data with a marker
                            result[key] = .string("$ENCRYPTED$\(encryptedData.base64EncodedString())")
                        } else {
                            throw ConfigurationError.cryptoFailed("Encryption result was empty")
                        }
                    } catch {
                        throw ConfigurationError.cryptoFailed("Failed to encrypt sensitive value: \(error.localizedDescription)")
                    }
                }
                
            case .dictionary(let dictValue):
                // Recursively process dictionaries
                result[key] = try await .dictionary(
                    encryptSensitiveValues(dictValue, using: securityService, context: context)
                )
                
            case .array(let arrayValue):
                // Process arrays of dictionaries
                var processedArray: [ConfigValueDTO] = []
                
                for item in arrayValue {
                    if case .dictionary(let dictItem) = item {
                        processedArray.append(
                            try await .dictionary(
                                encryptSensitiveValues(dictItem, using: securityService, context: context)
                            )
                        )
                    } else {
                        processedArray.append(item)
                    }
                }
                
                result[key] = .array(processedArray)
                
            default:
                // Other value types are left as-is
                break
            }
        }
        
        return result
    }
}
