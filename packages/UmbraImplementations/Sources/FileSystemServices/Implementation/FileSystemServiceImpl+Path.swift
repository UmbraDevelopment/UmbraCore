import CoreDTOs
import FileSystemInterfaces
import FileSystemTypes
import Foundation
import LoggingTypes

/**
 # Path Operations Extension

 This extension provides path manipulation and normalisation operations for the
 FileSystemServiceImpl, enabling standardised handling of file paths.
 */
extension FileSystemServiceImpl {
  /**
   Normalises a file path, resolving any relative components and symlinks.

   - Parameter path: The path to normalise
   - Returns: The normalised path
   - Throws: `FileSystemError.invalidPath` if the path is invalid
             `FileSystemError.readError` if path resolution fails
   */
  public func normalisePath(_ path: FilePathDTO) async throws -> FilePathDTO {
    guard !path.path.isEmpty else {
      throw FileSystemInterfaces.FileSystemError.invalidPath(
        path: "",
        reason: "Empty path provided"
      )
    }

    // Convert to URL for standardisation
    let url=URL(fileURLWithPath: path.path)

    // Resolve any relative components (such as "../" or "./")
    let standardisedURL=url.standardized

    do {
      // This can fail if we don't have permission to access the file system
      // Force unwrapping this is safe as we've already checked path.path is not empty
      let resolvedURL=try FileManager.default.fileExists(atPath: standardisedURL.path)
        ? URL(
          fileURLWithPath: FileManager.default
            .destinationOfSymbolicLink(atPath: standardisedURL.path),
          isDirectory: path.isDirectory
        )
        : standardisedURL

      // Create a new FilePath with the resolved path
      return FilePathDTO(
        path: resolvedURL.path,
        isDirectory: path.isDirectory,
        securityOptions: path.securityOptions
      )
    } catch {
      throw FileSystemInterfaces.FileSystemError.readError(
        path: path.path,
        reason: "Failed to resolve path: \(error.localizedDescription)"
      )
    }
  }

  /**
   Joins a base path with a component, handling path separators correctly.

   - Parameters:
     - base: The base path
     - component: The component to append
   - Returns: The joined path
   - Throws: `FileSystemError.invalidPath` if the base path is invalid
   */
  public func joinPath(_ base: FilePathDTO, with component: String) async throws -> FilePathDTO {
    guard !base.path.isEmpty else {
      throw FileSystemInterfaces.FileSystemError.invalidPath(
        path: "",
        reason: "Empty base path provided"
      )
    }

    // Start with the base path
    var fullPath=base.path

    // Add a path separator if needed
    if !fullPath.hasSuffix("/") && !component.hasPrefix("/") {
      fullPath += "/"
    }

    // Append the component
    fullPath += component

    // Create and return a new FilePath
    return FilePathDTO(
      path: fullPath,
      isDirectory: component.hasSuffix("/"),
      securityOptions: base.securityOptions
    )
  }

  /**
   Gets the directory path component from a file path.

   - Parameter path: The path to extract the directory from
   - Returns: The directory path
   */
  public func directoryPath(from path: FilePathDTO) async -> FilePathDTO {
    guard !path.path.isEmpty else {
      return FilePathDTO(path: "")
    }

    // If it's already a directory, return it as is
    if path.isDirectory {
      return path
    }

    // Get the directory component
    let url=URL(fileURLWithPath: path.path)
    let directoryURL=url.deletingLastPathComponent()

    // Create and return a new FilePath
    return FilePathDTO(
      path: directoryURL.path,
      isDirectory: true,
      securityOptions: path.securityOptions
    )
  }

  /**
   Creates a unique filename in the specified directory.

   - Parameters:
     - directory: The directory in which to create the unique name
     - prefix: Optional prefix for the file name
     - extension: Optional file extension
   - Returns: A path with a unique filename
   - Throws: `FileSystemError.invalidPath` if the directory is invalid
             `FileSystemError.writeError` if the operation fails
   */
  public func createUniqueFilename(
    in directory: String,
    prefix: String?,
    extension: String?
  ) async throws -> FilePathDTO {
    guard !directory.isEmpty else {
      throw FileSystemInterfaces.FileSystemError.invalidPath(
        path: "",
        reason: "Empty directory path provided"
      )
    }

    // Build the unique filename components
    let filenamePrefix=prefix ?? "file"
    let filenameExtension=`extension` != nil ? ".\(`extension`!)" : ""
    let uniqueComponent=UUID().uuidString

    // Create the full path
    let directoryPath=directory.hasSuffix("/") ? directory : "\(directory)/"
    let filename="\(filenamePrefix)_\(uniqueComponent)\(filenameExtension)"
    let fullPath="\(directoryPath)\(filename)"

    // Return the new path
    return FilePathDTO(path: fullPath)
  }

