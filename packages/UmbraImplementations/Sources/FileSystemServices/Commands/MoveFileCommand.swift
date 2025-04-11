import DomainFileSystemTypes
import Foundation
import LoggingInterfaces
import LoggingTypes

/**
 Command for moving a file from one location to another.

 This command follows the Alpha Dot Five architecture principles with privacy-aware
 logging and strong error handling.
 */
public class MoveFileCommand: BaseFileSystemCommand, FileSystemCommand {
  /// The type of result returned by this command
  public typealias ResultType=Void

  /// The source file path
  private let sourcePath: String

  /// The destination file path
  private let destinationPath: String

  /// Whether to overwrite the destination if it exists
  private let overwrite: Bool

  /// Whether to create parent directories for the destination if they don't exist
  private let createParentDirectories: Bool

  /**
   Initialises a new move file command.

   - Parameters:
      - sourcePath: Path to the source file
      - destinationPath: Path to the destination file
      - overwrite: Whether to overwrite the destination if it exists
      - createParentDirectories: Whether to create parent directories for the destination
      - fileManager: File manager to use for operations
      - logger: Optional logger for operation tracking
   */
  public init(
    sourcePath: String,
    destinationPath: String,
    overwrite: Bool=false,
    createParentDirectories: Bool=true,
    fileManager: FileManager = .default,
    logger: LoggingProtocol?=nil
  ) {
    self.sourcePath=sourcePath
    self.destinationPath=destinationPath
    self.overwrite=overwrite
    self.createParentDirectories=createParentDirectories
    super.init(fileManager: fileManager, logger: logger)
  }

  /**
   Executes the file move operation.

   - Parameters:
      - context: Logging context for the operation
      - operationID: Unique identifier for this operation instance
   - Returns: Void if successful, error otherwise
   */
  public func execute(
    context _: LogContextDTO,
    operationID: String
  ) async -> Result<Void, FileSystemError> {
    // Create a log context with proper privacy classification
    let logContext=createLogContext(
      operation: "moveFile",
      correlationID: operationID,
      additionalMetadata: [
        ("sourcePath", (value: sourcePath, privacyLevel: .protected)),
        ("destinationPath", (value: destinationPath, privacyLevel: .protected)),
        ("overwrite", (value: "\(overwrite)", privacyLevel: .public)),
        ("createParentDirectories", (value: "\(createParentDirectories)", privacyLevel: .public))
      ]
    )

    await logDebug("Starting file move operation", context: logContext)

    // Validate that the source path exists and is a file
    let sourcePathResult=validatePath(sourcePath, expectedType: .file)
    guard case let .success(validSourcePath)=sourcePathResult else {
      if case let .failure(error)=sourcePathResult {
        await logError("Source file validation failed: \(error)", context: logContext)
        return .failure(error)
      }
      // This shouldn't happen, but just in case
      await logError("Unknown source path validation error", context: logContext)
      return .failure(.invalidPath)
    }

    // Normalise the destination path
    let normalisedDestinationPath=normalisePath(destinationPath)

    // Check if destination file exists and handle according to overwrite parameter
    if fileManager.fileExists(atPath: normalisedDestinationPath) {
      if !overwrite {
        await logError(
          "Destination file already exists and overwrite is disabled",
          context: logContext
        )
        return .failure(.fileAlreadyExists)
      }

      do {
        // Delete the existing destination file
        try fileManager.removeItem(atPath: normalisedDestinationPath)
        await logInfo("Removed existing destination file", context: logContext)
      } catch {
        await logError(
          "Failed to remove existing destination file: \(error.localizedDescription)",
          context: logContext
        )
        return .failure(.deleteError(error.localizedDescription))
      }
    }

    // Ensure parent directory exists if requested
    if createParentDirectories {
      let destinationDirectoryPath=(normalisedDestinationPath as NSString).deletingLastPathComponent

      if !fileManager.fileExists(atPath: destinationDirectoryPath) {
        do {
          try fileManager.createDirectory(
            atPath: destinationDirectoryPath,
            withIntermediateDirectories: true,
            attributes: nil
          )

          await logInfo("Created parent directories for destination", context: logContext)
        } catch {
          await logError(
            "Failed to create parent directories for destination: \(error.localizedDescription)",
            context: logContext
          )
          return .failure(.createDirectoryFailed(error.localizedDescription))
        }
      }
    }

    do {
      // Move the file
      try fileManager.moveItem(atPath: validSourcePath, toPath: normalisedDestinationPath)

      await logInfo(
        "Successfully moved file from \(validSourcePath) to \(normalisedDestinationPath)",
        context: logContext
      )

      return .success(())
    } catch {
      let fileSystemError: FileSystemError=if let nsError=error as NSError? {
        switch nsError.code {
          case NSFileNoSuchFileError:
            .pathNotFound
          case NSFileWriteNoPermissionError:
            .accessDenied
          case NSFileWriteOutOfSpaceError:
            .insufficientSpace
          case NSFileWriteVolumeReadOnlyError:
            .readOnlyVolume
          default:
            .moveError(error.localizedDescription)
        }
      } else {
        .moveError(error.localizedDescription)
      }

      await logError(
        "Failed to move file: \(error.localizedDescription)",
        context: logContext
      )

      return .failure(fileSystemError)
    }
  }
}
