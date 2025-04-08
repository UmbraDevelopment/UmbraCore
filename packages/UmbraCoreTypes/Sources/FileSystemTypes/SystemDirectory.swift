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
  var foundationDirectory: FileManager.SearchPathDirectory? {
    switch self {
      case .documents:
        .documentDirectory
      case .downloads:
        .downloadsDirectory
      case .desktop:
        .desktopDirectory
      case .applicationSupport:
        .applicationSupportDirectory
      case .caches:
        .cachesDirectory
      case .library:
        .libraryDirectory
      case .applicationBundle:
        nil // Special case, handled separately
      case .home:
        nil // Special case, handled separately
      case .applications:
        .applicationDirectory
      case .pictures:
        .picturesDirectory
      case .movies:
        .moviesDirectory
      case .music:
        .musicDirectory
      case .temporary:
        nil // Special case, handled separately
    }
  }

  /// Returns a human-readable description of this directory
  public var description: String {
    switch self {
      case .documents:
        "Documents Directory"
      case .downloads:
        "Downloads Directory"
      case .desktop:
        "Desktop Directory"
      case .applicationSupport:
        "Application Support Directory"
      case .caches:
        "Caches Directory"
      case .temporary:
        "Temporary Directory"
      case .library:
        "Library Directory"
      case .applicationBundle:
        "Application Bundle Directory"
      case .home:
        "Home Directory"
      case .applications:
        "Applications Directory"
      case .pictures:
        "Pictures Directory"
      case .movies:
        "Movies Directory"
      case .music:
        "Music Directory"
    }
  }
}
