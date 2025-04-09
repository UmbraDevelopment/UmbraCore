import Foundation

/**
 # Temporary File Options
 
 Options for controlling how temporary files and directories are created.
 
 ## Alpha Dot Five Architecture
 
 This type follows the Alpha Dot Five architecture principles:
 - Uses immutable structs for thread safety
 - Provides clear, well-documented options
 - Uses British spelling in documentation
 */
public struct TemporaryFileOptions: Sendable, Equatable {
    /// Whether to delete the temporary file or directory when the process exits
    public let deleteOnExit: Bool
    
    /// Custom directory where the temporary file or directory should be created
    /// If nil, the system's temporary directory is used
    public let customDirectory: String?
    
    /// Security level for the temporary file or directory
    public let securityLevel: TemporaryFileSecurityLevel
    
    /// Creates new temporary file options
    public init(
        deleteOnExit: Bool = true,
        customDirectory: String? = nil,
        securityLevel: TemporaryFileSecurityLevel = .standard
    ) {
        self.deleteOnExit = deleteOnExit
        self.customDirectory = customDirectory
        self.securityLevel = securityLevel
    }
}

/**
 # Temporary File Security Level
 
 Defines the security level for temporary files and directories.
 
 ## Alpha Dot Five Architecture
 
 This type follows the Alpha Dot Five architecture principles:
 - Uses a simple enum for strong typing
 - Follows British spelling in documentation
 */
public enum TemporaryFileSecurityLevel: String, Sendable, Equatable {
    /// Standard security level using default system protections
    case standard
    
    /// Enhanced security with more restrictive permissions
    case enhanced
    
    /// Maximum security with encryption and restrictive permissions
    case maximum
}
