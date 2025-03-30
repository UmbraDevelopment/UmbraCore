import Foundation
import BackupInterfaces
import LoggingTypes

/**
 * Provides a log context adapter for backup operations.
 *
 * This adapter implements the privacy-aware logging pattern from Alpha Dot Five,
 * ensuring appropriate privacy labels are applied to context data.
 */
public struct BackupLogContextAdapter: LogContextDTO {
    /// The operation being performed
    private let operation: String
    
    /// Parameters for the operation
    private let parameters: Any
    
    /// Unique identifier for this operation context
    private let contextID = UUID().uuidString
    
    /// Additional context values with privacy annotations
    private var additionalContext: [(key: String, value: String, privacy: PrivacyLevel)] = []
    
    /**
     * Creates a new backup log context.
     *
     * - Parameters:
     *   - operation: The operation being performed
     *   - parameters: The parameters for the operation
     */
    public init(operation: String, parameters: Any) {
        self.operation = operation
        self.parameters = parameters
    }
    
    /**
     * Gets the source of this log context.
     *
     * - Returns: The context source string
     */
    public func getSource() -> String {
        return "BackupService.\(operation)"
    }
    
    /**
     * Gets the metadata for this log context.
     *
     * - Returns: The context metadata
     */
    public func getMetadata() -> PrivacyMetadata {
        var metadata = PrivacyMetadata()
        
        // Add operation information
        metadata["operation"] = PrivacyMetadataValue(value: operation, privacy: .public)
        metadata["contextID"] = PrivacyMetadataValue(value: contextID, privacy: .public)
        
        // Add operation-specific metadata
        if let createParams = parameters as? BackupCreateParameters {
            metadata["sourceCount"] = PrivacyMetadataValue(value: String(createParams.sources.count), privacy: .public)
            metadata["sourcePaths"] = PrivacyMetadataValue(
                value: createParams.sources.map(\.path).joined(separator: ", "), 
                privacy: .restricted
            )
            if let tags = createParams.tags, !tags.isEmpty {
                metadata["tags"] = PrivacyMetadataValue(value: tags.joined(separator: ", "), privacy: .public)
            }
        } else if let restoreParams = parameters as? BackupRestoreParameters {
            metadata["snapshotID"] = PrivacyMetadataValue(value: restoreParams.snapshotID, privacy: .public)
            metadata["targetPath"] = PrivacyMetadataValue(value: restoreParams.targetPath.path, privacy: .restricted)
        } else if let listParams = parameters as? BackupListParameters {
            if let tags = listParams.tags, !tags.isEmpty {
                metadata["tags"] = PrivacyMetadataValue(value: tags.joined(separator: ", "), privacy: .public)
            }
            if let before = listParams.before {
                metadata["before"] = PrivacyMetadataValue(value: before.description, privacy: .public)
            }
            if let after = listParams.after {
                metadata["after"] = PrivacyMetadataValue(value: after.description, privacy: .public)
            }
        } else if let deleteParams = parameters as? BackupDeleteParameters {
            metadata["snapshotID"] = PrivacyMetadataValue(value: deleteParams.snapshotID, privacy: .public)
            metadata["pruneAfterDelete"] = PrivacyMetadataValue(value: String(deleteParams.pruneAfterDelete), privacy: .public)
        } else if let maintenanceParams = parameters as? BackupMaintenanceParameters {
            metadata["maintenanceType"] = PrivacyMetadataValue(value: String(describing: maintenanceParams.maintenanceType), privacy: .public)
            if let dryRun = maintenanceParams.options?.dryRun {
                metadata["dryRun"] = PrivacyMetadataValue(value: String(dryRun), privacy: .public)
            }
        }
        
        // Add additional context values
        for (key, value, privacy) in additionalContext {
            metadata[key] = PrivacyMetadataValue(value: value, privacy: privacy)
        }
        
        return metadata
    }
    
    /**
     * Creates a new context with an additional key-value pair.
     *
     * - Parameters:
     *   - key: The key for the value
     *   - value: The value to add
     *   - privacy: The privacy level for the value
     * - Returns: A new context with the additional value
     */
    public func with(key: String, value: String, privacy: PrivacyLevel) -> BackupLogContextAdapter {
        var newContext = self
        newContext.additionalContext.append((key: key, value: value, privacy: privacy))
        return newContext
    }
    
    /**
     * Creates a new context with an additional key-value pair.
     *
     * - Parameters:
     *   - key: The key for the value
     *   - value: The value to add
     * - Returns: A new context with the additional value
     */
    public func with(key: String, value: String) -> BackupLogContextAdapter {
        return with(key: key, value: value, privacy: .restricted)
    }
}
