import Foundation

/**
 # File Metadata DTO
 
 A data transfer object that encapsulates file metadata information.
 
 This struct provides a clean, immutable representation of file metadata
 that can be passed between different components without tight coupling.
 
 ## Alpha Dot Five Architecture
 
 This type follows the Alpha Dot Five architecture principles:
 - Uses immutable structs for thread safety
 - Implements Sendable for safe concurrent access
 - Provides clear, well-documented properties
 - Uses British spelling in documentation
 */
public struct FileMetadataDTO: Sendable, Equatable {
    /// Size of the file in bytes
    public let size: UInt64
    
    /// Date when the file was created
    public let creationDate: Date
    
    /// Date when the file was last modified
    public let modificationDate: Date
    
    /// Date when the file was last accessed (if available)
    public let accessDate: Date?
    
    /// Owner ID of the file
    public let ownerID: UInt
    
    /// Group ID of the file
    public let groupID: UInt
    
    /// POSIX file permissions
    public let posixPermissions: UInt16
    
    /// Type of the file (file, directory, symbolic link, etc.)
    public let fileType: String?
    
    /// File system flags
    public let flags: UInt
    
    /// Extended attributes as name-value pairs
    public let extendedAttributes: [String: ExtendedAttributeDTO]?
    
    /**
     Creates a new file metadata DTO.
     
     - Parameters:
        - size: Size of the file in bytes
        - creationDate: Date when the file was created
        - modificationDate: Date when the file was last modified
        - accessDate: Date when the file was last accessed (optional)
        - ownerID: Owner ID of the file
        - groupID: Group ID of the file
        - posixPermissions: POSIX file permissions
        - fileType: Type of the file (optional)
        - flags: File system flags
        - extendedAttributes: Extended attributes (optional)
     */
    public init(
        size: UInt64,
        creationDate: Date,
        modificationDate: Date,
        accessDate: Date? = nil,
        ownerID: UInt,
        groupID: UInt,
        posixPermissions: UInt16,
        fileType: String? = nil,
        flags: UInt = 0,
        extendedAttributes: [String: ExtendedAttributeDTO]? = nil
    ) {
        self.size = size
        self.creationDate = creationDate
        self.modificationDate = modificationDate
        self.accessDate = accessDate
        self.ownerID = ownerID
        self.groupID = groupID
        self.posixPermissions = posixPermissions
        self.fileType = fileType
        self.flags = flags
        self.extendedAttributes = extendedAttributes
    }
    
    /**
     Creates a file metadata DTO from Foundation file attributes.
     
     - Parameter attributes: Foundation file attributes dictionary
     - Returns: A file metadata DTO, or nil if required attributes are missing
     */
    public static func from(attributes: [FileAttributeKey: Any]) -> FileMetadataDTO? {
        guard
            let size = attributes[.size] as? UInt64,
            let creationDate = attributes[.creationDate] as? Date,
            let modificationDate = attributes[.modificationDate] as? Date
        else {
            return nil
        }
        
        return FileMetadataDTO(
            size: size,
            creationDate: creationDate,
            modificationDate: modificationDate,
            accessDate: attributes[.modificationDate] as? Date,
            ownerID: attributes[.ownerAccountID] as? UInt ?? 0,
            groupID: attributes[.groupOwnerAccountID] as? UInt ?? 0,
            posixPermissions: attributes[.posixPermissions] as? UInt16 ?? 0,
            fileType: attributes[.type] as? String,
            flags: 0
        )
    }
}
