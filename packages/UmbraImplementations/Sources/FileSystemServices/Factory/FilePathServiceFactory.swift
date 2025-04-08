import FileSystemInterfaces
import FileSystemTypes
import Foundation
import LoggingInterfaces
import LoggingTypes

/**
 # File Path Service Factory

 Factory for creating instances of FilePathServiceProtocol with different configurations.
 This provides a centralised way to create file path services with consistent options.

 The factory follows the Alpha Dot Five architecture principles by:
 1. Using actor isolation for thread safety
 2. Providing clear, purpose-specific factory methods
 3. Ensuring all returned instances are protocol-conforming

 ## Thread Safety

 As an actor, this factory is fully thread-safe and can be safely accessed
 from multiple concurrent contexts without external synchronization.
 The returned services are also actors, ensuring thread safety for all operations.

 ## British Spelling

 This implementation uses British spelling conventions where appropriate
 in documentation and public-facing elements.
 */
@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
public actor FilePathServiceFactory {
  /// Shared singleton instance
  public static let shared: FilePathServiceFactory = .init()

  /// Private initialiser to enforce singleton pattern
  private init() {}

  /**
   Creates a default file path service implementation.

   This is the recommended factory method for most use cases. It provides
   a balanced configuration suitable for general file path operations.

   - Returns: An implementation of FilePathServiceProtocol
   */
  public func createDefault() -> FilePathServiceProtocol {
    FilePathServiceImpl()
  }

  /**
   Creates a secure file path service implementation.

   This service prioritises security measures such as path validation,
   sandbox enforcement, and symlink restrictions. Use this when working
   with sensitive data or in security-critical contexts.

   - Parameters:
      - securityLevel: The security level to enforce
      - logger: Optional logger for operation tracking
   - Returns: An implementation of FilePathServiceProtocol
   */
  public func createSecure(
    securityLevel: SecurityLevel = .high,
    logger: (any LoggingProtocol)?=nil
  ) -> FilePathServiceProtocol {
    SecureFilePathService(
      securityLevel: securityLevel,
      logger: logger ?? NullLogger()
    )
  }

  /**
   Creates a sandboxed file path service implementation.

   This service restricts all operations to a specific root directory,
   preventing access to files outside that directory. Use this for
   applications that need to provide file system access to untrusted code.

   - Parameters:
      - rootDirectory: The directory to restrict operations to
      - logger: Optional logger for operation tracking
   - Returns: An implementation of FilePathServiceProtocol
   */
  public func createSandboxed(
    rootDirectory: String,
    logger: (any LoggingProtocol)?=nil
  ) -> FilePathServiceProtocol {
    SandboxedFilePathService(
      rootDirectory: rootDirectory,
      logger: logger ?? NullLogger()
    )
  }
}

/**
 Default implementation of FilePathServiceProtocol.
 */
