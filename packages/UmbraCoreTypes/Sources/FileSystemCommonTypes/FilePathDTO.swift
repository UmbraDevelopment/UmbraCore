import Foundation

/// A Foundation-independent representation of a file path
///
/// This is the canonical path representation for the Alpha Dot Five architecture,
/// providing a comprehensive and type-safe way to work with file paths.
public struct FilePathDTO: Sendable, Equatable, Hashable {
  // MARK: - Types

  /// Type of resource the path represents
  public enum ResourceType: String, Sendable, Equatable, Hashable {
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

  /// Whether this path represents a directory (for compatibility)
  public var isDirectory: Bool {
    resourceType == .directory
  }

  /// Whether the path is absolute
  public let isAbsolute: Bool

  /// Security options for this path
  public let securityOptions: SecurityOptions?

  // MARK: - Initialization

  /// Create a file path DTO
  /// - Parameters:
  ///   - path: The full path as a string
  ///   - fileName: The file name component
  ///   - directoryPath: The directory path component
  ///   - resourceType: The type of resource this path represents
  ///   - isAbsolute: Whether this is an absolute path
  ///   - securityOptions: Optional security options for this path
  public init(
    path: String,
    fileName: String,
    directoryPath: String,
    resourceType: ResourceType = .unknown,
    isAbsolute: Bool=true,
    securityOptions: SecurityOptions?=nil
  ) {
    self.path=path
    self.fileName=fileName
    self.directoryPath=directoryPath
    self.resourceType=resourceType
    self.isAbsolute=isAbsolute
    self.securityOptions=securityOptions
  }

  /// Creates a new file path with simplified parameters
  /// - Parameters:
  ///   - path: The string representation of the path
  ///   - isDirectory: Whether this path represents a directory
  ///   - securityOptions: Optional security options for this path
  public init(
    path: String,
    isDirectory: Bool=false,
    securityOptions: SecurityOptions?=nil
  ) {
    let components=path.split(separator: "/")
    let fileName=components.last.map(String.init) ?? ""
    let directoryPath=components.dropLast().joined(separator: "/")
    let fullDirectoryPath=path.hasPrefix("/") ? "/\(directoryPath)" : directoryPath

    self.path=path
    self.fileName=fileName
    self.directoryPath=fullDirectoryPath
    resourceType=isDirectory ? .directory : .file
    isAbsolute=path.hasPrefix("/")
    self.securityOptions=securityOptions
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
      isAbsolute: isAbsolute,
      securityOptions: securityOptions
    )
  }

  /// Create a new path with updated security options
  /// - Parameter securityOptions: The new security options
  /// - Returns: A new path with updated security options
  public func withSecurityOptions(_ securityOptions: SecurityOptions?) -> FilePathDTO {
    FilePathDTO(
      path: path,
      fileName: fileName,
      directoryPath: directoryPath,
      resourceType: resourceType,
      isAbsolute: isAbsolute,
      securityOptions: securityOptions
    )
  }
}
