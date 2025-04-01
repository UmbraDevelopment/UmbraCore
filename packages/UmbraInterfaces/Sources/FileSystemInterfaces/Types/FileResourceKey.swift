import Foundation

/**
 Represents resource keys for file system items.
 
 This enumeration defines the resource keys that can be used to retrieve
 specific information about files in the file system, providing a type-safe
 way to access file metadata.
 */
public enum FileResourceKey: String, Sendable, Hashable, Equatable, CaseIterable {
    /// Creation date resource key
    case creationDate = "NSURLCreationDateKey"
    
    /// Content modification date resource key
    case contentModificationDate = "NSURLContentModificationDateKey"
    
    /// Content access date resource key
    case contentAccessDate = "NSURLContentAccessDateKey"
    
    /// Content type resource key
    case contentType = "NSURLContentTypeKey"
    
    /// File size resource key
    case fileSize = "NSURLFileSizeKey"
    
    /// File allocation size resource key
    case fileAllocatedSize = "NSURLFileAllocatedSizeKey"
    
    /// Whether the item is a directory
    case isDirectory = "NSURLIsDirectoryKey"
    
    /// Whether the item is a symbolic link
    case isSymbolicLink = "NSURLIsSymbolicLinkKey"
    
    /// Whether the item is regular file
    case isRegularFile = "NSURLIsRegularFileKey"
    
    /// Whether the item is readable
    case isReadable = "NSURLIsReadableKey"
    
    /// Whether the item is writable
    case isWritable = "NSURLIsWritableKey"
    
    /// Whether the item is executable
    case isExecutable = "NSURLIsExecutableKey"
    
    /// Whether the item is hidden
    case isHidden = "NSURLIsHiddenKey"
    
    /// The item's filename
    case filename = "NSURLNameKey"
    
    /// The item's path
    case path = "NSURLPathKey"
    
    /// Returns a human-readable localised description of the resource key
    public var localisedDescription: String {
        switch self {
        case .creationDate:
            return "Creation Date"
        case .contentModificationDate:
            return "Modification Date"
        case .contentAccessDate:
            return "Access Date"
        case .contentType:
            return "Content Type"
        case .fileSize:
            return "File Size"
        case .fileAllocatedSize:
            return "Allocated Size"
        case .isDirectory:
            return "Is Directory"
        case .isSymbolicLink:
            return "Is Symbolic Link"
        case .isRegularFile:
            return "Is Regular File"
        case .isReadable:
            return "Is Readable"
        case .isWritable:
            return "Is Writable"
        case .isExecutable:
            return "Is Executable"
        case .isHidden:
            return "Is Hidden"
        case .filename:
            return "Filename"
        case .path:
            return "Path"
        }
    }
}
