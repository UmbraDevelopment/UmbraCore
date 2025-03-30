import Foundation
import LoggingTypes

/// Configuration options for the error logging system
///
/// This struct provides a centralised way to configure error logging
/// behaviour throughout the application.
public struct ErrorLoggerConfiguration: Sendable, Equatable {
    /// Global minimum log level for errors
    public let globalMinimumLevel: ErrorLoggingLevel
    
    /// Whether to include stack traces in error logs
    public let includeStackTraces: Bool
    
    /// Whether to include error metadata in logs
    public let includeMetadata: Bool
    
    /// Whether error logs should include source file information
    public let includeSourceInfo: Bool
    
    /// Privacy level for error metadata
    public let metadataPrivacyLevel: LogPrivacy
    
    /// Default initialiser
    /// - Parameters:
    ///   - globalMinimumLevel: The minimum level for error logging
    ///   - includeStackTraces: Whether stack traces should be included
    ///   - includeMetadata: Whether error metadata should be included
    ///   - includeSourceInfo: Whether source file information should be included
    ///   - metadataPrivacyLevel: Privacy level for error metadata
    public init(
        globalMinimumLevel: ErrorLoggingLevel = .info,
        includeStackTraces: Bool = true,
        includeMetadata: Bool = true,
        includeSourceInfo: Bool = true,
        metadataPrivacyLevel: LogPrivacy = .private
    ) {
        self.globalMinimumLevel = globalMinimumLevel
        self.includeStackTraces = includeStackTraces
        self.includeMetadata = includeMetadata
        self.includeSourceInfo = includeSourceInfo
        self.metadataPrivacyLevel = metadataPrivacyLevel
    }
    
    /// Create a new configuration with updated settings
    /// - Parameters:
    ///   - globalMinimumLevel: The minimum level for error logging
    ///   - includeStackTraces: Whether stack traces should be included
    ///   - includeMetadata: Whether error metadata should be included
    ///   - includeSourceInfo: Whether source file information should be included
    ///   - metadataPrivacyLevel: Privacy level for error metadata
    /// - Returns: A new configuration instance with the specified values
    public func with(
        globalMinimumLevel: ErrorLoggingLevel? = nil,
        includeStackTraces: Bool? = nil,
        includeMetadata: Bool? = nil,
        includeSourceInfo: Bool? = nil,
        metadataPrivacyLevel: LogPrivacy? = nil
    ) -> ErrorLoggerConfiguration {
        ErrorLoggerConfiguration(
            globalMinimumLevel: globalMinimumLevel ?? self.globalMinimumLevel,
            includeStackTraces: includeStackTraces ?? self.includeStackTraces,
            includeMetadata: includeMetadata ?? self.includeMetadata,
            includeSourceInfo: includeSourceInfo ?? self.includeSourceInfo,
            metadataPrivacyLevel: metadataPrivacyLevel ?? self.metadataPrivacyLevel
        )
    }
}
