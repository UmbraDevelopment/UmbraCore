import Foundation

/**
 * Represents file permissions in a backup.
 *
 * This struct encapsulates the file mode bits that define permissions
 * for owner, group, and others.
 */
public struct FilePermissions: Sendable, Equatable, Hashable {
  /// The raw mode value
  public let mode: UInt16

  /// Creates a new file permissions instance
  /// - Parameter mode: The raw mode value
  public init(mode: UInt16) {
    self.mode=mode
  }

  /// Whether the owner can read the file
  public var ownerCanRead: Bool {
    (mode & 0o400) != 0
  }

  /// Whether the owner can write to the file
  public var ownerCanWrite: Bool {
    (mode & 0o200) != 0
  }

  /// Whether the owner can execute the file
  public var ownerCanExecute: Bool {
    (mode & 0o100) != 0
  }

  /// Whether the group can read the file
  public var groupCanRead: Bool {
    (mode & 0o040) != 0
  }

  /// Whether the group can write to the file
  public var groupCanWrite: Bool {
    (mode & 0o020) != 0
  }

  /// Whether the group can execute the file
  public var groupCanExecute: Bool {
    (mode & 0o010) != 0
  }

  /// Whether others can read the file
  public var othersCanRead: Bool {
    (mode & 0o004) != 0
  }

  /// Whether others can write to the file
  public var othersCanWrite: Bool {
    (mode & 0o002) != 0
  }

  /// Whether others can execute the file
  public var othersCanExecute: Bool {
    (mode & 0o001) != 0
  }

  /// Returns a string representation of the permissions (e.g., "rwxr-xr--")
  public var permissionString: String {
    var result=""

    // Owner permissions
    result += ownerCanRead ? "r" : "-"
    result += ownerCanWrite ? "w" : "-"
    result += ownerCanExecute ? "x" : "-"

    // Group permissions
    result += groupCanRead ? "r" : "-"
    result += groupCanWrite ? "w" : "-"
    result += groupCanExecute ? "x" : "-"

    // Others permissions
    result += othersCanRead ? "r" : "-"
    result += othersCanWrite ? "w" : "-"
    result += othersCanExecute ? "x" : "-"

    return result
  }

  // MARK: - Hashable

  /// Hash function for Hashable conformance
  public func hash(into hasher: inout Hasher) {
    hasher.combine(mode)
  }
}
