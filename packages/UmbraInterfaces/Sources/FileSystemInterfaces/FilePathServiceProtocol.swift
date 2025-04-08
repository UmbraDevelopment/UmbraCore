import FileSystemTypes
import Foundation

/**
 # FilePathServiceProtocol

 Provides a standardised interface for file path operations
 that abstracts away Foundation dependencies.

 This protocol follows the Alpha Dot Five architecture principles
 by providing a clear separation between the interface and implementation,
 allowing for better testability and reduced coupling to Foundation.

 ## Thread Safety

 Implementations of this protocol should be thread-safe and
 suitable for use across actor boundaries.

 ## British Spelling

 This interface uses British spelling conventions where appropriate
 in documentation and public-facing elements.
 */
public protocol FilePathServiceProtocol: Sendable {
  /**
   Creates a secure path from a string.

   - Parameters:
      - path: The path string
      - isDirectory: Whether the path represents a directory
   - Returns: A secure path, or nil if the path is invalid
   */
  func createPath(from path: String, isDirectory: Bool) async -> SecurePath?

  /**
   Creates a secure path by joining components.

   - Parameters:
      - base: The base path
      - components: The components to append
   - Returns: A secure path with the components appended
   */
  func joinPath(_ base: SecurePath, _ components: String...) async -> SecurePath?

  /**
   Creates a secure path by joining components.

   - Parameters:
      - base: The base path
      - components: The components to append
   - Returns: A secure path with the components appended
   */
  func joinPath(_ base: SecurePath, _ components: [String]) async -> SecurePath?

  /**
   Determines if a path exists in the file system.

   - Parameter path: The path to check
   - Returns: true if the path exists, false otherwise
   */
  func exists(_ path: SecurePath) async -> Bool

  /**
   Determines if a path is a directory.

   - Parameter path: The path to check
   - Returns: true if the path is a directory, false otherwise
   */
  func isDirectory(_ path: SecurePath) async -> Bool

  /**
   Determines if a path is a regular file.

   - Parameter path: The path to check
   - Returns: true if the path is a regular file, false otherwise
   */
  func isFile(_ path: SecurePath) async -> Bool

  /**
   Returns the parent directory of a path.

   - Parameter path: The path to get the parent of
   - Returns: The parent directory path
   */
  func parentDirectory(of path: SecurePath) async -> SecurePath?

  /**
   Returns the last component of a path.

   - Parameter path: The path to get the last component of
   - Returns: The last path component
   */
  func lastComponent(of path: SecurePath) async -> String

  /**
   Returns the file extension of a path.

   - Parameter path: The path to get the extension of
   - Returns: The file extension, or nil if there is none
   */
  func fileExtension(of path: SecurePath) async -> String?

  /**
   Returns a path with the file extension changed.

   - Parameters:
      - path: The path to change the extension of
      - extension: The new file extension
   - Returns: A path with the extension changed
   */
  func changingFileExtension(of path: SecurePath, to extension: String) async -> SecurePath?

  /**
   Creates a path to a temporary directory.

   - Returns: A path to a temporary directory
   */
  func temporaryDirectory() async -> SecurePath

  /**
   Creates a path to a unique temporary file.

   - Parameter extension: Optional file extension
   - Returns: A path to a unique temporary file
   */
  func uniqueTemporaryFile(extension: String?) async -> SecurePath

  /**
   Creates a security bookmark for a path.

   - Parameter path: The path to create a bookmark for
   - Returns: A path with the bookmark data attached
   */
  func createSecurityBookmark(for path: SecurePath) async -> SecurePath?

  /**
   Resolves a security bookmark.

   - Parameter path: The path with bookmark data
   - Returns: A resolved path
   */
  func resolveSecurityBookmark(_ path: SecurePath) async -> SecurePath?

  /**
   Starts accessing a security-scoped resource.

   - Parameter path: The path to access
   - Returns: true if access was granted, false otherwise
   */
  func startAccessingSecurityScopedResource(_ path: SecurePath) async -> Bool

  /**
   Stops accessing a security-scoped resource.

   - Parameter path: The path to stop accessing
   */
  func stopAccessingSecurityScopedResource(_ path: SecurePath) async

  /**
   Returns the home directory path.

   - Returns: The home directory path
   */
  func homeDirectory() async -> SecurePath

  /**
   Returns the current working directory path.

   - Returns: The current working directory path
   */
  func currentDirectory() async -> SecurePath

  /**
   Returns the path to a system directory.

   - Parameter directory: The system directory to locate
   - Returns: The path to the system directory
   */
  func systemDirectory(_ directory: SystemDirectory) async -> SecurePath
}
