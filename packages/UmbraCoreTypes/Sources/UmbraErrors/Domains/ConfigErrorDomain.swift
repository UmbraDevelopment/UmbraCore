import Foundation

/// Configuration errors for the Alpha Dot Five architecture
///
/// These error types represent various failure conditions that can occur
/// during configuration operations. All errors include descriptive messages
/// to facilitate debugging and error handling.
public enum ConfigError: Error, Sendable, Equatable {
    /// Thrown when initialisation of a configuration service fails
    case initialisationError(message: String)
    
    /// Thrown when attempting to add a configuration source that already exists
    case duplicateSource(message: String)
    
    /// Thrown when a requested configuration source cannot be found
    case sourceNotFound(message: String)
    
    /// Thrown when there is a general error with a configuration source
    case sourceError(message: String, error: Error?)
    
    /// Thrown when attempting to access a configuration value with the wrong type
    case typeMismatch(message: String, expected: String, actual: String)
    
    /// Thrown when no writable configuration source is available
    case noWritableSource(message: String)
    
    /// Thrown when attempting to write to a read-only configuration source
    case sourceReadOnly(message: String)
    
    public static func == (lhs: ConfigError, rhs: ConfigError) -> Bool {
        switch (lhs, rhs) {
        case let (.initialisationError(lm), .initialisationError(rm)):
            return lm == rm
        case let (.duplicateSource(lm), .duplicateSource(rm)):
            return lm == rm
        case let (.sourceNotFound(lm), .sourceNotFound(rm)):
            return lm == rm
        case let (.sourceError(lm, _), .sourceError(rm, _)):
            return lm == rm
        case let (.typeMismatch(lm, le, la), .typeMismatch(rm, re, ra)):
            return lm == rm && le == re && la == ra
        case let (.noWritableSource(lm), .noWritableSource(rm)):
            return lm == rm
        case let (.sourceReadOnly(lm), .sourceReadOnly(rm)):
            return lm == rm
        default:
            return false
        }
    }
}

extension ConfigError: CustomStringConvertible {
    public var description: String {
        switch self {
        case .initialisationError(let message):
            return "Configuration initialisation error: \(message)"
        case .duplicateSource(let message):
            return "Duplicate configuration source: \(message)"
        case .sourceNotFound(let message):
            return "Configuration source not found: \(message)"
        case .sourceError(let message, let error):
            if let error = error {
                return "Configuration source error: \(message) - \(error)"
            }
            return "Configuration source error: \(message)"
        case .typeMismatch(let message, let expected, let actual):
            return "Configuration type mismatch: \(message) - Expected: \(expected), Actual: \(actual)"
        case .noWritableSource(let message):
            return "No writable configuration source available: \(message)"
        case .sourceReadOnly(let message):
            return "Configuration source is read-only: \(message)"
        }
    }
}
