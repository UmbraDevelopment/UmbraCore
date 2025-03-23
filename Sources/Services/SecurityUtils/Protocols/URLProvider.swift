import CoreErrors
import ErrorHandlingDomains
import Foundation
import UmbraCoreTypes
import UmbraSecurity
import XPCProtocolsCore

/// Protocol for URL-based operations
public protocol URLProvider: Sendable {
  /// Create a bookmark for a path
  /// - Parameter path: Path to create bookmark for
  /// - Returns: Bookmark data
  /// - Throws: SecurityError if bookmark creation fails
  func createBookmark(forPath path: String) async -> Result<Data, UmbraErrors.Security.Protocols>

  /// Resolve a bookmark to a path
  /// - Parameter bookmarkData: Bookmark data to resolve
  /// - Returns: Tuple containing resolved path and whether bookmark is stale
  /// - Throws: SecurityError if bookmark resolution fails
  func resolveBookmark(_ bookmarkData: [UInt8]) async
    -> Result<(path: String, isStale: Bool), UmbraErrors.Security.Protocols>

  /// Start accessing a path
  /// - Parameter path: Path to access
  /// - Returns: True if access was granted
  /// - Throws: SecurityError if access fails
  func startAccessing(path: String) async -> Result<Bool, UmbraErrors.Security.Protocols>

  /// Stop accessing a path
  /// - Parameter path: Path to stop accessing
  func stopAccessing(path: String) async

  /// Checks if a path is currently being accessed
  /// - Parameter path: The path to check
  /// - Returns: True if the path is being accessed, false otherwise
  func isAccessing(path: String) async -> Bool

  /// Get all paths that are currently being accessed
  /// - Returns: Set of paths that are currently being accessed
  func getAccessedPaths() async -> Set<String>

  /// Stop accessing all resources
  func stopAccessingAllResources() async
}

/// Default implementation of URLProvider using Foundation
extension URLProvider {
  public func createBookmark(forPath path: String) async
  -> Result<Data, UmbraErrors.Security.Protocols> {
    guard let url=URL(string: path) else {
      return .failure(.internalError("Invalid URL path: \(path)"))
    }

    return await url.createSecurityScopedBookmark()
  }

  public func resolveBookmark(_ bookmarkData: [UInt8]) async throws
  -> (path: String, isStale: Bool) {
    let data=Data(bookmarkData)
    let (url, isStale)=try await URL.resolveSecurityScopedBookmark(data)
    return (url.path, isStale)
  }

  public func stopAccessing(path: String) async {
    guard let url=URL(string: path) else {
      return
    }

    url.stopSecurityScopedAccess()
  }

  public func isAccessing(path _: String) async -> Bool {
    // This is a placeholder implementation
    // Foundation doesn't provide a direct way to check if a URL is being accessed
    false
  }

  public func startAccessing(path: String) async -> Result<Bool, UmbraErrors.Security.Protocols> {
    guard let url=URL(string: path) else {
      return .failure(.internalError("Invalid URL path: \(path)"))
    }

    if url.startSecurityScopedAccess() {
      return .success(true)
    } else {
      return .failure(.internalError("Failed to access security-scoped resource"))
    }
  }

  public func getAccessedPaths() async -> Set<String> {
    // For now, just return an empty set
    Set<String>()
  }

  public func stopAccessingAllResources() async {
    // Default implementation does nothing
    // Subclasses should override this if they track accessed resources
  }
}
