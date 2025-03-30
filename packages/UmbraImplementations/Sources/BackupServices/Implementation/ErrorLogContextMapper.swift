import Foundation
import LoggingTypes
import BackupInterfaces

/**
 * A mapper for converting various error types to standardised BackupError types
 * and creating appropriate error contexts for logging.
 * 
 * This follows the Alpha Dot Five pattern of providing structured error handling
 * with proper privacy controls.
 */
public struct ErrorLogContextMapper {
    /// Create a suitable error context from a log context
    /// - Parameter logContext: The original log context
    /// - Returns: A log context enriched with error information
    public func createErrorContext(from logContext: LogContextDTO) -> LogContextDTO {
        // If we have a SnapshotLogContextAdapter, use it directly
        if let snapshotContext = logContext as? SnapshotLogContextAdapter {
            return snapshotContext.with(key: "errorTimestamp", value: ISO8601DateFormatter().string(from: Date()), privacy: .public)
        }
        
        // For other contexts, do our best to create a meaningful error context
        var contextDictionary: [String: String] = [:]
        logContext.getMetadata().forEach { key, metadata in
            if let value = metadata.getValue() as? String {
                contextDictionary[key] = value
            }
        }
        
        // Create a new context with the operation from the original context
        let source = logContext.getSource()
        if source.contains("Snapshot") {
            return SnapshotLogContextAdapter(
                snapshotID: contextDictionary["snapshotID"] ?? "unknown",
                operation: contextDictionary["operation"] ?? "unknown",
                additionalContext: contextDictionary
            )
        } else {
            // Fall back to a simple context with the same metadata
            let newContext = SnapshotLogContextAdapter(
                snapshotID: "unknown",
                operation: "errorHandling"
            )
            
            // Add all metadata from the original context
            return contextDictionary.reduce(newContext) { context, entry in
                context.with(key: entry.key, value: entry.value, privacy: .public)
            }
        }
    }
    
    /// Maps a general Error to a suitable BackupError
    /// - Parameter error: The error to convert
    /// - Returns: A BackupError that best represents the original error
    public func mapToBackupError(_ error: Error) -> BackupError {
        // If it's already a BackupError, return it directly
        if let backupError = error as? BackupError {
            return backupError
        }
        
        // Check for cancellation
        if let nsError = error as NSError?, nsError.domain == NSURLErrorDomain && nsError.code == NSURLErrorCancelled {
            return BackupError.operationCancelled(reason: "User cancelled operation")
        }
        
        // Map other error types as needed
        // For now, we'll wrap them in an unexpected error
        return BackupError.unexpectedError(
            underlyingError: error,
            description: "An unexpected error occurred: \(error.localizedDescription)"
        )
    }
}
