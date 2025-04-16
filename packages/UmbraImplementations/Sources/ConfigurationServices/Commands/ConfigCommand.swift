import ConfigurationInterfaces
import CoreDTOs
import Foundation
import LoggingInterfaces
import LoggingTypes

/**
 Protocol for all configuration commands.

 This protocol defines the contract that all configuration commands must adhere to,
 following the command pattern architecture.
 */
public protocol ConfigCommand {
  /// The type of result that the command produces
  associatedtype ResultType

  /**
   Executes the command.

   - Parameters:
      - context: The logging context for the operation
   - Returns: The result of the command execution
   - Throws: Error if the command execution fails
   */
  func execute(context: LogContextDTO) async throws -> ResultType
}

/**
 Base class for configuration commands.

 This class provides common functionality for all configuration commands,
 such as standardised logging and error handling.
 */
public class BaseConfigCommand {
  /// Logger instance for configuration operations
  let logger: PrivacyAwareLoggingProtocol

  /// Configuration provider to perform the actual operations
  let provider: ConfigurationProviderProtocol

  /// Shared configuration cache
  static var configurationCache: [String: ConfigurationDTO]=[:]

  /// Currently active configuration
  static var activeConfiguration: ConfigurationDTO?

  /**
   Initialises a new base configuration command.

   - Parameters:
      - provider: Provider for configuration operations
      - logger: Logger instance for configuration operations
   */
  init(provider: ConfigurationProviderProtocol, logger: PrivacyAwareLoggingProtocol) {
    self.provider=provider
    self.logger=logger
  }

  /**
   Creates a log context for a configuration operation.

   - Parameters:
      - operation: The operation being performed
      - configId: The identifier of the configuration being operated on (optional)
      - additionalMetadata: Additional metadata to include in the context
   - Returns: A log context for the operation
   */
  func createLogContext(
    operation: String,
    configID: String?=nil,
    additionalMetadata: [String: (value: String, privacyLevel: PrivacyLevel)]=[:]
  ) -> LogContextDTO {
    var metadata=LogMetadataDTOCollection.empty

    if let configID {
      metadata=metadata.withPublic(key: "configId", value: configID)
    }

    for (key, value) in additionalMetadata {
      metadata=metadata.with(
        key: key,
        value: value.value,
        privacyLevel: value.privacyLevel
      )
    }

    return LogContextDTO(
      operation: operation,
      category: "Configuration",
      metadata: metadata
    )
  }

  /**
   Logs the start of a configuration operation.

   - Parameters:
      - operation: The name of the operation
      - context: The logging context
   */
  func logOperationStart(operation: String, context: LogContextDTO) async {
    await logger.log(.info, "Starting configuration operation: \(operation)", context: context)
  }

  /**
   Logs the successful completion of a configuration operation.

   - Parameters:
      - operation: The name of the operation
      - context: The logging context
      - additionalMetadata: Additional metadata to include in the log
   */
  func logOperationSuccess(
    operation: String,
    context: LogContextDTO,
    additionalMetadata: [String: (value: String, privacyLevel: PrivacyLevel)]=[:]
  ) async {
    var enrichedContext=context

    for (key, value) in additionalMetadata {
      enrichedContext=enrichedContext.withMetadata(
        LogMetadataDTOCollection().with(
          key: key,
          value: value.value,
          privacyLevel: value.privacyLevel
        )
      )
    }

    await logger.log(
      .info,
      "Configuration operation successful: \(operation)",
      context: enrichedContext
    )
  }

  /**
   Logs the failure of a configuration operation.

   - Parameters:
      - operation: The name of the operation
      - error: The error that occurred
      - context: The logging context
   */
  func logOperationFailure(operation: String, error: Error, context: LogContextDTO) async {
    let errorDescription=error.localizedDescription

    let enrichedContext=context.withMetadata(
      LogMetadataDTOCollection().withProtected(
        key: "errorDescription",
        value: errorDescription
      )
    )

    await logger.log(
      .error,
      "Configuration operation failed: \(operation)",
      context: enrichedContext
    )
  }

  /**
   Caches a configuration for future use.

   - Parameters:
      - configuration: The configuration to cache
      - source: The source the configuration was loaded from
   */
  func cacheConfiguration(configuration: ConfigurationDTO, source: ConfigSourceDTO) {
    let cacheKey="\(source.sourceType.rawValue):\(source.location)"
    Self.configurationCache[cacheKey]=configuration
  }

