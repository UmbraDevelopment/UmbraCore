import CoreErrors
import CoreTypesInterfaces
import ErrorHandlingDomains
import Foundation
import SecurityTypes
import SecurityTypesProtocols
import UmbraCoreTypes
import XPCProtocolsCore

/// Extension to URL that provides functionality for working with security-scoped bookmarks.
/// Security-scoped bookmarks allow an app to maintain access to user-selected files and directories
/// across app launches.
extension URL {
  /// Creates a security-scoped bookmark for this URL.
  /// - Returns: Data containing the security-scoped bookmark
  /// - Throws: SecurityError.bookmarkError if bookmark creation fails due to:
  ///   - Invalid file path
  ///   - Insufficient permissions
  ///   - File system errors
  public func createSecurityScopedBookmark() async -> Result<Data, UmbraErrors.Security.Protocols> {
    let path=path
    do {
      return try .success(bookmarkData(
        options: [.withSecurityScope, .securityScopeAllowOnlyReadAccess],
        includingResourceValuesForKeys: nil,
        relativeTo: nil
      ))
    } catch {
      return .failure(.internalError("Failed to create bookmark for: \(path)"))
    }
  }

  /// Creates a security-scoped bookmark for this URL and returns it as SecureBytes.
  /// - Returns: SecureBytes containing the security-scoped bookmark
  /// - Throws: SecurityError.bookmarkError if bookmark creation fails
  public func createSecurityScopedBookmarkData() async
  -> Result<UmbraCoreTypes.SecureBytes, UmbraErrors.Security.Protocols> {
    let result=await createSecurityScopedBookmark()
    switch result {
      case let .success(data):
        return .success(UmbraCoreTypes.SecureBytes(bytes: [UInt8](data)))
      case let .failure(error):
        return .failure(error)
    }
  }

  /// Resolves a security-scoped bookmark to its URL.
  /// - Parameter bookmarkData: The bookmark data to resolve
  /// - Returns: A tuple containing:
  ///   - URL: The resolved URL
  ///   - Bool: Whether the bookmark is stale and should be recreated
  /// - Throws: SecurityError.bookmarkError if bookmark resolution fails due to:
  ///   - Invalid bookmark data
  ///   - File no longer exists
  ///   - Insufficient permissions
  public static func resolveSecurityScopedBookmark(_ bookmarkData: Data) async throws
  -> (URL, Bool) {
    var isStale=false
    let url=try URL(
      resolvingBookmarkData: bookmarkData,
      options: .withSecurityScope,
      relativeTo: nil,
      bookmarkDataIsStale: &isStale
    )
    return (url, isStale)
  }

  /// Starts accessing a security-scoped resource.
  /// This must be called before accessing the resource and paired with a call to
  /// stopSecurityScopedAccess.
  /// - Returns: True if access was granted, false otherwise
  public func startSecurityScopedAccess() -> Bool {
    startAccessingSecurityScopedResource()
  }

  /// Stops accessing a security-scoped resource.
  /// This should be called after you are done accessing the resource to release system resources.
  public func stopSecurityScopedAccess() {
    stopAccessingSecurityScopedResource()
  }

  /// Performs an operation with security-scoped access to this URL.
  /// Automatically handles starting and stopping security-scoped access.
  /// - Parameter operation: The operation to perform while access is granted
  /// - Returns: The result of the operation
  /// - Throws: Any error thrown by the operation
  public func withSecurityScopedAccess<T: Sendable>(
    _ operation: @Sendable () throws -> T
  ) throws -> T {
    guard startSecurityScopedAccess() else {
      throw UmbraErrors.Security.Protocols.internalError("Failed to access: \(path)")
    }
    defer { stopSecurityScopedAccess() }
    return try operation()
  }

  /// Performs an async operation with security-scoped access to this URL.
  /// Automatically handles starting and stopping security-scoped access.
  /// - Parameter operation: The async operation to perform while access is granted
  /// - Returns: The result of the operation
  /// - Throws: Any error thrown by the operation
  public func withSecurityScopedAccess<T: Sendable>(
    _ operation: @Sendable () async throws -> T
  ) async throws -> T {
    guard startSecurityScopedAccess() else {
      throw UmbraErrors.Security.Protocols.internalError("Failed to access: \(path)")
    }
    defer { stopSecurityScopedAccess() }
    return try await operation()
  }
}
