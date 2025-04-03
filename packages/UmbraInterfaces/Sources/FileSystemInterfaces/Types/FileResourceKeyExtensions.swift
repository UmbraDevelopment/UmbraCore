import Foundation

/**
 Extensions on FileResourceKey to convert between URLResourceKey and FileResourceKey.
 
 These extensions provide bidirectional conversion between the URLResourceKey type
 from Foundation and our custom FileResourceKey type.
 */

extension FileResourceKey {
    /**
     Converts this FileResourceKey to the corresponding URLResourceKey.
     
     - Returns: A URLResourceKey if the conversion is valid, nil otherwise.
     */
    public func toURLResourceKey() -> URLResourceKey? {
        switch self {
        case .creationDate:
            return URLResourceKey.creationDateKey
        case .contentModificationDate:
            return URLResourceKey.contentModificationDateKey
        case .contentAccessDate:
            return URLResourceKey.contentAccessDateKey
        case .contentType:
            return URLResourceKey.contentTypeKey
        case .fileSize:
            return URLResourceKey.fileSizeKey
        case .fileAllocatedSize:
            return URLResourceKey.fileAllocatedSizeKey
        case .isDirectory:
            return URLResourceKey.isDirectoryKey
        case .isSymbolicLink:
            return URLResourceKey.isSymbolicLinkKey
        case .isRegularFile:
            return URLResourceKey.isRegularFileKey
        case .isReadable:
            return URLResourceKey.isReadableKey
        case .isWritable:
            return URLResourceKey.isWritableKey
        case .isExecutable:
            return URLResourceKey.isExecutableKey
        case .isHidden:
            return URLResourceKey.isHiddenKey
        case .filename:
            return URLResourceKey.nameKey
        case .path:
            return URLResourceKey.pathKey
        }
    }
    
    /**
     Initializes a FileResourceKey from a URLResourceKey.
     
     - Parameter urlResourceKey: The URLResourceKey to convert
     - Returns: A corresponding FileResourceKey, or nil if the conversion is not possible
     */
    public init?(fromURLResourceKey urlResourceKey: URLResourceKey) {
        let keyString = urlResourceKey.rawValue
        
        // Map the URLResourceKey to our FileResourceKey
        switch keyString {
        case URLResourceKey.creationDateKey.rawValue:
            self = .creationDate
        case URLResourceKey.contentModificationDateKey.rawValue:
            self = .contentModificationDate
        case URLResourceKey.contentAccessDateKey.rawValue:
            self = .contentAccessDate
        case URLResourceKey.contentTypeKey.rawValue:
            self = .contentType
        case URLResourceKey.fileSizeKey.rawValue:
            self = .fileSize
        case URLResourceKey.fileAllocatedSizeKey.rawValue:
            self = .fileAllocatedSize
        case URLResourceKey.isDirectoryKey.rawValue:
            self = .isDirectory
        case URLResourceKey.isSymbolicLinkKey.rawValue:
            self = .isSymbolicLink
        case URLResourceKey.isRegularFileKey.rawValue:
            self = .isRegularFile
        case URLResourceKey.isReadableKey.rawValue:
            self = .isReadable
        case URLResourceKey.isWritableKey.rawValue:
            self = .isWritable
        case URLResourceKey.isExecutableKey.rawValue:
            self = .isExecutable
        case URLResourceKey.isHiddenKey.rawValue:
            self = .isHidden
        case URLResourceKey.nameKey.rawValue:
            self = .filename
        case URLResourceKey.pathKey.rawValue:
            self = .path
        default:
            // Key not supported
            return nil
        }
    }
}