  /**
   Retrieves a cached configuration if available.

   - Parameters:
      - source: The source to look up in the cache
   - Returns: Cached configuration if available, nil otherwise
   */
  func getCachedConfiguration(for source: ConfigSourceDTO) -> ConfigurationDTO? {
    let cacheKey="\(source.sourceType.rawValue):\(source.location)"
    return Self.configurationCache[cacheKey]
  }

  /**
   Clears a specific configuration from the cache.

   - Parameters:
      - source: The source to remove from the cache
   */
  func clearCachedConfiguration(for source: ConfigSourceDTO) {
    let cacheKey="\(source.sourceType.rawValue):\(source.location)"
    Self.configurationCache.removeValue(forKey: cacheKey)
  }

  /**
   Sets the active configuration.

   - Parameters:
      - configuration: The configuration to set as active
   */
  func setActiveConfiguration(_ configuration: ConfigurationDTO) {
    Self.activeConfiguration=configuration
  }

  /**
   Gets the active configuration if available.

   - Returns: The active configuration or nil if none is set
   */
  func getActiveConfiguration() -> ConfigurationDTO? {
    Self.activeConfiguration
  }

  /**
   Applies environment-specific overrides to a configuration.

   - Parameters:
      - configuration: The base configuration
      - environment: The target environment
   - Returns: Configuration with environment-specific overrides applied
   */
  func applyEnvironmentOverrides(
    to configuration: ConfigurationDTO,
    for _: String
  ) -> ConfigurationDTO {
    // This would be implemented to handle environment-specific configuration
    // For now, we'll just return the original configuration
    configuration
  }

  /**
   Merges two configurations according to the specified strategy.

   - Parameters:
      - base: The base configuration
      - overlay: The configuration to merge on top
      - strategy: How to handle conflicts
   - Returns: The merged configuration
   */
  func mergeConfigurations(
    base: ConfigurationDTO,
    overlay: ConfigurationDTO,
    strategy: ConfigLoadOptionsDTO.MergeStrategy
  ) -> ConfigurationDTO {
    var mergedValues: [String: ConfigValueDTO]=[:]

    switch strategy {
      case .override:
        // Start with base values and override with overlay values
        mergedValues=base.values
        for (key, value) in overlay.values {
          mergedValues[key]=value
        }

      case .keepExisting:
        // Start with overlay values and keep base values if they exist
        mergedValues=overlay.values
        for (key, value) in base.values {
          if mergedValues[key] == nil {
            mergedValues[key]=value
          }
        }

      case .deepMerge:
        // Deep merge requires recursively merging nested dictionaries
        mergedValues=deepMerge(base: base.values, overlay: overlay.values)
    }

    return ConfigurationDTO(
      id: overlay.id,
      name: overlay.name,
      version: overlay.version,
      environment: overlay.environment,
      createdAt: base.createdAt,
      updatedAt: Date(),
      values: mergedValues,
      metadata: mergeDictionaries(base: base.metadata, overlay: overlay.metadata)
    )
  }

  /**
   Deep merges two configuration value dictionaries.

   - Parameters:
      - base: The base dictionary
      - overlay: The dictionary to merge on top
   - Returns: The merged dictionary
   */
  private func deepMerge(
    base: [String: ConfigValueDTO],
    overlay: [String: ConfigValueDTO]
  ) -> [String: ConfigValueDTO] {
    var result=base

    for (key, overlayValue) in overlay {
      if let baseValue=base[key] {
        // Handle different types of values
        switch (baseValue, overlayValue) {
          case let (.dictionary(baseDict), .dictionary(overlayDict)):
            // Recursively merge dictionaries
            result[key] = .dictionary(deepMerge(base: baseDict, overlay: overlayDict))

          case let (.array(baseArray), .array(overlayArray)):
            // For arrays, we just replace with the overlay value
            // A more sophisticated implementation might merge arrays
            result[key]=overlayValue

          default:
            // For all other types, the overlay value wins
            result[key]=overlayValue
        }
      } else {
        // If the key doesn't exist in the base, add it from the overlay
        result[key]=overlayValue
      }
    }

    return result
  }

  /**
   Merges two string dictionaries.

   - Parameters:
      - base: The base dictionary
      - overlay: The dictionary to merge on top
   - Returns: The merged dictionary
   */
  private func mergeDictionaries(
    base: [String: String],
    overlay: [String: String]
  ) -> [String: String] {
    var result=base
    for (key, value) in overlay {
      result[key]=value
    }
    return result
  }
}
