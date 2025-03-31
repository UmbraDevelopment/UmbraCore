import FileSystemInterfaces
import FileSystemTypes
import Foundation
import LoggingTypes

/**
 # File Operations Extension

 This extension provides file-specific operations for the FileSystemServiceImpl,
 including reading, writing, and manipulating files.
 */
extension FileSystemServiceImpl {
  /**
   Reads the entire contents of a file as bytes.

   - Parameter path: The path to read from
   - Returns: The file contents as an array of bytes
   - Throws: `FileSystemError.readError` if the file cannot be read
   */
  public func readFile(at path: FilePath) async throws -> [UInt8] {
    guard !path.path.isEmpty else {
      throw FileSystemInterfaces.FileSystemError.invalidPath(
        path: "",
        reason: "Empty path provided"
      )
    }

    do {
      let data=try Data(contentsOf: URL(fileURLWithPath: path.path))
      let bytes=[UInt8](data)

      await logger.debug(
        "Read \(bytes.count) bytes from \(path.path)",
        metadata: nil,
        source: "FileSystemService"
      )

      return bytes
    } catch {
      await logger.error(
        "Failed to read file at \(path.path): \(error.localizedDescription)",
        metadata: nil,
        source: "FileSystemService"
      )
      throw FileSystemInterfaces.FileSystemError.readError(
        path: path.path,
        reason: error.localizedDescription
      )
    }
  }

  /**
   Reads data from a file (protocol conformance).

   - Parameter path: The file path to read
   - Returns: The file data as a byte array
   - Throws: `FileSystemError` if the operation fails
   */
  public func readData(at path: FilePath) async throws -> [UInt8] {
    try await readFile(at: path)
  }

  /**
   Reads the text contents of a file using the specified encoding.

   - Parameters:
      - path: The path to read from
      - encoding: The text encoding to use (defaults to UTF-8)
   - Returns: The file contents as a string
   - Throws: `FileSystemError.readError` if the file cannot be read or decoded
   */
  public func readTextFile(
    at path: FilePath,
    encoding: String.Encoding = .utf8
  ) async throws -> String {
    guard !path.path.isEmpty else {
      throw FileSystemInterfaces.FileSystemError.invalidPath(
        path: "",
        reason: "Empty path provided"
      )
    }

    do {
      let data=try Data(contentsOf: URL(fileURLWithPath: path.path))

      guard let string=String(data: data, encoding: encoding) else {
        throw FileSystemInterfaces.FileSystemError.readError(
          path: path.path,
          reason: "Failed to decode content with encoding \(encoding)"
        )
      }

      await logger.debug(
        "Read text file (\(data.count) bytes) from \(path.path)",
        metadata: nil,
        source: "FileSystemService"
      )

      return string
    } catch let fsError as FileSystemInterfaces.FileSystemError {
      // Rethrow FileSystemError directly
      throw fsError
    } catch {
      await logger.error(
        "Failed to read text file at \(path.path): \(error.localizedDescription)",
        metadata: nil,
        source: "FileSystemService"
      )
      throw FileSystemInterfaces.FileSystemError.readError(
        path: path.path,
        reason: error.localizedDescription
      )
    }
  }

