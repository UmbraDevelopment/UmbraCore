import Foundation

/**
 # Composite File System Service Protocol

 A protocol that combines all file system operations domains into a unified interface.

 This composite protocol provides a comprehensive API for applications to
 perform all necessary file system operations while maintaining separation
 of concerns in the implementation.

 ## Alpha Dot Five Architecture

 This protocol follows the Alpha Dot Five architecture principles:
 - Uses protocol composition for better separation of concerns
 - Maintains British spelling in documentation
 - Follows actor isolation patterns for thread safety
 - Provides a cohesive API that hides implementation details
 */
public protocol CompositeFileSystemServiceProtocol: CoreFileOperationsProtocol,
  FileMetadataOperationsProtocol,
  SecureFileOperationsProtocol,
  FileSandboxingProtocol
{
  /**
   Creates a directory at the specified path.

   - Parameters:
      - path: The path where the directory should be created.
      - options: Optional creation options.
   - Returns: The path to the created directory and operation result.
   - Throws: FileSystemError if directory creation fails.
   */
  func createDirectory(at path: String, options: DirectoryCreationOptions?) async throws
    -> (String, FileOperationResultDTO)

  /**
   Creates a file at the specified path.

   - Parameters:
      - path: The path where the file should be created.
      - options: Optional creation options.
   - Returns: The path to the created file and operation result.
   - Throws: FileSystemError if file creation fails.
   */
  func createFile(at path: String, options: FileCreationOptions?) async throws
    -> (String, FileOperationResultDTO)

  /**
   Deletes the item at the specified path.

   - Parameter path: The path to the item to delete.
   - Returns: Operation result.
   - Throws: FileSystemError if the delete operation fails.
   */
  func delete(at path: String) async throws -> FileOperationResultDTO

  /**
   Moves an item from one path to another.

   - Parameters:
      - sourcePath: The source path.
      - destinationPath: The destination path.
      - options: Optional move options.
   - Returns: Operation result.
   - Throws: FileSystemError if the move operation fails.
   */
  func move(
    from sourcePath: String,
    to destinationPath: String,
    options: FileMoveOptions?
  ) async throws -> FileOperationResultDTO

  /**
   Copies an item from one path to another.

   - Parameters:
      - sourcePath: The source path.
      - destinationPath: The destination path.
      - options: Optional copy options.
   - Returns: Operation result.
   - Throws: FileSystemError if the copy operation fails.
   */
  func copy(
    from sourcePath: String,
    to destinationPath: String,
    options: FileCopyOptions?
  ) async throws -> FileOperationResultDTO

  /**
   Lists the contents of a directory recursively.

   - Parameter path: The path to the directory to list.
   - Returns: An array of file paths and operation result.
   - Throws: FileSystemError if the directory cannot be read.
   */
  func listDirectoryRecursively(at path: String) async throws -> ([String], FileOperationResultDTO)
}
