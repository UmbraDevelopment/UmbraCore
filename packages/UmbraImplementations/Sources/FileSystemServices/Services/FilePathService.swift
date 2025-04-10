import FileSystemInterfaces
import Foundation

/**
 # File Path Service Protocol

 Defines operations for manipulating file paths in a platform-appropriate way.
 */
public protocol FilePathServiceProtocol {
  /**
   Joins multiple path components together.

   - Parameters:
      - components: The path components to join.
   - Returns: A path with the components joined.
   */
  func join(_ components: String...) -> String

  /**
   Normalises a file path according to system rules.

   - Parameter path: The path to normalise.
   - Returns: The normalised path.
   */
  func normalise(_ path: String) -> String

  /**
   Validates that a path is within a specified root directory.

   - Parameters:
      - path: The path to validate.
      - rootDirectory: The root directory that should contain the path.
   - Returns: Whether the path is within the root directory.
   */
  func isPathWithinRoot(_ path: String, rootDirectory: String) -> Bool
}

/**
 # File Path Service

 Implementation of FilePathServiceProtocol that handles path operations
 according to the platform standards.

 ## Alpha Dot Five Architecture

 This actor follows the Alpha Dot Five architecture principles:
 - Uses immutable value types where appropriate
 - Provides clear error handling
 - Uses British spelling in documentation
 */
public actor FilePathService: FilePathServiceProtocol {

  /// Initialises a new file path service.
  public init() {}

  public func join(_ components: String...) -> String {
    let path = NSString.path(withComponents: components) as String
    return (path as NSString).standardizingPath
  }

  public func normalise(_ path: String) -> String {
    (path as NSString).standardizingPath
  }

  public func isPathWithinRoot(_ path: String, rootDirectory: String) -> Bool {
    let normalizedPath = normalise(path)
    let normalizedRoot = normalise(rootDirectory)

    // Ensure root ends with a path separator
    let rootWithSeparator = normalizedRoot.hasSuffix("/") ? normalizedRoot : normalizedRoot + "/"

    // Check if the normalized path starts with the normalized root
    // This ensures that "/root/path" is contained within "/root" but "/root-other" is not
    return normalizedPath.hasPrefix(rootWithSeparator) || normalizedPath == normalizedRoot
  }
}
