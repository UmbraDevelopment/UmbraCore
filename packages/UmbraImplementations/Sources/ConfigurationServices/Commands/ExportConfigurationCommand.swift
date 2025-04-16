import ConfigurationInterfaces
import CoreDTOs
import Foundation
import LoggingInterfaces
import LoggingTypes
import SecurityInterfaces

/**
 Command for exporting configuration to a specific format.

 This command encapsulates the logic for exporting configuration data to various formats,
 following the command pattern architecture.
 */
public class ExportConfigurationCommand: BaseConfigCommand, ConfigCommand {
  /// The result type for this command
  public typealias ResultType=Data

  /// Configuration to export
  private let configuration: ConfigurationDTO

  /// Format to export to
  private let format: ConfigFormatType

  /// Options for exporting
  private let options: ConfigExportOptionsDTO

  /// Security service for handling sensitive values
  private let securityService: CryptoServiceProtocol?

  /**
   Initialises a new export configuration command.

   - Parameters:
      - configuration: Configuration to export
      - format: Format to export to
      - options: Options for exporting
      - provider: Provider for configuration operations
      - logger: Logger instance for configuration operations
      - securityService: Optional security service for handling sensitive values
   */
  public init(
    configuration: ConfigurationDTO,
    format: ConfigFormatType,
    options: ConfigExportOptionsDTO,
    provider: ConfigurationProviderProtocol,
    logger: PrivacyAwareLoggingProtocol,
    securityService: CryptoServiceProtocol?=nil
  ) {
    self.configuration=configuration
    self.format=format
    self.options=options
    self.securityService=securityService

    super.init(provider: provider, logger: logger)
  }

  /**
   Executes the export configuration command.

   - Parameters:
      - context: The logging context for the operation
   - Returns: The exported configuration data
   - Throws: ConfigurationError if exporting fails
   */
  public func execute(context _: LogContextDTO) async throws -> Data {
    // Create a log context for this specific operation
    let operationContext=createLogContext(
      operation: "exportConfiguration",
      configID: configuration.id,
      additionalMetadata: [
        "configName": (value: configuration.name, privacyLevel: .public),
        "exportFormat": (value: format.rawValue, privacyLevel: .public),
        "prettyPrint": (value: String(options.prettyPrint), privacyLevel: .public),
        "includeMetadata": (value: String(options.includeMetadata), privacyLevel: .public),
        "encryptSensitiveValues": (value: String(options.encryptSensitiveValues),
                                   privacyLevel: .public)
      ]
    )

    // Log operation start
    await logOperationStart(operation: "exportConfiguration", context: operationContext)

    do {
      // Process configuration for export
      let processedConfig=try await processConfiguration(context: operationContext)

      // Export configuration using provider
      let exportedData=try await provider.exportConfiguration(
        configuration: processedConfig,
        to: format,
        context: operationContext
      )

      // Log success
      await logOperationSuccess(
        operation: "exportConfiguration",
        context: operationContext,
        additionalMetadata: [
          "dataSize": (value: String(exportedData.count), privacyLevel: .public)
        ]
      )

      return exportedData

    } catch let error as ConfigurationError {
      // Log failure
      await logOperationFailure(
        operation: "exportConfiguration",
        error: error,
        context: operationContext
      )

      throw error

    } catch {
      // Map unknown error to ConfigurationError
      let configError=ConfigurationError.general(error.localizedDescription)

      // Log failure
      await logOperationFailure(
        operation: "exportConfiguration",
        error: configError,
        context: operationContext
      )

      throw configError
    }
  }

  // MARK: - Private Methods

  /**
   Processes the configuration for export.

   This handles inclusion/exclusion of metadata, encryption of sensitive values,
   and exclusion of sections based on options.

   - Parameters:
      - context: The logging context for the operation
   - Returns: The processed configuration ready for export
   - Throws: ConfigurationError if processing fails
   */
  private func processConfiguration(context: LogContextDTO) async throws -> ConfigurationDTO {
    var processedValues=configuration.values
    var processedMetadata=options.includeMetadata ? configuration.metadata : [:]

    // Add export-specific metadata
    if options.includeMetadata {
      processedMetadata["exportedAt"]=ISO8601DateFormatter().string(from: Date())
      processedMetadata["exportFormat"]=format.rawValue
      processedMetadata["exportVersion"]="1.0"
    }

    // Apply exclusions if specified
    if !options.excludeSections.isEmpty {
      await logger.log(
        .debug,
        "Excluding \(options.excludeSections.count) sections from exported configuration",
        context: context
      )

      for section in options.excludeSections {
        processedValues.removeValue(forKey: section)
      }
    }

    // Handle sensitive values if requested and security service is available
    if options.encryptSensitiveValues, let securityService {
      await logger.log(
        .debug,
        "Encrypting sensitive values in exported configuration",
        context: context
      )

      processedValues=try await encryptSensitiveValues(
        processedValues,
        using: securityService,
        context: context
      )
    }

    // Return a copy of the configuration with processed values and metadata
    return ConfigurationDTO(
      id: configuration.id,
      name: configuration.name,
      version: configuration.version,
      environment: configuration.environment,
      createdAt: configuration.createdAt,
      updatedAt: configuration.updatedAt,
      values: processedValues,
      metadata: processedMetadata
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
    var result=values

    // Find values marked as sensitive and encrypt them
    for (key, value) in values {
      switch value {
        case let .string(stringValue):
          if
            key.lowercased().contains("password") ||
            key.lowercased().contains("secret") ||
            key.lowercased().contains("key") ||
            key.lowercased().contains("token")
          {

            // This is a sensitive value, encrypt it
            do {
              let securityConfig=SecurityConfigDTO(
                operationType: .encrypt,
                algorithm: .aes256,
                keyType: .generated,
                options: SecurityConfigOptions(
                  metadata: [
                    "plaintext": stringValue
                  ]
                )
              )

              let encryptResult=try await securityService.encrypt(config: securityConfig)

              if let encryptedData=encryptResult.resultData {
                // Store the encrypted data with a marker
                result[key] = .string("$ENCRYPTED$\(encryptedData.base64EncodedString())")
              } else {
                throw ConfigurationError.cryptoFailed("Encryption result was empty")
              }
            } catch {
              throw ConfigurationError
                .cryptoFailed("Failed to encrypt sensitive value: \(error.localizedDescription)")
            }
          }

        case let .dictionary(dictValue):
          // Recursively process dictionaries
          result[key]=try await .dictionary(
            encryptSensitiveValues(dictValue, using: securityService, context: context)
          )

        case let .array(arrayValue):
          // Process arrays of dictionaries
          var processedArray: [ConfigValueDTO]=[]

          for item in arrayValue {
            if case let .dictionary(dictItem)=item {
              try await processedArray.append(
                .dictionary(
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
