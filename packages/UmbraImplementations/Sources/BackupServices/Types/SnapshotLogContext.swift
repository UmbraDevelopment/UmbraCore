import Foundation
import LoggingTypes

/**
 * Context for snapshot-related logging.
 *
 * This structure provides a standardised way to include relevant snapshot
 * operation details in log messages while maintaining privacy awareness.
 */
public struct SnapshotLogContext {
    /// The operation being performed
    public let operation: String
    
    /// The snapshot ID (if applicable)
    public let snapshotId: String
    
    /// Optional error message if operation failed
    public let errorMessage: String?
    
    /**
     * Creates a new snapshot log context.
     *
     * - Parameters:
     *   - operation: The operation being performed
     *   - snapshotId: The snapshot ID (if applicable)
     *   - errorMessage: Optional error message if operation failed
     */
    public init(
        operation: String,
        snapshotId: String,
        errorMessage: String? = nil
    ) {
        self.operation = operation
        self.snapshotId = snapshotId
        self.errorMessage = errorMessage
    }
    
    /**
     * Converts this context to privacy-aware metadata.
     *
     * - Returns: Privacy metadata for logging
     */
    public func toPrivacyMetadata() -> PrivacyMetadata {
        var metadata = PrivacyMetadata()
        
        // Add operation (public)
        metadata["operation"] = PrivacyMetadataValue(value: operation, privacy: .public)
        
        // Add snapshot ID (public)
        metadata["snapshotId"] = PrivacyMetadataValue(value: snapshotId, privacy: .public)
        
        // Add error message if present (potentially sensitive)
        if let errorMessage = errorMessage {
            metadata["error"] = PrivacyMetadataValue(value: errorMessage, privacy: .private)
        }
        
        return metadata
    }
}
