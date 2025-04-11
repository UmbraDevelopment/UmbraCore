import DomainFileSystemTypes
import Foundation
import LoggingInterfaces
import LoggingTypes

/**
 Command for deleting a file.

 This command follows the Alpha Dot Five architecture principles with privacy-aware
 logging and strong error handling.
 */
public class DeleteFileCommand: BaseFileSystemCommand, FileSystemCommand {
  /// The type of result returned by this command
  public typealias ResultType=Void

  /// The path of the file to delete
  private let filePath: String

  /// Whether to secure delete the file
  private let secureDelete: Bool

  /**
   Initialises a new delete file command.

   - Parameters:
      - filePath: Path to the file to delete
      - secureDelete: Whether to perform a secure deletion (overwrite with zeros)
      - fileManager: File manager to use for operations
      - logger: Optional logger for operation tracking
   */
  public init(
    filePath: String,
    secureDelete: Bool=false,
    fileManager: FileManager = .default,
    logger: LoggingProtocol?=nil
  ) {
    self.filePath=filePath
    self.secureDelete=secureDelete
    super.init(fileManager: fileManager, logger: logger)
  }

  /**
   Executes the file deletion operation.

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
      operation: "deleteFile",
      correlationID: operationID,
      additionalMetadata: [
        ("filePath", (value: filePath, privacyLevel: .protected)),
        ("secureDelete", (value: "\(secureDelete)", privacyLevel: .public))
      ]
    )

    await logDebug("Starting file deletion operation", context: logContext)

    // Validate that the path exists and is a file
    let pathResult=validatePath(filePath, expectedType: .file)
    guard case let .success(validPath)=pathResult else {
      if case let .failure(error)=pathResult {
        await logInfo("File does not exist or is not a file: \(error)", context: logContext)
        return .success(()) // Consider non-existence as success for idempotence
      }
      // This shouldn't happen, but just in case
      await logError("Unknown path validation error", context: logContext)
      return .failure(.invalidPath)
    }

    do {
      // Secure delete if requested
      if secureDelete {
        // If secure delete is requested, overwrite the file with zeros before deletion
        let fileURL=URL(fileURLWithPath: validPath)
        let fileSize=try fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0

        if fileSize > 0 {
          // Create a file handle for overwriting
          let fileHandle=try FileHandle(forWritingTo: fileURL)
          defer { try? fileHandle.close() }

          // Create a buffer of zeros
          let bufferSize=min(fileSize, 1024 * 1024) // 1MB buffer or file size, whichever is smaller
          let zeroBuffer=[UInt8](repeating: 0, count: bufferSize)

          // Calculate number of full buffer writes and remaining bytes
          let fullBufferWrites=fileSize / bufferSize
          let remainingBytes=fileSize % bufferSize

          // Overwrite the file with zeros
          try fileHandle.seek(toOffset: 0)

          for _ in 0..<fullBufferWrites {
            try fileHandle.write(contentsOf: zeroBuffer)
          }

          if remainingBytes > 0 {
            let remainingBuffer=[UInt8](repeating: 0, count: Int(remainingBytes))
            try fileHandle.write(contentsOf: remainingBuffer)
          }

          try fileHandle.synchronize()
          try fileHandle.close()

          await logInfo("Securely overwrote file contents", context: logContext)
        }
      }

      // Delete the file
      try fileManager.removeItem(atPath: validPath)

      await logInfo(
        "Successfully deleted file: \(validPath)",
        context: logContext
      )

      return .success(())
    } catch {
      let fileSystemError: FileSystemError

      if let nsError=error as NSError? {
        switch nsError.code {
          case NSFileNoSuchFileError:
            await logInfo("File does not exist, considering delete successful", context: logContext)
            return .success(()) // Consider non-existence as success for idempotence
          case NSFileWriteNoPermissionError:
            fileSystemError = .accessDenied
          case NSFileLockingError:
            fileSystemError = .fileLocked
          default:
            fileSystemError = .deleteError(error.localizedDescription)
        }
      } else {
        fileSystemError = .deleteError(error.localizedDescription)
      }

      await logError(
        "Failed to delete file: \(error.localizedDescription)",
        context: logContext
      )

      return .failure(fileSystemError)
    }
  }
}
