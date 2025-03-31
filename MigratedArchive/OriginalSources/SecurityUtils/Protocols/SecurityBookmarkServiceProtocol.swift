import Foundation
import SecurityInterfaces

/// Protocol for security bookmark service
public protocol SecurityBookmarkServiceProtocol: Sendable {
  /// Creates a security-scoped bookmark for a URL
  /// - Parameter url: URL to create bookmark for
  /// - Returns: Bookmark data
  func createBookmark(for url: URL) async throws -> Data

  /// Resolves a security-scoped bookmark to a URL
  /// - Parameter bookmarkData: Bookmark data
  /// - Returns: Resolved URL
  func resolveBookmark(_ bookmarkData: Data) async throws -> URL

  /// Starts accessing a security-scoped resource
  /// - Parameter url: URL to access
  /// - Returns: Whether access was started successfully
  func startAccessing(_ url: URL) async -> Bool

  /// Stops accessing a security-scoped resource
  /// - Parameter url: URL to stop accessing
  func stopAccessing(_ url: URL) async
}
