import Foundation

/**
 # Temporary File Options
 
 Options for creating temporary files and directories.
 */
public struct TemporaryFileOptions: Sendable {
    /// The parent directory where the temporary file or directory should be created
    public let directory: FilePath?
    
    /// File protection level for the temporary file or directory
    public let fileProtection: FileProtectionType?
    
    /// POSIX permissions for the temporary file or directory
    public let permissions: NSNumber?
    
    /**
     Initialises a new TemporaryFileOptions instance.
     
     - Parameters:
        - directory: Optional parent directory where the temporary file or directory should be created
        - fileProtection: Optional file protection level
        - permissions: Optional POSIX permissions
     */
    public init(
        directory: FilePath? = nil,
        fileProtection: FileProtectionType? = nil,
        permissions: NSNumber? = nil
    ) {
        self.directory = directory
        self.fileProtection = fileProtection
        self.permissions = permissions
    }
    
    /// Default options for temporary files and directories
    public static let `default` = TemporaryFileOptions()
    
    /// Options for secure temporary files with complete protection
    public static let secure = TemporaryFileOptions(
        fileProtection: .complete,
        permissions: NSNumber(value: 0o600) // Read/write for owner only
    )
    
    /// Options for read-only temporary files
    public static let readOnly = TemporaryFileOptions(
        permissions: NSNumber(value: 0o400) // Read-only for owner
    )
}