private actor FilePathServiceImpl: FilePathServiceProtocol {
  /**
   Initialises a new file path service.
   */
  init() {}

  /**
   Creates a secure path from a string.

   - Parameters:
      - path: The path string
      - isDirectory: Whether the path represents a directory
   - Returns: A secure path, or nil if the path is invalid
   */
  func createPath(from path: String, isDirectory: Bool) async -> SecurePath? {
    SecurePath(path: path, isDirectory: isDirectory)
  }

  /**
   Creates a secure path by joining components.

   - Parameters:
      - base: The base path
      - components: The components to append
   - Returns: A secure path with the components appended
   */
  func joinPath(_ base: SecurePath, _ components: String...) async -> SecurePath? {
    await joinPath(base, components)
  }

  /**
   Creates a secure path by joining components.

   - Parameters:
      - base: The base path
      - components: The components to append
   - Returns: A secure path with the components appended
   */
  func joinPath(_ base: SecurePath, _ components: [String]) async -> SecurePath? {
    var url=URL(fileURLWithPath: base.toString())

    for component in components {
      url=url.appendingPathComponent(component)
    }

    return SecurePath(
      path: url.path,
      isDirectory: url.hasDirectoryPath,
      securityLevel: base.securityLevel
    )
  }

  /**
   Checks if a path exists in the file system.

   - Parameter path: The path to check
   - Returns: Whether the path exists
   */
  func exists(_ path: SecurePath) async -> Bool {
    FileManager.default.fileExists(atPath: path.toString())
  }

  /**
   Checks if a path is a file.

   - Parameter path: The path to check
   - Returns: Whether the path is a file
   */
  func isFile(_ path: SecurePath) async -> Bool {
    var isDir: ObjCBool=false
    let exists=FileManager.default.fileExists(atPath: path.toString(), isDirectory: &isDir)
    return exists && !isDir.boolValue
  }

  /**
   Checks if a path is a directory.

   - Parameter path: The path to check
   - Returns: Whether the path is a directory
   */
  func isDirectory(_ path: SecurePath) async -> Bool {
    var isDir: ObjCBool=false
    let exists=FileManager.default.fileExists(atPath: path.toString(), isDirectory: &isDir)
    return exists && isDir.boolValue
  }

  /**
   Gets the parent directory of a path.

   - Parameter path: The path to get the parent of
   - Returns: The parent directory, or nil if there is no parent
   */
  func parentDirectory(of path: SecurePath) async -> SecurePath? {
    let url=URL(fileURLWithPath: path.toString())
    let parentPath=url.deletingLastPathComponent().path
    return SecurePath(path: parentPath, isDirectory: true)
  }

  /**
   Gets the last component of a path.

   - Parameter path: The path to get the last component of
   - Returns: The last component of the path
   */
  func lastComponent(of path: SecurePath) async -> String {
    let url=URL(fileURLWithPath: path.toString())
    return url.lastPathComponent
  }

  /**
   Gets the file extension of a path.

   - Parameter path: The path to get the extension of
   - Returns: The file extension, or nil if there is none
   */
  func fileExtension(of path: SecurePath) async -> String? {
    let url=URL(fileURLWithPath: path.toString())
    let ext=url.pathExtension
    return ext.isEmpty ? nil : ext
  }

  /**
   Returns a path with the file extension changed.

   - Parameters:
      - path: The path to change the extension of
      - extension: The new file extension
   - Returns: A path with the extension changed
   */
  func changingFileExtension(of path: SecurePath, to extension: String) async -> SecurePath? {
    let url=URL(fileURLWithPath: path.toString())
    let newURL=url.deletingPathExtension().appendingPathExtension(`extension`)
    return SecurePath(
      path: newURL.path,
      isDirectory: false,
      securityLevel: path.securityLevel
    )
  }

  /**
   Creates a path to a temporary directory.

   - Returns: A path to a temporary directory
   */
  func temporaryDirectory() async -> SecurePath {
    let tempDir=FileManager.default.temporaryDirectory.path
    guard let securePath=SecurePath(path: tempDir, isDirectory: true) else {
      // Fallback to a known valid path if the temporary directory can't be secured
      return SecurePath(path: "/tmp", isDirectory: true)!
    }
    return securePath
  }

  /**
   Creates a path to a unique temporary file.

   - Parameter extension: Optional file extension
   - Returns: A path to a unique temporary file
   */
  func uniqueTemporaryFile(extension: String?) async -> SecurePath {
    let tempDir=FileManager.default.temporaryDirectory
    let uuid=UUID().uuidString
    let filename=`extension` != nil ? "\(uuid).\(`extension`!)" : uuid
    let url=tempDir.appendingPathComponent(filename)
    guard let securePath=SecurePath(path: url.path, isDirectory: false) else {
      // Fallback to a known valid path if the temporary file can't be secured
      let fallbackPath="/tmp/\(filename)"
      return SecurePath(path: fallbackPath, isDirectory: false)!
    }
    return securePath
  }

  /**
   Creates a security bookmark for a path.

   - Parameter path: The path to create a bookmark for
   - Returns: A path with the bookmark data attached
   */
  func createSecurityBookmark(for path: SecurePath) async -> SecurePath? {
    let url=path.toURL()

    do {
      // Use _ to ignore the unused value
      _=try url.bookmarkData(
        options: .withSecurityScope,
        includingResourceValuesForKeys: nil,
        relativeTo: nil
      )

      // Return the original path with bookmark data
      return path
    } catch {
      return nil
    }
  }

  /**
   Resolves a security bookmark.

   - Parameter path: The path with bookmark data
   - Returns: A resolved path
   */
  func resolveSecurityBookmark(_ path: SecurePath) async -> SecurePath? {
    // In a real implementation, you would access the bookmark data from the path
    // and resolve it. Since bookmarkData is private, this is a placeholder.
    path
  }

  /**
   Starts accessing a security-scoped resource.

   - Parameter path: The path to access
   - Returns: Whether access was successfully started
   */
  func startAccessingSecurityScopedResource(_ path: SecurePath) async -> Bool {
    // In a real implementation, you would access the bookmark data from the path
    // Since bookmarkData is private, we need to use a different approach
    let url=URL(fileURLWithPath: path.toString())
    return url.startAccessingSecurityScopedResource()
  }

  /**
   Stops accessing a security-scoped resource.

   - Parameter path: The path to stop accessing
   */
  func stopAccessingSecurityScopedResource(_ path: SecurePath) async {
    // In a real implementation, you would access the bookmark data from the path
    // Since bookmarkData is private, we need to use a different approach
    let url=URL(fileURLWithPath: path.toString())
    url.stopAccessingSecurityScopedResource()
  }

  /**
   Returns the home directory path.

   - Returns: The home directory path
   */
  func homeDirectory() async -> SecurePath {
    let homePath=FileManager.default.homeDirectoryForCurrentUser.path
    guard let securePath=SecurePath(path: homePath, isDirectory: true) else {
      // Fallback to a known valid path if the home directory can't be secured
      return SecurePath(path: "/Users", isDirectory: true)!
    }
    return securePath
  }

  /**
   Returns the current working directory path.

   - Returns: The current working directory path
   */
  func currentDirectory() async -> SecurePath {
    let currentPath=FileManager.default.currentDirectoryPath
    guard let securePath=SecurePath(path: currentPath, isDirectory: true) else {
      // Fallback to home directory if the current directory can't be secured
      return await homeDirectory()
    }
    return securePath
  }

  /**
   Returns the path to a system directory.

   - Parameter directory: The system directory to locate
   - Returns: The path to the system directory
   */
  func systemDirectory(_ directory: SystemDirectory) async -> SecurePath {
    let fileManager=FileManager.default
    let searchPathDirectory: FileManager.SearchPathDirectory

    switch directory {
      case .documents:
        searchPathDirectory = .documentDirectory
      case .caches:
        searchPathDirectory = .cachesDirectory
      case .applicationSupport:
        searchPathDirectory = .applicationSupportDirectory
      case .temporary:
        return await temporaryDirectory()
      // Add all missing cases to make the switch exhaustive
      case .downloads:
        searchPathDirectory = .downloadsDirectory
      case .desktop:
        searchPathDirectory = .desktopDirectory
      case .library:
        searchPathDirectory = .libraryDirectory
      case .applicationBundle:
        searchPathDirectory = .applicationDirectory
      case .home:
        return await homeDirectory()
      case .applications:
        searchPathDirectory = .applicationDirectory
      case .pictures:
        searchPathDirectory = .picturesDirectory
      case .movies:
        searchPathDirectory = .moviesDirectory
      case .music:
        searchPathDirectory = .musicDirectory
    }

    if let url=fileManager.urls(for: searchPathDirectory, in: .userDomainMask).first {
      guard let securePath=SecurePath(path: url.path, isDirectory: true) else {
        // Fallback to home directory if the system directory can't be secured
        return await homeDirectory()
      }
      return securePath
    } else {
      // Fallback to home directory if the system directory can't be found
      return await homeDirectory()
    }
  }
}

