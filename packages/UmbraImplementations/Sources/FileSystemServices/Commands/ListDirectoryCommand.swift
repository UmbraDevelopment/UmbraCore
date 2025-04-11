import DomainFileSystemTypes
import Foundation
import LoggingInterfaces
import LoggingTypes

/**
 Command for listing the contents of a directory.

 This command follows the Alpha Dot Five architecture principles with privacy-aware
 logging and strong error handling.
 */
public class ListDirectoryCommand: BaseFileSystemCommand, FileSystemCommand {
  /// The type of result returned by this command
  public typealias ResultType=[FileSystemItem]

  /// The path of the directory to list
  private let directoryPath: String

  /// Whether to include hidden files
  private let includeHidden: Bool

  /// Whether to recursively list subdirectories
  private let recursive: Bool

  /// Optional file extension filter
  private let extensionFilter: String?

  /**
   Initialises a new list directory command.

   - Parameters:
      - directoryPath: Path to the directory to list
      - includeHidden: Whether to include hidden files
      - recursive: Whether to recursively list subdirectories
      - extensionFilter: Optional file extension filter
      - fileManager: File manager to use for operations
      - logger: Optional logger for operation tracking
   */
  public init(
    directoryPath: String,
    includeHidden: Bool=false,
    recursive: Bool=false,
    extensionFilter: String?=nil,
    fileManager: FileManager = .default,
    logger: LoggingProtocol?=nil
  ) {
    self.directoryPath=directoryPath
    self.includeHidden=includeHidden
    self.recursive=recursive
    self.extensionFilter=extensionFilter
    super.init(fileManager: fileManager, logger: logger)
  }

  /**
   Executes the directory listing operation.

   - Parameters:
      - context: Logging context for the operation
      - operationID: Unique identifier for this operation instance
   - Returns: Array of file system items if successful, error otherwise
   */
  public func execute(
    context _: LogContextDTO,
    operationID: String
  ) async -> Result<[FileSystemItem], FileSystemError> {
    // Create a log context with proper privacy classification
    let logContext=createLogContext(
      operation: "listDirectory",
      correlationID: operationID,
      additionalMetadata: [
        ("directoryPath", (value: directoryPath, privacyLevel: .protected)),
        ("includeHidden", (value: "\(includeHidden)", privacyLevel: .public)),
        ("recursive", (value: "\(recursive)", privacyLevel: .public)),
        ("extensionFilter", (value: extensionFilter ?? "none", privacyLevel: .public))
      ]
    )

    await logDebug("Starting directory listing operation", context: logContext)

    // Validate that the path exists and is a directory
    let pathResult=validatePath(directoryPath, expectedType: .directory)
    guard case let .success(validPath)=pathResult else {
      if case let .failure(error)=pathResult {
        await logError("Directory path validation failed: \(error)", context: logContext)
        return .failure(error)
      }
      // This shouldn't happen, but just in case
      await logError("Unknown path validation error", context: logContext)
      return .failure(.invalidPath)
    }

    do {
      // Get directory contents
      let items=try listItems(
        at: validPath,
        includeHidden: includeHidden,
        recursive: recursive,
        extensionFilter: extensionFilter
      )

      await logInfo(
        "Successfully listed directory contents: \(items.count) items found",
        context: logContext
      )

      return .success(items)
    } catch {
      let fileSystemError: FileSystemError=if let nsError=error as NSError? {
        switch nsError.code {
          case NSFileNoSuchFileError:
            .pathNotFound
          case NSFileReadNoPermissionError:
            .accessDenied
          default:
            .listError(error.localizedDescription)
        }
      } else {
        .listError(error.localizedDescription)
      }

      await logError(
        "Failed to list directory contents: \(error.localizedDescription)",
        context: logContext
      )

      return .failure(fileSystemError)
    }
  }

  /**
   Lists directory contents with the specified options.

   - Parameters:
      - path: The directory path to list
      - includeHidden: Whether to include hidden files
      - recursive: Whether to recursively list subdirectories
      - extensionFilter: Optional file extension filter
   - Returns: Array of file system items
   - Throws: Error if listing fails
   */
  private func listItems(
    at path: String,
    includeHidden: Bool,
    recursive: Bool,
    extensionFilter: String?
  ) throws -> [FileSystemItem] {
    var result: [FileSystemItem]=[]

    // Get directory contents
    let contents=try fileManager.contentsOfDirectory(
      at: URL(fileURLWithPath: path),
      includingPropertiesForKeys: [
        .isDirectoryKey,
        .fileSizeKey,
        .creationDateKey,
        .contentModificationDateKey
      ],
      options: includeHidden ? [] : .skipsHiddenFiles
    )

    // Process each item
    for url in contents {
      // Apply extension filter if specified
      if
        let extensionFilter,
        !url.pathExtension.lowercased().contains(extensionFilter.lowercased())
      {
        continue
      }

      // Get item attributes
      let attributes=try url.resourceValues(forKeys: [
        .isDirectoryKey,
        .fileSizeKey,
        .creationDateKey,
        .contentModificationDateKey
      ])

      // Determine if item is a directory
      let isDirectory=attributes.isDirectory ?? false

      // Create file system item
      let item=FileSystemItem(
        name: url.lastPathComponent,
        path: url.path,
        type: isDirectory ? .directory : .file,
        size: attributes.fileSize ?? 0,
        creationDate: attributes.creationDate,
        modificationDate: attributes.contentModificationDate
      )

      // Add item to result
      result.append(item)

      // Recursively list subdirectories if requested
      if recursive && isDirectory {
        let subItems=try listItems(
          at: url.path,
          includeHidden: includeHidden,
          recursive: recursive,
          extensionFilter: extensionFilter
        )

        result.append(contentsOf: subItems)
      }
    }

    return result
  }
}
