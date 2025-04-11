import Foundation
import ConfigurationInterfaces
import LoggingInterfaces
import LoggingTypes
import CoreDTOs

/**
 Command for validating configuration against a schema or rules.
 
 This command encapsulates the logic for configuration validation,
 following the command pattern architecture.
 */
public class ValidateConfigurationCommand: BaseConfigCommand, ConfigCommand {
    /// The result type for this command
    public typealias ResultType = ConfigValidationResultDTO
    
    /// Configuration to validate
    private let configuration: ConfigurationDTO
    
    /// Schema to validate against (optional)
    private let schema: ConfigSchemaDTO?
    
    /**
     Initialises a new validate configuration command.
     
     - Parameters:
        - configuration: Configuration to validate
        - schema: Schema to validate against (optional)
        - provider: Provider for configuration operations
        - logger: Logger instance for configuration operations
     */
    public init(
        configuration: ConfigurationDTO,
        schema: ConfigSchemaDTO?,
        provider: ConfigurationProviderProtocol,
        logger: PrivacyAwareLoggingProtocol
    ) {
        self.configuration = configuration
        self.schema = schema
        
        super.init(provider: provider, logger: logger)
    }
    
    /**
     Executes the validate configuration command.
     
     - Parameters:
        - context: The logging context for the operation
     - Returns: The validation results
     - Throws: ConfigurationError if validation processing fails
     */
    public func execute(context: LogContextDTO) async throws -> ConfigValidationResultDTO {
        // Create a log context for this specific operation
        let operationContext = createLogContext(
            operation: "validateConfiguration",
            configId: configuration.id,
            additionalMetadata: [
                "configVersion": (value: configuration.version, privacyLevel: .public),
                "hasSchema": (value: String(schema != nil), privacyLevel: .public)
            ]
        )
        
        // Log operation start
        await logOperationStart(operation: "validateConfiguration", context: operationContext)
        
        do {
            // Perform basic validation checks
            let basicValidationResult = performBasicValidation(context: operationContext)
            
            // If basic validation failed, return the result
            if !basicValidationResult.isValid {
                await logValidationResult(
                    basicValidationResult,
                    context: operationContext
                )
                return basicValidationResult
            }
            
            // Perform schema validation if a schema is provided
            let validationResult: ConfigValidationResultDTO
            if let schema = schema {
                validationResult = try await provider.validateConfiguration(
                    configuration: configuration,
                    schema: schema,
                    context: operationContext
                )
            } else {
                // No schema provided, assume configuration is valid
                validationResult = ConfigValidationResultDTO.valid()
            }
            
            // Log validation result
            await logValidationResult(
                validationResult,
                context: operationContext
            )
            
            return validationResult
            
        } catch let error as ConfigurationError {
            // Log failure
            await logOperationFailure(
                operation: "validateConfiguration",
                error: error,
                context: operationContext
            )
            
            throw error
            
        } catch {
            // Map unknown error to ConfigurationError
            let configError = ConfigurationError.validationFailed(error.localizedDescription)
            
            // Log failure
            await logOperationFailure(
                operation: "validateConfiguration",
                error: configError,
                context: operationContext
            )
            
            throw configError
        }
    }
    
    // MARK: - Private Methods
    
    /**
     Performs basic validation on the configuration.
     
     This checks for things like required fields and structure
     without needing a schema.
     
     - Parameters:
        - context: The logging context for the operation
     - Returns: Validation results
     */
    private func performBasicValidation(context: LogContextDTO) -> ConfigValidationResultDTO {
        var issues: [ConfigValidationResultDTO.ValidationIssue] = []
        var warnings: [ConfigValidationResultDTO.ValidationIssue] = []
        
        // Check that required fields are present and non-empty
        if configuration.id.isEmpty {
            issues.append(
                ConfigValidationResultDTO.ValidationIssue(
                    type: .missingProperty,
                    message: "Configuration ID cannot be empty",
                    path: "id",
                    severity: .error
                )
            )
        }
        
        if configuration.name.isEmpty {
            issues.append(
                ConfigValidationResultDTO.ValidationIssue(
                    type: .missingProperty,
                    message: "Configuration name cannot be empty",
                    path: "name",
                    severity: .error
                )
            )
        }
        
        if configuration.version.isEmpty {
            issues.append(
                ConfigValidationResultDTO.ValidationIssue(
                    type: .missingProperty,
                    message: "Configuration version cannot be empty",
                    path: "version",
                    severity: .error
                )
            )
        }
        
        if configuration.environment.isEmpty {
            issues.append(
                ConfigValidationResultDTO.ValidationIssue(
                    type: .missingProperty,
                    message: "Configuration environment cannot be empty",
                    path: "environment",
                    severity: .error
                )
            )
        }
        
        // Check for empty values dictionary
        if configuration.values.isEmpty {
            warnings.append(
                ConfigValidationResultDTO.ValidationIssue(
                    type: .other,
                    message: "Configuration values dictionary is empty",
                    path: "values",
                    severity: .warning
                )
            )
        }
        
        // Return validation result
        return ConfigValidationResultDTO(
            isValid: issues.isEmpty,
            issues: issues,
            warnings: warnings,
            schema: nil
        )
    }
    
    /**
     Logs the validation result.
     
     - Parameters:
        - result: The validation result to log
        - context: The logging context for the operation
     */
    private func logValidationResult(
        _ result: ConfigValidationResultDTO,
        context: LogContextDTO
    ) async {
        if result.isValid {
            // Log success
            let warningCount = result.warnings.count
            let warningMessage = warningCount > 0 ? " with \(warningCount) warnings" : ""
            
            await logOperationSuccess(
                operation: "validateConfiguration",
                context: context,
                additionalMetadata: [
                    "warningCount": (value: String(warningCount), privacyLevel: .public)
                ]
            )
            
            // Log warnings if any
            if warningCount > 0 {
                for warning in result.warnings {
                    await logger.log(
                        .warning,
                        "Configuration validation warning: \(warning.message) at \(warning.path)",
                        context: context
                    )
                }
            }
        } else {
            // Log validation failure
            let issueCount = result.issues.count
            let warningCount = result.warnings.count
            
            await logger.log(
                .error,
                "Configuration validation failed with \(issueCount) issues and \(warningCount) warnings",
                context: context
            )
            
            // Log each issue
            for issue in result.issues {
                await logger.log(
                    .error,
                    "Configuration validation issue: \(issue.message) at \(issue.path)",
                    context: context
                )
            }
            
            // Log warnings
            for warning in result.warnings {
                await logger.log(
                    .warning,
                    "Configuration validation warning: \(warning.message) at \(warning.path)",
                    context: context
                )
            }
        }
    }
}
