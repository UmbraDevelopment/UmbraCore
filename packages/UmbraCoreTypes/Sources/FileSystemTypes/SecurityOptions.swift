import Foundation

/**
 Security options for file system operations.
 
 This struct encapsulates security-related settings for file system operations,
 providing consistent configuration for access controls and permissions.
 */
public struct SecurityOptions: Equatable, Sendable {
    /// Whether to preserve permissions during copy/move operations
    public let preservePermissions: Bool
    
    /// Whether to enforce sandboxing (restrict operations to specific directories)
    public let enforceSandboxing: Bool
    
    /// Whether to allow operations on symbolic links
    public let allowSymlinks: Bool
    
    /**
     Initialises security options for file system operations.
     
     - Parameters:
        - preservePermissions: Whether to preserve permissions during copy/move operations
        - enforceSandboxing: Whether to restrict operations to specific directories
        - allowSymlinks: Whether to allow operations on symbolic links
     */
    public init(
        preservePermissions: Bool,
        enforceSandboxing: Bool,
        allowSymlinks: Bool
    ) {
        self.preservePermissions = preservePermissions
        self.enforceSandboxing = enforceSandboxing
        self.allowSymlinks = allowSymlinks
    }
}
