import Foundation

/**
 # BookmarkSecurityError

 Comprehensive error type for security-scoped bookmark operations, providing
 detailed information about failures in the bookmark subsystem.

 This type follows the architecture pattern for domain-specific
 errors with descriptive messages and categorisation.
 */
public enum BookmarkSecurityError: Error, Equatable, Sendable {
  /// The bookmark is invalid and cannot be resolved
  case invalidBookmark(String)

  /// The bookmark is stale and needs to be recreated
  case staleBookmark(String)

  /// The URL cannot be resolved from the bookmark data
  case cannotResolveURL(String)

  /// Unable to create a bookmark for the URL
  case cannotCreateBookmark(String)

  /// The URL is not currently being accessed
  case notAccessing(String)

  /// Attempt to access a URL that is already being accessed
  case alreadyAccessing(String)

  /// The URL could not be accessed with security-scoped bookmark
  case accessDenied(String)

  /// A security operation failed with the given reason
  case operationFailed(String)

  /// Creates a human-readable description of the error
  public var localizedDescription: String {
    switch self {
      case let .invalidBookmark(message):
        "Invalid security bookmark: \(message)"
      case let .staleBookmark(message):
        "Stale security bookmark: \(message)"
      case let .cannotResolveURL(message):
        "Cannot resolve URL from bookmark: \(message)"
      case let .cannotCreateBookmark(message):
        "Cannot create security bookmark: \(message)"
      case let .notAccessing(message):
        "URL is not being accessed: \(message)"
      case let .alreadyAccessing(message):
        "URL is already being accessed: \(message)"
      case let .accessDenied(message):
        "Access denied to URL: \(message)"
      case let .operationFailed(message):
        "Bookmark operation failed: \(message)"
    }
  }
}
