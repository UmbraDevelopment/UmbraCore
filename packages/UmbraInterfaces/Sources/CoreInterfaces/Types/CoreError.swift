import Foundation
import UmbraErrors

/// Core errors representing issues with fundamental services and operations
public enum CoreError: Error, Sendable, Equatable {
    /// Service was not found or could not be resolved
    case serviceNotFound(name: String)
    
    /// Service initialisation failed
    case initialisationFailed(details: String)
    
    /// Operation is not supported
    case operationNotSupported(details: String)
    
    /// Configuration error
    case configurationError(details: String)
    
    /// Invalid parameter provided
    case invalidParameter(name: String, details: String)
    
    /// Required dependency is missing
    case missingDependency(name: String)
    
    /// External system integration error
    case systemIntegrationError(details: String)
}

extension CoreError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .serviceNotFound(let name):
            return "Service not found: \(name)"
        case .initialisationFailed(let details):
            return "Service initialisation failed: \(details)"
        case .operationNotSupported(let details):
            return "Operation not supported: \(details)"
        case .configurationError(let details):
            return "Configuration error: \(details)"
        case .invalidParameter(let name, let details):
            return "Invalid parameter '\(name)': \(details)"
        case .missingDependency(let name):
            return "Missing dependency: \(name)"
        case .systemIntegrationError(let details):
            return "System integration error: \(details)"
        }
    }
}
