import Foundation
import LoggingTypes

/**
 * A domain-specific adapter for snapshot logging contexts that implements the standard
 * LogContextDTO protocol. This provides structured, privacy-aware logging for snapshot operations
 * following the Alpha Dot Five architecture principles.
 *
 * This adapter uses the LogMetadataDTOCollection to handle privacy annotations properly
 * and ensures proper separation between domain-specific metadata and core logging infrastructure.
 */
public struct SnapshotLogContextAdapter: LogContextDTO {
    /// The source identifier for this log context
    private let source: String = "BackupServices.Snapshot"
    
    /// The operation being performed
    private let operationName: String
    
    /// The snapshot ID related to this operation
    private let snapshotID: String
    
    /// Metadata collection with privacy annotations
    private var metadata: LogMetadataDTOCollection
    
    /// Create a new snapshot log context
    /// - Parameters:
    ///   - snapshotID: The ID of the snapshot being operated on
    ///   - operation: The operation being performed
    ///   - additionalContext: Optional additional context information
    public init(
        snapshotID: String,
        operation: String,
        additionalContext: [String: String]? = nil
    ) {
        self.snapshotID = snapshotID
        self.operationName = operation
        
        // Initialise metadata collection
        self.metadata = LogMetadataDTOCollection()
        
        // Add standard fields
        self.metadata.add(key: "snapshotID", value: snapshotID, privacy: .public)
        self.metadata.add(key: "operation", value: operation, privacy: .public)
        
        // Add any additional context if provided
        additionalContext?.forEach { key, value in
            self.metadata.add(key: key, value: value, privacy: .public)
        }
    }
    
    /// Get the source identifier for this log context
    public func getSource() -> String {
        return source
    }
    
    /// Get metadata for this log context
    public func getMetadata() -> LogMetadata {
        return metadata.buildMetadata()
    }
    
    /// Create a new context with an additional key-value pair
    /// - Parameters:
    ///   - key: The key for the value
    ///   - value: The value to add
    ///   - privacy: The privacy level
    /// - Returns: A new context with the additional value
    public func with(key: String, value: String, privacy: LogPrivacyLevel) -> SnapshotLogContextAdapter {
        var newContext = self
        newContext.metadata.add(key: key, value: value, privacy: privacy)
        return newContext
    }
    
    /// Create a new context with an additional key-value pair with public privacy
    /// - Parameters:
    ///   - key: The key for the value
    ///   - value: The value to add
    /// - Returns: A new context with the additional value
    public func with(key: String, value: String) -> SnapshotLogContextAdapter {
        return with(key: key, value: value, privacy: .public)
    }
    
    /// Create a new context with additional key-value pairs
    /// - Parameter additionalContext: The additional context
    /// - Returns: A new context with the additional values
    public func with(additionalContext: [String: String]) -> SnapshotLogContextAdapter {
        var newContext = self
        additionalContext.forEach { key, value in
            newContext.metadata.add(key: key, value: value, privacy: .public)
        }
        return newContext
    }
    
    /// Create a new context with source paths information
    /// - Parameters:
    ///   - paths: The array of paths
    ///   - privacy: The privacy level
    /// - Returns: A new context with source paths information
    public func with(sources paths: [String], privacy: LogPrivacyLevel) -> SnapshotLogContextAdapter {
        guard !paths.isEmpty else {
            return self
        }
        
        var newContext = self
        newContext.metadata.add(key: "sourceCount", value: String(paths.count), privacy: .public)
        newContext.metadata.add(key: "sources", value: paths.joined(separator: ", "), privacy: privacy)
        return newContext
    }
    
    /// Create a new context with exclude paths information
    /// - Parameters:
    ///   - paths: The array of paths
    ///   - privacy: The privacy level
    /// - Returns: A new context with exclude paths information
    public func with(excludePaths paths: [String]?, privacy: LogPrivacyLevel) -> SnapshotLogContextAdapter {
        guard let paths = paths, !paths.isEmpty else {
            return self
        }
        
        var newContext = self
        newContext.metadata.add(key: "excludeCount", value: String(paths.count), privacy: .public)
        newContext.metadata.add(key: "excludePaths", value: paths.joined(separator: ", "), privacy: privacy)
        return newContext
    }
    
    /// Create a new context with include paths information
    /// - Parameters:
    ///   - paths: The array of paths
    ///   - privacy: The privacy level
    /// - Returns: A new context with include paths information
    public func with(includePaths paths: [String]?, privacy: LogPrivacyLevel) -> SnapshotLogContextAdapter {
        guard let paths = paths, !paths.isEmpty else {
            return self
        }
        
        var newContext = self
        newContext.metadata.add(key: "includeCount", value: String(paths.count), privacy: .public)
        newContext.metadata.add(key: "includePaths", value: paths.joined(separator: ", "), privacy: privacy)
        return newContext
    }
    
    /// Create a new context with tags information
    /// - Parameters:
    ///   - tags: The array of tags
    ///   - privacy: The privacy level
    /// - Returns: A new context with tags information
    public func with(tags: [String]?, privacy: LogPrivacyLevel) -> SnapshotLogContextAdapter {
        guard let tags = tags, !tags.isEmpty else {
            return self
        }
        
        var newContext = self
        newContext.metadata.add(key: "tagCount", value: String(tags.count), privacy: .public)
        newContext.metadata.add(key: "tags", value: tags.joined(separator: ", "), privacy: privacy)
        return newContext
    }
}
