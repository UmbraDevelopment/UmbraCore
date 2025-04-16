import DomainFileSystemTypes
import Foundation
import LoggingInterfaces
import LoggingTypes

/// Command for creating a directory.
///
/// This command follows the Alpha Dot Five architecture principles with privacy-aware
/// logging and strong error handling.
public class CreateDirectoryCommand: BaseFileSystemCommand, FileSystemCommand {
  /// The type of result returned by this command
  public typealias ResultType=Void

  /// The path of the directory to create
  private let directoryPath: String

  /// Whether to create intermediate directories
  private let createIntermediates: Bool

  /// Directory attributes to set
  private let attributes: [FileAttributeKey: Any]?

  /// Initialises a new create directory command.
  ///
  /// - Parameters:
  ///   - directoryPath: Path to the directory to create
  ///   - createIntermediates: Whether to create intermediate directories
  ///   - attributes: Optional attributes to set on the directory
  ///   - fileManager: File manager to use for operations
  ///   - logger: Optional logger for operation tracking
  public init(
    directoryPath: String,
    createIntermediates: Bool=true,
    attributes: [FileAttributeKey: Any]?=nil,
    fileManager: FileManager = .default,
    logger: LoggingProtocol?=nil
  ) {
    self.directoryPath=directoryPath
    self.createIntermediates=createIntermediates
    self.attributes=attributes
    super.init(fileManager: fileManager, logger: logger)
  }

  /// Executes the directory creation operation.
  ///
  /// - Parameters:
  ///   - context: Logging context for the operation
  ///   - operationID: Unique identifier for this operation instance
  /// - Returns: Void if successful, error otherwise
  public func execute(
    context _: LogContextDTO,
    operationID: String
  ) async -> Result<Void, FileSystemError> {
    // Create a log context with proper privacy classification
    let logContext=createLogContext(
      operation: "createDirectory",
      correlationID: operationID,
      additionalMetadata: [
        ("directoryPath", (value: directoryPath, privacyLevel: .protected)),
        ("createIntermediates", (value: "\(createIntermediates)", privacyLevel: .public)),
        ("hasAttributes", (value: attributes != nil ? "true" : "false", privacyLevel: .public))
      ]
    )

    await logDebug("Starting directory creation operation", context: logContext)

    // Normalise the path
    let normalisedPath=normalisePath(directoryPath)

    // Check if directory already exists
    if fileManager.fileExists(atPath: normalisedPath) {
      var isDirectory: ObjCBool=false
      fileManager.fileExists(atPath: normalisedPath, isDirectory: &isDirectory)

      if isDirectory.boolValue {
        await logInfo(
          "Directory already exists: \(normalisedPath)",
          context: logContext
        )
        return .success(())
      } else {
        await logError(
          "Path exists but is not a directory: \(normalisedPath)",
          context: logContext
        )
        return .failure(.invalidPathType(expectedType: .directory, actualType: .file))
      }
    }

    do {
      // Create the directory
      try fileManager.createDirectory(
        atPath: normalisedPath,
        withIntermediateDirectories: createIntermediates,
        attributes: attributes
      )

      await logInfo(
        "Successfully created directory: \(normalisedPath)",
        context: logContext
      )

      return .success(())
    } catch {
      let fileSystemError: FileSystemError=if let nsError=error as NSError? {
        switch nsError.code {
          case NSFileNoSuchFileError where !createIntermediates:
            .pathNotFound
          case NSFileWriteNoPermissionError:
            .accessDenied
          case NSFileWriteOutOfSpaceError:
            .insufficientSpace
          case NSFileWriteVolumeReadOnlyError:
            .readOnlyVolume
          default:
            .createDirectoryFailed(error.localizedDescription)
        }
      } else {
        .createDirectoryFailed(error.localizedDescription)
      }

      await logError(
        "Failed to create directory: \(error.localizedDescription)",
        context: logContext
      )

      return .failure(fileSystemError)
    }
  }
}
