import Foundation

/**
 # File Move Options
 
 Options for controlling file move operations.
 This type provides a Foundation-independent abstraction for file move
 operations, allowing for consistent behaviour across different implementations.
 
 ## Thread Safety
 
 This type is designed to be thread-safe and can be safely used across
 actor boundaries as it is a value type with no shared state.
 
 ## British Spelling
 
 This implementation uses British spelling conventions where appropriate
 in documentation and public-facing elements.
 */
public struct FileMoveOptions: OptionSet, Sendable, Equatable {
    public let rawValue: UInt
    
    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }
    
    /// Replace the destination file if it already exists
    public static let replaceExisting = FileMoveOptions(rawValue: 1 << 0)
    
    /// Fail if the source file is a directory
    public static let failIfSourceIsDirectory = FileMoveOptions(rawValue: 1 << 1)
    
    /// Fail if the destination file exists and is a directory
    public static let failIfDestinationIsDirectory = FileMoveOptions(rawValue: 1 << 2)
    
    /// Copy file attributes (creation date, modification date, etc.)
    public static let copyAttributes = FileMoveOptions(rawValue: 1 << 3)
    
    /// Perform the move atomically (all-or-nothing)
    public static let atomic = FileMoveOptions(rawValue: 1 << 4)
    
    /**
     Converts to Foundation's FileManager move options.
     
     - Returns: A dictionary of options that can be used with FileManager
     */
    public func toFoundationOptions() -> [FileAttributeKey: Any] {
        let options: [FileAttributeKey: Any] = [:]
        
        // Foundation doesn't have direct equivalents for all our options,
        // but we can map the ones it does support
        
        return options
    }
}
