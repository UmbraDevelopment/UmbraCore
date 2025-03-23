import Foundation
import UmbraCoreTypes

/// A Foundation-independent representation of a file path
public struct FilePathDTO: Sendable, Equatable {
  // MARK: - Types

  /// Type of resource the path represents
  public enum ResourceType: String, Sendable, Equatable {
    /// A file resource
    case file

    /// A directory resource
    case directory

    /// A symbolic link
    case symbolicLink

    /// Unknown resource type
    case unknown
  }

  // MARK: - Properties

  /// The absolute path as a string
  public let path: String

  /// The file name component
  public let fileName: String

  /// The directory path component
  public let directoryPath: String

  /// The resource type
  public let resourceType: ResourceType

  /// Whether the path is absolute
  public let isAbsolute: Bool

  // MARK: - Initialization

  /// Create a file path DTO
  /// - Parameters:
  ///   - path: The full path as a string
  ///   - fileName: The file name component
  ///   - directoryPath: The directory path component
  ///   - resourceType: The type of resource this path represents
  ///   - isAbsolute: Whether this is an absolute path
  public init(
    path: String,
    fileName: String,
    directoryPath: String,
    resourceType: ResourceType = .unknown,
    isAbsolute: Bool=true
  ) {
    self.path=path
    self.fileName=fileName
    self.directoryPath=directoryPath
    self.resourceType=resourceType
    self.isAbsolute=isAbsolute
  }

  // MARK: - Factory Methods

  /// Create a path DTO from a string path
  /// - Parameter path: The string path
  /// - Returns: A new FilePathDTO
  public static func fromString(_ path: String) -> FilePathDTO {
    // Simple path component extraction
    let components=path.split(separator: "/")
    let fileName=components.last.map(String.init) ?? ""
    let directoryPath=components.dropLast().joined(separator: "/")
    let fullDirectoryPath=path.hasPrefix("/") ? "/\(directoryPath)" : directoryPath

    return FilePathDTO(
      path: path,
      fileName: fileName,
      directoryPath: fullDirectoryPath,
      resourceType: .unknown,
      isAbsolute: path.hasPrefix("/")
    )
  }

  /// Create a temporary file path
  /// - Parameter prefix: Optional file name prefix
  /// - Returns: A path to a temporary location
  public static func temporary(prefix: String="tmp") -> FilePathDTO {
    let uniqueName="\(prefix)_\(UUID().uuidString)"
    return FilePathDTO(
      path: "/tmp/\(uniqueName)",
      fileName: uniqueName,
      directoryPath: "/tmp",
      resourceType: .file,
      isAbsolute: true
    )
  }
}

/// Extension with convenience methods for FilePathDTO
extension FilePathDTO {
  /// Create a new path by appending a component
  /// - Parameter component: Component to append
  /// - Returns: A new path with the component appended
  public func appendingComponent(_ component: String) -> FilePathDTO {
    let newPath="\(path)/\(component)"
    return FilePathDTO.fromString(newPath)
  }

  /// Create a new path with a modified resource type
  /// - Parameter resourceType: The new resource type
  /// - Returns: A new path with updated resource type
  public func withResourceType(_ resourceType: ResourceType) -> FilePathDTO {
    FilePathDTO(
      path: path,
      fileName: fileName,
      directoryPath: directoryPath,
      resourceType: resourceType,
      isAbsolute: isAbsolute
    )
  }
}
