import Foundation

/**
 # BookmarkCreationOptions

 Options for creating security-scoped bookmarks.

 This type encapsulates parameters that control how bookmarks are created
 and stored, following the Alpha Dot Five architecture's preference for
 immutable data structures with clear semantics.
 */
public struct BookmarkCreationOptions: Sendable, Equatable {
  /// Whether the bookmark should be for read-only access
  public let readOnly: Bool

  /// Additional creation options for the bookmark
  public let options: URL.BookmarkCreationOptions?

  /**
   Creates a new set of bookmark creation options.

   - Parameters:
     - readOnly: Whether the bookmark should be for read-only access
     - options: Additional standard options to use when creating the bookmark
   */
  public init(
    readOnly: Bool=false,
    options: URL.BookmarkCreationOptions?=nil
  ) {
    self.readOnly=readOnly
    self.options=options
  }

  /// Default options for creating bookmarks (read-write access)
  public static let `default`=BookmarkCreationOptions()

  /// Options for creating read-only bookmarks
  public static let readOnly=BookmarkCreationOptions(readOnly: true)
}
