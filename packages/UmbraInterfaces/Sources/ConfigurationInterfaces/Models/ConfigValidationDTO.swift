import Foundation

/**
 Represents a schema for validating configuration.
 
 This struct defines the expected structure and constraints for
 configuration values to enable validation.
 */
public struct ConfigSchemaDTO: Codable, Equatable, Sendable {
    /// Schema name or identifier
    public let name: String
    
    /// Schema version
    public let version: String
    
    /// Properties defined in the schema
    public let properties: [String: PropertyDefinition]
    
    /// Required property keys
    public let required: [String]
    
    /// Additional schema metadata
    public let metadata: [String: String]
    
    /**
     Definition of an expected property and its constraints.
     */
    public struct PropertyDefinition: Codable, Equatable, Sendable {
        /// Property type
        public let type: PropertyType
        
        /// Property description
        public let description: String
        
        /// Default value if not specified
        public let defaultValue: ConfigValueDTO?
        
        /// Whether the property is deprecated
        public let deprecated: Bool
        
        /// Nested properties for object types
        public let properties: [String: PropertyDefinition]?
        
        /// Array item definition for array types
        public let items: PropertyDefinition?
        
        /// Validation constraints
        public let constraints: ValidationConstraints?
        
        /**
         Initialises a property definition.
         
         - Parameters:
            - type: Property type
            - description: Property description
            - defaultValue: Default value if not specified
            - deprecated: Whether the property is deprecated
            - properties: Nested properties for object types
            - items: Array item definition for array types
            - constraints: Validation constraints
         */
        public init(
            type: PropertyType,
            description: String,
            defaultValue: ConfigValueDTO? = nil,
            deprecated: Bool = false,
            properties: [String: PropertyDefinition]? = nil,
            items: PropertyDefinition? = nil,
            constraints: ValidationConstraints? = nil
        ) {
            self.type = type
            self.description = description
            self.defaultValue = defaultValue
            self.deprecated = deprecated
            self.properties = properties
            self.items = items
            self.constraints = constraints
        }
    }
    
    /**
     Type of configuration property.
     */
    public enum PropertyType: String, Codable, Sendable {
        /// String type
        case string
        /// Integer type
        case integer
        /// Number (floating point) type
        case number
        /// Boolean type
        case boolean
        /// Array type
        case array
        /// Object (dictionary) type
        case object
        /// Date type
        case date
        /// Any type (no type validation)
        case any
    }
    
    /**
     Validation constraints for configuration values.
     */
    public struct ValidationConstraints: Codable, Equatable, Sendable {
        /// Minimum value for numeric types
        public let minimum: Double?
        
        /// Maximum value for numeric types
        public let maximum: Double?
        
        /// Minimum length for string and array types
        public let minLength: Int?
        
        /// Maximum length for string and array types
        public let maxLength: Int?
        
        /// Pattern for string types (regular expression)
        public let pattern: String?
        
        /// Enumerated allowed values
        public let enumValues: [String]?
        
        /// Format constraint for string types
        public let format: StringFormat?
        
        /**
         Initialises validation constraints.
         
         - Parameters:
            - minimum: Minimum value for numeric types
            - maximum: Maximum value for numeric types
            - minLength: Minimum length for string and array types
            - maxLength: Maximum length for string and array types
            - pattern: Pattern for string types (regular expression)
            - enumValues: Enumerated allowed values
            - format: Format constraint for string types
         */
        public init(
            minimum: Double? = nil,
            maximum: Double? = nil,
            minLength: Int? = nil,
            maxLength: Int? = nil,
            pattern: String? = nil,
            enumValues: [String]? = nil,
            format: StringFormat? = nil
        ) {
            self.minimum = minimum
            self.maximum = maximum
            self.minLength = minLength
            self.maxLength = maxLength
            self.pattern = pattern
            self.enumValues = enumValues
            self.format = format
        }
    }
    
    /**
     Format constraints for string values.
     */
    public enum StringFormat: String, Codable, Sendable {
        /// Email address format
        case email
        /// URI/URL format
        case uri
        /// Date format
        case date
        /// Date-time format
        case dateTime
        /// IPv4 address format
        case ipv4
        /// IPv6 address format
        case ipv6
        /// UUID format
        case uuid
    }
    
    /**
     Initialises a configuration schema.
     
     - Parameters:
        - name: Schema name or identifier
        - version: Schema version
        - properties: Properties defined in the schema
        - required: Required property keys
        - metadata: Additional schema metadata
     */
    public init(
        name: String,
        version: String,
        properties: [String: PropertyDefinition],
        required: [String] = [],
        metadata: [String: String] = [:]
    ) {
        self.name = name
        self.version = version
        self.properties = properties
        self.required = required
        self.metadata = metadata
    }
}

/**
 Result of validating a configuration against a schema.
 
 Contains information about whether validation passed and any issues encountered.
 */
public struct ConfigValidationResultDTO: Codable, Equatable, Sendable {
    /// Whether validation was successful
    public let isValid: Bool
    
    /// Validation issues found (if any)
    public let issues: [ValidationIssue]
    
    /// Warnings that don't invalidate the configuration
    public let warnings: [ValidationIssue]
    
    /// Schema used for validation
    public let schema: ConfigSchemaDTO?
    
    /**
     Represents a validation issue in configuration.
     */
    public struct ValidationIssue: Codable, Equatable, Sendable {
        /// Type of validation issue
        public let type: IssueType
        
        /// Message describing the issue
        public let message: String
        
        /// Path to the problematic configuration element
        public let path: String
        
        /// Severity of the issue
        public let severity: IssueSeverity
        
        /**
         Initialises a validation issue.
         
         - Parameters:
            - type: Type of validation issue
            - message: Message describing the issue
            - path: Path to the problematic configuration element
            - severity: Severity of the issue
         */
        public init(
            type: IssueType,
            message: String,
            path: String,
            severity: IssueSeverity
        ) {
            self.type = type
            self.message = message
            self.path = path
            self.severity = severity
        }
    }
    
    /**
     Type of validation issue.
     */
    public enum IssueType: String, Codable, Sendable {
        /// Missing required property
        case missingProperty
        /// Type mismatch (e.g., string instead of number)
        case typeMismatch
        /// Value outside allowed range
        case rangeViolation
        /// String too short or too long
        case lengthViolation
        /// String doesn't match pattern
        case patternViolation
        /// Value not in enumerated list
        case enumViolation
        /// Invalid format (e.g., not a valid email)
        case formatViolation
        /// Property is deprecated
        case deprecatedProperty
        /// Any other validation issue
        case other
    }
    
    /**
     Severity of validation issue.
     */
    public enum IssueSeverity: String, Codable, Sendable {
        /// Critical issue that must be fixed
        case critical
        /// Error that should be fixed
        case error
        /// Warning that doesn't invalidate configuration
        case warning
        /// Informational message
        case info
    }
    
    /**
     Initialises a configuration validation result.
     
     - Parameters:
        - isValid: Whether validation was successful
        - issues: Validation issues found (if any)
        - warnings: Warnings that don't invalidate the configuration
        - schema: Schema used for validation
     */
    public init(
        isValid: Bool,
        issues: [ValidationIssue] = [],
        warnings: [ValidationIssue] = [],
        schema: ConfigSchemaDTO? = nil
    ) {
        self.isValid = isValid
        self.issues = issues
        self.warnings = warnings
        self.schema = schema
    }
    
    /// Returns a successful validation result with no issues
    public static func valid(schema: ConfigSchemaDTO? = nil) -> ConfigValidationResultDTO {
        return ConfigValidationResultDTO(isValid: true, schema: schema)
    }
}
