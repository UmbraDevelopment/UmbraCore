import Foundation

/**
 # Umbra Log Retention Policy DTO
 
 Defines policy for how long log entries should be retained.
 
 This object governs log rotation, archiving, and deletion policies to ensure
 logs don't consume excessive storage while maintaining a useful history.
 */
public struct UmbraLogRetentionPolicyDTO: Codable, Equatable, Sendable {
    /// Maximum number of log entries to retain
    public let maxEntries: Int?
    
    /// Maximum size in bytes for stored logs
    public let maxSizeBytes: UInt64?
    
    /// Maximum age in days for log entries
    public let maxAgeDays: Int?
    
    /// Whether to archive logs before deletion
    public let archiveBeforeDelete: Bool
    
    /// Strategy for handling log rotation
    public enum RotationStrategy: String, Codable, Sendable {
        /// Rotate based on time (daily, weekly, etc.)
        case time
        /// Rotate based on file size
        case size
        /// Rotate based on entry count
        case count
        /// No automatic rotation
        case none
    }
    
    /// When to rotate logs
    public let rotationStrategy: RotationStrategy
    
    /// Interval for rotation (if using time strategy)
    public let rotationInterval: TimeInterval?
    
    /// Number of backup/rotated logs to keep
    public let backupCount: Int
    
    /**
     Initialises a log retention policy.
     
     - Parameters:
        - maxEntries: Maximum number of log entries to retain (nil for unlimited)
        - maxSizeBytes: Maximum size in bytes for stored logs (nil for unlimited)
        - maxAgeDays: Maximum age in days for log entries (nil for unlimited)
        - archiveBeforeDelete: Whether to archive logs before deletion
        - rotationStrategy: When to rotate logs
        - rotationInterval: Interval for rotation (if using time strategy)
        - backupCount: Number of backup/rotated logs to keep
     */
    public init(
        maxEntries: Int? = nil,
        maxSizeBytes: UInt64? = nil,
        maxAgeDays: Int? = nil,
        archiveBeforeDelete: Bool = true,
        rotationStrategy: RotationStrategy = .size,
        rotationInterval: TimeInterval? = 86400, // 1 day default
        backupCount: Int = 5
    ) {
        self.maxEntries = maxEntries
        self.maxSizeBytes = maxSizeBytes
        self.maxAgeDays = maxAgeDays
        self.archiveBeforeDelete = archiveBeforeDelete
        self.rotationStrategy = rotationStrategy
        self.rotationInterval = rotationInterval
        self.backupCount = backupCount
    }
}
