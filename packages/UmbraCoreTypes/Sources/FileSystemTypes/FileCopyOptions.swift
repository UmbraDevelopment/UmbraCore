import Foundation

/**
 # File Copy Options
 
 Options for controlling file copy operations.
 This type provides a Foundation-independent abstraction for file copy
 operations, allowing for consistent behaviour across different implementations.
 
 ## Thread Safety
 
 This type is designed to be thread-safe and can be safely used across
 actor boundaries as it is a value type with no shared state.
 
 ## British Spelling
 
 This implementation uses British spelling conventions where appropriate
 in documentation and public-facing elements.
 */
public struct FileCopyOptions: OptionSet, Sendable, Equatable {
    public let rawValue: UInt
    
    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }
    
    /// Replace the destination file if it already exists
    public static let replaceExisting = FileCopyOptions(rawValue: 1 << 0)
    
    /// Fail if the source file is a directory
    public static let failIfSourceIsDirectory = FileCopyOptions(rawValue: 1 << 1)
    
    /// Fail if the destination file exists and is a directory
    public static let failIfDestinationIsDirectory = FileCopyOptions(rawValue: 1 << 2)
    
    /// Copy file attributes (creation date, modification date, etc.)
    public static let copyAttributes = FileCopyOptions(rawValue: 1 << 3)
    
    /// Follow symbolic links when copying
    public static let followSymlinks = FileCopyOptions(rawValue: 1 << 4)
    
    /// Skip files that cannot be read
    public static let skipUnreadableFiles = FileCopyOptions(rawValue: 1 << 5)
    
    /**
     Converts to Foundation's FileManager copy options.
     
     - Returns: A dictionary of options that can be used with FileManager
     */
    public func toFoundationOptions() -> [FileAttributeKey: Any] {
        let options: [FileAttributeKey: Any] = [:]
        
        // Foundation doesn't have direct equivalents for all our options,
        // but we can map the ones it does support
        
        return options
    }
}
