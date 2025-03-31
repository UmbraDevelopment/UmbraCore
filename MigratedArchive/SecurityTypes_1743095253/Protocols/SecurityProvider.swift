import Foundation

/// Protocol for providing security-related operations
public protocol SecurityProvider {
  /// Create a security-scoped bookmark for a URL
  /// - Parameter url: The URL to create a bookmark for
  /// - Returns: The bookmark data
  /// - Throws: Error if bookmark creation fails
  func createSecurityBookmark(for url: URL) throws -> Data

  /// Resolve a security-scoped bookmark to a URL
  /// - Parameter bookmarkData: The bookmark data to resolve
  /// - Returns: The resolved URL
  /// - Throws: Error if bookmark resolution fails
  func resolveSecurityBookmark(_ bookmarkData: Data) throws -> URL

  /// Start accessing a security-scoped resource
  /// - Parameter path: Path to the resource
  /// - Returns: True if access was granted
  /// - Throws: Error if access cannot be granted
  func startAccessing(path: String) async throws -> Bool

  /// Stop accessing a security-scoped resource
  /// - Parameter path: Path to the resource
  func stopAccessing(path: String) async

  /// Stop accessing all security-scoped resources
  func stopAccessingAllResources() async

  /// Check if a security-scoped resource is being accessed
  /// - Parameter path: Path to the resource
  /// - Returns: True if the resource is being accessed
  func isAccessing(path: String) async -> Bool

  /// Get all paths that are currently being accessed
  /// - Returns: Set of paths that are currently being accessed
  func getAccessedPaths() async -> Set<String>

  /// Perform an operation with security-scoped access to a resource
  /// - Parameters:
  ///   - path: Path to the resource
  ///   - operation: Operation to perform while resource is accessible
  /// - Returns: Result of the operation
  /// - Throws: Error if access cannot be granted or operation fails
  func withSecurityScopedAccess<T>(
    to path: String,
    perform operation: @Sendable () async throws -> T
  ) async throws -> T
}
