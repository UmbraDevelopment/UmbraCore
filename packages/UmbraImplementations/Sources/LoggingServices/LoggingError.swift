import Foundation
import LoggingTypes

/// Errors that can occur during logging operations
public enum LoggingError: Error, Sendable {
    /// Destination with the given identifier already exists
    case destinationAlreadyExists(identifier: String)
    
    /// Failed to flush a destination
    case flushFailed(destinationId: String, underlyingError: Error)
    
    /// Multiple flush operations failed
    case multipleFlushFailures(errors: [LoggingError])
    
    /// Failed to create a log destination
    case destinationCreationFailed(reason: String)
    
    /// Failed to write to a log destination
    case writeError(destinationId: String, reason: String)
}

extension LoggingError: CustomStringConvertible {
    public var description: String {
        switch self {
        case .destinationAlreadyExists(let identifier):
            return "Log destination with identifier '\(identifier)' already exists"
        case .flushFailed(let destinationId, let error):
            return "Failed to flush log destination '\(destinationId)': \(error)"
        case .multipleFlushFailures(let errors):
            let errorMessages = errors.map { $0.description }.joined(separator: ", ")
            return "Multiple flush failures occurred: \(errorMessages)"
        case .destinationCreationFailed(let reason):
            return "Failed to create log destination: \(reason)"
        case .writeError(let destinationId, let reason):
            return "Failed to write to log destination '\(destinationId)': \(reason)"
        }
    }
}
