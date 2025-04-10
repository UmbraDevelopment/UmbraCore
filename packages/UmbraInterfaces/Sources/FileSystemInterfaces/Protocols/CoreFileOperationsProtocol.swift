import Foundation

/**
 # Core File Operations Protocol

 Defines the fundamental file system operations like reading, writing,
 and checking for file existence.

 This protocol centralises all core file operations to ensure consistency
 across different file system service implementations.

 ## Alpha Dot Five Architecture

 This protocol conforms to the Alpha Dot Five architecture principles:
 - Focuses on a single responsibility (core operations)
 - Uses asynchronous APIs for thread safety
 - Provides comprehensive error handling
 - Uses British spelling in documentation
 */
public protocol CoreFileOperationsProtocol: Actor, Sendable {
  /**
   Reads a file at the specified path.

   - Parameter path: Path to the file to read.
   - Returns: A tuple containing the file data and the operation result.
   - Throws: FileSystemError if the read operation fails.
   */
  func readFile(at path: String) async throws -> (Data, FileOperationResultDTO)

  /**
   Reads a file at the specified path as a string with the given encoding.

   - Parameters:
      - path: Path to the file to read.
      - encoding: Text encoding to use for the file.
   - Returns: A tuple containing the file contents as a string and the operation result.
   - Throws: FileSystemError if the read operation fails.
   */
  func readFileAsString(at path: String, encoding: String.Encoding) async throws
    -> (String, FileOperationResultDTO)

  /**
   Writes data to a file at the specified path.

   - Parameters:
      - data: The data to write.
      - path: The path where the data should be written.
      - options: Optional write options.
   - Returns: The operation result.
   - Throws: FileSystemError if the write operation fails.
   */
  func writeFile(data: Data, to path: String, options: FileWriteOptions?) async throws
    -> FileOperationResultDTO

  /**
   Writes a string to a file at the specified path with the given encoding.

   - Parameters:
      - string: The string to write.
      - path: The path where the string should be written.
      - encoding: Text encoding to use for the file.
      - options: Optional write options.
   - Returns: The operation result.
   - Throws: FileSystemError if the write operation fails.
   */
  func writeFileFromString(
    _ string: String,
    to path: String,
    encoding: String.Encoding,
    options: FileWriteOptions?
  ) async throws -> FileOperationResultDTO

  /**
   Checks if a file exists at the specified path.

   - Parameter path: Path to check.
   - Returns: A tuple containing a boolean indicating if the file exists and the operation result.
   */
  func fileExists(at path: String) async -> (Bool, FileOperationResultDTO)

  /**
   Gets the URLs of all files in a directory.

   - Parameter path: Path to the directory.
   - Returns: A tuple containing an array of file URLs and the operation result.
   - Throws: FileSystemError if the directory cannot be read.
   */
  func getFileURLs(in path: String) async throws -> ([URL], FileOperationResultDTO)

  /**
   Creates a directory at the specified path.

   - Parameters:
      - path: Path where the directory should be created.
      - options: Optional directory creation options.
   - Returns: A tuple containing the created directory path and the operation result.
   - Throws: FileSystemError if directory creation fails.
   */
  func createDirectory(at path: String, options: DirectoryCreationOptions?) async throws
    -> (String, FileOperationResultDTO)

  /**
   Creates a file at the specified path.

   - Parameters:
      - path: Path where the file should be created.
      - options: Optional file creation options.
   - Returns: A tuple containing the created file path and the operation result.
   - Throws: FileSystemError if file creation fails.
   */
  func createFile(at path: String, options: FileCreationOptions?) async throws
    -> (String, FileOperationResultDTO)

  /**
   Deletes a file or directory at the specified path.

   - Parameter path: Path to the file or directory to delete.
   - Returns: The operation result.
   - Throws: FileSystemError if the delete operation fails.
   */
  func delete(at path: String) async throws -> FileOperationResultDTO

  /**
   Moves a file or directory from one path to another.

   - Parameters:
      - sourcePath: Path to the file or directory to move.
      - destinationPath: Path where the file or directory should be moved.
      - options: Optional move options.
   - Returns: The operation result.
   - Throws: FileSystemError if the move operation fails.
   */
  func move(
    from sourcePath: String,
    to destinationPath: String,
    options: FileMoveOptions?
  ) async throws -> FileOperationResultDTO

  /**
   Copies a file or directory from one path to another.

   - Parameters:
      - sourcePath: Path to the file or directory to copy.
      - destinationPath: Path where the file or directory should be copied.
      - options: Optional copy options.
   - Returns: The operation result.
   - Throws: FileSystemError if the copy operation fails.
   */
  func copy(
    from sourcePath: String,
    to destinationPath: String,
    options: FileCopyOptions?
  ) async throws -> FileOperationResultDTO

  /**
   Gets a list of all files and directories in a directory, recursively.

   - Parameter path: Path to the directory.
   - Returns: A tuple containing an array of paths and the operation result.
   - Throws: FileSystemError if the directory cannot be read.
   */
  func listDirectoryRecursively(at path: String) async throws -> ([String], FileOperationResultDTO)
}
