import Foundation
import ConfigurationInterfaces
import LoggingInterfaces
import LoggingTypes
import CoreDTOs

/**
 Command for loading configuration from a source.
 
 This command encapsulates the logic for loading configuration data,
 following the command pattern architecture.
 */
public class LoadConfigurationCommand: BaseConfigCommand, ConfigCommand {
    /// The result type for this command
    public typealias ResultType = ConfigurationDTO
    
    /// Source from which to load configuration
    private let source: ConfigSourceDTO
    
    /// Options for loading configuration
    private let options: ConfigLoadOptionsDTO
    
    /**
     Initialises a new load configuration command.
     
     - Parameters:
        - source: Source from which to load configuration
        - options: Options for loading configuration
        - provider: Provider for configuration operations
        - logger: Logger instance for configuration operations
     */
    public init(
        source: ConfigSourceDTO,
        options: ConfigLoadOptionsDTO,
        provider: ConfigurationProviderProtocol,
        logger: PrivacyAwareLoggingProtocol
    ) {
        self.source = source
        self.options = options
        
        super.init(provider: provider, logger: logger)
    }
    
    /**
     Executes the load configuration command.
     
     - Parameters:
        - context: The logging context for the operation
     - Returns: The loaded configuration
     - Throws: ConfigurationError if loading fails
     */
    public func execute(context: LogContextDTO) async throws -> ConfigurationDTO {
        // Create a log context for this specific operation
        let operationContext = createLogContext(
            operation: "loadConfiguration",
            additionalMetadata: [
                "sourceType": (value: source.sourceType.rawValue, privacyLevel: .public),
                "format": (value: source.format.rawValue, privacyLevel: .public),
                "location": (value: source.location, privacyLevel: .protected)
            ]
        )
        
        // Log operation start
        await logOperationStart(operation: "loadConfiguration", context: operationContext)
        
        do {
            // Check cache first if we're not forcing reload
            if !options.forceReload, let cachedConfig = getCachedConfiguration(for: source) {
                await logger.log(
                    .debug,
                    "Using cached configuration",
                    context: operationContext
                )
                
                return cachedConfig
            }
            
            // Attempt to load from primary source
            let loadedConfig: ConfigurationDTO
            do {
                loadedConfig = try await provider.loadConfiguration(
                    from: source,
                    context: operationContext
                )
            } catch {
                // If primary source fails and we have fallbacks, try them
                if !options.fallbackSources.isEmpty {
                    return try await tryFallbackSources(
                        error: error,
                        context: operationContext
                    )
                } else {
                    throw error
                }
            }
            
            // Apply environment-specific overrides if needed
            let finalConfig = applyEnvironmentOverrides(
                loadedConfig,
                context: operationContext
            )
            
            // Merge with existing active configuration if requested
            let resultConfig = mergeWithExistingIfNeeded(
                finalConfig,
                context: operationContext
            )
            
            // Cache the configuration if caching is enabled
            if options.enableCaching {
                cacheConfiguration(configuration: resultConfig, source: source)
            }
            
            // Log success
            await logOperationSuccess(
                operation: "loadConfiguration",
                context: operationContext,
                additionalMetadata: [
                    "configId": (value: resultConfig.id, privacyLevel: .public),
                    "configVersion": (value: resultConfig.version, privacyLevel: .public),
                    "environment": (value: resultConfig.environment, privacyLevel: .public)
                ]
            )
            
            // Set as active if none exists
            if getActiveConfiguration() == nil {
                setActiveConfiguration(resultConfig)
            }
            
            return resultConfig
            
        } catch let error as ConfigurationError {
            // Log failure
            await logOperationFailure(
                operation: "loadConfiguration",
                error: error,
                context: operationContext
            )
            
            throw error
            
        } catch {
            // Map unknown error to ConfigurationError
            let configError = ConfigurationError.loadFailed(error.localizedDescription)
            
            // Log failure
            await logOperationFailure(
                operation: "loadConfiguration",
                error: configError,
                context: operationContext
            )
            
            throw configError
        }
    }
    
    // MARK: - Private Methods
    
    /**
     Tries to load configuration from fallback sources after primary source fails.
     
     - Parameters:
        - error: The error that occurred with the primary source
        - context: The logging context for the operation
     - Returns: Configuration loaded from a fallback source
     - Throws: ConfigurationError if all fallback sources fail
     */
    private func tryFallbackSources(
        error: Error,
        context: LogContextDTO
    ) async throws -> ConfigurationDTO {
        await logger.log(
            .warning,
            "Primary source failed, trying fallbacks: \(error.localizedDescription)",
            context: context
        )
        
        // Try each fallback source in order
        for (index, fallbackSource) in options.fallbackSources.enumerated() {
            do {
                let fallbackContext = context.withMetadata(
                    LogMetadataDTOCollection()
                        .withPublic(key: "fallbackIndex", value: String(index))
                        .withPublic(key: "fallbackSourceType", value: fallbackSource.sourceType.rawValue)
                        .withProtected(key: "fallbackLocation", value: fallbackSource.location)
                )
                
                await logger.log(
                    .debug,
                    "Trying fallback source",
                    context: fallbackContext
                )
                
                // Load from this fallback source
                let config = try await provider.loadConfiguration(
                    from: fallbackSource,
                    context: fallbackContext
                )
                
                await logger.log(
                    .info,
                    "Successfully loaded from fallback source",
                    context: fallbackContext
                )
                
                return config
                
            } catch {
                await logger.log(
                    .debug,
                    "Fallback source failed: \(error.localizedDescription)",
                    context: context
                )
                // Continue to the next fallback source
            }
        }
        
        // If we get here, all fallbacks failed
        throw ConfigurationError.loadFailed(
            "All configuration sources failed, including \(options.fallbackSources.count) fallbacks"
        )
    }
    
    /**
     Applies environment-specific overrides based on options.
     
     - Parameters:
        - config: The base configuration
        - context: The logging context for the operation
     - Returns: Configuration with environment overrides applied if needed
     */
    private func applyEnvironmentOverrides(
        _ config: ConfigurationDTO,
        context: LogContextDTO
    ) -> ConfigurationDTO {
        if options.environmentOverrides == .ignore {
            return config
        }
        
        await logger.log(
            .debug,
            "Applying environment overrides for environment: \(config.environment)",
            context: context
        )
        
        return applyEnvironmentOverrides(to: config, for: config.environment)
    }
    
    /**
     Merges the loaded configuration with existing active configuration if needed.
     
     - Parameters:
        - loadedConfig: The newly loaded configuration
        - context: The logging context for the operation
     - Returns: Merged configuration or the loaded configuration if no merge needed
     */
    private func mergeWithExistingIfNeeded(
        _ loadedConfig: ConfigurationDTO,
        context: LogContextDTO
    ) -> ConfigurationDTO {
        if !options.merge || getActiveConfiguration() == nil {
            return loadedConfig
        }
        
        guard let activeConfig = getActiveConfiguration() else {
            return loadedConfig
        }
        
        await logger.log(
            .debug,
            "Merging with existing configuration using strategy: \(options.mergeStrategy.rawValue)",
            context: context
        )
        
        return mergeConfigurations(
            base: activeConfig,
            overlay: loadedConfig,
            strategy: options.mergeStrategy
        )
    }
}
