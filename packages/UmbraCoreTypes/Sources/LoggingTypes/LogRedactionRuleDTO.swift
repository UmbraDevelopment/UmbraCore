import Foundation

/**
 # Umbra Log Redaction Rule DTO
 
 Defines rules for redacting sensitive information in log entries.
 
 These rules control how different types of sensitive data are handled
 in log entries before they are sent to destinations.
 */
public struct UmbraLogRedactionRuleDTO: Codable, Equatable, Sendable {
    /// Type of data to redact
    public enum RedactionType: String, Codable, Sendable {
        /// Regular expression pattern matching
        case regex
        /// Exact string matching
        case exact
        /// Data type matching (e.g., credit card, email)
        case dataType
    }
    
    /// Strategy for how to redact matched content
    public enum RedactionStrategy: String, Codable, Sendable {
        /// Replace with fixed text (e.g., "[REDACTED]")
        case fixed
        /// Replace with hash of original content
        case hash
        /// Replace with partial content (e.g., "1234****5678")
        case partial
        /// Remove entirely
        case remove
    }
    
    /// Unique identifier for this rule
    public let id: String
    
    /// Name for this rule
    public let name: String
    
    /// Pattern to match for redaction
    public let pattern: String
    
    /// Type of pattern matching to use
    public let type: RedactionType
    
    /// How to redact matched content
    public let strategy: RedactionStrategy
    
    /// Replacement text (if applicable)
    public let replacement: String?
    
    /// Priority of this rule (higher numbers take precedence)
    public let priority: Int
    
    /// Whether this rule is enabled
    public let isEnabled: Bool
    
    /**
     Initialises a log redaction rule.
     
     - Parameters:
        - id: Unique identifier for this rule
        - name: Name for this rule
        - pattern: Pattern to match for redaction
        - type: Type of pattern matching to use
        - strategy: How to redact matched content
        - replacement: Replacement text (if applicable)
        - priority: Priority of this rule (higher numbers take precedence)
        - isEnabled: Whether this rule is enabled
     */
    public init(
        id: String = UUID().uuidString,
        name: String,
        pattern: String,
        type: RedactionType,
        strategy: RedactionStrategy,
        replacement: String? = nil,
        priority: Int = 100,
        isEnabled: Bool = true
    ) {
        self.id = id
        self.name = name
        self.pattern = pattern
        self.type = type
        self.strategy = strategy
        self.replacement = replacement
        self.priority = priority
        self.isEnabled = isEnabled
    }
}
