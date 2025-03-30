import Foundation
import LoggingTypes

/**
 # Backup Log Context
 
 A structured context object for privacy-aware logging of backup operations.
 This follows the Alpha Dot Five architecture principles for privacy-enhanced
 logging with appropriate data classification.
 
 The context uses builder pattern methods that return a new instance,
 allowing for immutable context objects and thread safety.
 */
public struct BackupLogContext: LogContextDTO {
    /// Dictionary of metadata entries with privacy annotations
    private var entries: [String: PrivacyMetadataValue] = [:]
    
    /// Current operation being performed
    public var operation: String? {
        if let value = entries["operation"]?.value as? String {
            return value
        }
        return nil
    }
    
    /// Initialises an empty backup log context
    public init() {}
    
    /// Converts the context to privacy metadata for logging
    /// - Returns: Privacy metadata with appropriate annotations
    public func toPrivacyMetadata() -> PrivacyMetadata {
        var metadata = PrivacyMetadata()
        
        for (key, value) in entries {
            metadata[key] = value
        }
        
        return metadata
    }
    
    /// Adds a general key-value pair to the context
    /// - Parameters:
    ///   - key: The metadata key
    ///   - value: The value to store
    ///   - privacy: Privacy level for the data
    /// - Returns: A new context with the added information
    public func with(key: String, value: String, privacy: PrivacyClassification) -> BackupLogContext {
        var newContext = self
        newContext.entries[key] = PrivacyMetadataValue(value: value, privacy: privacy)
        return newContext
    }
    
    /// Adds operation information to the context
    /// - Parameter operation: The operation being performed
    /// - Returns: A new context with the added information
    public func with(operation: String) -> BackupLogContext {
        var newContext = self
        newContext.entries["operation"] = PrivacyMetadataValue(value: operation, privacy: .public)
        return newContext
    }
    
    /// Adds sources information to the context
    /// - Parameters:
    ///   - sources: Array of source paths
    ///   - privacy: Privacy level for the paths
    /// - Returns: A new context with the added information
    public func with(sources: [String]?, privacy: PrivacyClassification) -> BackupLogContext {
        guard let sources = sources, !sources.isEmpty else { return self }
        
        var newContext = self
        newContext.entries["sources"] = PrivacyMetadataValue(
            value: sources.joined(separator: ", "),
            privacy: privacy
        )
        return newContext
    }
    
    /// Adds exclude paths information to the context
    /// - Parameters:
    ///   - excludePaths: Array of paths to exclude
    ///   - privacy: Privacy level for the paths
    /// - Returns: A new context with the added information
    public func with(excludePaths: [String]?, privacy: PrivacyClassification) -> BackupLogContext {
        guard let excludePaths = excludePaths, !excludePaths.isEmpty else { return self }
        
        var newContext = self
        newContext.entries["excludePaths"] = PrivacyMetadataValue(
            value: excludePaths.joined(separator: ", "),
            privacy: privacy
        )
        return newContext
    }
    
    /// Adds include paths information to the context
    /// - Parameters:
    ///   - includePaths: Array of paths to include
    ///   - privacy: Privacy level for the paths
    /// - Returns: A new context with the added information
    public func with(includePaths: [String]?, privacy: PrivacyClassification) -> BackupLogContext {
        guard let includePaths = includePaths, !includePaths.isEmpty else { return self }
        
        var newContext = self
        newContext.entries["includePaths"] = PrivacyMetadataValue(
            value: includePaths.joined(separator: ", "),
            privacy: privacy
        )
        return newContext
    }
    
    /// Adds tags information to the context
    /// - Parameters:
    ///   - tags: Array of tags
    ///   - privacy: Privacy level for the tags
    /// - Returns: A new context with the added information
    public func with(tags: [String]?, privacy: PrivacyClassification) -> BackupLogContext {
        guard let tags = tags, !tags.isEmpty else { return self }
        
        var newContext = self
        newContext.entries["tags"] = PrivacyMetadataValue(
            value: tags.joined(separator: ", "),
            privacy: privacy
        )
        return newContext
    }
    
    /// Adds repository ID information to the context
    /// - Parameters:
    ///   - repositoryID: Repository identifier
    ///   - privacy: Privacy level for the repository ID
    /// - Returns: A new context with the added information
    public func with(repositoryID: String?, privacy: PrivacyClassification) -> BackupLogContext {
        guard let repositoryID = repositoryID, !repositoryID.isEmpty else { return self }
        
        var newContext = self
        newContext.entries["repositoryID"] = PrivacyMetadataValue(value: repositoryID, privacy: privacy)
        return newContext
    }
    
    /// Adds snapshot ID information to the context
    /// - Parameters:
    ///   - snapshotID: Snapshot identifier
    ///   - privacy: Privacy level for the snapshot ID
    /// - Returns: A new context with the added information
    public func with(snapshotID: String, privacy: PrivacyClassification) -> BackupLogContext {
        var newContext = self
        newContext.entries["snapshotID"] = PrivacyMetadataValue(value: snapshotID, privacy: privacy)
        return newContext
    }
}
