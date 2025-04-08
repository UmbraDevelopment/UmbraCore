import FileSystemInterfaces
import FileSystemTypes
import Foundation

/**
 # FilePathServiceImpl

 Implementation of the FilePathServiceProtocol that provides comprehensive
 file path operations while abstracting away Foundation dependencies.

 This service follows the Alpha Dot Five architecture principles by providing
 a clear separation between interface and implementation, and ensuring thread
 safety through actor isolation.

 ## Thread Safety

 This implementation is an actor, ensuring all operations are thread-safe
 and can be safely called from multiple concurrent contexts.

 ## British Spelling

 This implementation uses British spelling conventions where appropriate
 in documentation and public-facing elements.
 */
public actor FilePathServiceImpl: FilePathServiceProtocol {
  /// The file manager used for file system operations
  private let fileManager: FileManager

  /// The application bundle identifier
  private let bundleIdentifier: String

  /**
   Initialises a new file path service with the specified configuration.

   - Parameters:
      - fileManager: The file manager to use for file system operations
      - bundleIdentifier: The application bundle identifier
   */
  public init(
    fileManager: FileManager = .default,
    bundleIdentifier: String=Bundle.main.bundleIdentifier ?? "com.umbra.core"
  ) {
    self.fileManager=fileManager
    self.bundleIdentifier=bundleIdentifier
  }

  /**
   Creates a secure path from a string.

   - Parameters:
      - path: The path string
      - isDirectory: Whether the path represents a directory
   - Returns: A secure path, or nil if the path is invalid
   */
  public func createPath(from path: String, isDirectory: Bool) -> SecurePath? {
    SecurePath(path: path, isDirectory: isDirectory)
  }

  /**
   Creates a secure path by joining components.

   - Parameters:
      - base: The base path
      - components: The components to append
   - Returns: A secure path with the components appended
   */
  public func joinPath(_ base: SecurePath, _ components: String...) -> SecurePath? {
    joinPath(base, components)
  }

  /**
   Creates a secure path by joining components.

   - Parameters:
      - base: The base path
      - components: The components to append
   - Returns: A secure path with the components appended
   */
  public func joinPath(_ base: SecurePath, _ components: [String]) -> SecurePath? {
    base.appendingComponents(components)
  }

  /**
   Determines if a path exists in the file system.

   - Parameter path: The path to check
   - Returns: true if the path exists, false otherwise
   */
  public func exists(_ path: SecurePath) -> Bool {
    fileManager.fileExists(atPath: path.toString())
  }

  /**
   Determines if a path is a directory.

   - Parameter path: The path to check
   - Returns: true if the path is a directory, false otherwise
   */
  public func isDirectory(_ path: SecurePath) -> Bool {
    var isDir: ObjCBool=false
    let exists=fileManager.fileExists(atPath: path.toString(), isDirectory: &isDir)
    return exists && isDir.boolValue
  }

  /**
   Determines if a path is a regular file.

   - Parameter path: The path to check
   - Returns: true if the path is a regular file, false otherwise
   */
  public func isFile(_ path: SecurePath) -> Bool {
    var isDir: ObjCBool=false
    let exists=fileManager.fileExists(atPath: path.toString(), isDirectory: &isDir)
    return exists && !isDir.boolValue
  }

  /**
   Returns the parent directory of a path.

   - Parameter path: The path to get the parent of
   - Returns: The parent directory path
   */
  public func parentDirectory(of path: SecurePath) -> SecurePath? {
    path.deletingLastComponent()
  }

  /**
   Returns the last component of a path.

   - Parameter path: The path to get the last component of
   - Returns: The last path component
   */
  public func lastComponent(of path: SecurePath) -> String {
    path.lastComponent()
  }

  /**
   Returns the file extension of a path.

   - Parameter path: The path to get the extension of
   - Returns: The file extension, or nil if there is none
   */
  public func fileExtension(of path: SecurePath) -> String? {
    path.fileExtension()
  }

  /**
   Returns a path with the file extension changed.

   - Parameters:
      - path: The path to change the extension of
      - extension: The new file extension
   - Returns: A path with the extension changed
   */
  public func changingFileExtension(of path: SecurePath, to extension: String) -> SecurePath? {
    path.changingFileExtension(to: `extension`)
  }

  /**
   Creates a path to a temporary directory.

   - Returns: A path to a temporary directory
   */
  public func temporaryDirectory() -> SecurePath {
    SecurePath.temporaryDirectory()
  }

  /**
   Creates a path to a unique temporary file.

   - Parameter extension: Optional file extension
   - Returns: A path to a unique temporary file
   */
  public func uniqueTemporaryFile(extension: String?=nil) -> SecurePath {
    SecurePath.uniqueTemporaryFile(extension: `extension`)
  }

  /**
   Creates a security bookmark for a path.

   - Parameter path: The path to create a bookmark for
   - Returns: A path with the bookmark data attached
   */
  public func createSecurityBookmark(for path: SecurePath) -> SecurePath? {
    path.creatingSecurityBookmark()
  }

  /**
   Resolves a security bookmark.

   - Parameter path: The path with bookmark data
   - Returns: A resolved path
   */
  public func resolveSecurityBookmark(_ path: SecurePath) -> SecurePath? {
    // The bookmark is already resolved in the SecurePath implementation
    path
  }

  /**
   Starts accessing a security-scoped resource.

   - Parameter path: The path to access
   - Returns: true if access was granted, false otherwise
   */
  public func startAccessingSecurityScopedResource(_ path: SecurePath) -> Bool {
    path.startAccessingSecurityScopedResource()
  }

  /**
   Stops accessing a security-scoped resource.

   - Parameter path: The path to stop accessing
   */
  public func stopAccessingSecurityScopedResource(_ path: SecurePath) {
    path.stopAccessingSecurityScopedResource()
  }

  /**
   Returns the home directory path.

   - Returns: The home directory path
   */
  public func homeDirectory() -> SecurePath {
    let homePath=NSHomeDirectory()
    return SecurePath(path: homePath, isDirectory: true)!
  }

  /**
   Returns the current working directory path.

   - Returns: The current working directory path
   */
  public func currentDirectory() -> SecurePath {
    let currentPath=fileManager.currentDirectoryPath
    return SecurePath(path: currentPath, isDirectory: true)!
  }

  /**
   Returns the path to a system directory.

   - Parameter directory: The system directory to locate
   - Returns: The path to the system directory
   */
  public func systemDirectory(_ directory: SystemDirectory) -> SecurePath {
    switch directory {
      case .home:
        return homeDirectory()

      case .temporary:
        return temporaryDirectory()

      case .applicationBundle:
        if let bundleURL=Bundle.main.bundleURL {
          return SecurePath(url: bundleURL, securityLevel: .standard)!
        } else {
          // Fallback to the current directory if bundle URL is not available
          return currentDirectory()
        }

      default:
        if let foundationDir=directory.foundationDirectory {
          let urls=fileManager.urls(for: foundationDir, in: .userDomainMask)
          if let url=urls.first {
            return SecurePath(url: url, securityLevel: .standard)!
          }
        }

        // Fallback to the home directory if the system directory is not available
        return homeDirectory()
    }
  }
}
