import ConfigurationInterfaces
import CoreDTOs
import Foundation
import LoggingInterfaces
import LoggingTypes

/**
 Command for importing configuration from external data.

 This command encapsulates the logic for importing configuration data from various formats,
 following the command pattern architecture.
 */
public class ImportConfigurationCommand: BaseConfigCommand, ConfigCommand {
  /// The result type for this command
  public typealias ResultType=ConfigurationDTO

  /// Data to import
  private let data: Data

  /// Format of the data
  private let format: ConfigFormatType

  /// Options for importing
  private let options: ConfigImportOptionsDTO

  /**
   Initialises a new import configuration command.

   - Parameters:
      - data: Data to import
      - format: Format of the data
      - options: Options for importing
      - provider: Provider for configuration operations
      - logger: Logger instance for configuration operations
   */
  public init(
    data: Data,
    format: ConfigFormatType,
    options: ConfigImportOptionsDTO,
    provider: ConfigurationProviderProtocol,
    logger: PrivacyAwareLoggingProtocol
  ) {
    self.data=data
    self.format=format
    self.options=options

    super.init(provider: provider, logger: logger)
  }

  /**
   Executes the import configuration command.

   - Parameters:
      - context: The logging context for the operation
   - Returns: The imported configuration
   - Throws: ConfigurationError if importing fails
   */
  public func execute(context _: LogContextDTO) async throws -> ConfigurationDTO {
    // Create a log context for this specific operation
    let operationContext=createLogContext(
      operation: "importConfiguration",
      additionalMetadata: [
        "importFormat": (value: format.rawValue, privacyLevel: .public),
        "dataSize": (value: String(data.count), privacyLevel: .public),
        "validateAfterImport": (value: String(options.validateAfterImport), privacyLevel: .public),
        "merge": (value: String(options.merge), privacyLevel: .public),
        "setActive": (value: String(options.setActive), privacyLevel: .public)
      ]
    )

    // Log operation start
    await logOperationStart(operation: "importConfiguration", context: operationContext)

    do {
      // Import configuration using provider
      let importedConfig=try await provider.importConfiguration(
        from: data,
        format: format,
        context: operationContext
      )

      // Validate if requested
      if options.validateAfterImport {
        await logger.log(
          .debug,
          "Validating imported configuration",
          context: operationContext
        )

        let validateCommand=ValidateConfigurationCommand(
          configuration: importedConfig,
          schema: nil, // No schema validation at this stage
          provider: provider,
          logger: logger
        )

        let validationResult=try await validateCommand.execute(context: operationContext)

        if !validationResult.isValid {
          throw ConfigurationError.validationFailed(
            "Post-import validation failed with \(validationResult.issues.count) issues"
          )
        }
      }

      // Merge with existing active configuration if requested
      let resultConfig=try await mergeWithExistingIfNeeded(
        importedConfig,
        context: operationContext
      )

      // Set as active if requested
      if options.setActive {
        await logger.log(
          .debug,
          "Setting imported configuration as active",
          context: operationContext
        )

        setActiveConfiguration(resultConfig)
      }

      // Save if requested
      if options.saveAfterImport, let destination=options.saveDestination {
        await logger.log(
          .debug,
          "Saving imported configuration",
          context: operationContext.withMetadata(
            LogMetadataDTOCollection().withProtected(
              key: "saveDestination",
              value: destination.location
            )
          )
        )

        let saveCommand=SaveConfigurationCommand(
          configuration: resultConfig,
          destination: destination,
          options: ConfigSaveOptionsDTO.default,
          provider: provider,
          logger: logger
        )

        _=try await saveCommand.execute(context: operationContext)
      }

      // Log success
      await logOperationSuccess(
        operation: "importConfiguration",
        context: operationContext,
        additionalMetadata: [
          "configId": (value: resultConfig.id, privacyLevel: .public),
          "configName": (value: resultConfig.name, privacyLevel: .public),
          "configVersion": (value: resultConfig.version, privacyLevel: .public),
          "environment": (value: resultConfig.environment, privacyLevel: .public)
        ]
      )

      return resultConfig

    } catch let error as ConfigurationError {
      // Log failure
      await logOperationFailure(
        operation: "importConfiguration",
        error: error,
        context: operationContext
      )

      throw error

    } catch {
      // Map unknown error to ConfigurationError
      let configError=ConfigurationError.parseFailed(error.localizedDescription)

      // Log failure
      await logOperationFailure(
        operation: "importConfiguration",
        error: configError,
        context: operationContext
      )

      throw configError
    }
  }

  // MARK: - Private Methods

  /**
   Merges the imported configuration with existing active configuration if needed.

   - Parameters:
      - importedConfig: The imported configuration
      - context: The logging context for the operation
   - Returns: Merged configuration or the imported configuration if no merge needed
   - Throws: ConfigurationError if merging fails
   */
  private func mergeWithExistingIfNeeded(
    _ importedConfig: ConfigurationDTO,
    context: LogContextDTO
  ) async throws -> ConfigurationDTO {
    if !options.merge || getActiveConfiguration() == nil {
      return importedConfig
    }

    guard let activeConfig=getActiveConfiguration() else {
      return importedConfig
    }

    await logger.log(
      .debug,
      "Merging imported configuration with existing using strategy: \(options.mergeStrategy.rawValue)",
      context: context
    )

    return mergeConfigurations(
      base: activeConfig,
      overlay: importedConfig,
      strategy: options.mergeStrategy
    )
  }
}
