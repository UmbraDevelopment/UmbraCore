import DomainFileSystemTypes
import Foundation
import LoggingInterfaces
import LoggingTypes

/**
 # FileSystemService

 Thread-safe implementation of file system operations using a command pattern architecture.

 This service follows the Alpha Dot Five architecture principles with actor-based
 concurrency, privacy-aware logging, and strong error handling. It encapsulates
 file system operations in discrete command objects with a consistent interface.

 ## Features

 - File reading and writing with comprehensive error handling
 - Directory creation and management
 - File copying, moving, and deletion
 - Secure file deletion with data overwriting
 - Directory listing with filtering options

 ## Thread Safety

 As an actor, this implementation guarantees thread safety when used from multiple
 concurrent contexts, preventing data races in file system operations.

 ## Privacy Controls

 This implementation ensures proper privacy classification of sensitive information:
 - File paths are treated as protected information
 - File contents are treated as private information
 - Error details are appropriately classified based on sensitivity
 */
public actor FileSystemService {
  /// The file manager to use for operations
  private let fileManager: FileManager

  /// Optional logger for operation tracking
  private let logger: LoggingProtocol?

  /**
   Initialises a new file system service.

   - Parameters:
      - fileManager: The file manager to use for operations
      - logger: Optional logger for operation tracking
   */
  public init(
    fileManager: FileManager = .default,
    logger: LoggingProtocol?=nil
  ) {
    self.fileManager=fileManager
    self.logger=logger
  }

  // MARK: - File Operations

  /**
   Reads the contents of a file.

   - Parameter path: The path to the file to read
   - Returns: The file contents as a byte array
   */
  public func readFile(path: String) async -> Result<[UInt8], FileSystemError> {
    let operationID=UUID().uuidString
    let command=ReadFileCommand(
      filePath: path,
      fileManager: fileManager,
      logger: logger
    )

    return await command.execute(
      context: LogContextDTO(metadata: LogMetadataDTO()),
      operationID: operationID
    )
  }

  /**
   Writes data to a file.

   - Parameters:
      - data: The data to write
      - path: The path to the file to write
      - createParentDirectories: Whether to create parent directories if they don't exist
      - overwrite: Whether to overwrite the file if it already exists
   - Returns: Void if successful, error otherwise
   */
  public func writeFile(
    data: [UInt8],
    path: String,
    createParentDirectories: Bool=true,
    overwrite: Bool=true
  ) async -> Result<Void, FileSystemError> {
    let operationID=UUID().uuidString
    let command=WriteFileCommand(
      filePath: path,
      data: data,
      createParentDirectories: createParentDirectories,
      overwrite: overwrite,
      fileManager: fileManager,
      logger: logger
    )

    return await command.execute(
      context: LogContextDTO(metadata: LogMetadataDTO()),
      operationID: operationID
    )
  }

  /**
   Creates a directory.

   - Parameters:
      - path: The path to the directory to create
      - createIntermediates: Whether to create intermediate directories
      - attributes: Optional attributes to set on the directory
   - Returns: Void if successful, error otherwise
   */
  public func createDirectory(
    path: String,
    createIntermediates: Bool=true,
    attributes: [FileAttributeKey: Any]?=nil
  ) async -> Result<Void, FileSystemError> {
    let operationID=UUID().uuidString
    let command=CreateDirectoryCommand(
      directoryPath: path,
      createIntermediates: createIntermediates,
      attributes: attributes,
      fileManager: fileManager,
      logger: logger
    )

    return await command.execute(
      context: LogContextDTO(metadata: LogMetadataDTO()),
      operationID: operationID
    )
  }

  /**
   Deletes a file.

   - Parameters:
      - path: The path to the file to delete
      - secureDelete: Whether to perform a secure deletion (overwrite with zeros)
   - Returns: Void if successful, error otherwise
   */
  public func deleteFile(
    path: String,
    secureDelete: Bool=false
  ) async -> Result<Void, FileSystemError> {
    let operationID=UUID().uuidString
    let command=DeleteFileCommand(
      filePath: path,
      secureDelete: secureDelete,
      fileManager: fileManager,
      logger: logger
    )

    return await command.execute(
      context: LogContextDTO(metadata: LogMetadataDTO()),
      operationID: operationID
    )
  }

  /**
   Copies a file from one location to another.

   - Parameters:
      - sourcePath: The path to the source file
      - destinationPath: The path to the destination file
      - overwrite: Whether to overwrite the destination if it exists
      - createParentDirectories: Whether to create parent directories for the destination
   - Returns: Void if successful, error otherwise
   */
  public func copyFile(
    sourcePath: String,
    destinationPath: String,
    overwrite: Bool=false,
    createParentDirectories: Bool=true
  ) async -> Result<Void, FileSystemError> {
    let operationID=UUID().uuidString
    let command=CopyFileCommand(
      sourcePath: sourcePath,
      destinationPath: destinationPath,
      overwrite: overwrite,
      createParentDirectories: createParentDirectories,
      fileManager: fileManager,
      logger: logger
    )

    return await command.execute(
      context: LogContextDTO(metadata: LogMetadataDTO()),
      operationID: operationID
    )
  }

  /**
   Moves a file from one location to another.

   - Parameters:
      - sourcePath: The path to the source file
      - destinationPath: The path to the destination file
      - overwrite: Whether to overwrite the destination if it exists
      - createParentDirectories: Whether to create parent directories for the destination
   - Returns: Void if successful, error otherwise
   */
  public func moveFile(
    sourcePath: String,
    destinationPath: String,
    overwrite: Bool=false,
    createParentDirectories: Bool=true
  ) async -> Result<Void, FileSystemError> {
    let operationID=UUID().uuidString
    let command=MoveFileCommand(
      sourcePath: sourcePath,
      destinationPath: destinationPath,
      overwrite: overwrite,
      createParentDirectories: createParentDirectories,
      fileManager: fileManager,
      logger: logger
    )

    return await command.execute(
      context: LogContextDTO(metadata: LogMetadataDTO()),
      operationID: operationID
    )
  }

  /**
   Lists the contents of a directory.

   - Parameters:
      - path: The path to the directory to list
      - includeHidden: Whether to include hidden files
      - recursive: Whether to recursively list subdirectories
      - extensionFilter: Optional file extension filter
   - Returns: Array of file system items if successful, error otherwise
   */
  public func listDirectory(
    path: String,
    includeHidden: Bool=false,
    recursive: Bool=false,
    extensionFilter: String?=nil
  ) async -> Result<[FileSystemItem], FileSystemError> {
    let operationID=UUID().uuidString
    let command=ListDirectoryCommand(
      directoryPath: path,
      includeHidden: includeHidden,
      recursive: recursive,
      extensionFilter: extensionFilter,
      fileManager: fileManager,
      logger: logger
    )

    return await command.execute(
      context: LogContextDTO(metadata: LogMetadataDTO()),
      operationID: operationID
    )
  }

  // MARK: - Utility Methods

  /**
   Checks if a file exists at the specified path.

   - Parameter path: The path to check
   - Returns: True if a file exists, false otherwise
   */
  public func fileExists(at path: String) -> Bool {
    var isDirectory: ObjCBool=false
    let exists=fileManager.fileExists(atPath: path, isDirectory: &isDirectory)
    return exists && !isDirectory.boolValue
  }

  /**
   Checks if a directory exists at the specified path.

   - Parameter path: The path to check
   - Returns: True if a directory exists, false otherwise
   */
  public func directoryExists(at path: String) -> Bool {
    var isDirectory: ObjCBool=false
    let exists=fileManager.fileExists(atPath: path, isDirectory: &isDirectory)
    return exists && isDirectory.boolValue
  }

  /**
   Gets the size of a file.

   - Parameter path: The path to the file
   - Returns: The file size in bytes if successful, error otherwise
   */
  public func fileSize(at path: String) async -> Result<Int, FileSystemError> {
    do {
      let attributes=try fileManager.attributesOfItem(atPath: path)
      guard let fileSize=attributes[.size] as? Int else {
        return .failure(.invalidAttributeType)
      }
      return .success(fileSize)
    } catch {
      return .failure(.attributeError(error.localizedDescription))
    }
  }
}
