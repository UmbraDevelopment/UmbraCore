import CoreDTOs
import Foundation
import SecurityBridgeTypes
import UmbraCoreTypes

/// Factory for creating Foundation-independent security service DTOs
public enum SecurityServiceDTOFactory {
  /// Create a security service DTO adapter
  /// - Parameter securityService: Optional custom security service to use
  /// - Returns: A security service adapter with Foundation-independent interface
  public static func createSecurityService(
    securityService: SecurityService=DefaultSecurityService.shared
  ) -> SecurityServiceDTOAdapter {
    SecurityServiceDTOAdapter(securityService: securityService)
  }

  /// Create a bookmark service DTO adapter
  /// - Parameter bookmarkService: Optional custom bookmark service to use
  /// - Returns: A bookmark service adapter with Foundation-independent interface
  public static func createBookmarkService(
    bookmarkService: BookmarkServiceType=DefaultSecurityService.shared as! BookmarkServiceType
  ) -> BookmarkServiceDTOAdapter {
    BookmarkServiceDTOAdapter(bookmarkService: bookmarkService)
  }

  /// Create a complete security service configuration
  /// - Returns: A tuple containing security and bookmark service adapters
  public static func createComplete() -> (
    security: SecurityServiceDTOAdapter,
    bookmarks: BookmarkServiceDTOAdapter
  ) {
    let securityService=DefaultSecurityService.shared
    return (
      security: SecurityServiceDTOAdapter(securityService: securityService),
      bookmarks: BookmarkServiceDTOAdapter(bookmarkService: securityService as! BookmarkServiceType)
    )
  }
}

// MARK: - Example Usage

/*
 Example usage of the Foundation-independent security services:

 ```swift
 // Create the service adapters
 let (securityService, bookmarkService) = SecurityServiceDTOFactory.createComplete()

 // Generate random bytes
 let randomBytesResult = securityService.generateRandomBytes(count: 32)
 switch randomBytesResult {
 case .success(let bytes):
     print("Generated \(bytes.count) random bytes")
 case .failure(let error):
     print("Failed to generate random bytes: \(error.error.message)")
 }

 // Create a bookmark
 let path = FilePathDTO.documentsDirectory().appendingComponent("example.txt")
 let bookmarkResult = bookmarkService.createBookmark(for: path)
 switch bookmarkResult {
 case .success(let bookmark):
     print("Created bookmark for \(bookmark.displayPath)")

     // Resolve the bookmark
     let resolveResult = bookmarkService.resolveBookmark(bookmark)
     switch resolveResult {
     case .success(let (resolvedPath, wasStale)):
         print("Resolved to \(resolvedPath.path) (stale: \(wasStale))")
     case .failure(let error):
         print("Failed to resolve bookmark: \(error.error.message)")
     }

 case .failure(let error):
     print("Failed to create bookmark: \(error.error.message)")
 }
 ```
 */
