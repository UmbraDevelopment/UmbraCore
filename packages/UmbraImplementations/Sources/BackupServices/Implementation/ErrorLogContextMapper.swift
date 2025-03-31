import BackupInterfaces
import Foundation
import LoggingTypes

/**
 * A mapper for converting various error types to standardised BackupOperationError types
 * and creating appropriate error contexts for logging.
 *
 * This follows the Alpha Dot Five pattern of providing structured error handling
 * with proper privacy controls.
 */
public struct ErrorLogContextMapper {
  /// Create a suitable error context from a log context
  /// - Parameter logContext: The original log context
  /// - Returns: A log context enriched with error information
  public func createErrorContext(from logContext: LogContextDTO) -> LogContextDTO {
    // If we have a SnapshotLogContextAdapter, use it directly
    if let snapshotContext=logContext as? SnapshotLogContextAdapter {
      return snapshotContext.with(
        key: "errorTimestamp",
        value: ISO8601DateFormatter().string(from: Date()),
        privacy: .public
      )
    }

    // For other contexts, do our best to create a meaningful error context
    var contextDictionary: [String: String]=[:]
    let metadata=logContext.toPrivacyMetadata()

    // Extract metadata fields manually since PrivacyMetadata doesn't have forEach
    for key in metadata.keys {
      if let value=metadata[key] {
        contextDictionary[key]=value.valueString
      }
    }

    // Create a new context with the operation from the original context
    let source=logContext.getSource()
    if source.contains("Snapshot") {
      return SnapshotLogContextAdapter(
        snapshotID: contextDictionary["snapshotID"] ?? "unknown",
        operation: contextDictionary["operation"] ?? "unknown",
        additionalContext: contextDictionary
      )
    } else {
      // Fall back to a simple context with the same metadata
      let newContext=SnapshotLogContextAdapter(
        snapshotID: "unknown",
        operation: "errorHandling"
      )

      // Add all metadata from the original context
      return contextDictionary.reduce(newContext) { context, entry in
        context.with(key: entry.key, value: entry.value, privacy: .public)
      }
    }
  }

  /// Maps a general Error to a suitable BackupOperationError
  /// - Parameter error: The error to convert
  /// - Returns: A BackupOperationError that best represents the original error
  public func mapToBackupError(_ error: Error) -> BackupOperationError {
    // If it's already a BackupOperationError, return it directly
    if let backupError=error as? BackupOperationError {
      return backupError
    }

    // Check for cancellation
    if
      error is CancellationError ||
      (error as? NSError)?.domain == NSURLErrorDomain &&
      (error as? NSError)?.code == NSURLErrorCancelled
    {
      return BackupOperationError.operationCancelled("Operation was cancelled by the user")
    }

    // Map URLError
    if let urlError=error as? URLError {
      return BackupOperationError.networkError(
        "Network error \(urlError.code.rawValue): \(urlError.localizedDescription)"
      )
    }

    // Map NSError
    if let nsError=error as? NSError {
      switch nsError.domain {
        case NSPOSIXErrorDomain:
          switch nsError.code {
            case 2: // ENOENT
              return BackupOperationError
                .fileNotFound("File not found: \(nsError.localizedDescription)")
            case 13: // EACCES
              return BackupOperationError
                .permissionDenied("Permission denied: \(nsError.localizedDescription)")
            case 28: // ENOSPC
              return BackupOperationError
                .insufficientSpace("No space left on device: \(nsError.localizedDescription)")
            default:
              break
          }

        case NSCocoaErrorDomain:
          switch CocoaError.Code(rawValue: nsError.code) {
            case .fileNoSuchFile, .fileReadNoSuchFile:
              return BackupOperationError
                .fileNotFound("File not found: \(nsError.localizedDescription)")
            case .fileReadNoPermission, .fileWriteNoPermission:
              return BackupOperationError
                .permissionDenied("Permission denied: \(nsError.localizedDescription)")
            default:
              break
          }

        case NSURLErrorDomain:
          return BackupOperationError.networkError("Network error: \(nsError.localizedDescription)")

        default:
          break
      }
    }

    // Fall back to unexpected error
    return BackupOperationError.unexpected("Unexpected error: \(error.localizedDescription)")
  }
}
