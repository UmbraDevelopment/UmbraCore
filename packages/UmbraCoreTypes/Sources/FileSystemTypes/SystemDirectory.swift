import Foundation

/**
 # SystemDirectory
 
 Represents system directories that can be accessed through the FilePathService.
 This enum abstracts away Foundation's FileManager.SearchPathDirectory to provide
 a more focused set of directories relevant to the application.
 
 ## Thread Safety
 
 This type is designed to be thread-safe and can be safely used across
 actor boundaries as it conforms to Sendable.
 
 ## British Spelling
 
 This implementation uses British spelling conventions where appropriate
 in documentation and public-facing elements.
 */
public enum SystemDirectory: String, Sendable, Codable, CaseIterable {
    /// The user's documents directory
    case documents
    
    /// The user's downloads directory
    case downloads
    
    /// The user's desktop directory
    case desktop
    
    /// The user's application support directory
    case applicationSupport
    
    /// The user's caches directory
    case caches
    
    /// The user's temporary directory
    case temporary
    
    /// The user's library directory
    case library
    
    /// The application's bundle directory
    case applicationBundle
    
    /// The user's home directory
    case home
    
    /// The system's applications directory
    case applications
    
    /// The user's pictures directory
    case pictures
    
    /// The user's movies directory
    case movies
    
    /// The user's music directory
    case music
    
    /// Maps this enum to the corresponding Foundation search path directory
    internal var foundationDirectory: FileManager.SearchPathDirectory? {
        switch self {
        case .documents:
            return .documentDirectory
        case .downloads:
            return .downloadsDirectory
        case .desktop:
            return .desktopDirectory
        case .applicationSupport:
            return .applicationSupportDirectory
        case .caches:
            return .cachesDirectory
        case .library:
            return .libraryDirectory
        case .applicationBundle:
            return nil // Special case, handled separately
        case .home:
            return nil // Special case, handled separately
        case .applications:
            return .applicationDirectory
        case .pictures:
            return .picturesDirectory
        case .movies:
            return .moviesDirectory
        case .music:
            return .musicDirectory
        case .temporary:
            return nil // Special case, handled separately
        }
    }
    
    /// Returns a human-readable description of this directory
    public var description: String {
        switch self {
        case .documents:
            return "Documents Directory"
        case .downloads:
            return "Downloads Directory"
        case .desktop:
            return "Desktop Directory"
        case .applicationSupport:
            return "Application Support Directory"
        case .caches:
            return "Caches Directory"
        case .temporary:
            return "Temporary Directory"
        case .library:
            return "Library Directory"
        case .applicationBundle:
            return "Application Bundle Directory"
        case .home:
            return "Home Directory"
        case .applications:
            return "Applications Directory"
        case .pictures:
            return "Pictures Directory"
        case .movies:
            return "Movies Directory"
        case .music:
            return "Music Directory"
        }
    }
}
