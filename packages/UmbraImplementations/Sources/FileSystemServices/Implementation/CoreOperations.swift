import FileSystemInterfaces
import FileSystemTypes
import Foundation
import LoggingTypes

/**
 # Core File System Operations Extension

 This extension implements the core operations required by the FileSystemServiceProtocol,
 providing the essential functionality for the file system service.
 */
extension FileSystemServiceImpl {
  /**
   Removes an item at the specified path.

   - Parameters:
      - path: The path to remove
      - recursive: Whether to remove directories recursively
   - Throws: `FileSystemError.pathNotFound` if the path doesn't exist
             `FileSystemError.writeError` if the item cannot be removed
   */
  public func remove(
    at path: FilePath,
    recursive: Bool=false
  ) async throws {
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

    // Check if it's a directory and recursive flag is required
    if recursive == false {
      var isDir: ObjCBool=false
      fileManager.fileExists(atPath: path.path, isDirectory: &isDir)

      if isDir.boolValue {
        let contents=try fileManager.contentsOfDirectory(atPath: path.path)
        if !contents.isEmpty {
          throw FileSystemInterfaces.FileSystemError.writeError(
            path: path.path,
            reason: "Cannot remove non-empty directory without recursive flag"
          )
        }
      }
    }

    do {
      try fileManager.removeItem(atPath: path.path)

      await logger.debug("Removed item at \(path.path)", metadata: nil, source: "FileSystemService")
    } catch {
      await logger.error(
        "Failed to remove item at \(path.path): \(error.localizedDescription)",
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
   Copies an item from one path to another.

   - Parameters:
      - sourcePath: The source path
      - destinationPath: The destination path
      - overwrite: Whether to overwrite existing files
      - preserveAttributes: Whether to preserve file attributes
   - Throws: `FileSystemError.pathNotFound` if the source doesn't exist
             `FileSystemError.pathAlreadyExists` if the destination exists and overwrite is false
             `FileSystemError.writeError` if the copy operation fails
   */
  public func copy(
    from sourcePath: FilePath,
    to destinationPath: FilePath,
    overwrite: Bool=false,
    preserveAttributes _: Bool=true
  ) async throws {
    guard !sourcePath.path.isEmpty else {
      throw FileSystemInterfaces.FileSystemError.invalidPath(
        path: "",
        reason: "Empty source path provided"
      )
    }

    guard !destinationPath.path.isEmpty else {
      throw FileSystemInterfaces.FileSystemError.invalidPath(
        path: "",
        reason: "Empty destination path provided"
      )
    }

    // Check if source exists
    if !fileManager.fileExists(atPath: sourcePath.path) {
      throw FileSystemInterfaces.FileSystemError.pathNotFound(path: sourcePath.path)
    }

    // Check if destination already exists
    if fileManager.fileExists(atPath: destinationPath.path) {
      if !overwrite {
        throw FileSystemInterfaces.FileSystemError.pathAlreadyExists(path: destinationPath.path)
      }

      // Remove existing destination if overwrite is true
      do {
        try fileManager.removeItem(atPath: destinationPath.path)
      } catch {
        throw FileSystemInterfaces.FileSystemError.writeError(
          path: destinationPath.path,
          reason: "Failed to remove existing item: \(error.localizedDescription)"
        )
      }
    }

    // Ensure parent directory exists
    let destinationURL=URL(fileURLWithPath: destinationPath.path)
    let destinationDir=destinationURL.deletingLastPathComponent()

    if !fileManager.fileExists(atPath: destinationDir.path) {
      do {
        try fileManager.createDirectory(
          at: destinationDir,
          withIntermediateDirectories: true,
          attributes: nil
        )
      } catch {
        throw FileSystemInterfaces.FileSystemError.writeError(
          path: destinationDir.path,
          reason: "Failed to create parent directory: \(error.localizedDescription)"
        )
      }
    }

    // Perform the copy operation
    do {
      try fileManager.copyItem(
        atPath: sourcePath.path,
        toPath: destinationPath.path
      )

      await logger.debug(
        "Copied item from \(sourcePath.path) to \(destinationPath.path)",
        metadata: nil,
        source: "FileSystemService"
      )
    } catch {
      await logger.error(
        "Failed to copy from \(sourcePath.path) to \(destinationPath.path): \(error.localizedDescription)",
        metadata: nil,
        source: "FileSystemService"
      )
      throw FileSystemInterfaces.FileSystemError.writeError(
        path: destinationPath.path,
        reason: error.localizedDescription
      )
    }
  }

  /**
   Moves an item from one path to another.

   - Parameters:
      - sourcePath: The source path
      - destinationPath: The destination path
      - overwrite: Whether to overwrite existing files
   - Throws: `FileSystemError.pathNotFound` if the source doesn't exist
             `FileSystemError.pathAlreadyExists` if the destination exists and overwrite is false
             `FileSystemError.writeError` if the move operation fails
   */
  public func move(
    from sourcePath: FilePath,
    to destinationPath: FilePath,
    overwrite: Bool=false
  ) async throws {
    guard !sourcePath.path.isEmpty else {
      throw FileSystemInterfaces.FileSystemError.invalidPath(
        path: "",
        reason: "Empty source path provided"
      )
    }

    guard !destinationPath.path.isEmpty else {
      throw FileSystemInterfaces.FileSystemError.invalidPath(
        path: "",
        reason: "Empty destination path provided"
      )
    }

    // Check if source exists
    if !fileManager.fileExists(atPath: sourcePath.path) {
      throw FileSystemInterfaces.FileSystemError.pathNotFound(path: sourcePath.path)
    }

    // Check if destination already exists
    if fileManager.fileExists(atPath: destinationPath.path) {
      if !overwrite {
        throw FileSystemInterfaces.FileSystemError.pathAlreadyExists(path: destinationPath.path)
      }

      // Remove existing destination if overwrite is true
      do {
        try fileManager.removeItem(atPath: destinationPath.path)
      } catch {
        throw FileSystemInterfaces.FileSystemError.writeError(
          path: destinationPath.path,
          reason: "Failed to remove existing item: \(error.localizedDescription)"
        )
      }
    }

    // Ensure parent directory exists
    let destinationURL=URL(fileURLWithPath: destinationPath.path)
    let destinationDir=destinationURL.deletingLastPathComponent()

    if !fileManager.fileExists(atPath: destinationDir.path) {
      do {
        try fileManager.createDirectory(
          at: destinationDir,
          withIntermediateDirectories: true,
          attributes: nil
        )
      } catch {
        throw FileSystemInterfaces.FileSystemError.writeError(
          path: destinationDir.path,
          reason: "Failed to create parent directory: \(error.localizedDescription)"
        )
      }
    }

    // Perform the move operation
    do {
      try fileManager.moveItem(
        atPath: sourcePath.path,
        toPath: destinationPath.path
      )

      await logger.debug(
        "Moved item from \(sourcePath.path) to \(destinationPath.path)",
        metadata: nil,
        source: "FileSystemService"
      )
    } catch {
      await logger.error(
        "Failed to move from \(sourcePath.path) to \(destinationPath.path): \(error.localizedDescription)",
        metadata: nil,
        source: "FileSystemService"
      )
      throw FileSystemInterfaces.FileSystemError.writeError(
        path: destinationPath.path,
        reason: error.localizedDescription
      )
    }
  }

  // MARK: - Backwards Compatibility Methods

  /**
   Removes an item at the specified path (alias for remove(at:recursive:)).

   - Parameters:
      - path: The path to remove
      - recursive: Whether to remove directories recursively
   - Throws: `FileSystemError` if the operation fails
   */
  public func removeItem(
    at path: FilePath,
    recursive: Bool=false
  ) async throws {
    try await remove(at: path, recursive: recursive)
  }

  /**
   Copies an item from one path to another (alias for copy(from:to:overwrite:preserveAttributes:)).

   - Parameters:
      - source: The source path
      - destination: The destination path
      - overwrite: Whether to overwrite existing files
      - preserveAttributes: Whether to preserve file attributes
   - Throws: `FileSystemError` if the operation fails
   */
  public func copyItem(
    at source: FilePath,
    to destination: FilePath,
    overwrite: Bool=false,
    preserveAttributes: Bool=true
  ) async throws {
    try await copy(
      from: source,
      to: destination,
      overwrite: overwrite,
      preserveAttributes: preserveAttributes
    )
  }

  /**
   Moves an item from one path to another (alias for move(from:to:overwrite:)).

   - Parameters:
      - sourcePath: The source path
      - destinationPath: The destination path
      - overwrite: Whether to overwrite existing files
   - Throws: `FileSystemError` if the operation fails
   */
  public func moveItem(
    from sourcePath: FilePath,
    to destinationPath: FilePath,
    overwrite: Bool=false
  ) async throws {
    try await move(from: sourcePath, to: destinationPath, overwrite: overwrite)
  }
}
