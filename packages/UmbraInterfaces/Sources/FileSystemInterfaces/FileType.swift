import Foundation

/**
 # FileType

 Enum representing the different types of files that can be managed by the file system.

 This follows the Alpha Dot Five architecture with:
 - Foundation-independent type definitions
 - British spelling in documentation
 - Comprehensive type options
 */
public enum FileType: String, Sendable, Equatable, Hashable, CaseIterable {
  /// Regular files containing data
  case regular

  /// Directory containing other files and directories
  case directory

  /// Symbolic link to another file or directory
  case symbolicLink

  /// Special character device
  case characterSpecial

  /// Block special file (such as a device file)
  case blockSpecial

  /// Named pipe (FIFO)
  case fifo

  /// Socket file
  case socket

  /// Unknown file type
  case unknown

  /**
   Creates a FileType from a file's URL resource values.

   - Parameter isDirectory: Whether the file is a directory
   - Parameter isSymbolicLink: Whether the file is a symbolic link
   - Returns: The corresponding FileType
   */
  public static func fromResourceValues(isDirectory: Bool, isSymbolicLink: Bool) -> FileType {
    if isSymbolicLink {
      .symbolicLink
    } else if isDirectory {
      .directory
    } else {
      .regular
    }
  }
}
