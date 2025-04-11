import Foundation

/**
 # Log Destination Options DTO
 
 Configuration options for log destinations. Specifies behavior and filtering
 options for log destinations.
 
 These options control how log entries are filtered and processed before being
 sent to a destination.
 */
@preconcurrency
public struct LogDestinationOptionsDTO: Sendable, Equatable {
    /// The minimum log level that will be sent to this destination
    public var minimumLevel: UmbraLogLevel
    
    /// Optional filter patterns to include (if non-empty, only matching entries will be logged)
    public var includePatterns: [String]
    
    /// Optional filter patterns to exclude (matching entries will be ignored)
    public var excludePatterns: [String]
    
    /// Whether to include source location information
    public var includeSourceLocation: Bool
    
    /// Whether to include stack traces for errors
    public var includeStackTraces: Bool
    
    /// Whether to include privacy annotations in formatted output
    public var includePrivacyAnnotations: Bool
    
    /// Whether to include metadata in formatted output
    public var includeMetadata: Bool
    
    /// Maximum size of the destination in bytes (if applicable)
    public var maxSize: UInt64?
    
    /// Maximum number of entries to keep (if applicable)
    public var maxEntries: Int?
    
    /// Default initializer with sensible defaults
    public init(
        minimumLevel: UmbraLogLevel = .info,
        includePatterns: [String] = [],
        excludePatterns: [String] = [],
        includeSourceLocation: Bool = true,
        includeStackTraces: Bool = true,
        includePrivacyAnnotations: Bool = true,
        includeMetadata: Bool = true,
        maxSize: UInt64? = nil,
        maxEntries: Int? = nil
    ) {
        self.minimumLevel = minimumLevel
        self.includePatterns = includePatterns
        self.excludePatterns = excludePatterns
        self.includeSourceLocation = includeSourceLocation
        self.includeStackTraces = includeStackTraces
        self.includePrivacyAnnotations = includePrivacyAnnotations
        self.includeMetadata = includeMetadata
        self.maxSize = maxSize
        self.maxEntries = maxEntries
    }
}
