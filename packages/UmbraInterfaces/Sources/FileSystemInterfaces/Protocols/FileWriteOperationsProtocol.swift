import CoreDTOs
import Foundation

/**
 # File Write Operations Protocol

 Defines the core write operations that can be performed on a file system.

 This protocol centralises all file write operations to ensure consistency
 across different file system service implementations.

 ## Alpha Dot Five Architecture

 This protocol conforms to the Alpha Dot Five architecture principles:
 - Focuses on a single responsibility (writing operations)
 - Uses asynchronous APIs for thread safety
 - Provides comprehensive error handling
 */
public protocol FileWriteOperationsProtocol: Actor, Sendable {
  /**
   Creates an empty file at the specified path.

   - Parameters:
      - path: The path where the file should be created.
      - options: Optional file creation options.
   - Returns: The path to the created file.
   - Throws: FileSystemError if the file creation fails.
   */
  func createFile(at path: FilePathDTO, options: FileCreationOptions?) async throws -> FilePathDTO

  /**
   Writes data to a file at the specified path.

   - Parameters:
      - data: The data to write.
      - path: The path where the data should be written.
      - options: Optional file write options.
   - Throws: FileSystemError if the write operation fails.
   */
  func writeFile(data: Data, to path: FilePathDTO, options: FileWriteOptions?) async throws

  /**
   Writes a string to a file at the specified path.

   - Parameters:
      - string: The string to write.
      - path: The path where the string should be written.
      - encoding: The string encoding to use.
      - options: Optional file write options.
   - Throws: FileSystemError if the write operation fails.
   */
  func writeString(
    _ string: String,
    to path: FilePathDTO,
    encoding: String.Encoding,
    options: FileWriteOptions?
  ) async throws

  /**
   Creates a directory at the specified path.

   - Parameters:
      - path: The path where the directory should be created.
      - options: Optional directory creation options.
   - Returns: The path to the created directory.
   - Throws: FileSystemError if the directory creation fails.
   */
  func createDirectory(at path: FilePathDTO, options: DirectoryCreationOptions?) async throws
    -> FilePathDTO

  /**
   Deletes a file or directory at the specified path.

   - Parameter path: The path to the file or directory to delete.
   - Throws: FileSystemError if the deletion fails.
   */
  func delete(at path: FilePathDTO) async throws

  /**
   Moves a file or directory from one path to another.

   - Parameters:
      - sourcePath: The path of the file or directory to move.
      - destinationPath: The destination path.
      - options: Optional move options.
   - Throws: FileSystemError if the move operation fails.
   */
  func move(
    from sourcePath: FilePathDTO,
    to destinationPath: FilePathDTO,
    options: FileMoveOptions?
  ) async throws

  /**
   Copies a file or directory from one path to another.

   - Parameters:
      - sourcePath: The path of the file or directory to copy.
      - destinationPath: The destination path.
      - options: Optional copy options.
   - Throws: FileSystemError if the copy operation fails.
   */
  func copy(
    from sourcePath: FilePathDTO,
    to destinationPath: FilePathDTO,
    options: FileCopyOptions?
  ) async throws
}
