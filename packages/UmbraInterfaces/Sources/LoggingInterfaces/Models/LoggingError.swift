import Foundation

/**
 Errors that can occur during logging operations.
 
 This comprehensive set of errors provides detailed information about
 logging failures to facilitate proper handling and reporting.
 */
public enum LoggingError: Error, Equatable {
    /// Failed to write to log destination
    case writeFailure(String)
    
    /// Log destination not found
    case destinationNotFound(String)
    
    /// Invalid log destination configuration
    case invalidDestinationConfig(String)
    
    /// Permission denied for logging operation
    case permissionDenied(String)
    
    /// Log file rotation failed
    case rotationFailed(String)
    
    /// Log export failed
    case exportFailed(String)
    
    /// Log archiving failed
    case archiveFailed(String)
    
    /// Log retrieval failed
    case retrievalFailed(String)
    
    /// Failed to apply filter or redaction
    case filteringFailed(String)
    
    /// Failed to initialise logger
    case initialisationFailed(String)
    
    /// Log destination already exists
    case destinationAlreadyExists(String)
    
    /// Invalid log level
    case invalidLogLevel(String)
    
    /// Privacy policy violation
    case privacyViolation(String)
    
    /// Log storage full
    case storageFull(String)
    
    /// General logging error
    case general(String)
    
    /// Operation timed out
    case timeout(String)
}

// MARK: - LocalizedError Conformance

extension LoggingError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .writeFailure(let message):
            return "Failed to write to log destination: \(message)"
        case .destinationNotFound(let message):
            return "Log destination not found: \(message)"
        case .invalidDestinationConfig(let message):
            return "Invalid log destination configuration: \(message)"
        case .permissionDenied(let message):
            return "Permission denied for logging operation: \(message)"
        case .rotationFailed(let message):
            return "Log file rotation failed: \(message)"
        case .exportFailed(let message):
            return "Log export failed: \(message)"
        case .archiveFailed(let message):
            return "Log archiving failed: \(message)"
        case .retrievalFailed(let message):
            return "Log retrieval failed: \(message)"
        case .filteringFailed(let message):
            return "Failed to apply filter or redaction: \(message)"
        case .initialisationFailed(let message):
            return "Failed to initialise logger: \(message)"
        case .destinationAlreadyExists(let message):
            return "Log destination already exists: \(message)"
        case .invalidLogLevel(let message):
            return "Invalid log level: \(message)"
        case .privacyViolation(let message):
            return "Privacy policy violation in logging: \(message)"
        case .storageFull(let message):
            return "Log storage full: \(message)"
        case .general(let message):
            return "Logging error: \(message)"
        case .timeout(let message):
            return "Logging operation timed out: \(message)"
        }
    }
}
