/// ConfigValueDTO
///
/// Represents a typed configuration value in the UmbraCore framework.
/// This DTO uses a type-safe approach to configuration values, ensuring
/// that type information is preserved across module boundaries.
///
/// All properties are immutable to ensure thread safety when
/// passing instances between actors or across module boundaries.
public struct ConfigValueDTO: Sendable, Equatable {
    /// The type of the configuration value
    public let valueType: ConfigValueType
    
    /// The underlying string representation of the value
    public let stringValue: String
    
    /// Flag indicating whether this value contains sensitive information
    public let isSensitive: Bool
    
    /// Optional metadata about the value
    public let metadata: [String: String]?
    
    /// Creates a new ConfigValueDTO instance
    /// - Parameters:
    ///   - valueType: The type of the configuration value
    ///   - stringValue: The string representation of the value
    ///   - isSensitive: Whether the value contains sensitive information
    ///   - metadata: Optional metadata about the value
    public init(
        valueType: ConfigValueType,
        stringValue: String,
        isSensitive: Bool = false,
        metadata: [String: String]? = nil
    ) {
        self.valueType = valueType
        self.stringValue = stringValue
        self.isSensitive = isSensitive
        self.metadata = metadata
    }
    
    /// Creates a string configuration value
    /// - Parameters:
    ///   - value: The string value
    ///   - isSensitive: Whether the value contains sensitive information
    ///   - metadata: Optional metadata
    /// - Returns: A configured ConfigValueDTO
    public static func string(
        _ value: String,
        isSensitive: Bool = false,
        metadata: [String: String]? = nil
    ) -> ConfigValueDTO {
        ConfigValueDTO(
            valueType: .string,
            stringValue: value,
            isSensitive: isSensitive,
            metadata: metadata
        )
    }
    
    /// Creates a boolean configuration value
    /// - Parameters:
    ///   - value: The boolean value
    ///   - metadata: Optional metadata
    /// - Returns: A configured ConfigValueDTO
    public static func bool(
        _ value: Bool,
        metadata: [String: String]? = nil
    ) -> ConfigValueDTO {
        ConfigValueDTO(
            valueType: .bool,
            stringValue: value ? "true" : "false",
            isSensitive: false,
            metadata: metadata
        )
    }
    
    /// Creates an integer configuration value
    /// - Parameters:
    ///   - value: The integer value
    ///   - metadata: Optional metadata
    /// - Returns: A configured ConfigValueDTO
    public static func int(
        _ value: Int,
        metadata: [String: String]? = nil
    ) -> ConfigValueDTO {
        ConfigValueDTO(
            valueType: .int,
            stringValue: "\(value)",
            isSensitive: false,
            metadata: metadata
        )
    }
    
    /// Creates a double configuration value
    /// - Parameters:
    ///   - value: The double value
    ///   - metadata: Optional metadata
    /// - Returns: A configured ConfigValueDTO
    public static func double(
        _ value: Double,
        metadata: [String: String]? = nil
    ) -> ConfigValueDTO {
        ConfigValueDTO(
            valueType: .double,
            stringValue: "\(value)",
            isSensitive: false,
            metadata: metadata
        )
    }
    
    /// Creates a secure configuration value (e.g., API keys, tokens)
    /// - Parameters:
    ///   - value: The sensitive string value
    ///   - metadata: Optional metadata
    /// - Returns: A configured ConfigValueDTO
    public static func secure(
        _ value: String,
        metadata: [String: String]? = nil
    ) -> ConfigValueDTO {
        ConfigValueDTO(
            valueType: .string,
            stringValue: value,
            isSensitive: true,
            metadata: metadata
        )
    }
    
    /// Attempts to parse the value as a boolean
    /// - Returns: The boolean value if parsing succeeded, nil otherwise
    public func boolValue() -> Bool? {
        guard valueType == .bool else { return nil }
        return stringValue.lowercased() == "true"
    }
    
    /// Attempts to parse the value as an integer
    /// - Returns: The integer value if parsing succeeded, nil otherwise
    public func intValue() -> Int? {
        guard valueType == .int else { return nil }
        return Int(stringValue)
    }
    
    /// Attempts to parse the value as a double
    /// - Returns: The double value if parsing succeeded, nil otherwise
    public func doubleValue() -> Double? {
        guard valueType == .double else { return nil }
        return Double(stringValue)
    }
}

/// Represents the types of configuration values available
public enum ConfigValueType: String, Sendable, Equatable, CaseIterable {
    case string
    case bool
    case int
    case double
    case array
    case dictionary
}