  /**
   Gets the directory path from a file path (non-isolated helper).

   - Parameter path: The path to extract the directory from
   - Returns: The directory path
   */
  public nonisolated func directoryPath(_ path: FilePathDTO) -> FilePathDTO {
    guard !path.path.isEmpty else {
      return FilePathDTO(path: "")
    }

    // If it's already marked as a directory, return it
    if path.isDirectory {
      return path
    }

    // Otherwise extract the directory component
    let url=URL(fileURLWithPath: path.path)
    let directoryURL=url.deletingLastPathComponent()

    return FilePathDTO(
      path: directoryURL.path,
      isDirectory: true,
      securityOptions: path.securityOptions
    )
  }

  /**
   Joins a base path with a component (non-isolated helper).

   - Parameters:
     - base: The base path
     - component: The component to append
   - Returns: The joined path
   */
  public nonisolated func joinPath(
    _ base: FilePathDTO,
    with component: String
  ) -> FilePathDTO {
    guard !base.path.isEmpty else {
      return FilePathDTO(path: component)
    }

    // Start with the base path
    var fullPath=base.path

    // Add a path separator if needed
    if !fullPath.hasSuffix("/") && !component.hasPrefix("/") {
      fullPath += "/"
    }

    // Append the component
    fullPath += component

    // Create and return a new FilePath
    return FilePathDTO(
      path: fullPath,
      isDirectory: component.hasSuffix("/"),
      securityOptions: base.securityOptions
    )
  }

  /**
   Gets the file name component of a path.

   - Parameter path: The path to extract the file name from
   - Returns: The file name component, or an empty string if the path ends with a directory separator
   */
  public func fileName(from path: FilePathDTO) async -> String {
    guard !path.path.isEmpty else {
      return ""
    }

    let url=URL(fileURLWithPath: path.path)
    let fileName=url.lastPathComponent

    await logger.debug(
      "Extracted file name",
      context: FileSystemLogContext(
        operation: "getFileName",
        path: path.path,
        source: "FileSystemService"
      ).withUpdatedMetadata(
        LogMetadataDTOCollection().withPublic(key: "fileName", value: fileName)
      )
    )

    return fileName
  }

  /**
   Gets the directory component of a path.

   - Parameter path: The path to extract the directory from
   - Returns: The directory component
   */
  public func directoryPath(from path: FilePathDTO) async -> FilePathDTO {
    guard !path.path.isEmpty else {
      return FilePathDTO(path: "")
    }

    let url=URL(fileURLWithPath: path.path)
    let directoryURL=url.deletingLastPathComponent()
    let directoryPath=FilePathDTO(path: directoryURL.path)

    await logger.debug(
      "Extracted directory path",
      context: FileSystemLogContext(
        operation: "getDirectoryPath",
        path: path.path,
        source: "FileSystemService"
      ).withUpdatedMetadata(
        LogMetadataDTOCollection().withPublic(key: "directoryPath", value: directoryPath.path)
      )
    )

    return directoryPath
  }

  /**
   Gets the file extension component of a path.

   - Parameter path: The path to extract the extension from
   - Returns: The file extension (without the leading dot), or an empty string if there is no extension
   */
  public func fileExtension(from path: FilePathDTO) async -> String {
    guard !path.path.isEmpty else {
      return ""
    }

    let url=URL(fileURLWithPath: path.path)
    let fileExtension=url.pathExtension

    await logger.debug(
      "Extracted file extension",
      context: FileSystemLogContext(
        operation: "getFileExtension",
        path: path.path,
        source: "FileSystemService"
      ).withUpdatedMetadata(
        LogMetadataDTOCollection().withPublic(key: "fileExtension", value: fileExtension)
      )
    )

    return fileExtension
  }