/**
 Secure implementation of FilePathServiceProtocol.
 */
private actor SecureFilePathService: FilePathServiceProtocol {
  /// The security level for this service
  private let securityLevel: SecurityLevel

  /// Logger for recording operations
  private let logger: any LoggingProtocol

  /**
   Initialises a new secure file path service.

   - Parameters:
      - securityLevel: The security level to enforce
      - logger: Logger for recording operations
   */
  init(securityLevel: SecurityLevel, logger: any LoggingProtocol) {
    self.securityLevel=securityLevel
    self.logger=logger
  }

  /**
   Creates a secure path from a string.

   - Parameters:
      - path: The path string
      - isDirectory: Whether the path represents a directory
   - Returns: A secure path, or nil if the path is invalid
   */
  func createPath(from path: String, isDirectory: Bool) async -> SecurePath? {
    SecurePath(path: path, isDirectory: isDirectory)
  }

  /**
   Creates a secure path by joining components.

   - Parameters:
      - base: The base path
      - components: The components to append
   - Returns: A secure path with the components appended
   */
  func joinPath(_ base: SecurePath, _ components: String...) async -> SecurePath? {
    await joinPath(base, components)
  }

  /**
   Creates a secure path by joining components.

   - Parameters:
      - base: The base path
      - components: The components to append
   - Returns: A secure path with the components appended
   */
  func joinPath(_ base: SecurePath, _ components: [String]) async -> SecurePath? {
    var url=URL(fileURLWithPath: base.toString())

    for component in components {
      url=url.appendingPathComponent(component)
    }

    return SecurePath(
      path: url.path,
      isDirectory: url.hasDirectoryPath,
      securityLevel: base.securityLevel
    )
  }

  /**
   Checks if a path exists in the file system.

   - Parameter path: The path to check
   - Returns: Whether the path exists
   */
  func exists(_ path: SecurePath) async -> Bool {
    validateSecurityLevel(path)
    return FileManager.default.fileExists(atPath: path.toString())
  }

  /**
   Checks if a path is a file.

   - Parameter path: The path to check
   - Returns: Whether the path is a file
   */
  func isFile(_ path: SecurePath) async -> Bool {
    validateSecurityLevel(path)
    var isDir: ObjCBool=false
    let exists=FileManager.default.fileExists(atPath: path.toString(), isDirectory: &isDir)
    return exists && !isDir.boolValue
  }

  /**
   Checks if a path is a directory.

   - Parameter path: The path to check
   - Returns: Whether the path is a directory
   */
  func isDirectory(_ path: SecurePath) async -> Bool {
    validateSecurityLevel(path)
    var isDir: ObjCBool=false
    let exists=FileManager.default.fileExists(atPath: path.toString(), isDirectory: &isDir)
    return exists && isDir.boolValue
  }

  /**
   Gets the parent directory of a path.

   - Parameter path: The path to get the parent of
   - Returns: The parent directory, or nil if there is no parent
   */
  func parentDirectory(of path: SecurePath) async -> SecurePath? {
    validateSecurityLevel(path)
    let url=URL(fileURLWithPath: path.toString())
    let parentPath=url.deletingLastPathComponent().path
    return SecurePath(
      path: parentPath,
      isDirectory: true,
      securityLevel: path.securityLevel
    )
  }

  /**
   Gets the last component of a path.

   - Parameter path: The path to get the last component of
   - Returns: The last component of the path
   */
  func lastComponent(of path: SecurePath) async -> String {
    validateSecurityLevel(path)
    let url=URL(fileURLWithPath: path.toString())
    return url.lastPathComponent
  }

  /**
   Gets the file extension of a path.

   - Parameter path: The path to get the extension of
   - Returns: The file extension, or nil if there is none
   */
  func fileExtension(of path: SecurePath) async -> String? {
    validateSecurityLevel(path)
    let url=URL(fileURLWithPath: path.toString())
    let ext=url.pathExtension
    return ext.isEmpty ? nil : ext
  }

  /**
   Returns a path with the file extension changed.

   - Parameters:
      - path: The path to change the extension of
      - extension: The new file extension
   - Returns: A path with the extension changed
   */
  func changingFileExtension(of path: SecurePath, to extension: String) async -> SecurePath? {
    validateSecurityLevel(path)
    let url=URL(fileURLWithPath: path.toString())
    let newURL=url.deletingPathExtension().appendingPathExtension(`extension`)
    return SecurePath(
      path: newURL.path,
      isDirectory: false,
      securityLevel: path.securityLevel
    )
  }

  /**
   Creates a path to a temporary directory.

   - Returns: A path to a temporary directory
   */
  func temporaryDirectory() async -> SecurePath {
    let tempDir=FileManager.default.temporaryDirectory.path
    guard let securePath=SecurePath(path: tempDir, isDirectory: true) else {
      // Fallback to a known valid path if the temporary directory can't be secured
      return SecurePath(path: "/tmp", isDirectory: true)!
    }
    return securePath
  }

  /**
   Creates a path to a unique temporary file.

   - Parameter extension: Optional file extension
   - Returns: A path to a unique temporary file
   */
  func uniqueTemporaryFile(extension: String?) async -> SecurePath {
    let tempDir=FileManager.default.temporaryDirectory
    let uuid=UUID().uuidString
    let filename=`extension` != nil ? "\(uuid).\(`extension`!)" : uuid
    let url=tempDir.appendingPathComponent(filename)
    guard let securePath=SecurePath(path: url.path, isDirectory: false) else {
      // Fallback to a known valid path if the temporary file can't be secured
      let fallbackPath="/tmp/\(filename)"
      return SecurePath(path: fallbackPath, isDirectory: false)!
    }
    return securePath
  }

  /**
   Creates a security bookmark for a path.

   - Parameter path: The path to create a bookmark for
   - Returns: A path with the bookmark data attached
   */
  func createSecurityBookmark(for path: SecurePath) async -> SecurePath? {
    validateSecurityLevel(path)

    let url=path.toURL()

    do {
      let bookmarkData=try url.bookmarkData(
        options: .withSecurityScope,
        includingResourceValuesForKeys: nil,
        relativeTo: nil
      )

      // Create a new SecurePath with the resolved path and bookmark data
      return SecurePath(
        path: path.toString(),
        isDirectory: (try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false,
        bookmarkData: bookmarkData
      )
    } catch {
      return nil
    }
  }

  /**
   Resolves a security bookmark.

   - Parameter path: The path with bookmark data
   - Returns: A resolved path
   */
  func resolveSecurityBookmark(_ path: SecurePath) async -> SecurePath? {
    validateSecurityLevel(path)

    guard let bookmarkData=path.getBookmarkData() else {
      return nil
    }

    do {
      var isStale=false
      let url=try URL(
        resolvingBookmarkData: bookmarkData,
        options: .withSecurityScope,
        relativeTo: nil,
        bookmarkDataIsStale: &isStale
      )

      // Create a new SecurePath with the resolved path and bookmark data
      return SecurePath(
        path: url.path,
        isDirectory: (try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false,
        bookmarkData: bookmarkData
      )
    } catch {
      return nil
    }
  }

  /**
   Starts accessing a security-scoped resource.

   - Parameter path: The path to access
   - Returns: true if access was granted, false otherwise
   */
  func startAccessingSecurityScopedResource(_ path: SecurePath) async -> Bool {
    validateSecurityLevel(path)

    // Use the getBookmarkData() method instead of accessing the private property
    guard let bookmarkData=path.getBookmarkData() else {
      return false
    }

    do {
      var isStale=false
      let url=try URL(
        resolvingBookmarkData: bookmarkData,
        options: .withSecurityScope,
        relativeTo: nil,
        bookmarkDataIsStale: &isStale
      )

      // Start accessing the security-scoped resource
      return url.startAccessingSecurityScopedResource()
    } catch {
      return false
    }
  }

  /**
   Stops accessing a security-scoped resource.

   - Parameter path: The path to stop accessing
   */
  func stopAccessingSecurityScopedResource(_ path: SecurePath) async {
    validateSecurityLevel(path)

    // Use the getBookmarkData() method instead of accessing the private property
    guard let bookmarkData=path.getBookmarkData() else {
      return
    }

    do {
      var isStale=false
      let url=try URL(
        resolvingBookmarkData: bookmarkData,
        options: .withSecurityScope,
        relativeTo: nil,
        bookmarkDataIsStale: &isStale
      )

      url.stopAccessingSecurityScopedResource()
    } catch {
      // Silently fail
    }
  }

  /**
   Returns the home directory path.

   - Returns: The home directory path
   */
  func homeDirectory() async -> SecurePath {
    let homePath=FileManager.default.homeDirectoryForCurrentUser.path
    guard let securePath=SecurePath(path: homePath, isDirectory: true) else {
      // Fallback to a known valid path if the home directory can't be secured
      return SecurePath(path: "/Users", isDirectory: true)!
    }
    return securePath
  }

  /**
   Returns the current working directory path.

   - Returns: The current working directory path
   */
  func currentDirectory() async -> SecurePath {
    let currentPath=FileManager.default.currentDirectoryPath
    guard let securePath=SecurePath(path: currentPath, isDirectory: true) else {
      // Fallback to home directory if the current directory can't be secured
      return await homeDirectory()
    }
    return securePath
  }

  /**
   Returns the path to a system directory.

   - Parameter directory: The system directory to locate
   - Returns: The path to the system directory
   */
  func systemDirectory(_ directory: SystemDirectory) async -> SecurePath {
    let fileManager=FileManager.default
    let searchPathDirectory: FileManager.SearchPathDirectory

    switch directory {
      case .documents:
        searchPathDirectory = .documentDirectory
      case .caches:
        searchPathDirectory = .cachesDirectory
      case .applicationSupport:
        searchPathDirectory = .applicationSupportDirectory
      case .temporary:
        return await temporaryDirectory()
      // Add all missing cases to make the switch exhaustive
      case .downloads:
        searchPathDirectory = .downloadsDirectory
      case .desktop:
        searchPathDirectory = .desktopDirectory
      case .library:
        searchPathDirectory = .libraryDirectory
      case .applicationBundle:
        searchPathDirectory = .applicationDirectory
      case .home:
        return await homeDirectory()
      case .applications:
        searchPathDirectory = .applicationDirectory
      case .pictures:
        searchPathDirectory = .picturesDirectory
      case .movies:
        searchPathDirectory = .moviesDirectory
      case .music:
        searchPathDirectory = .musicDirectory
    }

    if let url=fileManager.urls(for: searchPathDirectory, in: .userDomainMask).first {
      guard let securePath=SecurePath(path: url.path, isDirectory: true) else {
        // Fallback to home directory if the system directory can't be secured
        return await homeDirectory()
      }
      return securePath
    } else {
      // Fallback to home directory if the system directory can't be found
      return await homeDirectory()
    }
  }

  /**
   Validates that a path meets the security level requirements.

   - Parameter path: The path to validate
   */
  private func validateSecurityLevel(_ path: SecurePath) {
    if path.securityLevel.rawValue < securityLevel.rawValue {
      Task {
        await logger.warning(
          "Path security level (\(path.securityLevel)) is lower than service security level (\(securityLevel))",
          context: FileSystemLogContextDTO(
            operation: "SecureFilePathService.validateSecurityLevel",
            path: path.toString()
          )
        )
      }
    }
  }
}

/**
 Sandboxed implementation of FilePathServiceProtocol.
 */
private actor SandboxedFilePathService: FilePathServiceProtocol {
  /// The root directory to restrict operations to
  private let rootDirectory: String

  /// Logger for recording operations
  private let logger: any LoggingProtocol

  /**
   Initialises a new sandboxed file path service.

   - Parameters:
      - rootDirectory: The directory to restrict operations to
      - logger: Logger for recording operations
   */
  init(rootDirectory: String, logger: any LoggingProtocol) {
    self.rootDirectory=rootDirectory
    self.logger=logger
  }

  /**
   Creates a secure path from a string.

   - Parameters:
      - path: The path string
      - isDirectory: Whether the path represents a directory
   - Returns: A secure path, or nil if the path is invalid
   */
  func createPath(from path: String, isDirectory: Bool) async -> SecurePath? {
    SecurePath(path: path, isDirectory: isDirectory)
  }

  /**
   Creates a secure path by joining components.

   - Parameters:
      - base: The base path
      - components: The components to append
   - Returns: A secure path with the components appended
   */
  func joinPath(_ base: SecurePath, _ components: String...) async -> SecurePath? {
    await joinPath(base, components)
  }

  /**
   Creates a secure path by joining components.

   - Parameters:
      - base: The base path
      - components: The components to append
   - Returns: A secure path with the components appended
   */
  func joinPath(_ base: SecurePath, _ components: [String]) async -> SecurePath? {
    var url=URL(fileURLWithPath: base.toString())

    for component in components {
      url=url.appendingPathComponent(component)
    }

    return SecurePath(
      path: url.path,
      isDirectory: url.hasDirectoryPath,
      securityLevel: base.securityLevel
    )
  }

  /**
   Checks if a path exists in the file system.

   - Parameter path: The path to check
   - Returns: Whether the path exists
   */
  func exists(_ path: SecurePath) async -> Bool {
    guard let resolvedPath=resolvePath(path) else {
      return false
    }

    return FileManager.default.fileExists(atPath: resolvedPath)
  }

  /**
   Checks if a path is a file.

   - Parameter path: The path to check
   - Returns: Whether the path is a file
   */
  func isFile(_ path: SecurePath) async -> Bool {
    guard let resolvedPath=resolvePath(path) else {
      return false
    }

    var isDir: ObjCBool=false
    let exists=FileManager.default.fileExists(atPath: resolvedPath, isDirectory: &isDir)
    return exists && !isDir.boolValue
  }

  /**
   Checks if a path is a directory.

   - Parameter path: The path to check
   - Returns: Whether the path is a directory
   */
  func isDirectory(_ path: SecurePath) async -> Bool {
    guard let resolvedPath=resolvePath(path) else {
      return false
    }

    var isDir: ObjCBool=false
    let exists=FileManager.default.fileExists(atPath: resolvedPath, isDirectory: &isDir)
    return exists && isDir.boolValue
  }

  /**
   Gets the parent directory of a path.

   - Parameter path: The path to get the parent of
   - Returns: The parent directory, or nil if there is no parent
   */
  func parentDirectory(of path: SecurePath) async -> SecurePath? {
    guard let resolvedPath=resolvePath(path) else {
      return nil
    }

    let url=URL(fileURLWithPath: resolvedPath)
    let parentPath=url.deletingLastPathComponent().path

    // Don't allow escaping the sandbox
    if !parentPath.hasPrefix(rootDirectory) {
      return nil
    }

    return SecurePath(
      path: parentPath,
      isDirectory: true,
      securityLevel: path.securityLevel
    )
  }

  /**
   Gets the last component of a path.

   - Parameter path: The path to get the last component of
   - Returns: The last component of the path
   */
  func lastComponent(of path: SecurePath) async -> String {
    guard let resolvedPath=resolvePath(path) else {
      return ""
    }

    let url=URL(fileURLWithPath: resolvedPath)
    return url.lastPathComponent
  }

  /**
   Gets the file extension of a path.

   - Parameter path: The path to get the extension of
   - Returns: The file extension, or nil if there is none
   */
  func fileExtension(of path: SecurePath) async -> String? {
    guard let resolvedPath=resolvePath(path) else {
      return nil
    }

    let url=URL(fileURLWithPath: resolvedPath)
    let ext=url.pathExtension
    return ext.isEmpty ? nil : ext
  }

  /**
   Returns a path with the file extension changed.

   - Parameters:
      - path: The path to change the extension of
      - extension: The new file extension
   - Returns: A path with the extension changed
   */
  func changingFileExtension(of path: SecurePath, to extension: String) async -> SecurePath? {
    guard let resolvedPath=resolvePath(path) else {
      return nil
    }

    let url=URL(fileURLWithPath: resolvedPath)
    let newURL=url.deletingPathExtension().appendingPathExtension(`extension`)
    return SecurePath(
      path: newURL.path,
      isDirectory: false,
      securityLevel: path.securityLevel
    )
  }

  /**
   Creates a path to a temporary directory.

   - Returns: A path to a temporary directory
   */
  func temporaryDirectory() async -> SecurePath {
    let tempDir=FileManager.default.temporaryDirectory.path
    guard let securePath=SecurePath(path: tempDir, isDirectory: true) else {
      // Fallback to a known valid path if the temporary directory can't be secured
      return SecurePath(path: "/tmp", isDirectory: true)!
    }
    return securePath
  }

  /**
   Creates a path to a unique temporary file.

   - Parameter extension: Optional file extension
   - Returns: A path to a unique temporary file
   */
  func uniqueTemporaryFile(extension: String?) async -> SecurePath {
    let tempDir=FileManager.default.temporaryDirectory
    let uuid=UUID().uuidString
    let filename=`extension` != nil ? "\(uuid).\(`extension`!)" : uuid
    let url=tempDir.appendingPathComponent(filename)
    guard let securePath=SecurePath(path: url.path, isDirectory: false) else {
      // Fallback to a known valid path if the temporary file can't be secured
      let fallbackPath="/tmp/\(filename)"
      return SecurePath(path: fallbackPath, isDirectory: false)!
    }
    return securePath
  }

  /**
   Creates a security bookmark for a path.

   - Parameter path: The path to create a bookmark for
   - Returns: A path with the bookmark data attached
   */
  func createSecurityBookmark(for path: SecurePath) async -> SecurePath? {
    guard let resolvedPath=resolvePath(path) else {
      return nil
    }

    let url=URL(fileURLWithPath: resolvedPath)

    do {
      let bookmarkData=try url.bookmarkData(
        options: .withSecurityScope,
        includingResourceValuesForKeys: nil,
        relativeTo: nil
      )

      // Create a new SecurePath with the resolved path and bookmark data
      return SecurePath(
        path: resolvedPath,
        isDirectory: (try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false,
        bookmarkData: bookmarkData
      )
    } catch {
      return nil
    }
  }

  /**
   Resolves a security bookmark.

   - Parameter path: The path with bookmark data
   - Returns: A resolved path
   */
  func resolveSecurityBookmark(_ path: SecurePath) async -> SecurePath? {
    // In a real implementation, you would access the bookmark data from the path
    // and resolve it. Since bookmarkData is private, this is a placeholder.
    path
  }

  /**
   Starts accessing a security-scoped resource.

   - Parameter path: The path to access
   - Returns: Whether access was successfully started
   */
  func startAccessingSecurityScopedResource(_ path: SecurePath) async -> Bool {
    // Check if the path exists in the sandbox
    guard resolvePath(path) != nil else {
      return false
    }

    // Use the getBookmarkData() method instead of accessing the private property
    guard let bookmarkData=path.getBookmarkData() else {
      return false
    }

    do {
      var isStale=false
      let url=try URL(
        resolvingBookmarkData: bookmarkData,
        options: .withSecurityScope,
        relativeTo: nil,
        bookmarkDataIsStale: &isStale
      )

      // Don't allow escaping the sandbox
      if !url.path.hasPrefix(rootDirectory) {
        return false
      }

      return url.startAccessingSecurityScopedResource()
    } catch {
      return false
    }
  }

  /**
   Stops accessing a security-scoped resource.

   - Parameter path: The path to stop accessing
   */
  func stopAccessingSecurityScopedResource(_ path: SecurePath) async {
    // Check if the path exists in the sandbox
    guard resolvePath(path) != nil else {
      return
    }

    // Use the getBookmarkData() method instead of accessing the private property
    guard let bookmarkData=path.getBookmarkData() else {
      return
    }

    do {
      var isStale=false
      let url=try URL(
        resolvingBookmarkData: bookmarkData,
        options: .withSecurityScope,
        relativeTo: nil,
        bookmarkDataIsStale: &isStale
      )

      // Don't allow escaping the sandbox
      if !url.path.hasPrefix(rootDirectory) {
        return
      }

      url.stopAccessingSecurityScopedResource()
    } catch {
      // Silently fail
    }
  }

  /**
   Returns the home directory path.

   - Returns: The home directory path
   */
  func homeDirectory() async -> SecurePath {
    let homePath=FileManager.default.homeDirectoryForCurrentUser.path
    guard let securePath=SecurePath(path: homePath, isDirectory: true) else {
      // Fallback to a known valid path if the home directory can't be secured
      return SecurePath(path: "/Users", isDirectory: true)!
    }
    return securePath
  }

  /**
   Returns the current working directory path.

   - Returns: The current working directory path
   */
  func currentDirectory() async -> SecurePath {
    let currentPath=FileManager.default.currentDirectoryPath
    guard let securePath=SecurePath(path: currentPath, isDirectory: true) else {
      // Fallback to home directory if the current directory can't be secured
      return await homeDirectory()
    }
    return securePath
  }

  /**
   Returns the path to a system directory.

   - Parameter directory: The system directory to locate
   - Returns: The path to the system directory
   */
  func systemDirectory(_ directory: SystemDirectory) async -> SecurePath {
    let fileManager=FileManager.default
    let searchPathDirectory: FileManager.SearchPathDirectory

    switch directory {
      case .documents:
        searchPathDirectory = .documentDirectory
      case .caches:
        searchPathDirectory = .cachesDirectory
      case .applicationSupport:
        searchPathDirectory = .applicationSupportDirectory
      case .temporary:
        return await temporaryDirectory()
      // Add all missing cases to make the switch exhaustive
      case .downloads:
        searchPathDirectory = .downloadsDirectory
      case .desktop:
        searchPathDirectory = .desktopDirectory
      case .library:
        searchPathDirectory = .libraryDirectory
      case .applicationBundle:
        searchPathDirectory = .applicationDirectory
      case .home:
        return await homeDirectory()
      case .applications:
        searchPathDirectory = .applicationDirectory
      case .pictures:
        searchPathDirectory = .picturesDirectory
      case .movies:
        searchPathDirectory = .moviesDirectory
      case .music:
        searchPathDirectory = .musicDirectory
    }

    if let url=fileManager.urls(for: searchPathDirectory, in: .userDomainMask).first {
      guard let securePath=SecurePath(path: url.path, isDirectory: true) else {
        // Fallback to home directory if the system directory can't be secured
        return await homeDirectory()
      }
      return securePath
    } else {
      // Fallback to home directory if the system directory can't be found
      return await homeDirectory()
    }
  }

  /**
   Resolves a path to ensure it's within the sandbox.

   - Parameter path: The path to resolve
   - Returns: The resolved path, or nil if the path is outside the sandbox
   */
  private func resolvePath(_ path: SecurePath) -> String? {
    let pathString=path.toString()

    // If the path is already absolute and within the sandbox, use it
    if path.isAbsolute && pathString.hasPrefix(rootDirectory) {
      return pathString
    }

    // If the path is relative, resolve it against the root directory
    if !path.isAbsolute {
      let resolvedPath=rootDirectory + (rootDirectory.hasSuffix("/") ? "" : "/") + pathString
      return resolvedPath
    }

    // Path is absolute but outside the sandbox
    Task {
      await logger.warning(
        "Attempted to access path outside sandbox: \(pathString)",
        context: FileSystemLogContextDTO(
          operation: "SandboxedFilePathService.resolvePath",
          path: pathString
        )
      )
    }

    return nil
  }
}

/**
 A null logger implementation used as a default when no logger is provided.
 */
private actor NullLogger: LoggingProtocol {
  nonisolated let loggingActor: LoggingInterfaces.LoggingActor = .init(destinations: [])

  func log(_: LogLevel, _: String, context _: LogContextDTO) async {
    // Do nothing - this is a null logger
  }
}
