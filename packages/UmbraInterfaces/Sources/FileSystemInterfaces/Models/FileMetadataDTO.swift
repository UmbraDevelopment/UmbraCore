import Foundation

/**
 # File Metadata DTO
 
 Encapsulates metadata information for files and directories.
 
 This DTO provides a consistent structure for file metadata across
 the system, improving information flow and reducing coupling.
 
 ## Alpha Dot Five Architecture
 
 This type follows the Alpha Dot Five architecture principles:
 - Uses immutable struct for thread safety
 - Implements Sendable for concurrency safety
 - Provides comprehensive metadata
 - Uses British spelling in documentation
 */
public struct FileMetadataDTO: Sendable {
    /// File size in bytes
    public let size: UInt64
    
    /// File creation date
    public let creationDate: Date
    
    /// Last modification date
    public let modificationDate: Date
    
    /// Last access date
    public let lastAccessDate: Date
    
    /// Whether the path is a directory
    public let isDirectory: Bool
    
    /// Whether the path is a regular file
    public let isRegularFile: Bool
    
    /// Whether the path is a symbolic link
    public let isSymbolicLink: Bool
    
    /// File extension, if any
    public let fileExtension: String?
    
    /// POSIX permissions
    public let posixPermissions: Int16
    
    /// File owner ID
    public let ownerID: Int
    
    /// File group ID
    public let groupID: Int
    
    /// Extended attributes, if any
    public let extendedAttributes: [String: Data]?
    
    /// File resource values
    public let resourceValues: [URLResourceKey: Any]?
    
    /// Creates a new file metadata object
    public init(
        size: UInt64,
        creationDate: Date,
        modificationDate: Date,
        lastAccessDate: Date,
        isDirectory: Bool,
        isRegularFile: Bool,
        isSymbolicLink: Bool,
        fileExtension: String?,
        posixPermissions: Int16,
        ownerID: Int,
        groupID: Int,
        extendedAttributes: [String: Data]? = nil,
        resourceValues: [URLResourceKey: Any]? = nil
    ) {
        self.size = size
        self.creationDate = creationDate
        self.modificationDate = modificationDate
        self.lastAccessDate = lastAccessDate
        self.isDirectory = isDirectory
        self.isRegularFile = isRegularFile
        self.isSymbolicLink = isSymbolicLink
        self.fileExtension = fileExtension
        self.posixPermissions = posixPermissions
        self.ownerID = ownerID
        self.groupID = groupID
        self.extendedAttributes = extendedAttributes
        self.resourceValues = resourceValues
    }
    
    /// Creates a file metadata object from FileManager attributes
    public static func from(
        attributes: [FileAttributeKey: Any],
        path: String,
        extendedAttributes: [String: Data]? = nil,
        resourceValues: [URLResourceKey: Any]? = nil
    ) -> FileMetadataDTO {
        let fileSize = (attributes[.size] as? NSNumber)?.uint64Value ?? 0
        let creationDate = attributes[.creationDate] as? Date ?? Date.distantPast
        let modificationDate = attributes[.modificationDate] as? Date ?? Date.distantPast
        let accessDate = attributes[.modificationDate] as? Date ?? Date.distantPast
        
        let fileType = attributes[.type] as? String
        let isDirectory = fileType == FileAttributeType.typeDirectory.rawValue
        let isRegularFile = fileType == FileAttributeType.typeRegular.rawValue
        let isSymbolicLink = fileType == FileAttributeType.typeSymbolicLink.rawValue
        
        let posixPermissions = (attributes[.posixPermissions] as? NSNumber)?.int16Value ?? 0
        let ownerID = (attributes[.ownerAccountID] as? NSNumber)?.intValue ?? 0
        let groupID = (attributes[.groupOwnerAccountID] as? NSNumber)?.intValue ?? 0
        
        let fileExtension = URL(fileURLWithPath: path).pathExtension.isEmpty ? nil : URL(fileURLWithPath: path).pathExtension
        
        return FileMetadataDTO(
            size: fileSize,
            creationDate: creationDate,
            modificationDate: modificationDate,
            lastAccessDate: accessDate,
            isDirectory: isDirectory,
            isRegularFile: isRegularFile,
            isSymbolicLink: isSymbolicLink,
            fileExtension: fileExtension,
            posixPermissions: posixPermissions,
            ownerID: ownerID,
            groupID: groupID,
            extendedAttributes: extendedAttributes,
            resourceValues: resourceValues
        )
    }
}

// MARK: - Equatable Implementation

// Manual implementation of Equatable since resourceValues contains non-Equatable types
extension FileMetadataDTO: Equatable {
    public static func == (lhs: FileMetadataDTO, rhs: FileMetadataDTO) -> Bool {
        // Compare scalar properties
        guard lhs.size == rhs.size,
              lhs.creationDate == rhs.creationDate,
              lhs.modificationDate == rhs.modificationDate,
              lhs.lastAccessDate == rhs.lastAccessDate,
              lhs.isDirectory == rhs.isDirectory,
              lhs.isRegularFile == rhs.isRegularFile,
              lhs.isSymbolicLink == rhs.isSymbolicLink,
              lhs.fileExtension == rhs.fileExtension,
              lhs.posixPermissions == rhs.posixPermissions,
              lhs.ownerID == rhs.ownerID,
              lhs.groupID == rhs.groupID else {
            return false
        }
        
        // Compare extended attributes
        if let lhsEA = lhs.extendedAttributes, let rhsEA = rhs.extendedAttributes {
            if lhsEA != rhsEA {
                return false
            }
        } else if lhs.extendedAttributes != nil || rhs.extendedAttributes != nil {
            return false
        }
        
        // For resourceValues, we can only do a basic comparison of keys
        // since the values aren't necessarily Equatable
        if let lhsRV = lhs.resourceValues, let rhsRV = rhs.resourceValues {
            let lhsKeys = Set(lhsRV.keys)
            let rhsKeys = Set(rhsRV.keys)
            if lhsKeys != rhsKeys {
                return false
            }
            
            // For values, we'll compare what we can and use string descriptions for the rest
            for key in lhsKeys {
                let lhsValue = lhsRV[key]
                let rhsValue = rhsRV[key]
                
                // Handle specific known types
                if let lhsInt = lhsValue as? Int, let rhsInt = rhsValue as? Int {
                    if lhsInt != rhsInt { return false }
                } else if let lhsString = lhsValue as? String, let rhsString = rhsValue as? String {
                    if lhsString != rhsString { return false }
                } else if let lhsDate = lhsValue as? Date, let rhsDate = rhsValue as? Date {
                    if lhsDate != rhsDate { return false }
                } else if let lhsBool = lhsValue as? Bool, let rhsBool = rhsValue as? Bool {
                    if lhsBool != rhsBool { return false }
                } else if let lhsData = lhsValue as? Data, let rhsData = rhsValue as? Data {
                    if lhsData != rhsData { return false }
                } else {
                    // For non-Equatable types, compare string descriptions
                    if String(describing: lhsValue) != String(describing: rhsValue) {
                        return false
                    }
                }
            }
        } else if lhs.resourceValues != nil || rhs.resourceValues != nil {
            return false
        }
        
        return true
    }
}