  /**
   Creates a new path with a different extension.

   - Parameters:
      - path: The original path
      - extension: The new extension (without the leading dot)
   - Returns: A new path with the specified extension
   - Throws: `FileSystemError.invalidPath` if the path is invalid
   */
  public func changingFileExtension(
    of path: FilePathDTO,
    to `extension`: String
  ) async throws -> FilePathDTO {
    guard !path.path.isEmpty else {
      throw FileSystemInterfaces.FileSystemError.invalidPath(
        path: "",
        reason: "Empty path provided"
      )
    }

    let url=URL(fileURLWithPath: path.path)
    let fileName=url.deletingPathExtension().lastPathComponent
    let directory=url.deletingLastPathComponent()

    // Create the new file name with the specified extension
    let newFileName: String=if `extension`.isEmpty {
      fileName
    } else {
      fileName + "." + `extension`
    }

    let newURL=directory.appendingPathComponent(newFileName)
    let newPath=FilePathDTO(path: newURL.path)

    await logger.debug(
      "Changed file extension",
      context: FileSystemLogContext(
        operation: "changeFileExtension",
        path: path.path,
        source: "FileSystemService"
      ).withUpdatedMetadata(
        LogMetadataDTOCollection()
          .withPublic(key: "newExtension", value: `extension`)
          .withPublic(key: "newPath", value: newPath.path)
      )
    )

    return newPath
  }

  /**
   Gets the filename component of a path.

   - Parameter path: The path
   - Returns: The filename component
   */
  public func getFilename(_ path: String) async -> String {
    (path as NSString).lastPathComponent
  }

  /**
   Gets the extension of a path.

   - Parameter path: The path
   - Returns: The extension
   */
  public func getExtension(_ path: String) async -> String {
    (path as NSString).pathExtension
  }

  /**
   Gets the directory name component of a path.

   - Parameter path: The path
   - Returns: The directory name component
   */
  public func getDirectoryName(_ path: String) async -> String {
    (path as NSString).deletingLastPathComponent
  }

  // MARK: - Non-Isolated Path Methods (Protocol Conformance)

  /**
   Extracts the file name component from a path (non-isolated version).

   - Parameter path: The path to process
   - Returns: The file name component
   */
  public nonisolated func fileName(_ path: FilePathDTO) -> String {
    guard !path.path.isEmpty else {
      return ""
    }

    let url=URL(fileURLWithPath: path.path)
    return url.lastPathComponent
  }

  /**
   Extracts the directory component from a path (non-isolated version).

   - Parameter path: The path to process
   - Returns: The directory component
   */
  public nonisolated func directoryPath(_ path: FilePathDTO) -> FilePathDTO {
    guard !path.path.isEmpty else {
      return FilePathDTO(path: "")
    }

    let url=URL(fileURLWithPath: path.path)
    let directoryURL=url.deletingLastPathComponent()
    return FilePathDTO(path: directoryURL.path)
  }

  /**
   Joins a base path with additional components (non-isolated version).

   - Parameters:
      - base: The base path
      - components: Additional path components to join
   - Returns: The combined path
   */
  public nonisolated func joinPath(
    _ base: FilePathDTO,
    withComponents components: [String]
  ) -> FilePathDTO {
    guard !base.path.isEmpty else {
      return base
    }

    var url=URL(fileURLWithPath: base.path)

    for component in components {
      if !component.isEmpty {
        url=url.appendingPathComponent(component)
      }
    }

    return FilePathDTO(path: url.path)
  }

  /**
   Checks if a path is within a specified directory (non-isolated version).

   - Parameters:
      - path: The path to check
      - directory: The directory to check against
   - Returns: True if path is a subpath of directory
   */
  public nonisolated func isSubpath(
    _ path: FilePathDTO,
    of directory: FilePathDTO
  ) -> Bool {
    guard !path.path.isEmpty && !directory.path.isEmpty else {
      return false
    }

    let pathComponents=URL(fileURLWithPath: path.path).standardized.pathComponents
    let dirComponents=URL(fileURLWithPath: directory.path).standardized.pathComponents

    // If directory has more components than path, path cannot be a subpath
    if dirComponents.count > pathComponents.count {
      return false
    }

    // Check that all directory components match the beginning of path components
    for i in 0..<dirComponents.count {
      if pathComponents[i] != dirComponents[i] {
        return false
      }
    }

    return true
  }
}
