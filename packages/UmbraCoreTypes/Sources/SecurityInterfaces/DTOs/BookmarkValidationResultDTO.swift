import CoreDTOs
import DomainSecurityTypes
import Foundation

/**
 # BookmarkValidationResultDTO

 Result of validating a security-scoped bookmark.

 This DTO provides a Foundation-independent way to represent the
 result of validating a security-scoped bookmark, including whether
 it's valid, stale, and if a new bookmark was created.
 */
public struct BookmarkValidationResultDTO: Sendable {
  /// Whether the bookmark is valid and can be used
  public let isValid: Bool

  /// Whether the bookmark is stale and should be recreated
  public let isStale: Bool

  /// Updated bookmark data if the bookmark was recreated
  public let updatedBookmark: [UInt8]?

  /// The resolved URL of the bookmark
  public let url: URL

  /**
   Creates a new BookmarkValidationResultDTO.

   - Parameters:
      - isValid: Whether the bookmark is valid and can be used
      - isStale: Whether the bookmark is stale and should be recreated
      - updatedBookmark: Updated bookmark data if the bookmark was recreated
      - url: The resolved URL of the bookmark
   */
  public init(
    isValid: Bool,
    isStale: Bool,
    updatedBookmark: [UInt8]?,
    url: URL
  ) {
    self.isValid=isValid
    self.isStale=isStale
    self.updatedBookmark=updatedBookmark
    self.url=url
  }

  /// Creates a result indicating the bookmark is valid and not stale
  public static func valid(url: URL) -> BookmarkValidationResultDTO {
    BookmarkValidationResultDTO(
      isValid: true,
      isStale: false,
      updatedBookmark: nil,
      url: url
    )
  }

  /// Creates a result indicating the bookmark is valid but stale
  public static func stale(url: URL) -> BookmarkValidationResultDTO {
    BookmarkValidationResultDTO(
      isValid: true,
      isStale: true,
      updatedBookmark: nil,
      url: url
    )
  }

  /// Creates a result indicating the bookmark is valid but stale and has been recreated
  public static func recreated(url: URL, bookmark: [UInt8]) -> BookmarkValidationResultDTO {
    BookmarkValidationResultDTO(
      isValid: true,
      isStale: true,
      updatedBookmark: bookmark,
      url: url
    )
  }

  /// Creates a result indicating the bookmark is invalid
  public static func invalid(url: URL) -> BookmarkValidationResultDTO {
    BookmarkValidationResultDTO(
      isValid: false,
      isStale: false,
      updatedBookmark: nil,
      url: url
    )
  }
}
