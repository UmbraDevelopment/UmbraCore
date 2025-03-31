import Foundation

// Use the shared declarations instead of local ones
import Interfaces
import UmbraErrorsCore

/// Error domain namespace

/// Error context protocol

/// Base error context implementation

extension UmbraErrors.Bookmark {
  /// Core bookmark errors related to bookmark creation, resolution, and access
  public enum Core: Error, UmbraErrorsCore.UmbraError, StandardErrorCapabilitiesProtocol {
    // Bookmark creation and resolution errors
    /// Failed to create bookmark data for URL
    case creationFailed(url: URL, reason: String?)

    /// Failed to resolve bookmark data to URL
    case resolutionFailed(reason: String?, underlyingError: Error?)

    /// Bookmark data is stale and needs to be recreated
    case staleBookmark(url: URL)

    /// Invalid bookmark data format
    case invalidBookmarkData(reason: String?)

    // Security and access errors
    /// Security-scoped resource access was denied
    case accessDenied(url: URL, reason: String?)

    /// Failed to start security-scoped resource access
    case startAccessFailed(url: URL, reason: String?)

    /// Failed to stop security-scoped resource access
    case stopAccessFailed(url: URL, reason: String?)

    // Resource errors
    /// File does not exist at URL
    case fileNotFound(url: URL)

    /// File is not accessible due to permissions
    case permissionDenied(url: URL)

    /// File moved or renamed
    case fileRelocated(originalURL: URL, currentURL: URL?)

    /// File type is not supported for bookmarking
    case unsupportedFileType(url: URL, fileType: String)

    /// Failed to serialise bookmark data
    case serialisationFailed(reason: String?)

    /// Failed to deserialise bookmark data
    case deserialisationFailed(reason: String?)

    // MARK: - UmbraError Protocol

    /// Domain identifier for bookmark core errors
    public var domain: String {
      "Bookmark.Core"
    }

    /// Error code uniquely identifying the error type
    public var code: String {
      switch self {
        case .creationFailed:
          "creation_failed"
        case .resolutionFailed:
          "resolution_failed"
        case .staleBookmark:
          "stale_bookmark"
        case .invalidBookmarkData:
          "invalid_bookmark_data"
        case .accessDenied:
          "access_denied"
        case .startAccessFailed:
          "start_access_failed"
        case .stopAccessFailed:
          "stop_access_failed"
        case .fileNotFound:
          "file_not_found"
        case .permissionDenied:
          "permission_denied"
        case .fileRelocated:
          "file_relocated"
        case .unsupportedFileType:
          "unsupported_file_type"
        case .serialisationFailed:
          "serialisation_failed"
        case .deserialisationFailed:
          "deserialisation_failed"
      }
    }

    /// Human-readable description of the error
    public var errorDescription: String {
      switch self {
        case let .creationFailed(url, reason):
          let baseMessage="Failed to create bookmark for file at \(url.path)"
          return reason.map { "\(baseMessage): \($0)" } ?? baseMessage
        case let .resolutionFailed(reason, underlyingError):
          var baseMessage="Failed to resolve bookmark"
          if let reason {
            baseMessage += ": \(reason)"
          }
          if let error=underlyingError {
            baseMessage += " (\(error.localizedDescription))"
          }
          return baseMessage
        case let .staleBookmark(url):
          return "Bookmark is stale for file at \(url.path)"
        case let .invalidBookmarkData(reason):
          let baseMessage="Invalid bookmark data format"
          return reason.map { "\(baseMessage): \($0)" } ?? baseMessage
        case let .accessDenied(url, reason):
          let baseMessage="Access denied to file at \(url.path)"
          return reason.map { "\(baseMessage): \($0)" } ?? baseMessage
        case let .startAccessFailed(url, reason):
          let baseMessage="Failed to start security-scoped access for \(url.path)"
          return reason.map { "\(baseMessage): \($0)" } ?? baseMessage
        case let .stopAccessFailed(url, reason):
          let baseMessage="Failed to stop security-scoped access for \(url.path)"
          return reason.map { "\(baseMessage): \($0)" } ?? baseMessage
        case let .fileNotFound(url):
          return "File does not exist at \(url.path)"
        case let .permissionDenied(url):
          return "Permission denied for file at \(url.path)"
        case let .fileRelocated(originalURL, currentURL):
          let baseMessage="File relocated from \(originalURL.path)"
          return currentURL.map { "\(baseMessage) to \($0.path)" } ?? baseMessage
        case let .unsupportedFileType(url, fileType):
          return "Unsupported file type '\(fileType)' for bookmarking at \(url.path)"
        case let .serialisationFailed(reason):
          let baseMessage="Failed to serialise bookmark data"
          return reason.map { "\(baseMessage): \($0)" } ?? baseMessage
        case let .deserialisationFailed(reason):
          let baseMessage="Failed to deserialise bookmark data"
          return reason.map { "\(baseMessage): \($0)" } ?? baseMessage
      }
    }