  /**
   Writes bytes to a file.

   - Parameters:
      - bytes: The bytes to write
      - path: The path to write to
      - createDirectories: Whether to create parent directories if they don't exist
   - Throws: `FileSystemError.writeError` if the file cannot be written
             `FileSystemError.writeError` if required directories cannot be created
   */
  public func writeFile(
    bytes: [UInt8],
    to path: FilePath,
    createDirectories: Bool=true
  ) async throws {
    guard !path.path.isEmpty else {
      throw FileSystemInterfaces.FileSystemError.invalidPath(
        path: "",
        reason: "Empty path provided"
      )
    }

    let url=URL(fileURLWithPath: path.path)

    // Create parent directory if it doesn't exist
    if createDirectories {
      let directory=url.deletingLastPathComponent()
      do {
        try fileManager.createDirectory(
          at: directory,
          withIntermediateDirectories: true,
          attributes: nil
        )
      } catch {
        await logger.error(
          "Failed to create parent directories for \(path.path): \(error.localizedDescription)",
          metadata: nil,
          source: "FileSystemService"
        )
        throw FileSystemInterfaces.FileSystemError.writeError(
          path: directory.path,
          reason: "Failed to create parent directories: \(error.localizedDescription)"
        )
      }
    }

    do {
      let data=Data(bytes)
      try data.write(to: url)

      await logger.debug(
        "Wrote \(bytes.count) bytes to \(path.path)",
        metadata: nil,
        source: "FileSystemService"
      )
    } catch {
      await logger.error(
        "Failed to write file at \(path.path): \(error.localizedDescription)",
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
   Writes data to a file (protocol conformance).

   - Parameters:
      - data: The data to write
      - path: The file path to write to
      - overwrite: Whether to overwrite an existing file
   - Throws: `FileSystemError` if the operation fails
   */
  public func writeData(
    _ data: [UInt8],
    to path: FilePath,
    overwrite: Bool=true
  ) async throws {
    if !overwrite && fileManager.fileExists(atPath: path.path) {
      throw FileSystemInterfaces.FileSystemError.pathAlreadyExists(path: path.path)
    }

    try await writeFile(bytes: data, to: path, createDirectories: true)
  }

  /**
   Writes a text string to a file using the specified encoding.

   - Parameters:
      - text: The text to write
      - path: The file path to write to
      - encoding: The text encoding to use (defaults to UTF-8)
      - createDirectories: Whether to create parent directories if they don't exist
   - Throws: `FileSystemError.writeError` if the file cannot be written
             `FileSystemError.writeError` if the text cannot be encoded
             `FileSystemError.writeError` if required directories cannot be created
   */
  public func writeTextFile(
    text: String,
    to path: FilePath,
    encoding: String.Encoding = .utf8,
    createDirectories: Bool=true
  ) async throws {
    guard !path.path.isEmpty else {
      throw FileSystemInterfaces.FileSystemError.invalidPath(
        path: "",
        reason: "Empty path provided"
      )
    }

    guard let data=text.data(using: encoding) else {
      throw FileSystemInterfaces.FileSystemError.writeError(
        path: path.path,
        reason: "Failed to encode text with encoding \(encoding)"
      )
    }

    try await writeFile(
      bytes: [UInt8](data),
      to: path,
      createDirectories: createDirectories
    )
  }

  /**
   Appends data to a file.

   - Parameters:
      - data: The data to append
      - path: The file path to append to
   - Throws: `FileSystemError.invalidPath` if the path is invalid
             `FileSystemError.pathNotFound` if the file does not exist
             `FileSystemError.writeError` if the file cannot be written
   */
  public func appendData(
    _ data: [UInt8],
    to path: FilePath
  ) async throws {
    guard !path.path.isEmpty else {
      throw FileSystemInterfaces.FileSystemError.invalidPath(
        path: "",
        reason: "Empty path provided"
      )
    }

    let url=URL(fileURLWithPath: path.path)

    // Check if the file exists
    if !fileManager.fileExists(atPath: path.path) {
      throw FileSystemInterfaces.FileSystemError.pathNotFound(path: path.path)
    }

    do {
      let fileHandle=try FileHandle(forWritingTo: url)
      defer {
        try? fileHandle.close()
      }

      // Seek to the end of the file
      try fileHandle.seekToEnd()

      // Write the data
      let fileData=Data(data)
      try fileHandle.write(contentsOf: fileData)

      await logger.debug(
        "Appended \(data.count) bytes to \(path.path)",
        metadata: nil,
        source: "FileSystemService"
      )
    } catch {
      await logger.error(
        "Failed to append data to \(path.path): \(error.localizedDescription)",
        metadata: nil,
        source: "FileSystemService"
      )
      throw FileSystemInterfaces.FileSystemError.writeError(
        path: path.path,
        reason: "Failed to append data: \(error.localizedDescription)"
      )
    }
  }

  /**
   Appends text to a file using the specified encoding.

   - Parameters:
      - text: The text to append
      - path: The file path to append to
      - encoding: The text encoding to use (defaults to UTF-8)
   - Throws: `FileSystemError.writeError` if the file cannot be written
             `FileSystemError.writeError` if the text cannot be encoded
   */
  public func appendTextFile(
    text: String,
    to path: FilePath,
    encoding: String.Encoding = .utf8
  ) async throws {
    guard !path.path.isEmpty else {
      throw FileSystemInterfaces.FileSystemError.invalidPath(
        path: "",
        reason: "Empty path provided"
      )
    }

    guard let data=text.data(using: encoding) else {
      throw FileSystemInterfaces.FileSystemError.writeError(
        path: path.path,
        reason: "Failed to encode text with encoding \(encoding)"
      )
    }

    try await appendData([UInt8](data), to: path)
  }

  /**
   Removes a file at the specified path.

   - Parameter path: The path of the file to remove
   - Throws: `FileSystemError.invalidPath` if the path is invalid
             `FileSystemError.pathNotFound` if the file does not exist
             `FileSystemError.writeError` if the file cannot be removed
   */
  public func removeFile(at path: FilePath) async throws {
    guard !path.path.isEmpty else {
      throw FileSystemInterfaces.FileSystemError.invalidPath(
        path: "",
        reason: "Empty path provided"
      )
    }

    // Check if it exists and is not a directory
    var isDir: ObjCBool=false
    let exists=fileManager.fileExists(atPath: path.path, isDirectory: &isDir)

    if !exists {
      await logger.warning(
        "File does not exist for removal: \(path.path)",
        metadata: nil,
        source: "FileSystemService"
      )
      throw FileSystemInterfaces.FileSystemError.pathNotFound(path: path.path)
    }

    if isDir.boolValue {
      await logger.warning(
        "Path is a directory, not a file: \(path.path)",
        metadata: nil,
        source: "FileSystemService"
      )
      throw FileSystemInterfaces.FileSystemError.invalidPath(
        path: path.path,
        reason: "Path is a directory, not a file"
      )
    }

    do {
      try fileManager.removeItem(atPath: path.path)
      await logger.info("Removed file at \(path.path)", metadata: nil, source: "FileSystemService")
    } catch {
      await logger.error(
        "Failed to remove file at \(path.path): \(error.localizedDescription)",
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
   Copies a file from one location to another.

   - Parameters:
      - sourcePath: The source file path
      - destinationPath: The destination file path
      - overwrite: Whether to overwrite an existing file at the destination
      - preserveAttributes: Whether to preserve file attributes during the copy
   - Throws: `FileSystemError.invalidPath` if either path is invalid
             `FileSystemError.pathNotFound` if the source file does not exist
             `FileSystemError.pathAlreadyExists` if the destination exists and overwrite is false
             `FileSystemError.writeError` if the file cannot be copied
   */
  public func copyFile(
    from sourcePath: FilePath,
    to destinationPath: FilePath,
    overwrite: Bool=false,
    preserveAttributes _: Bool=true
  ) async throws {
    guard !sourcePath.path.isEmpty && !destinationPath.path.isEmpty else {
      throw FileSystemInterfaces.FileSystemError.invalidPath(
        path: sourcePath.path.isEmpty ? "source" : "destination",
        reason: "Empty path provided"
      )
    }

    // Check if source exists and is a file
    var isSourceDir: ObjCBool=false
    let sourceExists=fileManager.fileExists(atPath: sourcePath.path, isDirectory: &isSourceDir)

    if !sourceExists {
      await logger.warning(
        "Source file does not exist: \(sourcePath.path)",
        metadata: nil,
        source: "FileSystemService"
      )
      throw FileSystemInterfaces.FileSystemError.pathNotFound(path: sourcePath.path)
    }

    if isSourceDir.boolValue {
      await logger.warning(
        "Source is a directory, not a file: \(sourcePath.path)",
        metadata: nil,
        source: "FileSystemService"
      )
      throw FileSystemInterfaces.FileSystemError.invalidPath(
        path: sourcePath.path,
        reason: "Source is a directory, not a file"
      )
    }

    // Check if destination exists
    if fileManager.fileExists(atPath: destinationPath.path) {
      if !overwrite {
        await logger.warning(
          "Destination already exists: \(destinationPath.path)",
          metadata: nil,
          source: "FileSystemService"
        )
        throw FileSystemInterfaces.FileSystemError.pathAlreadyExists(path: destinationPath.path)
      }

      // Remove existing file if overwrite is true
      try? fileManager.removeItem(atPath: destinationPath.path)
    }

    // Create parent directory if needed
    let destinationURL=URL(fileURLWithPath: destinationPath.path)
    let destinationDir=destinationURL.deletingLastPathComponent()
    if !fileManager.fileExists(atPath: destinationDir.path) {
      try? fileManager.createDirectory(
        at: destinationDir,
        withIntermediateDirectories: true,
        attributes: nil
      )
    }

    do {
      try fileManager.copyItem(
        atPath: sourcePath.path,
        toPath: destinationPath.path
      )

      // If we don't want to preserve attributes and the system did preserve them,
      // we would need additional code to reset attributes

      await logger.info(
        "Copied file from \(sourcePath.path) to \(destinationPath.path)",
        metadata: nil,
        source: "FileSystemService"
      )
    } catch {
      await logger.error(
        "Failed to copy file: \(error.localizedDescription)",
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
   Moves a file from one location to another.

   - Parameters:
      - sourcePath: The source file path
      - destinationPath: The destination file path
      - overwrite: Whether to overwrite an existing file at the destination
   - Throws: `FileSystemError.invalidPath` if either path is invalid
             `FileSystemError.pathNotFound` if the source file does not exist
             `FileSystemError.pathAlreadyExists` if the destination exists and overwrite is false
             `FileSystemError.writeError` if the file cannot be moved
   */
  public func moveFile(
    from sourcePath: FilePath,
    to destinationPath: FilePath,
    overwrite: Bool=false
  ) async throws {
    guard !sourcePath.path.isEmpty && !destinationPath.path.isEmpty else {
      throw FileSystemInterfaces.FileSystemError.invalidPath(
        path: sourcePath.path.isEmpty ? "source" : "destination",
        reason: "Empty path provided"
      )
    }

    // Similar to copyFile, but using moveItem instead
    var isSourceDir: ObjCBool=false
    let sourceExists=fileManager.fileExists(atPath: sourcePath.path, isDirectory: &isSourceDir)

    if !sourceExists {
      await logger.warning(
        "Source file does not exist: \(sourcePath.path)",
        metadata: nil,
        source: "FileSystemService"
      )
      throw FileSystemInterfaces.FileSystemError.pathNotFound(path: sourcePath.path)
    }

    if isSourceDir.boolValue {
      await logger.warning(
        "Source is a directory, not a file: \(sourcePath.path)",
        metadata: nil,
        source: "FileSystemService"
      )
      throw FileSystemInterfaces.FileSystemError.invalidPath(
        path: sourcePath.path,
        reason: "Source is a directory, not a file"
      )
    }

    if fileManager.fileExists(atPath: destinationPath.path) {
      if !overwrite {
        await logger.warning(
          "Destination already exists: \(destinationPath.path)",
          metadata: nil,
          source: "FileSystemService"
        )
        throw FileSystemInterfaces.FileSystemError.pathAlreadyExists(path: destinationPath.path)
      }

      try? fileManager.removeItem(atPath: destinationPath.path)
    }

    // Create parent directory if needed
    let destinationURL=URL(fileURLWithPath: destinationPath.path)
    let destinationDir=destinationURL.deletingLastPathComponent()
    if !fileManager.fileExists(atPath: destinationDir.path) {
      try? fileManager.createDirectory(
        at: destinationDir,
        withIntermediateDirectories: true,
        attributes: nil
      )
    }

    do {
      try fileManager.moveItem(
        atPath: sourcePath.path,
        toPath: destinationPath.path
      )

      await logger.info(
        "Moved file from \(sourcePath.path) to \(destinationPath.path)",
        metadata: nil,
        source: "FileSystemService"
      )
    } catch {
      await logger.error(
        "Failed to move file: \(error.localizedDescription)",
        metadata: nil,
        source: "FileSystemService"
      )
      throw FileSystemInterfaces.FileSystemError.writeError(
        path: destinationPath.path,
        reason: error.localizedDescription
      )
    }
  }
}
