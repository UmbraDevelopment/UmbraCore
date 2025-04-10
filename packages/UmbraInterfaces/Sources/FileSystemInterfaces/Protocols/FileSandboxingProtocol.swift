import Foundation

/**
 # File Sandboxing Protocol

 Defines operations for restricting file system operations to a specific directory.

 This protocol centralises all sandboxed file operations to ensure security
 and proper isolation of file operations within permitted directories.

 ## Alpha Dot Five Architecture

 This protocol conforms to the Alpha Dot Five architecture principles:
 - Focuses on a single responsibility (secure sandboxing)
 - Uses asynchronous APIs for thread safety
 - Provides comprehensive error handling
 - Implements strong privacy protections
 */
public protocol FileSandboxingProtocol: Actor, Sendable {
  /**
   Creates a directory within the sandbox.

   - Parameters:
      - path: Path where the directory should be created, relative to the sandbox root.
      - options: Optional directory creation options.
   - Returns: A tuple containing the created directory path and the operation result.
   - Throws: FileSystemError if the directory creation fails or is outside the sandbox.
   */
  func createSandboxedDirectory(at path: String, options: DirectoryCreationOptions?) async throws
    -> (String, FileOperationResultDTO)

  /**
   Creates a file within the sandbox.

   - Parameters:
      - path: Path where the file should be created, relative to the sandbox root.
      - options: Optional file creation options.
   - Returns: A tuple containing the created file path and the operation result.
   - Throws: FileSystemError if the file creation fails or is outside the sandbox.
   */
  func createSandboxedFile(at path: String, options: FileCreationOptions?) async throws
    -> (String, FileOperationResultDTO)

  /**
   Writes data to a file within the sandbox.

   - Parameters:
      - data: The data to write.
      - path: Path where the data should be written, relative to the sandbox root.
      - options: Optional file write options.
   - Returns: The operation result.
   - Throws: FileSystemError if the write operation fails or is outside the sandbox.
   */
  func writeSandboxedFile(data: Data, to path: String, options: FileWriteOptions?) async throws
    -> FileOperationResultDTO

  /**
   Reads a file within the sandbox.

   - Parameter path: Path to the file to read, relative to the sandbox root.
   - Returns: A tuple containing the file data and the operation result.
   - Throws: FileSystemError if the read operation fails or is outside the sandbox.
   */
  func readSandboxedFile(at path: String) async throws -> (Data, FileOperationResultDTO)

  /**
   Checks if a path is within the sandbox.

   - Parameter path: Path to check.
   - Returns: A tuple containing a boolean indicating if the path is within the sandbox and the operation result.
   */
  func isPathWithinSandbox(_ path: String) async -> (Bool, FileOperationResultDTO)

  /**
   Gets the absolute path within the sandbox for a given relative path.

   - Parameter relativePath: Relative path within the sandbox.
   - Returns: A tuple containing the absolute path and the operation result.
   - Throws: FileSystemError if the path resolution fails or is outside the sandbox.
   */
  func getAbsolutePath(for relativePath: String) async throws -> (String, FileOperationResultDTO)

  /**
   Gets the sandbox root directory.

   - Returns: The root directory path of the sandbox.
   */
  func getSandboxRoot() async -> String
}
