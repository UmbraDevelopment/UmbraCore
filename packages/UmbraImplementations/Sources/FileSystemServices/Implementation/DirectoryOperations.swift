import FileSystemInterfaces
import FileSystemTypes
import Foundation
import LoggingTypes

/**
 # Directory Operations Extension

 This extension provides directory-specific operations for the FileSystemServiceImpl,
 including listing, creating, and removing directories.
 */
extension FileSystemServiceImpl {
  /**
   Creates a directory at the specified path.

   - Parameters:
      - path: The directory path to create
      - withIntermediates: Whether to create intermediate directories
   - Throws: `FileSystemError.writeError` if the directory cannot be created
             `FileSystemError.pathAlreadyExists` if a file already exists at the path
   */
  public func createDirectory(
    at path: FilePath,
    withIntermediates: Bool=true
  ) async throws {
    guard !path.path.isEmpty else {
      throw FileSystemInterfaces.FileSystemError.invalidPath(
        path: "",
        reason: "Empty path provided"
      )
    }

    let url=URL(fileURLWithPath: path.path)

    // Check if a file (not directory) already exists at this path
    if fileManager.fileExists(atPath: path.path) {
      var isDir: ObjCBool=false
      fileManager.fileExists(atPath: path.path, isDirectory: &isDir)

      if !isDir.boolValue {
        await logger.warning(
          "Cannot create directory, file exists at path: \(path.path)",
          metadata: nil,
          source: "FileSystemService"
        )
        throw FileSystemInterfaces.FileSystemError.pathAlreadyExists(path: path.path)
      } else if !withIntermediates {
        // Directory already exists, which is fine
        await logger.debug(
          "Directory already exists at \(path.path)",
          metadata: nil,
          source: "FileSystemService"
        )
        return
      }
    }

    do {
      try fileManager.createDirectory(
        at: url,
        withIntermediateDirectories: withIntermediates,
        attributes: nil
      )

      await logger.debug(
        "Created directory at \(path.path)",
        metadata: nil,
        source: "FileSystemService"
      )
    } catch {
      await logger.error(
        "Failed to create directory at \(path.path): \(error.localizedDescription)",
        metadata: nil,
        source: "FileSystemService"
      )
      throw FileSystemInterfaces.FileSystemError.writeError(
        path: path.path,
        reason: error.localizedDescription
      )
    }
  }

  /**
   Checks if a directory is empty.

   - Parameter path: The directory path to check
   - Returns: Whether the directory is empty
   - Throws: `FileSystemError.invalidPath` if the path is invalid
             `FileSystemError.pathNotFound` if the directory does not exist
             `FileSystemError.invalidPath` if the path is not a directory
             `FileSystemError.readError` if the directory cannot be read
   */
  public func isDirectoryEmpty(at path: FilePath) async throws -> Bool {
    guard !path.path.isEmpty else {
      throw FileSystemInterfaces.FileSystemError.invalidPath(
        path: "",
        reason: "Empty path provided"
      )
    }

    // Check if the path exists
    if !fileManager.fileExists(atPath: path.path) {
      throw FileSystemInterfaces.FileSystemError.pathNotFound(path: path.path)
    }

    // Check if the path is a directory
    var isDir: ObjCBool=false
    fileManager.fileExists(atPath: path.path, isDirectory: &isDir)

    if !isDir.boolValue {
      throw FileSystemInterfaces.FileSystemError.invalidPath(
        path: path.path,
        reason: "Path is not a directory"
      )
    }

    do {
      let contents=try fileManager.contentsOfDirectory(atPath: path.path)
      let isEmpty=contents.isEmpty

      await logger.debug(
        "Checked if directory is empty at \(path.path): \(isEmpty)",
        metadata: nil,
        source: "FileSystemService"
      )

      return isEmpty
    } catch {
      await logger.error(
        "Failed to check if directory is empty at \(path.path): \(error.localizedDescription)",
        metadata: nil,
        source: "FileSystemService"
      )
      throw FileSystemInterfaces.FileSystemError.readError(
        path: path.path,
        reason: error.localizedDescription
      )
    }
  }
}
