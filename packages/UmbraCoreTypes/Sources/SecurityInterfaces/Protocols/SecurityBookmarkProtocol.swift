import CoreDTOs
import DomainSecurityTypes
import Foundation
import SecurityInterfacesDTOs
import UmbraErrors
import UmbraErrorsDomains

/**
 # SecurityBookmarkProtocol

 Protocol defining operations for managing security-scoped bookmarks.

 This protocol provides a standardised interface for creating, resolving,
 and managing access to security-scoped bookmarks in sandboxed applications.

 Following the Alpha Dot Five architecture, it:
 - Uses Foundation-independent DTOs where possible
 - Provides domain-specific error types
 - Uses proper async methods for concurrency
 */
public protocol SecurityBookmarkProtocol: Sendable {
  /**
   Creates a security-scoped bookmark for the provided URL.

   - Parameters:
      - url: The URL to create a bookmark for
      - readOnly: Whether the bookmark should be read-only
      - storageIdentifier: Optional identifier for storing the bookmark data. If nil, an identifier will be generated.

   - Returns: Result with storage identifier for the bookmark data or error
   */
  func createBookmark(
    for url: URL,
    readOnly: Bool,
    storageIdentifier: String?
  ) async -> Result<String, UmbraErrors.Security.Bookmark>

  /**
   Resolves a security-scoped bookmark to its URL.

   - Parameter storageIdentifier: The identifier for the stored bookmark data

   - Returns: Result with URL and staleness indicator or error
   */
  func resolveBookmark(
    withIdentifier storageIdentifier: String
  ) async -> Result<(URL, Bool), UmbraErrors.Security.Bookmark>

  /**
   Starts accessing a security-scoped resource represented by the URL.

   - Parameter url: The URL for which to start resource access

   - Returns: Result with success indicator or error
   */
  func startAccessing(
    _ url: URL
  ) async -> Result<Bool, UmbraErrors.Security.Bookmark>

  /**
   Stops accessing a security-scoped resource represented by the URL.

   - Parameter url: The URL for which to stop resource access

   - Returns: Result with count of remaining accesses or error
   */
  func stopAccessing(
    _ url: URL
  ) async -> Result<Int, UmbraErrors.Security.Bookmark>

  /**
   Validates a security-scoped bookmark.

   This method checks if a bookmark is valid and not stale.
   If stale, it can optionally recreate the bookmark.

   - Parameters:
      - storageIdentifier: The identifier for the stored bookmark data
      - recreateIfStale: Whether to recreate the bookmark if stale

   - Returns: Result with validation result or error
   */
  func validateBookmark(
    withIdentifier storageIdentifier: String,
    recreateIfStale: Bool
  ) async -> Result<BookmarkValidationResultDTO, UmbraErrors.Security.Bookmark>

  /**
   Checks if all resources have been properly released.

   - Returns: True if all resources have been released, false otherwise
   */
  func verifyAllResourcesReleased() async -> Bool

  /**
   Forces release of all security-scoped resources.

   This method should only be used during application termination
   or error recovery to ensure all resources are properly released.

   - Returns: The number of resources that were released
   */
  func forceReleaseAllResources() async -> Int
}
