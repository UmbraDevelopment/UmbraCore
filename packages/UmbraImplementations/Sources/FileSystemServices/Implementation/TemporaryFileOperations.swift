import FileSystemInterfaces
import FileSystemTypes
import Foundation
import LoggingTypes

/**
 # Temporary File Operations Extension

 This extension provides operations for working with temporary files and directories,
 including creating, managing, and cleaning up temporary resources.
 */
extension FileSystemServiceImpl {
  /**
   Creates a temporary file, performs an operation with it, and ensures cleanup.

   This method handles the lifecycle of a temporary file, making it available
   for the duration of the provided task and ensuring it's cleaned up afterwards
   regardless of whether the task succeeds or fails.

   - Parameters:
      - prefix: Prefix for the temporary file name
      - suffix: Suffix for the temporary file name
      - data: Optional initial data for the file
      - task: The operation to perform with the temporary file
   - Returns: The result of the task
   - Throws: `FileSystemError.writeError` if the temporary file couldn't be created
             `FileSystemError.writeError` if initial data couldn't be written
             Or rethrows any error from the task
   */
  public nonisolated func withTemporaryFile<T>(
    prefix: String,
    suffix: String,
    data: [UInt8]?=nil,
    task: (FilePath) async throws -> T
  ) async throws -> T {
    let tempDirectory=FileManager.default.temporaryDirectory
    let tempFileName="\(prefix)\(UUID().uuidString)\(suffix)"
    let tempURL=tempDirectory.appendingPathComponent(tempFileName)
    let tempPath=FilePath(path: tempURL.path)

    // Create the file and write initial data if provided
    if let initialData=data {
      do {
        let data=Data(initialData)
        try data.write(to: tempURL)
      } catch {
        // Convert to domain-specific error
        throw FileSystemInterfaces.FileSystemError.writeError(
          path: tempPath.path,
          reason: "Failed to write initial data: \(error.localizedDescription)"
        )
      }
    } else {
      // Create an empty file
      FileManager.default.createFile(atPath: tempURL.path, contents: nil)
    }

    do {
      // Perform the task with the temporary file
      let result=try await task(tempPath)

      // Cleanup: attempt to delete the temporary file
      try? FileManager.default.removeItem(at: tempURL)

      return result
    } catch {
      // Ensure cleanup even if the task fails
      try? FileManager.default.removeItem(at: tempURL)
      throw error
    }
  }

  /**
   Creates a temporary directory, performs an operation with it, and ensures cleanup.

   This method handles the lifecycle of a temporary directory, making it available
   for the duration of the provided task and ensuring it's cleaned up afterwards
   regardless of whether the task succeeds or fails.

   - Parameters:
      - prefix: Prefix for the temporary directory name
      - task: The operation to perform with the temporary directory
   - Returns: The result of the task
   - Throws: `FileSystemError.writeError` if the temporary directory couldn't be created
             Or rethrows any error from the task
   */
  public nonisolated func withTemporaryDirectory<T>(
    prefix: String,
    task: (FilePath) async throws -> T
  ) async throws -> T {
    let tempParentDirectory=FileManager.default.temporaryDirectory
    let tempDirName="\(prefix)\(UUID().uuidString)"
    let tempDirURL=tempParentDirectory.appendingPathComponent(tempDirName)
    let tempDirPath=FilePath(path: tempDirURL.path)

    // Create the temporary directory
    do {
      try FileManager.default.createDirectory(
        at: tempDirURL,
        withIntermediateDirectories: true,
        attributes: nil
      )
    } catch {
      throw FileSystemInterfaces.FileSystemError.writeError(
        path: tempDirPath.path,
        reason: "Failed to create temporary directory: \(error.localizedDescription)"
      )
    }

    do {
      // Perform the task with the temporary directory
      let result=try await task(tempDirPath)

      // Cleanup: attempt to delete the temporary directory and all its contents
      try? FileManager.default.removeItem(at: tempDirURL)

      return result
    } catch {
      // Ensure cleanup even if the task fails
      try? FileManager.default.removeItem(at: tempDirURL)
      throw error
    }
  }

  /**
   Creates a temporary file with the specified prefix, suffix, and optional initial data.

   Unlike `withTemporaryFile`, this method does not automatically clean up the file.
   The caller is responsible for managing the lifecycle of the temporary file.

   - Parameters:
      - prefix: Prefix for the temporary file name
      - suffix: Suffix for the temporary file name (typically an extension)
      - data: Optional initial data to write to the file
   - Returns: Path to the created file
   - Throws: `FileSystemError.writeError` if the temporary file couldn't be created
             `FileSystemError.writeError` if initial data couldn't be written
   */
  public func createTemporaryFile(
    prefix: String,
    suffix: String,
    data: [UInt8]?=nil
  ) async throws -> FilePath {
    let tempDirectory=FileManager.default.temporaryDirectory
    let tempFileName="\(prefix)\(UUID().uuidString)\(suffix)"
    let tempURL=tempDirectory.appendingPathComponent(tempFileName)
    let tempPath=FilePath(path: tempURL.path)

    // Create the file
    if !fileManager.createFile(atPath: tempURL.path, contents: nil) {
      throw FileSystemInterfaces.FileSystemError.writeError(
        path: tempPath.path,
        reason: "Failed to create temporary file"
      )
    }

    // Write initial data if provided
    if let initialData=data {
      try await writeFile(bytes: initialData, to: tempPath)
    }

    await logger.debug(
      "Created temporary file at \(tempPath.path)",
      metadata: nil,
      source: "FileSystemService"
    )

    return tempPath
  }

  /**
   Creates a temporary directory with the specified prefix.

   Unlike `withTemporaryDirectory`, this method does not automatically clean up the directory.
   The caller is responsible for managing the lifecycle of the temporary directory.

   - Parameter prefix: Prefix for the directory name
   - Returns: Path to the created directory
   - Throws: `FileSystemError.writeError` if the temporary directory couldn't be created
   */
  public func createTemporaryDirectory(
    prefix: String
  ) async throws -> FilePath {
    let tempParentDirectory=FileManager.default.temporaryDirectory
    let tempDirName="\(prefix)\(UUID().uuidString)"
    let tempDirURL=tempParentDirectory.appendingPathComponent(tempDirName)
    let tempDirPath=FilePath(path: tempDirURL.path)

    do {
      try fileManager.createDirectory(
        at: tempDirURL,
        withIntermediateDirectories: true,
        attributes: nil
      )

      await logger.debug(
        "Created temporary directory at \(tempDirPath.path)",
        metadata: nil,
        source: "FileSystemService"
      )

      return tempDirPath
    } catch {
      throw FileSystemInterfaces.FileSystemError.writeError(
        path: tempDirPath.path,
        reason: "Failed to create temporary directory: \(error.localizedDescription)"
      )
    }
  }
}
