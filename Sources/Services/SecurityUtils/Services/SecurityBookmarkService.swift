import CoreErrors
import ErrorHandlingDomains
import Foundation

// Removed SecurityInterfaces as it appears to be unavailable
import SecurityTypes
import SecurityTypesProtocols
import SecurityUtilsProtocols
import UmbraCoreTypes
import XPCProtocolsCore

/// Service for managing security-scoped bookmarks
public actor SecurityBookmarkService {
  private let urlProvider: URLProvider
  private var activeResources: Set<URL>

  /// Initialize a new security bookmark service
  /// - Parameter urlProvider: Provider for URL operations
  public init(urlProvider: URLProvider=PathURLProvider()) {
    self.urlProvider=urlProvider
    activeResources=[]
  }

  /// Create a security-scoped bookmark for a URL
  /// - Parameters:
  ///   - url: The URL to create a bookmark for
  ///   - options: Bookmark creation options
  /// - Returns: Bookmark data that can be stored and later used to access the resource
  public func createBookmark(
    for url: URL,
    options: BookmarkOptions=BookmarkDefaultOptions
  ) async throws -> Data {
    let fileURL=url.standardized

    // Start accessing the resource before creating bookmark
    guard fileURL.startAccessingSecurityScopedResource() else {
      throw UmbraErrors.Bookmark.Core.accessDenied(
        url: url,
        reason: "Could not access the resource"
      )
    }
    defer { fileURL.stopAccessingSecurityScopedResource() }

    // Create the bookmark data
    do {
      // Use standard Foundation API since URLProvider doesn't have createBookmarkData
      return try fileURL.bookmarkData(
        options: getSystemBookmarkOptions(from: options),
        includingResourceValuesForKeys: nil,
        relativeTo: nil
      )
    } catch {
      throw UmbraErrors.Bookmark.Core.creationFailed(url: url, reason: error.localizedDescription)
    }
  }

  /// Resolve bookmark data to a URL
  /// - Parameters:
  ///   - data: Bookmark data previously created with createBookmark
  ///   - options: Bookmark resolution options
  /// - Returns: URL to the bookmarked resource
  public func resolveBookmark(
    _ data: Data,
    options: BookmarkOptions=BookmarkDefaultOptions
  ) async throws -> URL {
    do {
      // Use standard Foundation API since URLProvider doesn't have resolveBookmarkData
      var isStale=false
      let url=try URL(
        resolvingBookmarkData: data,
        options: getSystemBookmarkResolutionOptions(from: options),
        relativeTo: nil,
        bookmarkDataIsStale: &isStale
      )

      // If bookmark is stale, we might need to recreate it in the future
      if isStale {
        // In a real implementation, we would handle this by recreating the bookmark
        // but for now, we'll just log it and continue
      }

      return url
    } catch {
      throw UmbraErrors.Bookmark.Core.resolutionFailed(
        reason: "Failed to resolve bookmark",
        underlyingError: error
      )
    }
  }

  /// Start accessing a security-scoped resource
  /// - Parameter url: URL to the security-scoped resource
  /// - Returns: True if access was started successfully
  public func startAccessingResource(_ url: URL) async throws -> Bool {
    let fileURL=url.standardized

    // Start accessing the resource
    guard fileURL.startAccessingSecurityScopedResource() else {
      throw UmbraErrors.Bookmark.Core.startAccessFailed(
        url: url,
        reason: "Could not start accessing the resource"
      )
    }

    // Track the active resource
    activeResources.insert(fileURL)
    return true
  }

  /// Stop accessing a security-scoped resource
  /// - Parameter url: URL to the security-scoped resource
  public func stopAccessingResource(_ url: URL) {
    let fileURL=url.standardized
    fileURL.stopAccessingSecurityScopedResource()
    activeResources.remove(fileURL)
  }

  /// Stop accessing all tracked security-scoped resources
  public func stopAccessingAllResources() {
    for url in activeResources {
      url.stopAccessingSecurityScopedResource()
    }
    activeResources.removeAll()
  }

  // MARK: - Helper methods

  /// Convert BookmarkOptions to NSURL.BookmarkCreationOptions
  private func getSystemBookmarkOptions(from options: BookmarkOptions) -> NSURL
  .BookmarkCreationOptions {
    var systemOptions: NSURL.BookmarkCreationOptions=[]

    if options.contains(.securityScoped) {
      systemOptions.insert(.withSecurityScope)
    }

    if options.contains(.iCloudCompatible) {
      systemOptions.insert(.suitableForBookmarkFile)
    }

    return systemOptions
  }

  /// Convert BookmarkOptions to NSURL.BookmarkResolutionOptions
  private func getSystemBookmarkResolutionOptions(from options: BookmarkOptions) -> NSURL
  .BookmarkResolutionOptions {
    var systemOptions: NSURL.BookmarkResolutionOptions=[]

    if options.contains(.securityScoped) {
      systemOptions.insert(.withSecurityScope)
    }

    if options.contains(.withoutUI) {
      systemOptions.insert(.withoutUI)
    }

    return systemOptions
  }
}

/// Options for bookmark creation and resolution
public struct BookmarkOptions: OptionSet, Sendable {
  public let rawValue: Int

  public init(rawValue: Int) {
    self.rawValue=rawValue
  }

  /// Bookmark should be appropriate for storage in iCloud and may include path components that are
  /// portable across users
  public static let iCloudCompatible=BookmarkOptions(rawValue: 1 << 0)

  /// Created bookmark data should include properties required to create a security-scoped bookmark
  public static let securityScoped=BookmarkOptions(rawValue: 1 << 1)

  /// Resolving the bookmark data should not trigger user interaction, such as prompting for
  /// credentials
  public static let withoutUI=BookmarkOptions(rawValue: 1 << 2)
}

/// Default bookmark options with security scoping enabled
public let BookmarkDefaultOptions: BookmarkOptions=[.securityScoped]
