import Foundation

/**
 # Umbra Log Destination Config DTO
 
 Configuration for a log destination.
 
 Contains settings such as destination-type specific configuration
 parameters specific to the destination type, retention policies, filtering rules,
 and redaction rules for sensitive information.
 */
public struct UmbraLogDestinationConfigDTO: Sendable, Equatable {
    /// Configuration parameters specific to the destination type
    public let parameters: [String: String]
    
    /// Retention policy for logs
    public let retentionPolicy: UmbraLogRetentionPolicyDTO?
    
    /// Rules for filtering log entries
    public let filterRules: [UmbraLogFilterRuleDTO]
    
    /// Rules for redacting sensitive information in log entries
    public let redactionRules: [UmbraLogRedactionRuleDTO]?
    
    /// Initialises a new destination configuration
    ///
    /// - Parameters:
    ///   - parameters: Configuration parameters specific to the destination type
    ///   - retentionPolicy: Retention policy for logs
    ///   - filterRules: Rules for filtering log entries
    ///   - redactionRules: Rules for redacting sensitive information
    public init(
        parameters: [String: String] = [:],
        retentionPolicy: UmbraLogRetentionPolicyDTO? = nil,
        filterRules: [UmbraLogFilterRuleDTO] = [],
        redactionRules: [UmbraLogRedactionRuleDTO]? = nil
    ) {
        self.parameters = parameters
        self.retentionPolicy = retentionPolicy
        self.filterRules = filterRules
        self.redactionRules = redactionRules
    }
    
    /// Creates a configuration for a file-based log destination
    ///
    /// - Parameters:
    ///   - path: Path to the log file
    ///   - append: Whether to append to the file if it exists
    ///   - maxSize: Maximum size in bytes for the log file
    ///   - retentionPolicy: Retention policy for logs
    /// - Returns: A configuration for a file-based log destination
    public static func forFile(
        path: String,
        append: Bool = true,
        maxSize: UInt64? = 10_485_760, // 10 MB default
        retentionPolicy: UmbraLogRetentionPolicyDTO? = UmbraLogRetentionPolicyDTO()
    ) -> UmbraLogDestinationConfigDTO {
        var parameters: [String: String] = [:]
        parameters["path"] = path
        parameters["append"] = String(append)
        if let maxSize = maxSize {
            parameters["maxSize"] = String(maxSize)
        }
        
        return UmbraLogDestinationConfigDTO(
            parameters: parameters,
            retentionPolicy: retentionPolicy
        )
    }
    
    /// Creates a configuration for a console-based log destination
    ///
    /// - Parameters:
    ///   - useColors: Whether to use colors in console output
    ///   - useEmoji: Whether to use emoji symbols in console output
    /// - Returns: A configuration for a console-based log destination
    public static func forConsole(
        useColors: Bool = true,
        useEmoji: Bool = true
    ) -> UmbraLogDestinationConfigDTO {
        let parameters: [String: String] = [
            "useColors": String(useColors),
            "useEmoji": String(useEmoji)
        ]
        
        return UmbraLogDestinationConfigDTO(parameters: parameters)
    }
    
    /**
     Creates a custom configuration
     */
    public static func custom(
        parameters: [String: String]
    ) -> UmbraLogDestinationConfigDTO {
        return UmbraLogDestinationConfigDTO(parameters: parameters)
    }
}

extension UmbraLogDestinationConfigDTO: Codable {
    // Define coding keys to match our property names
    private enum CodingKeys: String, CodingKey {
        case parameters
        case retentionPolicy
        case filterRules
        case redactionRules
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        parameters = try container.decode([String: String].self, forKey: .parameters)
        retentionPolicy = try container.decodeIfPresent(UmbraLogRetentionPolicyDTO.self, forKey: .retentionPolicy)
        filterRules = try container.decode([UmbraLogFilterRuleDTO].self, forKey: .filterRules)
        redactionRules = try container.decodeIfPresent([UmbraLogRedactionRuleDTO].self, forKey: .redactionRules)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(parameters, forKey: .parameters)
        try container.encodeIfPresent(retentionPolicy, forKey: .retentionPolicy)
        try container.encode(filterRules, forKey: .filterRules)
        try container.encodeIfPresent(redactionRules, forKey: .redactionRules)
    }
}
