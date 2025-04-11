import Foundation
import CoreDTOs

/**
 Represents a configuration value of any type.
 
 This enum allows for strongly-typed configuration values while
 supporting different value types commonly found in configuration.
 */
public enum ConfigValueDTO: Codable, Equatable, Sendable {
    /// String configuration value
    case string(String)
    /// Integer configuration value
    case integer(Int)
    /// Floating point configuration value
    case double(Double)
    /// Boolean configuration value
    case boolean(Bool)
    /// Date configuration value
    case date(Date)
    /// Array of configuration values
    case array([ConfigValueDTO])
    /// Dictionary of configuration values
    case dictionary([String: ConfigValueDTO])
    /// Null or empty configuration value
    case null
    
    // MARK: - Accessors
    
    /// Returns the value as a String if possible
    public var stringValue: String? {
        switch self {
        case .string(let value): return value
        case .integer(let value): return String(value)
        case .double(let value): return String(value)
        case .boolean(let value): return String(value)
        case .date(let value): return ISO8601DateFormatter().string(from: value)
        default: return nil
        }
    }
    
    /// Returns the value as an Int if possible
    public var intValue: Int? {
        switch self {
        case .integer(let value): return value
        case .string(let value): return Int(value)
        case .double(let value): return Int(value)
        case .boolean(let value): return value ? 1 : 0
        default: return nil
        }
    }
    
    /// Returns the value as a Double if possible
    public var doubleValue: Double? {
        switch self {
        case .double(let value): return value
        case .integer(let value): return Double(value)
        case .string(let value): return Double(value)
        default: return nil
        }
    }
    
    /// Returns the value as a Bool if possible
    public var boolValue: Bool? {
        switch self {
        case .boolean(let value): return value
        case .integer(let value): return value != 0
        case .string(let value):
            let lowercased = value.lowercased()
            if ["true", "yes", "1"].contains(lowercased) {
                return true
            } else if ["false", "no", "0"].contains(lowercased) {
                return false
            }
            return nil
        default: return nil
        }
    }
    
    /// Returns the value as a Date if possible
    public var dateValue: Date? {
        switch self {
        case .date(let value): return value
        case .string(let value): return ISO8601DateFormatter().date(from: value)
        case .integer(let value): return Date(timeIntervalSince1970: TimeInterval(value))
        default: return nil
        }
    }
    
    /// Returns the value as an Array if possible
    public var arrayValue: [ConfigValueDTO]? {
        switch self {
        case .array(let value): return value
        default: return nil
        }
    }
    
    /// Returns the value as a Dictionary if possible
    public var dictionaryValue: [String: ConfigValueDTO]? {
        switch self {
        case .dictionary(let value): return value
        default: return nil
        }
    }
    
    /// Returns whether the value is null
    public var isNull: Bool {
        switch self {
        case .null: return true
        default: return false
        }
    }
}

/**
 Represents a complete configuration with hierarchical structure.
 
 This struct contains all configuration values and metadata about the configuration.
 */
public struct ConfigurationDTO: Codable, Equatable, Sendable {
    /// Unique identifier for the configuration
    public let id: String
    
    /// Name of the configuration
    public let name: String
    
    /// Version of the configuration
    public let version: String
    
    /// Environment this configuration is for
    public let environment: String
    
    /// When the configuration was created
    public let createdAt: Date
    
    /// When the configuration was last updated
    public let updatedAt: Date
    
    /// The actual configuration values
    public let values: [String: ConfigValueDTO]
    
    /// Additional metadata about the configuration
    public let metadata: [String: String]
    
    /**
     Initialises a new configuration DTO.
     
     - Parameters:
        - id: Unique identifier for the configuration
        - name: Name of the configuration
        - version: Version of the configuration
        - environment: Environment this configuration is for
        - createdAt: When the configuration was created
        - updatedAt: When the configuration was last updated
        - values: The actual configuration values
        - metadata: Additional metadata about the configuration
     */
    public init(
        id: String,
        name: String,
        version: String,
        environment: String,
        createdAt: Date,
        updatedAt: Date,
        values: [String: ConfigValueDTO],
        metadata: [String: String] = [:]
    ) {
        self.id = id
        self.name = name
        self.version = version
        self.environment = environment
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.values = values
        self.metadata = metadata
    }
    
    /**
     Creates a new configuration with updated values.
     
     - Parameters:
        - values: The new values to use
     - Returns: A new configuration with updated values and timestamp
     */
    public func updating(values: [String: ConfigValueDTO]) -> ConfigurationDTO {
        return ConfigurationDTO(
            id: self.id,
            name: self.name,
            version: self.version,
            environment: self.environment,
            createdAt: self.createdAt,
            updatedAt: Date(),
            values: values,
            metadata: self.metadata
        )
    }
    
    /**
     Creates a new configuration with merged metadata.
     
     - Parameters:
        - metadata: The new metadata to merge
     - Returns: A new configuration with merged metadata
     */
    public func updatingMetadata(_ metadata: [String: String]) -> ConfigurationDTO {
        var newMetadata = self.metadata
        for (key, value) in metadata {
            newMetadata[key] = value
        }
        
        return ConfigurationDTO(
            id: self.id,
            name: self.name,
            version: self.version,
            environment: self.environment,
            createdAt: self.createdAt,
            updatedAt: Date(),
            values: self.values,
            metadata: newMetadata
        )
    }
}
