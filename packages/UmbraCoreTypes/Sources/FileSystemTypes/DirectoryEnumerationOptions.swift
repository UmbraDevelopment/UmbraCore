import Foundation

/**
 # Directory Enumeration Options
 
 Options for controlling directory enumeration behaviour.
 This type provides a Foundation-independent abstraction for directory
 enumeration options, allowing for consistent behaviour across different
 implementations.
 
 ## Thread Safety
 
 This type is designed to be thread-safe and can be safely used across
 actor boundaries as it is a value type with no shared state.
 
 ## British Spelling
 
 This implementation uses British spelling conventions where appropriate
 in documentation and public-facing elements.
 */
public struct DirectoryEnumerationOptions: OptionSet, Sendable, Equatable {
    public let rawValue: UInt
    
    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }
    
    /// Skip hidden files (those that begin with a period)
    public static let skipsHiddenFiles = DirectoryEnumerationOptions(rawValue: 1 << 0)
    
    /// Skip package contents (such as .app bundles)
    public static let skipsPackageDescendants = DirectoryEnumerationOptions(rawValue: 1 << 1)
    
    /// Skip subdirectories encountered during enumeration
    public static let skipsSubdirectoryDescendants = DirectoryEnumerationOptions(rawValue: 1 << 2)
    
    /**
     Converts to Foundation's FileManager.DirectoryEnumerationOptions.
     
     - Returns: The equivalent FileManager.DirectoryEnumerationOptions
     */
    public func toFoundationOptions() -> FileManager.DirectoryEnumerationOptions {
        var options: FileManager.DirectoryEnumerationOptions = []
        
        if contains(.skipsHiddenFiles) {
            options.insert(.skipsHiddenFiles)
        }
        
        if contains(.skipsPackageDescendants) {
            options.insert(.skipsPackageDescendants)
        }
        
        if contains(.skipsSubdirectoryDescendants) {
            options.insert(.skipsSubdirectoryDescendants)
        }
        
        return options
    }
    
    /**
     Creates DirectoryEnumerationOptions from Foundation's FileManager.DirectoryEnumerationOptions.
     
     - Parameter foundationOptions: The FileManager.DirectoryEnumerationOptions to convert
     - Returns: The equivalent DirectoryEnumerationOptions
     */
    public static func fromFoundationOptions(_ foundationOptions: FileManager.DirectoryEnumerationOptions) -> DirectoryEnumerationOptions {
        var options: DirectoryEnumerationOptions = []
        
        if foundationOptions.contains(.skipsHiddenFiles) {
            options.insert(.skipsHiddenFiles)
        }
        
        if foundationOptions.contains(.skipsPackageDescendants) {
            options.insert(.skipsPackageDescendants)
        }
        
        if foundationOptions.contains(.skipsSubdirectoryDescendants) {
            options.insert(.skipsSubdirectoryDescendants)
        }
        
        return options
    }
}
