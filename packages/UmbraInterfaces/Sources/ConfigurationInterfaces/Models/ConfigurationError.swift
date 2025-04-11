import Foundation

/**
 Errors that can occur during configuration operations.
 
 This comprehensive set of errors provides detailed information about
 configuration failures to facilitate proper handling and logging.
 */
public enum ConfigurationError: Error, Equatable {
    /// Failed to load configuration from source
    case loadFailed(String)
    
    /// Configuration validation failed
    case validationFailed(String)
    
    /// Failed to save configuration
    case saveFailed(String)
    
    /// Configuration key not found
    case keyNotFound(String)
    
    /// Type mismatch when accessing configuration value
    case typeMismatch(String)
    
    /// Invalid configuration format
    case invalidFormat(String)
    
    /// Failed to parse configuration data
    case parseFailed(String)
    
    /// Schema validation failed
    case schemaValidationFailed(String)
    
    /// Operation timed out
    case timeout(String)
    
    /// No active configuration
    case noActiveConfiguration
    
    /// Source not found
    case sourceNotFound(String)
    
    /// Dependency missing
    case dependencyMissing(String)
    
    /// Configuration version mismatch
    case versionMismatch(String)
    
    /// Permission denied for operation
    case permissionDenied(String)
    
    /// Encryption or decryption failed
    case cryptoFailed(String)
    
    /// General configuration error
    case general(String)
}

// MARK: - LocalizedError Conformance

extension ConfigurationError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .loadFailed(let message):
            return "Failed to load configuration: \(message)"
        case .validationFailed(let message):
            return "Configuration validation failed: \(message)"
        case .saveFailed(let message):
            return "Failed to save configuration: \(message)"
        case .keyNotFound(let message):
            return "Configuration key not found: \(message)"
        case .typeMismatch(let message):
            return "Type mismatch when accessing configuration value: \(message)"
        case .invalidFormat(let message):
            return "Invalid configuration format: \(message)"
        case .parseFailed(let message):
            return "Failed to parse configuration data: \(message)"
        case .schemaValidationFailed(let message):
            return "Schema validation failed: \(message)"
        case .timeout(let message):
            return "Configuration operation timed out: \(message)"
        case .noActiveConfiguration:
            return "No active configuration"
        case .sourceNotFound(let message):
            return "Configuration source not found: \(message)"
        case .dependencyMissing(let message):
            return "Configuration dependency missing: \(message)"
        case .versionMismatch(let message):
            return "Configuration version mismatch: \(message)"
        case .permissionDenied(let message):
            return "Permission denied for configuration operation: \(message)"
        case .cryptoFailed(let message):
            return "Configuration encryption or decryption failed: \(message)"
        case .general(let message):
            return "Configuration error: \(message)"
        }
    }
}
