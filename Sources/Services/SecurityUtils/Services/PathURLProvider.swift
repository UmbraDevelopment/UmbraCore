import ErrorHandlingDomains
import Foundation
import SecurityUtilsProtocols

/// Actor for tracking accessed paths safely across all instances
@globalActor
public actor PathAccessTracker {
  public static let shared=PathAccessTracker()

  private var accessedPaths: Set<String>=[]

  private init() {}

  func addPath(_ path: String) {
    accessedPaths.insert(path)
  }

  func removePath(_ path: String) {
    accessedPaths.remove(path)
  }

  func containsPath(_ path: String) -> Bool {
    accessedPaths.contains(path)
  }

  func getAllPaths() -> Set<String> {
    accessedPaths
  }

  func removeAllPaths() {
    accessedPaths.removeAll()
  }
}

/// Default implementation of URLProvider that uses FileManager
public struct PathURLProvider: URLProvider {
  // Use a static property instead of an instance property to avoid Sendable issues
  // FileManager.default is already thread-safe for read operations

  /// Initialize a new PathURLProvider
  public init() {
    // No initialization needed
  }

  /// Get the URL for a specified path
  /// - Parameter path: Path string
  /// - Returns: URL for the path
  public func url(forPath path: String) -> URL {
    URL(fileURLWithPath: path)
  }

  /// Get the URL for a specified directory
  /// - Parameters:
  ///   - directory: FileManager search path directory
  ///   - domain: FileManager search path domain mask
  /// - Returns: URL for the directory
  /// - Throws: Error if directory cannot be located
  public func url(
    for directory: FileManager.SearchPathDirectory,
    in domain: FileManager.SearchPathDomainMask
  ) throws -> URL {
    try FileManager.default.url(for: directory, in: domain, appropriateFor: nil, create: false)
  }

  /// Get the URL for a specified directory with additional path components
  /// - Parameters:
  ///   - directory: FileManager search path directory
  ///   - domain: FileManager search path domain mask
  ///   - pathComponents: Additional path components to append
  /// - Returns: URL for the directory with path components
  /// - Throws: Error if directory cannot be located
  public func url(
    for directory: FileManager.SearchPathDirectory,
    in domain: FileManager.SearchPathDomainMask,
    pathComponents: [String]
  ) throws -> URL {
    var url=try url(for: directory, in: domain)
    for component in pathComponents {
      url.appendPathComponent(component)
    }
    return url
  }

  // MARK: - URLProvider Protocol Implementation

  /// Create a bookmark for a path
  /// - Parameter path: Path to create bookmark for
  /// - Returns: Result with bookmark data or error
  public func createBookmark(forPath path: String) async
  -> Result<Data, UmbraErrors.Security.Protocols> {
    guard let url=URL(string: path) else {
      return .failure(.invalidInput("Invalid URL path: \(path)"))
    }

    do {
      let bookmarkData=try url.bookmarkData(
        options: .securityScopeAllowOnlyReadAccess,
        includingResourceValuesForKeys: nil,
        relativeTo: nil
      )
      return .success(bookmarkData)
    } catch {
      return .failure(
        .storageOperationFailed("Failed to create bookmark: \(error.localizedDescription)")
      )
    }
  }

  /// Resolve a bookmark to a path
  /// - Parameter bookmarkData: Bookmark data to resolve
  /// - Returns: Result with path and staleness or error
  public func resolveBookmark(_ bookmarkData: [UInt8]) async
  -> Result<(path: String, isStale: Bool), UmbraErrors.Security.Protocols> {
    let data=Data(bookmarkData)

    do {
      var isStale=false
      let url=try URL(
        resolvingBookmarkData: data,
        options: .withSecurityScope,
        relativeTo: nil,
        bookmarkDataIsStale: &isStale
      )
      return .success((path: url.path, isStale: isStale))
    } catch {
      return .failure(
        .storageOperationFailed("Failed to resolve bookmark: \(error.localizedDescription)")
      )
    }
  }

  /// Start accessing a path
  /// - Parameter path: Path to access
  /// - Returns: Result with success status or error
  public func startAccessing(path: String) async -> Result<Bool, UmbraErrors.Security.Protocols> {
    guard let url=URL(string: path) else {
      return .failure(.invalidInput("Invalid URL path: \(path)"))
    }

    do {
      if !url.startAccessingSecurityScopedResource() {
        return .failure(.storageOperationFailed("Failed to access security-scoped resource"))
      }
      // Add to tracked paths
      await PathAccessTracker.shared.addPath(path)
      return .success(true)
    } catch {
      return .failure(
        .storageOperationFailed("Error accessing resource: \(error.localizedDescription)")
      )
    }
  }

  /// Stop accessing a path
  /// - Parameter path: Path to stop accessing
  public func stopAccessing(path: String) async {
    guard let url=URL(string: path) else {
      return
    }

    url.stopAccessingSecurityScopedResource()
    // Remove from tracked paths
    await PathAccessTracker.shared.removePath(path)
  }

  /// Checks if a path is currently being accessed
  /// - Parameter path: The path to check
  /// - Returns: True if the path is being accessed, false otherwise
  public func isAccessing(path: String) async -> Bool {
    await PathAccessTracker.shared.containsPath(path)
  }

  /// Get all paths that are currently being accessed
  /// - Returns: Set of paths that are currently being accessed
  public func getAccessedPaths() async -> Set<String> {
    await PathAccessTracker.shared.getAllPaths()
  }

  /// Stop accessing all resources
  public func stopAccessingAllResources() async {
    let paths=await PathAccessTracker.shared.getAllPaths()
    for path in paths {
      if let url=URL(string: path) {
        url.stopAccessingSecurityScopedResource()
      }
    }
    await PathAccessTracker.shared.removeAllPaths()
  }
}
