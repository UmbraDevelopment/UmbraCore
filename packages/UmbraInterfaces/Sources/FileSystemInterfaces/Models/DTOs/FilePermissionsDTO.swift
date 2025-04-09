import Foundation

/**
 # File Permissions DTO
 
 A data transfer object that encapsulates file permission information.
 
 This struct provides a clean, immutable representation of file permissions
 that can be passed between different components without tight coupling.
 It includes helper methods to check specific permission types.
 
 ## Alpha Dot Five Architecture
 
 This type follows the Alpha Dot Five architecture principles:
 - Uses immutable structs for thread safety
 - Implements Sendable for safe concurrent access
 - Provides clear, well-documented properties
 - Uses British spelling in documentation
 */
public struct FilePermissionsDTO: Sendable, Equatable {
    /// Owner ID of the file
    public let ownerID: UInt
    
    /// Group ID of the file
    public let groupID: UInt
    
    /// POSIX file permissions (as a 16-bit value)
    public let posixPermissions: UInt16
    
    /**
     Creates a new file permissions DTO.
     
     - Parameters:
        - ownerID: Owner ID of the file
        - groupID: Group ID of the file
        - posixPermissions: POSIX file permissions
     */
    public init(
        ownerID: UInt,
        groupID: UInt,
        posixPermissions: UInt16
    ) {
        self.ownerID = ownerID
        self.groupID = groupID
        self.posixPermissions = posixPermissions
    }
    
    /// Whether the owner can read the file
    public var ownerCanRead: Bool {
        return (posixPermissions & 0o400) != 0
    }
    
    /// Whether the owner can write to the file
    public var ownerCanWrite: Bool {
        return (posixPermissions & 0o200) != 0
    }
    
    /// Whether the owner can execute the file
    public var ownerCanExecute: Bool {
        return (posixPermissions & 0o100) != 0
    }
    
    /// Whether the group can read the file
    public var groupCanRead: Bool {
        return (posixPermissions & 0o040) != 0
    }
    
    /// Whether the group can write to the file
    public var groupCanWrite: Bool {
        return (posixPermissions & 0o020) != 0
    }
    
    /// Whether the group can execute the file
    public var groupCanExecute: Bool {
        return (posixPermissions & 0o010) != 0
    }
    
    /// Whether others can read the file
    public var othersCanRead: Bool {
        return (posixPermissions & 0o004) != 0
    }
    
    /// Whether others can write to the file
    public var othersCanWrite: Bool {
        return (posixPermissions & 0o002) != 0
    }
    
    /// Whether others can execute the file
    public var othersCanExecute: Bool {
        return (posixPermissions & 0o001) != 0
    }
    
    /**
     Returns an octal string representation of the permissions.
     
     - Returns: A string representation in octal format (e.g., "0644")
     */
    public func octalString() -> String {
        return String(format: "0%o", posixPermissions & 0o777)
    }
    
    /**
     Returns a symbolic string representation of the permissions.
     
     - Returns: A string representation in symbolic format (e.g., "rw-r--r--")
     */
    public func symbolicString() -> String {
        var result = ""
        
        // Owner permissions
        result += ownerCanRead ? "r" : "-"
        result += ownerCanWrite ? "w" : "-"
        result += ownerCanExecute ? "x" : "-"
        
        // Group permissions
        result += groupCanRead ? "r" : "-"
        result += groupCanWrite ? "w" : "-"
        result += groupCanExecute ? "x" : "-"
        
        // Others permissions
        result += othersCanRead ? "r" : "-"
        result += othersCanWrite ? "w" : "-"
        result += othersCanExecute ? "x" : "-"
        
        return result
    }
}
