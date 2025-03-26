import CoreDTOs
import Foundation
import FileSystemTypes
import FileSystem
import Operations
import DTOs
import SecurityInterfaces

/// Protocol defining a Foundation-independent interface for file system operations
public protocol FileSystemServiceDTOProtocol: Sendable {
  /// Check if a file exists at the specified path
  /// - Parameter path: File path to check
  /// - Returns: Boolean indicating existence
  func fileExists(at path: FilePathDTO) async -> Bool

  /// Get metadata about a file
  /// - Parameter path: File path to check
  /// - Returns: Metadata or nil if file doesn't exist
  func getMetadata(at path: FilePathDTO) async -> FileSystemMetadataDTO?

  /// List contents of a directory
  /// - Parameters:
  ///   - directoryPath: Directory to list
  ///   - includeHidden: Whether to include hidden files
  /// - Returns: Array of file paths or error
  func listDirectory(at directoryPath: FilePathDTO, includeHidden: Bool) async
    -> OperationResultDTO<[FilePathDTO]>

  /// Create a directory
  /// - Parameters:
  ///   - path: Directory path to create
  ///   - withIntermediates: Whether to create intermediate directories
  /// - Returns: Success or error
  func createDirectory(at path: FilePathDTO, withIntermediates: Bool) async
    -> OperationResultDTO<Void>

  /// Create a file
  /// - Parameters:
  ///   - path: File path to create
  ///   - data: Data to write
  ///   - overwrite: Whether to overwrite if file exists
  /// - Returns: Success or error
  func createFile(at path: FilePathDTO, data: [UInt8], overwrite: Bool) async
    -> OperationResultDTO<Void>

  /// Read file contents
  /// - Parameter path: File path to read
  /// - Returns: File data or error
  func readFile(at path: FilePathDTO) async -> OperationResultDTO<[UInt8]>

  /// Write data to a file
  /// - Parameters:
  ///   - path: File path to write
  ///   - data: Data to write
  /// - Returns: Success or error
  func writeFile(at path: FilePathDTO, data: [UInt8]) async -> OperationResultDTO<Void>

  /// Append data to a file
  /// - Parameters:
  ///   - path: File path to append to
  ///   - data: Data to append
  /// - Returns: Success or error
  func appendFile(at path: FilePathDTO, data: [UInt8]) async -> OperationResultDTO<Void>

  /// Delete a file or directory
  /// - Parameters:
  ///   - path: Path to delete
  ///   - recursive: Whether to delete directory contents recursively
  /// - Returns: Success or error
  func delete(at path: FilePathDTO, recursive: Bool) async -> OperationResultDTO<Void>

  /// Move a file or directory
  /// - Parameters:
  ///   - sourcePath: Source path
  ///   - destinationPath: Destination path
  /// - Returns: Success or error
  func move(from sourcePath: FilePathDTO, to destinationPath: FilePathDTO) async
    -> OperationResultDTO<Void>

  /// Copy a file or directory
  /// - Parameters:
  ///   - sourcePath: Source path
  ///   - destinationPath: Destination path
  ///   - recursive: Whether to copy directory contents recursively
  /// - Returns: Success or error
  func copy(from sourcePath: FilePathDTO, to destinationPath: FilePathDTO, recursive: Bool) async
    -> OperationResultDTO<Void>

  /// Set file permissions
  /// - Parameters:
  ///   - path: File path
  ///   - readable: Whether file should be readable
  ///   - writable: Whether file should be writable
  ///   - executable: Whether file should be executable
  /// - Returns: Success or error
  func setPermissions(at path: FilePathDTO, readable: Bool, writable: Bool, executable: Bool) async
    -> OperationResultDTO<Void>

  /// Create a symbolic link
  /// - Parameters:
  ///   - path: Path for the link
  ///   - targetPath: Target the link points to
  /// - Returns: Success or error
  func createSymbolicLink(at path: FilePathDTO, targetPath: FilePathDTO) async
    -> OperationResultDTO<Void>

  /// Resolve a symbolic link
  /// - Parameter path: Path to resolve
  /// - Returns: Resolved path or error
  func resolveSymbolicLink(at path: FilePathDTO) async -> OperationResultDTO<FilePathDTO>

  /// Get temporary directory
  /// - Returns: Path to temporary directory
  func temporaryDirectory() -> FilePathDTO

  /// Get user's document directory
  /// - Returns: Path to document directory or error
  func documentDirectory() -> OperationResultDTO<FilePathDTO>
}