    /// Source information about where the error occurred
    public var source: UmbraErrorsCore.ErrorSource? {
      nil // Source is typically set when the error is created with context
    }

    /// The underlying error, if any
    public var underlyingError: Error? {
      if case let .resolutionFailed(_, error)=self {
        return error
      }
      return nil // Underlying error is typically set when the error is created with context
    }

    /// Additional context for the error
    public var context: UmbraErrorsCore.ErrorContext {
      UmbraErrorsCore.ErrorContext(
        source: domain,
        operation: "bookmark_operation",
        details: errorDescription
      )
    }

    /// Creates a new instance of the error with additional context
    public func with(context _: UmbraErrorsCore.ErrorContext) -> Self {
      // Since these are enum cases, we need to return a new instance with the same value
      switch self {
        case let .creationFailed(url, reason):
          .creationFailed(url: url, reason: reason)
        case let .resolutionFailed(reason, underlyingError):
          .resolutionFailed(reason: reason, underlyingError: underlyingError)
        case let .staleBookmark(url):
          .staleBookmark(url: url)
        case let .invalidBookmarkData(reason):
          .invalidBookmarkData(reason: reason)
        case let .accessDenied(url, reason):
          .accessDenied(url: url, reason: reason)
        case let .startAccessFailed(url, reason):
          .startAccessFailed(url: url, reason: reason)
        case let .stopAccessFailed(url, reason):
          .stopAccessFailed(url: url, reason: reason)
        case let .fileNotFound(url):
          .fileNotFound(url: url)
        case let .permissionDenied(url):
          .permissionDenied(url: url)
        case let .fileRelocated(originalURL, currentURL):
          .fileRelocated(originalURL: originalURL, currentURL: currentURL)
        case let .unsupportedFileType(url, fileType):
          .unsupportedFileType(url: url, fileType: fileType)
        case let .serialisationFailed(reason):
          .serialisationFailed(reason: reason)
        case let .deserialisationFailed(reason):
          .deserialisationFailed(reason: reason)
      }
      // In a real implementation, we would attach the context
    }

    /// Creates a new instance of the error with a specified underlying error
    public func with(underlyingError: Error) -> Self {
      // Since only resolutionFailed supports an underlying error directly
      if case let .resolutionFailed(reason, _)=self {
        return .resolutionFailed(reason: reason, underlyingError: underlyingError)
      }
      // For other cases, we would need a more complex implementation to store the error
      return self
    }

    /// Creates a new instance of the error with source information
    public func with(source _: UmbraErrorsCore.ErrorSource) -> Self {
      // Similar to above, return a new instance with the same value
      self // In a real implementation, we would attach the source information
    }
  }
}

// MARK: - Factory Methods

extension UmbraErrors.Bookmark.Core {
  /// Create an error for a failed bookmark creation
  public static func makeCreationFailedError(
    url: URL,
    reason: String?=nil,
    file _: String=#file,
    line _: Int=#line,
    function _: String=#function
  ) -> Self {
    .creationFailed(url: url, reason: reason)
  }

  /// Create an error for a failed bookmark resolution
  public static func makeResolutionFailedError(
    reason: String?=nil,
    underlyingError: Error?=nil,
    file _: String=#file,
    line _: Int=#line,
    function _: String=#function
  ) -> Self {
    .resolutionFailed(reason: reason, underlyingError: underlyingError)
  }

  /// Create an error for a stale bookmark
  public static func makeStaleBookmarkError(
    url: URL,
    file _: String=#file,
    line _: Int=#line,
    function _: String=#function
  ) -> Self {
    .staleBookmark(url: url)
  }

  /// Create an error for a file not found
  public static func makeFileNotFoundError(
    url: URL,
    file _: String=#file,
    line _: Int=#line,
    function _: String=#function
  ) -> Self {
    .fileNotFound(url: url)
  }

  /// Create an error for access denied
  public static func makeAccessDeniedError(
    url: URL,
    reason: String?=nil,
    file _: String=#file,
    line _: Int=#line,
    function _: String=#function
  ) -> Self {
    .accessDenied(url: url, reason: reason)
  }
}
