import DomainFileSystemTypes
import Foundation
import LoggingInterfaces
import LoggingTypes

/**
 Command for writing data to a file.

 This command follows the Alpha Dot Five architecture principles with privacy-aware
 logging and strong error handling.
 */
public class WriteFileCommand: BaseFileSystemCommand, FileSystemCommand {
  /// The type of result returned by this command
  public typealias ResultType=Void

  /// The path of the file to write
  private let filePath: String

  /// The data to write to the file
  private let data: [UInt8]

  /// Whether to create parent directories if they don't exist
  private let createParentDirectories: Bool

  /// Whether to overwrite the file if it already exists
  private let overwrite: Bool

  /**
   Initialises a new write file command.

   - Parameters:
      - filePath: Path to the file to write
      - data: Data to write to the file
      - createParentDirectories: Whether to create parent directories if they don't exist
      - overwrite: Whether to overwrite the file if it already exists
      - fileManager: File manager to use for operations
      - logger: Optional logger for operation tracking
   */
  public init(
    filePath: String,
    data: [UInt8],
    createParentDirectories: Bool=true,
    overwrite: Bool=true,
    fileManager: FileManager = .default,
    logger: LoggingProtocol?=nil
  ) {
    self.filePath=filePath
    self.data=data
    self.createParentDirectories=createParentDirectories
    self.overwrite=overwrite
    super.init(fileManager: fileManager, logger: logger)
  }

  /**
   Executes the file write operation.

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
      operation: "writeFile",
      correlationID: operationID,
      additionalMetadata: [
        ("filePath", (value: filePath, privacyLevel: .protected)),
        ("dataSize", (value: "\(data.count) bytes", privacyLevel: .public)),
        ("createParentDirectories", (value: "\(createParentDirectories)", privacyLevel: .public)),
        ("overwrite", (value: "\(overwrite)", privacyLevel: .public))
      ]
    )

    await logDebug("Starting write file operation", context: logContext)

    // Normalise the path
    let normalisedPath=normalisePath(filePath)

    // Check if file exists and handle according to overwrite parameter
    if fileManager.fileExists(atPath: normalisedPath) {
      if !overwrite {
        await logError("File already exists and overwrite is disabled", context: logContext)
        return .failure(.fileAlreadyExists)
      }

      await logInfo("File exists, will be overwritten", context: logContext)
    }

    // Ensure parent directory exists if requested
    if createParentDirectories {
      let directoryPath=(normalisedPath as NSString).deletingLastPathComponent

      if !fileManager.fileExists(atPath: directoryPath) {
        do {
          try fileManager.createDirectory(
            atPath: directoryPath,
            withIntermediateDirectories: true,
            attributes: nil
          )

          await logInfo("Created parent directories", context: logContext)
        } catch {
          await logError(
            "Failed to create parent directories: \(error.localizedDescription)",
            context: logContext
          )
          return .failure(.createDirectoryFailed(error.localizedDescription))
        }
      }
    }

    do {
      // Create data from the byte array
      let fileData=Data(data)

      // Write data to file
      try fileData.write(to: URL(fileURLWithPath: normalisedPath))

      await logInfo(
        "Successfully wrote \(data.count) bytes to file: \(normalisedPath)",
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
            .writeError(error.localizedDescription)
        }
      } else {
        .writeError(error.localizedDescription)
      }

      await logError(
        "Failed to write file: \(error.localizedDescription)",
        context: logContext
      )

      return .failure(fileSystemError)
    }
  }
}
