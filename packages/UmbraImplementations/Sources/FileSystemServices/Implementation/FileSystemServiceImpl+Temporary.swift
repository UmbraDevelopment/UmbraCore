import FileSystemInterfaces
import FileSystemTypes
import Foundation
import LoggingTypes
import CoreDTOs

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
    data: [UInt8]? = nil,
    task: (FilePathDTO) async throws -> T
  ) async throws -> T {
    let tempDirectory = FileManager.default.temporaryDirectory
    let tempFileName = "\(prefix)\(UUID().uuidString)\(suffix)"
    let tempURL = tempDirectory.appendingPathComponent(tempFileName)
    let tempPath = FilePathDTO(path: tempURL.path)

    // Create the file and write initial data if provided
    if let initialData = data {
      do {
        let data = Data(initialData)
        try data.write(to: tempURL)
      } catch {
        // Convert to domain-specific error
        throw FileSystemInterfaces.FileSystemError.writeError(
          path: tempPath.path,
          reason: "Failed to write initial data: \(error.localizedDescription)"
        )
      }
    } else {
      // Create empty file
      if !FileManager.default.createFile(atPath: tempURL.path, contents: nil) {
        throw FileSystemInterfaces.FileSystemError.writeError(
          path: tempPath.path,
          reason: "Failed to create temporary file"
        )
      }
    }

    do {
      // Perform the task with the temporary file
      let result = try await task(tempPath)

      // Clean up the temporary file
      try? FileManager.default.removeItem(at: tempURL)

      // Return the task result
      return result
    } catch {
      // Clean up the temporary file even if the task fails
      try? FileManager.default.removeItem(at: tempURL)

      // Rethrow the original error
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
    task: (FilePathDTO) async throws -> T
  ) async throws -> T {
    let tempDirectory = FileManager.default.temporaryDirectory
    let tempDirName = "\(prefix)\(UUID().uuidString)"
    let tempURL = tempDirectory.appendingPathComponent(tempDirName)
    let tempPath = FilePathDTO(path: tempURL.path, isDirectory: true)

    // Create the directory
    do {
      try FileManager.default.createDirectory(at: tempURL, withIntermediateDirectories: true)
    } catch {
      throw FileSystemInterfaces.FileSystemError.writeError(
        path: tempPath.path,
        reason: "Failed to create temporary directory: \(error.localizedDescription)"
      )
    }

    do {
      // Perform the task with the temporary directory
      let result = try await task(tempPath)

      // Clean up the temporary directory
      try? FileManager.default.removeItem(at: tempURL)

      // Return the task result
      return result
    } catch {
      // Clean up the temporary directory even if the task fails
      try? FileManager.default.removeItem(at: tempURL)

      // Rethrow the original error
      throw error
    }
  }

  /**
   Creates a temporary file with the given options.

   - Parameters:
      - options: Optional options for creating the temporary file
   - Returns: The path to the created temporary file
   - Throws: `FileSystemError.writeError` if the temporary file couldn't be created
   */
  public func createTemporaryFile(
    options: TemporaryFileOptions?
  ) async throws -> FilePathDTO {
    let tempDirectory = FileManager.default.temporaryDirectory
    let tempFileName = "\(options?.prefix ?? "tmp")\(UUID().uuidString)\(options?.suffix ?? "")"
    let tempURL = tempDirectory.appendingPathComponent(tempFileName)
    let tempPath = FilePathDTO(path: tempURL.path)

    await logger.debug(
      "Creating temporary file",
      context: FileSystemLogContext(
        operation: "createTemporaryFile",
        path: tempPath.path,
        source: "FileSystemService",
        metadata: LogMetadataDTOCollection()
          .withPublic(key: "tempFileName", value: tempFileName)
      )
    )

    // Create the file
    if !FileManager.default.createFile(atPath: tempURL.path, contents: nil) {
      let errorMetadata = LogMetadataDTOCollection()
        .withPublic(key: "tempFileName", value: tempFileName)

      await logger.error(
        "Failed to create temporary file",
        context: FileSystemLogContext(
          operation: "createTemporaryFile",
          path: tempPath.path,
          source: "FileSystemService",
          metadata: errorMetadata
        )
      )

      throw FileSystemInterfaces.FileSystemError.writeError(
        path: tempPath.path,
        reason: "Failed to create temporary file"
      )
    }

    await logger.debug(
      "Created temporary file",
      context: FileSystemLogContext(
        operation: "createTemporaryFile",
        path: tempPath.path,
        source: "FileSystemService",
        metadata: LogMetadataDTOCollection()
          .withPublic(key: "tempFileName", value: tempFileName)
      )
    )

    return tempPath
  }

  /**
   Creates a temporary directory with the given options.

   - Parameters:
      - options: Optional options for creating the temporary directory
   - Returns: The path to the created temporary directory
   - Throws: `FileSystemError.writeError` if the temporary directory couldn't be created
   */
  public func createTemporaryDirectory(
    options: TemporaryFileOptions?
  ) async throws -> FilePathDTO {
    let tempDirectory = FileManager.default.temporaryDirectory
    let tempDirName = "\(options?.prefix ?? "tmp")\(UUID().uuidString)"
    let tempURL = tempDirectory.appendingPathComponent(tempDirName)
    let tempPath = FilePathDTO(path: tempURL.path, isDirectory: true)

    await logger.debug(
      "Creating temporary directory",
      context: FileSystemLogContext(
        operation: "createTemporaryDirectory",
        path: tempPath.path,
        source: "FileSystemService",
        metadata: LogMetadataDTOCollection()
          .withPublic(key: "tempDirName", value: tempDirName)
      )
    )

    // Create the directory
    do {
      try FileManager.default.createDirectory(at: tempURL, withIntermediateDirectories: true)
    } catch {
      let errorMetadata = LogMetadataDTOCollection()
        .withPublic(key: "tempDirName", value: tempDirName)
        .withPublic(key: "errorType", value: "\(type(of: error))")
        .withPrivate(key: "errorMessage", value: error.localizedDescription)

      await logger.error(
        "Failed to create temporary directory",
        context: FileSystemLogContext(
          operation: "createTemporaryDirectory",
          path: tempPath.path,
          source: "FileSystemService",
          metadata: errorMetadata
        )
      )

      throw FileSystemInterfaces.FileSystemError.writeError(
        path: tempPath.path,
        reason: "Failed to create temporary directory: \(error.localizedDescription)"
      )
    }

    await logger.debug(
      "Created temporary directory",
      context: FileSystemLogContext(
        operation: "createTemporaryDirectory",
        path: tempPath.path,
        source: "FileSystemService",
        metadata: LogMetadataDTOCollection()
          .withPublic(key: "tempDirName", value: tempDirName)
      )
    )

    return tempPath
  }
}
