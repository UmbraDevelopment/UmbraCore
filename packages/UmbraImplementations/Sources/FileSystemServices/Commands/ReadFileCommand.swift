import DomainFileSystemTypes
import Foundation
import LoggingInterfaces
import LoggingTypes

/// Command for reading file contents.
///
/// This command follows the Alpha Dot Five architecture principles with privacy-aware
/// logging and strong error handling.
public class ReadFileCommand: BaseFileSystemCommand, FileSystemCommand {
  /// The type of result returned by this command
  public typealias ResultType=[UInt8]

  /// The path of the file to read
  private let filePath: String

  /// Initialises a new read file command.
  ///
  /// - Parameters:
  ///   - filePath: Path to the file to read
  ///   - fileManager: File manager to use for operations
  ///   - logger: Optional logger for operation tracking
  public init(
    filePath: String,
    fileManager: FileManager = .default,
    logger: LoggingProtocol?=nil
  ) {
    self.filePath=filePath
    super.init(fileManager: fileManager, logger: logger)
  }

  /// Executes the file read operation.
  ///
  /// - Parameters:
  ///   - context: Logging context for the operation
  ///   - operationID: Unique identifier for this operation instance
  /// - Returns: The file contents as a byte array
  public func execute(
    context _: LogContextDTO,
    operationID: String
  ) async -> Result<[UInt8], FileSystemError> {
    // Create a log context with proper privacy classification
    let logContext=createLogContext(
      operation: "readFile",
      correlationID: operationID,
      additionalMetadata: [
        ("filePath", (value: filePath, privacyLevel: .protected))
      ]
    )

    await logDebug("Starting read file operation", context: logContext)

    // Validate that the path exists and is a file
    let pathResult=validatePath(filePath, expectedType: .file)
    guard case let .success(validPath)=pathResult else {
      if case let .failure(error)=pathResult {
        await logError("File path validation failed: \(error)", context: logContext)
        return .failure(error)
      }
      // This shouldn't happen, but just in case
      await logError("Unknown path validation error", context: logContext)
      return .failure(.invalidPath)
    }

    do {
      // Read file contents
      let data=try Data(contentsOf: URL(fileURLWithPath: validPath))
      let bytes=[UInt8](data)

      await logInfo(
        "Successfully read file: \(validPath) (\(bytes.count) bytes)",
        context: logContext
      )

      return .success(bytes)
    } catch {
      let fileSystemError: FileSystemError=if let nsError=error as NSError? {
        switch nsError.code {
          case NSFileReadNoSuchFileError:
            .pathNotFound
          case NSFileReadNoPermissionError:
            .accessDenied
          case NSFileReadCorruptFileError:
            .corruptData
          default:
            .readError(error.localizedDescription)
        }
      } else {
        .readError(error.localizedDescription)
      }

      await logError(
        "Failed to read file: \(error.localizedDescription)",
        context: logContext
      )

      return .failure(fileSystemError)
    }
  }
}
