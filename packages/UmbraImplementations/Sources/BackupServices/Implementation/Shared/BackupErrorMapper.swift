import BackupInterfaces
import Foundation
import LoggingTypes
import UmbraErrors

/**
 * Maps general errors to domain-specific backup errors.
 *
 * This class follows the Alpha Dot Five architecture pattern for
 * structured error handling, ensuring consistent error mapping
 * throughout the backup services.
 */
public struct BackupErrorMapper {
  /// Creates a new error mapper
  public init() {}

  /**
   * Maps any error to an appropriate BackupOperationError
   * - Parameters:
   *   - error: The original error
   *   - context: Log context for the operation
   * - Returns: An appropriate BackupOperationError
   */
  public func mapError(_ error: Error, context _: BackupLogContext?=nil) -> BackupOperationError {
    // If it's already a BackupOperationError, just return it
    if let backupError=error as? BackupOperationError {
      return backupError
    }

    // Check if this is a cancellation
    if error is CancellationError {
      return BackupOperationError.operationCancelled("Operation was cancelled by the user")
    }

    // Handle URLError types
    if let urlError=error as? URLError {
      return BackupOperationError.networkError(
        "Network error \(urlError.code.rawValue): \(urlError.localizedDescription)"
      )
    }

    // Handle NSError types
    if let nsError=error as? NSError {
      switch nsError.domain {
        case NSURLErrorDomain:
          return BackupOperationError.networkError(
            "Network error \(nsError.code): \(nsError.localizedDescription)"
          )

        case NSPOSIXErrorDomain:
          // Handle POSIX errors by their numeric values
          switch nsError.code {
            case 2: // ENOENT
              return BackupOperationError.fileNotFound(
                "File or directory not found: \(nsError.localizedDescription)"
              )
            case 13: // EACCES
              return BackupOperationError.permissionDenied(
                "Permission denied: \(nsError.localizedDescription)"
              )
            case 28: // ENOSPC
              return BackupOperationError.insufficientSpace(
                "No space left on device: \(nsError.localizedDescription)"
              )
            default:
              break
          }

        case NSCocoaErrorDomain:
          switch CocoaError.Code(rawValue: nsError.code) {
            case .fileNoSuchFile, .fileReadNoSuchFile:
              return BackupOperationError.fileNotFound(
                "File not found: \(nsError.localizedDescription)"
              )
            case .fileReadNoPermission, .fileWriteNoPermission:
              return BackupOperationError.permissionDenied(
                "Permission denied: \(nsError.localizedDescription)"
              )
            default:
              break
          }

        default:
          break
      }
    }

    // For other errors, create a general error
    return BackupOperationError.unexpected(
      "Unexpected error: \(error.localizedDescription)"
    )
  }
}
