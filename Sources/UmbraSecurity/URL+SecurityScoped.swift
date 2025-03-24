import CoreTypesInterfaces
import ErrorHandlingCore
import ErrorHandlingDomains
import ErrorHandlingInterfaces
import ErrorHandlingMapping
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
    do {
      var isStale=false
      let url=try URL(
        resolvingBookmarkData: bookmarkData,
        options: .withSecurityScope,
        relativeTo: nil,
        bookmarkDataIsStale: &isStale
      )
      return (url, isStale)
    } catch {
      throw UmbraErrors.Security.Core.operationFailed(
        reason: "Failed to resolve security-scoped bookmark"
      )
    }
  }

  /// Resolves a security-scoped bookmark stored as SecureBytes to its URL.
  /// - Parameter bookmarkData: The SecureBytes containing the bookmark data
  /// - Returns: A tuple containing:
  ///   - URL: The resolved URL
  ///   - Bool: Whether the bookmark is stale and should be recreated
  /// - Throws: SecurityError.bookmarkError if bookmark resolution fails
  public static func resolveSecurityScopedBookmark(
    _ bookmarkData: UmbraCoreTypes
      .SecureBytes
  ) async throws
  -> (URL, Bool) {
    try await resolveSecurityScopedBookmark(Data(bookmarkData.bytes))
  }

  /// Starts accessing a security-scoped resource represented by this URL.
  /// This must be called before attempting to access the resource, and
  /// stopAccessingSecurityScopedResource
  /// must be called when done.
  /// - Returns: True if access was successfully started, false otherwise
  public func startAccessingSecurityScopedResource() async
  -> Result<Bool, UmbraErrors.Security.Protocols> {
    let result=startAccessingSecurityScopedResource()
    if result {
      return .success(true)
    } else {
      return .failure(.operationFailed("Failed to start accessing security-scoped resource"))
    }
  }

  /// Stops accessing a security-scoped resource that was previously accessed with
  /// startAccessingSecurityScopedResource.
  /// Must be called after access is no longer needed to release any resources.
  public func stopAccessingSecurityScopedResource() {
    stopAccessingSecurityScopedResource()
  }

  /// Executes an operation with temporary access to a security-scoped resource.
  /// This method automatically handles starting and stopping access to the resource.
  /// - Parameter operation: The operation to perform while the resource is accessible
  /// - Returns: The result of the operation
  /// - Throws: SecurityError if access cannot be granted, or any error thrown by the operation
  public func withSecurityScopedAccess<T>(_ operation: () async throws -> T) async throws -> T {
    let accessResult=await startAccessingSecurityScopedResource()
    switch accessResult {
      case .success:
        defer { stopAccessingSecurityScopedResource() }
        return try await operation()
      case .failure:
        throw UmbraErrors.Security.Core.operationFailed(
          reason: "Failed to access security-scoped resource: \(path)"
        )
    }
  }
}
