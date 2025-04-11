import Foundation
import ConfigurationInterfaces
import LoggingInterfaces
import LoggingTypes
import CoreDTOs

/**
 Provider implementation for file-based configuration storage.
 
 This provider handles loading and saving configurations to the local filesystem.
 */
public class FileConfigurationProvider: ConfigurationProviderProtocol {
    
    /// File manager for filesystem operations
    private let fileManager = FileManager.default
    
    /// JSON encoder and decoder for serialization
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    public init() {
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
    }
    
    /**
     Loads configuration from a file source.
     */
    public func loadConfiguration(
        from source: ConfigSourceDTO,
        context: LogContextDTO
    ) async throws -> ConfigurationDTO {
        guard source.sourceType == .file else {
            throw ConfigurationError.sourceNotFound("Source is not a file: \(source.sourceType.rawValue)")
        }
        
        let filePath = source.location
        
        guard fileManager.fileExists(atPath: filePath) else {
            throw ConfigurationError.sourceNotFound("File does not exist: \(filePath)")
        }
        
        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: filePath))
            let config = try parseData(data, format: source.format)
            
            // Add source metadata to the configuration
            var config = config
            var metadata = config.metadata
            metadata["sourceLocation"] = filePath
            metadata["sourceType"] = source.sourceType.rawValue
            metadata["sourceFormat"] = source.format.rawValue
            
            return ConfigurationDTO(
                id: config.id,
                name: config.name,
                version: config.version,
                environment: config.environment,
                createdAt: config.createdAt,
                updatedAt: config.updatedAt,
                values: config.values,
                metadata: metadata
            )
            
        } catch let error as ConfigurationError {
            throw error
        } catch {
            throw ConfigurationError.loadFailed("Failed to load configuration: \(error.localizedDescription)")
        }
    }
    
    /**
     Saves configuration to a file destination.
     */
    public func saveConfiguration(
        configuration: ConfigurationDTO,
        to destination: ConfigSourceDTO,
        context: LogContextDTO
    ) async throws -> ConfigSaveResultDTO {
        guard destination.sourceType == .file else {
            throw ConfigurationError.sourceNotFound("Destination is not a file: \(destination.sourceType.rawValue)")
        }
        
        let filePath = destination.location
        
        // Create directory if it doesn't exist
        let directoryURL = URL(fileURLWithPath: filePath).deletingLastPathComponent()
        
        if !fileManager.fileExists(atPath: directoryURL.path) {
            do {
                try fileManager.createDirectory(
                    at: directoryURL,
                    withIntermediateDirectories: true
                )
            } catch {
                throw ConfigurationError.saveFailed("Failed to create directory: \(error.localizedDescription)")
            }
        }
        
        do {
            // Generate data based on format
            let data = try generateData(from: configuration, format: destination.format)
            
            // Write to file
            try data.write(to: URL(fileURLWithPath: filePath))
            
            return ConfigSaveResultDTO.success(location: filePath)
            
        } catch let error as ConfigurationError {
            throw error
        } catch {
            throw ConfigurationError.saveFailed("Failed to save configuration: \(error.localizedDescription)")
        }
    }
    
    /**
     Validates configuration against a schema.
     */
    public func validateConfiguration(
        configuration: ConfigurationDTO,
        schema: ConfigSchemaDTO?,
        context: LogContextDTO
    ) async throws -> ConfigValidationResultDTO {
        guard let schema = schema else {
            // No schema provided, so we assume the configuration is valid
            return ConfigValidationResultDTO.valid()
        }
        
        var issues: [ConfigValidationResultDTO.ValidationIssue] = []
        var warnings: [ConfigValidationResultDTO.ValidationIssue] = []
        
        // Check required properties
        for requiredKey in schema.required {
            if configuration.values[requiredKey] == nil {
                issues.append(
                    ConfigValidationResultDTO.ValidationIssue(
                        type: .missingProperty,
                        message: "Missing required property: \(requiredKey)",
                        path: requiredKey,
                        severity: .error
                    )
                )
            }
        }
        
        // Validate properties against schema definitions
        for (key, propertyDef) in schema.properties {
            if let value = configuration.values[key] {
                // Check type
                if !validateType(value, against: propertyDef.type) {
                    issues.append(
                        ConfigValidationResultDTO.ValidationIssue(
                            type: .typeMismatch,
                            message: "Type mismatch for property: \(key). Expected \(propertyDef.type.rawValue)",
                            path: key,
                            severity: .error
                        )
                    )
                    continue
                }
                
                // Check constraints
                if let constraints = propertyDef.constraints {
                    let constraintIssues = validateConstraints(
                        value: value,
                        key: key,
                        constraints: constraints
                    )
                    issues.append(contentsOf: constraintIssues)
                }
                
                // Check for deprecated properties
                if propertyDef.deprecated {
                    warnings.append(
                        ConfigValidationResultDTO.ValidationIssue(
                            type: .deprecatedProperty,
                            message: "Property is deprecated: \(key)",
                            path: key,
                            severity: .warning
                        )
                    )
                }
            }
        }
        
        return ConfigValidationResultDTO(
            isValid: issues.isEmpty,
            issues: issues,
            warnings: warnings,
            schema: schema
        )
    }
    
    /**
     Exports configuration to a specific format.
     */
    public func exportConfiguration(
        configuration: ConfigurationDTO,
        to format: ConfigFormatType,
        context: LogContextDTO
    ) async throws -> Data {
        return try generateData(from: configuration, format: format)
    }
    
    /**
     Imports configuration from external data.
     */
    public func importConfiguration(
        from data: Data,
        format: ConfigFormatType,
        context: LogContextDTO
    ) async throws -> ConfigurationDTO {
        return try parseData(data, format: format)
    }
    
    /**
     Gets the source type that this provider can handle.
     */
    public func canHandleSourceType() -> ConfigSourceType {
        return .file
    }
    
    // MARK: - Private Methods
    
    /**
     Parses configuration data from a specific format.
     */
    private func parseData(_ data: Data, format: ConfigFormatType) throws -> ConfigurationDTO {
        switch format {
        case .json:
            do {
                return try decoder.decode(ConfigurationDTO.self, from: data)
            } catch {
                throw ConfigurationError.parseFailed("Failed to parse JSON: \(error.localizedDescription)")
            }
            
        case .plist:
            // Implementation for property list format
            throw ConfigurationError.invalidFormat("Plist format not implemented yet")
            
        case .yaml:
            // Implementation for YAML format
            throw ConfigurationError.invalidFormat("YAML format not implemented yet")
            
        case .custom:
            throw ConfigurationError.invalidFormat("Custom format not supported by file provider")
        }
    }
    
    /**
     Generates data from a configuration in a specific format.
     */
    private func generateData(from config: ConfigurationDTO, format: ConfigFormatType) throws -> Data {
        switch format {
        case .json:
            do {
                return try encoder.encode(config)
            } catch {
                throw ConfigurationError.invalidFormat("Failed to encode to JSON: \(error.localizedDescription)")
            }
            
        case .plist:
            // Implementation for property list format
            throw ConfigurationError.invalidFormat("Plist format not implemented yet")
            
        case .yaml:
            // Implementation for YAML format
            throw ConfigurationError.invalidFormat("YAML format not implemented yet")
            
        case .custom:
            throw ConfigurationError.invalidFormat("Custom format not supported by file provider")
        }
    }
    
    /**
     Validates if a configuration value matches the expected type.
     */
    private func validateType(_ value: ConfigValueDTO, against type: ConfigSchemaDTO.PropertyType) -> Bool {
        switch (value, type) {
        case (.string, .string), (.string, .any):
            return true
        case (.integer, .integer), (.integer, .number), (.integer, .any):
            return true
        case (.number, .number), (.number, .any):
            return true
        case (.boolean, .boolean), (.boolean, .any):
            return true
        case (.array, .array), (.array, .any):
            return true
        case (.dictionary, .object), (.dictionary, .any):
            return true
        case (.date, .date), (.date, .string), (.date, .any):
            return true
        default:
            return false
        }
    }
    
    /**
     Validates a configuration value against constraints.
     */
    private func validateConstraints(
        value: ConfigValueDTO,
        key: String,
        constraints: ConfigSchemaDTO.ValidationConstraints
    ) -> [ConfigValidationResultDTO.ValidationIssue] {
        var issues: [ConfigValidationResultDTO.ValidationIssue] = []
        
        switch value {
        case .string(let stringValue):
            // Validate string constraints
            if let minLength = constraints.minLength, stringValue.count < minLength {
                issues.append(
                    ConfigValidationResultDTO.ValidationIssue(
                        type: .lengthViolation,
                        message: "String too short: \(key). Minimum length is \(minLength)",
                        path: key,
                        severity: .error
                    )
                )
            }
            
            if let maxLength = constraints.maxLength, stringValue.count > maxLength {
                issues.append(
                    ConfigValidationResultDTO.ValidationIssue(
                        type: .lengthViolation,
                        message: "String too long: \(key). Maximum length is \(maxLength)",
                        path: key,
                        severity: .error
                    )
                )
            }
            
            if let pattern = constraints.pattern {
                let regex = try? NSRegularExpression(pattern: pattern)
                if let regex = regex {
                    let range = NSRange(location: 0, length: stringValue.utf16.count)
                    if regex.firstMatch(in: stringValue, options: [], range: range) == nil {
                        issues.append(
                            ConfigValidationResultDTO.ValidationIssue(
                                type: .patternViolation,
                                message: "String doesn't match pattern: \(key)",
                                path: key,
                                severity: .error
                            )
                        )
                    }
                }
            }
            
            if let enumValues = constraints.enumValues, !enumValues.contains(stringValue) {
                issues.append(
                    ConfigValidationResultDTO.ValidationIssue(
                        type: .enumViolation,
                        message: "Value not in allowed values: \(key)",
                        path: key,
                        severity: .error
                    )
                )
            }
            
        case .integer(let intValue):
            // Validate integer constraints
            if let minimum = constraints.minimum, Double(intValue) < minimum {
                issues.append(
                    ConfigValidationResultDTO.ValidationIssue(
                        type: .rangeViolation,
                        message: "Value too small: \(key). Minimum is \(minimum)",
                        path: key,
                        severity: .error
                    )
                )
            }
            
            if let maximum = constraints.maximum, Double(intValue) > maximum {
                issues.append(
                    ConfigValidationResultDTO.ValidationIssue(
                        type: .rangeViolation,
                        message: "Value too large: \(key). Maximum is \(maximum)",
                        path: key,
                        severity: .error
                    )
                )
            }
            
        case .number(let doubleValue):
            // Validate number constraints
            if let minimum = constraints.minimum, doubleValue < minimum {
                issues.append(
                    ConfigValidationResultDTO.ValidationIssue(
                        type: .rangeViolation,
                        message: "Value too small: \(key). Minimum is \(minimum)",
                        path: key,
                        severity: .error
                    )
                )
            }
            
            if let maximum = constraints.maximum, doubleValue > maximum {
                issues.append(
                    ConfigValidationResultDTO.ValidationIssue(
                        type: .rangeViolation,
                        message: "Value too large: \(key). Maximum is \(maximum)",
                        path: key,
                        severity: .error
                    )
                )
            }
            
        case .array(let arrayValue):
            // Validate array constraints
            if let minLength = constraints.minLength, arrayValue.count < minLength {
                issues.append(
                    ConfigValidationResultDTO.ValidationIssue(
                        type: .lengthViolation,
                        message: "Array too short: \(key). Minimum length is \(minLength)",
                        path: key,
                        severity: .error
                    )
                )
            }
            
            if let maxLength = constraints.maxLength, arrayValue.count > maxLength {
                issues.append(
                    ConfigValidationResultDTO.ValidationIssue(
                        type: .lengthViolation,
                        message: "Array too long: \(key). Maximum length is \(maxLength)",
                        path: key,
                        severity: .error
                    )
                )
            }
            
        default:
            break
        }
        
        return issues
    }
}
