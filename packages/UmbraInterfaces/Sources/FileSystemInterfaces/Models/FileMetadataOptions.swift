import Foundation

/**
 # File Metadata Options
 
 Options for controlling how file metadata is retrieved and processed.
 
 ## Alpha Dot Five Architecture
 
 This type follows the Alpha Dot Five architecture principles:
 - Uses immutable structs for thread safety
 - Provides clear, well-documented options
 - Uses British spelling in documentation
 */
public struct FileMetadataOptions: Sendable, Equatable {
    /// Whether to resolve symbolic links when retrieving metadata
    public let resolveSymlinks: Bool
    
    /// Specific attributes to retrieve (if nil, all available attributes are retrieved)
    public let specificAttributes: Set<String>?
    
    /// Whether to retrieve extended attributes
    public let includeExtendedAttributes: Bool
    
    /// Creates new file metadata options
    public init(
        resolveSymlinks: Bool = true,
        specificAttributes: Set<String>? = nil,
        includeExtendedAttributes: Bool = false
    ) {
        self.resolveSymlinks = resolveSymlinks
        self.specificAttributes = specificAttributes
        self.includeExtendedAttributes = includeExtendedAttributes
    }
}
