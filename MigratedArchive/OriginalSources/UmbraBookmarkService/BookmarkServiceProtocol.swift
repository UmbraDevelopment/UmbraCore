import Foundation

/// Protocol defining operations for security-scoped bookmark management
@objc
public protocol BookmarkServiceProtocol {
  /// Create a security-scoped bookmark for a file URL
  /// - Parameters:
  ///   - url: The file URL to create a bookmark for
  ///   - options: Options for bookmark creation
  /// - Returns: The bookmark data
  /// - Throws: BookmarkError if creation fails
  @preconcurrency
  @discardableResult
  func createBookmark(
    for url: URL,
    options: URL.BookmarkCreationOptions
  ) async throws -> Data

  /// Resolve a security-scoped bookmark to a URL
  /// - Parameters:
  ///   - bookmarkData: The bookmark data to resolve
  ///   - options: Options for bookmark resolution
  /// - Returns: The resolved URL and whether the bookmark is stale
  /// - Throws: BookmarkError if resolution fails
  @preconcurrency
  @discardableResult
  func resolveBookmark(
    _ bookmarkData: Data,
    options: URL.BookmarkResolutionOptions
  ) async throws -> (URL, Bool)

  /// Start accessing a security-scoped resource
  /// - Parameter url: The URL of the resource to access
  /// - Throws: BookmarkError if access cannot be started
  @preconcurrency
  func startAccessing(
    _ url: URL
  ) async throws

  /// Stop accessing a security-scoped resource
  /// - Parameter url: The URL of the resource to stop accessing
  @preconcurrency
  func stopAccessing(
    _ url: URL
  ) async

  /// Check if a URL is currently being accessed
  /// - Parameter url: The URL to check
  /// - Returns: true if the URL is being accessed, false otherwise
  @preconcurrency
  @discardableResult
  func isAccessing(
    _ url: URL
  ) async -> Bool
}
