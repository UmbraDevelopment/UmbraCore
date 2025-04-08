import Foundation

/**
 * Represents the type of a file in a backup.
 *
 * This enum defines the various file types that can be encountered
 * during backup operations.
 */
public enum FileType: String, Sendable, Equatable, CaseIterable {
  /// Regular file
  case regular

  /// Directory
  case directory

  /// Symbolic link
  case symlink

  /// Socket
  case socket

  /// Named pipe
  case pipe

  /// Device file
  case device

  /// Unknown file type
  case unknown
}
