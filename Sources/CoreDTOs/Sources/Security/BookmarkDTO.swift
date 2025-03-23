import UmbraCoreTypes

/// A Foundation-independent representation of a file bookmark
/// Used for saving and restoring access to file system resources
public struct BookmarkDTO: Sendable, Equatable {
  // MARK: - Properties

  /// The raw bookmark data as bytes
  public let data: [UInt8]

  /// Path representation of the resource (for display purposes only)
  public let displayPath: String

  /// Indicates whether this bookmark has a security scope
  public let hasSecurityScope: Bool

  // MARK: - Initialization

  /// Create a bookmark DTO with the provided data
  /// - Parameters:
  ///   - data: The raw bookmark data as bytes
  ///   - displayPath: A string representation of the path (for display only)
  ///   - hasSecurityScope: Whether this bookmark has a security scope
  public init(
    data: [UInt8],
    displayPath: String,
    hasSecurityScope: Bool=false
  ) {
    self.data=data
    self.displayPath=displayPath
    self.hasSecurityScope=hasSecurityScope
  }

  // MARK: - Factory Methods

  /// Create an empty bookmark DTO
  /// - Returns: An empty bookmark DTO
  public static func empty() -> BookmarkDTO {
    BookmarkDTO(data: [], displayPath: "", hasSecurityScope: false)
  }
}

/// Extension with convenience methods for working with BookmarkDTO
extension BookmarkDTO {
  /// Check if this bookmark is valid
  /// - Returns: True if the bookmark has data, false otherwise
  public var isValid: Bool {
    !data.isEmpty
  }

  /// Create a new BookmarkDTO with updated security scope setting
  /// - Parameter hasSecurityScope: The new security scope setting
  /// - Returns: A new BookmarkDTO with the updated setting
  public func withSecurityScope(_ hasSecurityScope: Bool) -> BookmarkDTO {
    BookmarkDTO(
      data: data,
      displayPath: displayPath,
      hasSecurityScope: hasSecurityScope
    )
  }
}
