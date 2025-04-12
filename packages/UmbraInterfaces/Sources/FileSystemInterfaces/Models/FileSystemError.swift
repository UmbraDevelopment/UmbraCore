import Foundation

/**
 # File System Error

 Comprehensive error type for file system operations.

 This enum provides detailed error categories and contextual information
 for all file system operation failures, enabling proper error handling
 and reporting throughout the application.

 ## Error Categories

 The errors are organised into categories that reflect the different types
 of failures that can occur during file system operations:

 - **Access Errors**: Permission and security-related issues
 - **Path Errors**: Problems with file paths or locations
 - **IO Errors**: Issues with reading or writing data
 - **Resource Errors**: Problems with system resources
 - **State Errors**: Unexpected file system states

 ## Alpha Dot Five Architecture

 This type follows the Alpha Dot Five architecture principles:
 - Uses enum with associated values for type safety
 - Provides rich context for debugging and error reporting
 - Conforms to standard error protocols
 - Uses British spelling in documentation
 */
public enum FileSystemError: Error, Equatable, Sendable {
  // MARK: - IO Errors

  /// Error when reading from a file
  case readError(path: String, reason: String)

  /// Error when writing to a file
  case writeError(path: String, reason: String)

  /// Error when a file operation is interrupted
  case operationInterrupted(path: String, reason: String)

  /// Error when data is corrupted or invalid
  case dataCorruption(path: String, reason: String)

  /// Error when a file format is not supported
  case unsupportedFormat(path: String, format: String)

  /// Error when a file cannot be deleted
  case deleteError(path: String, reason: String)

  /// Error when a file or directory cannot be moved
  case moveError(source: String, destination: String, reason: String)

  /// Error when a file or directory cannot be copied
  case copyError(source: String, destination: String, reason: String)

  // MARK: - Path Errors

  /// Error when a file or directory does not exist
  case notFound(path: String)

  /// Error when a path is not found (alias for notFound for compatibility)
  case pathNotFound(path: String)

  /// Error when a path already exists
  case pathAlreadyExists(path: String)

  /// Error when an item already exists at the specified path
  case itemAlreadyExists(path: String)

  /// Error when a file or directory already exists
  case alreadyExists(path: String)

  /// Error when a path is invalid
  case invalidPath(path: String, reason: String)

  /// The path couldn't be accessed (e.g., network path unavailable)
  case pathUnavailable(path: String, reason: String)

  /// Error when the type of item at path is not what was expected
  case unexpectedItemType(path: String, expected: String, actual: String?=nil)

  // MARK: - Access Errors

  /// Error when permission is denied
  case permissionDenied(path: String, reason: String)

  /// Error when access is denied due to security constraints
  case accessDenied(path: String, reason: String)

  /// The operation failed because the file is locked or in use
  case fileLocked(path: String)

  /// The operation failed because a security constraint was violated
  case securityViolation(path: String, constraint: String)

  /// Error when a secure operation fails
  case securityError(path: String, reason: String)

  // MARK: - Resource Errors

  /// Error when disk space is insufficient
  case diskSpaceFull(path: String, bytesRequired: UInt64?, bytesAvailable: UInt64?)

  /// Error when system resources are exhausted (file handles, memory, etc.)
  case resourceExhausted(resource: String, operation: String)

  /// Error when a timeout occurs during a file operation
  case timeout(path: String, operation: String, duration: TimeInterval)

  // MARK: - Metadata Errors

  /// Error when a file attribute operation fails
  case attributeError(path: String, attribute: String, reason: String)

  /// Error when a file metadata operation fails
  case metadataError(path: String, reason: String)

  /// Error when an extended attribute operation fails
  case extendedAttributeError(path: String, attribute: String, reason: String)

  // MARK: - State Errors

  /// Error when the file system is in an inconsistent state
  case inconsistentState(path: String, reason: String)

  /// Error when a file operation is not supported
  case operationNotSupported(path: String, operation: String)

  // MARK: - System Errors

  /// Error when a system call fails
  case systemError(path: String, code: Int, description: String)

  /// Wraps a standard Foundation error with additional context
  case wrappedError(Error, operation: String, path: String?=nil)

  /// A general error that doesn't fit into other categories
  case other(path: String?, reason: String)

  // MARK: - Error Factory Methods

  /**
   Wraps a standard Error into a FileSystemError with additional context.

   - Parameters:
      - error: The original error to wrap
      - operation: The operation that was being performed
      - path: Optional path related to the error
   - Returns: A FileSystemError that wraps the original error
   */
  public static func wrap(_ error: Error, operation: String, path: String?=nil) -> FileSystemError {
    // If it's already a FileSystemError, just return it
    if let fsError=error as? FileSystemError {
      return fsError
    }

    // For NSError, try to create a more specific error based on the error code
    // Any Swift Error can be bridged to NSError, so no conditional cast is needed
    let nsError = error as NSError
    switch nsError.domain {
      case NSCocoaErrorDomain:
        return mapCocoaError(nsError, operation: operation, path: path)
      case NSPOSIXErrorDomain:
        return mapPOSIXError(nsError, operation: operation, path: path)
      default:
        break
    }

    // Default case: just wrap the error
    return .wrappedError(error, operation: operation, path: path)
  }

  /**
   Maps a Cocoa error to a FileSystemError.

   - Parameters:
      - error: The NSError from Cocoa
      - operation: The operation that was being performed
      - path: Optional path related to the error
   - Returns: A FileSystemError that corresponds to the Cocoa error
   */
  private static func mapCocoaError(
    _ error: NSError,
    operation: String,
    path: String?
  ) -> FileSystemError {
    let path=path ?? ""

    switch error.code {
      case NSFileNoSuchFileError:
        return .notFound(path: path)
      case NSFileWriteNoPermissionError:
        return .permissionDenied(path: path, reason: "No write permission")
      case NSFileReadNoPermissionError:
        return .permissionDenied(path: path, reason: "No read permission")
      case NSFileWriteOutOfSpaceError:
        return .diskSpaceFull(path: path, bytesRequired: nil, bytesAvailable: nil)
      case NSFileWriteVolumeReadOnlyError:
        return .permissionDenied(path: path, reason: "Volume is read-only")
      case NSFileWriteFileExistsError:
        return .alreadyExists(path: path)
      default:
        // Map POSIX errors
        let errorCode=error.code

        switch errorCode {
          case Int(ENOENT):
            return .notFound(path: path)
          case Int(EACCES):
            return .permissionDenied(path: path, reason: "Permission denied")
          case Int(EEXIST):
            return .alreadyExists(path: path)
          case Int(ENOSPC):
            return .diskSpaceFull(path: path, bytesRequired: nil, bytesAvailable: nil)
          case Int(EROFS):
            return .permissionDenied(path: path, reason: "File system is read-only")
          case Int(EBUSY):
            return .fileLocked(path: path)
          case Int(EINVAL):
            return .invalidPath(path: path, reason: "Invalid argument")
          case Int(EISDIR):
            return .invalidPath(path: path, reason: "Is a directory")
          case Int(ENOTDIR):
            return .invalidPath(path: path, reason: "Not a directory")
          case Int(ETIMEDOUT):
            return .timeout(path: path, operation: operation, duration: 0)
          case Int(EINTR):
            return .operationInterrupted(path: path, reason: "Operation interrupted")
          default:
            return .systemError(
              path: path,
              code: errorCode,
              description: String(cString: strerror(Int32(errorCode)))
            )
        }
    }
  }

  /**
   Maps a POSIX error to a FileSystemError.

   - Parameters:
      - error: The NSError from POSIX
      - operation: The operation that was being performed
      - path: Optional path related to the error
   - Returns: A FileSystemError that corresponds to the POSIX error
   */
  private static func mapPOSIXError(
    _ error: NSError,
    operation: String,
    path: String?
  ) -> FileSystemError {
    let path=path ?? ""
    let errorCode=error.code

    switch errorCode {
      case Int(ENOENT):
        return .notFound(path: path)
      case Int(EACCES):
        return .permissionDenied(path: path, reason: "Permission denied")
      case Int(EEXIST):
        return .alreadyExists(path: path)
      case Int(ENOSPC):
        return .diskSpaceFull(path: path, bytesRequired: nil, bytesAvailable: nil)
      case Int(EROFS):
        return .permissionDenied(path: path, reason: "File system is read-only")
      case Int(EBUSY):
        return .fileLocked(path: path)
      case Int(EINVAL):
        return .invalidPath(path: path, reason: "Invalid argument")
      case Int(EISDIR):
        return .invalidPath(path: path, reason: "Is a directory")
      case Int(ENOTDIR):
        return .invalidPath(path: path, reason: "Not a directory")
      case Int(ETIMEDOUT):
        return .timeout(path: path, operation: operation, duration: 0)
      case Int(EINTR):
        return .operationInterrupted(path: path, reason: "Operation interrupted")
      default:
        return .systemError(
          path: path,
          code: errorCode,
          description: String(cString: strerror(Int32(errorCode)))
        )
    }
  }
}

// MARK: - Equatable Implementation

// Manual implementation of Equatable because Error protocol doesn't conform to Equatable
extension FileSystemError {
  public static func == (lhs: FileSystemError, rhs: FileSystemError) -> Bool {
    switch (lhs, rhs) {
      case let (.readError(lhsPath, lhsReason), .readError(rhsPath, rhsReason)):
        lhsPath == rhsPath && lhsReason == rhsReason

      case let (.writeError(lhsPath, lhsReason), .writeError(rhsPath, rhsReason)):
        lhsPath == rhsPath && lhsReason == rhsReason

      case let (
      .operationInterrupted(lhsPath, lhsReason),
      .operationInterrupted(rhsPath, rhsReason)
    ):
        lhsPath == rhsPath && lhsReason == rhsReason

      case let (.dataCorruption(lhsPath, lhsReason), .dataCorruption(rhsPath, rhsReason)):
        lhsPath == rhsPath && lhsReason == rhsReason

      case let (.unsupportedFormat(lhsPath, lhsFormat), .unsupportedFormat(rhsPath, rhsFormat)):
        lhsPath == rhsPath && lhsFormat == rhsFormat

      case let (.notFound(lhsPath), .notFound(rhsPath)):
        lhsPath == rhsPath

      case let (.pathNotFound(lhsPath), .pathNotFound(rhsPath)):
        lhsPath == rhsPath

      case let (.alreadyExists(lhsPath), .alreadyExists(rhsPath)):
        lhsPath == rhsPath

      case let (.invalidPath(lhsPath, lhsReason), .invalidPath(rhsPath, rhsReason)):
        lhsPath == rhsPath && lhsReason == rhsReason

      case let (.pathUnavailable(lhsPath, lhsReason), .pathUnavailable(rhsPath, rhsReason)):
        lhsPath == rhsPath && lhsReason == rhsReason

      case let (.permissionDenied(lhsPath, lhsReason), .permissionDenied(rhsPath, rhsReason)):
        lhsPath == rhsPath && lhsReason == rhsReason

      case let (.accessDenied(lhsPath, lhsReason), .accessDenied(rhsPath, rhsReason)):
        lhsPath == rhsPath && lhsReason == rhsReason

      case let (.fileLocked(lhsPath), .fileLocked(rhsPath)):
        lhsPath == rhsPath

      case let (
      .securityViolation(lhsPath, lhsConstraint),
      .securityViolation(rhsPath, rhsConstraint)
    ):
        lhsPath == rhsPath && lhsConstraint == rhsConstraint

      case let (.securityError(lhsPath, lhsReason), .securityError(rhsPath, rhsReason)):
        lhsPath == rhsPath && lhsReason == rhsReason

      case let (
      .diskSpaceFull(lhsPath, lhsRequired, lhsAvailable),
      .diskSpaceFull(rhsPath, rhsRequired, rhsAvailable)
    ):
        lhsPath == rhsPath && lhsRequired == rhsRequired && lhsAvailable == rhsAvailable

      case let (
      .resourceExhausted(lhsResource, lhsOperation),
      .resourceExhausted(rhsResource, rhsOperation)
    ):
        lhsResource == rhsResource && lhsOperation == rhsOperation

      case let (
      .timeout(lhsPath, lhsOperation, lhsDuration),
      .timeout(rhsPath, rhsOperation, rhsDuration)
    ):
        lhsPath == rhsPath && lhsOperation == rhsOperation && lhsDuration == rhsDuration

      case let (
      .attributeError(lhsPath, lhsAttribute, lhsReason),
      .attributeError(rhsPath, rhsAttribute, rhsReason)
    ):
        lhsPath == rhsPath && lhsAttribute == rhsAttribute && lhsReason == rhsReason

      case let (.metadataError(lhsPath, lhsReason), .metadataError(rhsPath, rhsReason)):
        lhsPath == rhsPath && lhsReason == rhsReason

      case let (
      .extendedAttributeError(lhsPath, lhsAttribute, lhsReason),
      .extendedAttributeError(rhsPath, rhsAttribute, rhsReason)
    ):
        lhsPath == rhsPath && lhsAttribute == rhsAttribute && lhsReason == rhsReason

      case let (.inconsistentState(lhsPath, lhsReason), .inconsistentState(rhsPath, rhsReason)):
        lhsPath == rhsPath && lhsReason == rhsReason

      case let (
      .operationNotSupported(lhsPath, lhsOperation),
      .operationNotSupported(rhsPath, rhsOperation)
    ):
        lhsPath == rhsPath && lhsOperation == rhsOperation

      case let (
      .systemError(lhsPath, lhsCode, lhsDescription),
      .systemError(rhsPath, rhsCode, rhsDescription)
    ):
        lhsPath == rhsPath && lhsCode == rhsCode && lhsDescription == rhsDescription

      // For wrapped errors, we compare the path and operation but not the underlying error
      // since Error is not Equatable
      case let (.wrappedError(_, lhsOperation, lhsPath), .wrappedError(_, rhsOperation, rhsPath)):
        lhsOperation == rhsOperation && lhsPath == rhsPath

      case let (.other(lhsPath, lhsReason), .other(rhsPath, rhsReason)):
        lhsPath == rhsPath && lhsReason == rhsReason

      case let (
      .unexpectedItemType(lhsPath, lhsExpected, lhsActual),
      .unexpectedItemType(rhsPath, rhsExpected, rhsActual)
    ):
        lhsPath == rhsPath && lhsExpected == rhsExpected && lhsActual == rhsActual

      case let (.deleteError(lhsPath, lhsReason), .deleteError(rhsPath, rhsReason)):
        lhsPath == rhsPath && lhsReason == rhsReason

      case let (
      .moveError(lhsSource, lhsDestination, lhsReason),
      .moveError(rhsSource, rhsDestination, rhsReason)
    ):
        lhsSource == rhsSource && lhsDestination == rhsDestination && lhsReason == rhsReason

      case let (
      .copyError(lhsSource, lhsDestination, lhsReason),
      .copyError(rhsSource, rhsDestination, rhsReason)
    ):
        lhsSource == rhsSource && lhsDestination == rhsDestination && lhsReason == rhsReason

      case let (.pathAlreadyExists(lhsPath), .pathAlreadyExists(rhsPath)):
        lhsPath == rhsPath

      case let (.itemAlreadyExists(lhsPath), .itemAlreadyExists(rhsPath)):
        lhsPath == rhsPath

      // If case patterns don't match, the errors are not equal
      default:
        false
    }
  }
}

// MARK: - CustomStringConvertible Extension

extension FileSystemError: CustomStringConvertible {
  public var description: String {
    switch self {
      case let .readError(path, reason):
        return "Cannot read from '\(path)': \(reason)"
      case let .writeError(path, reason):
        return "Cannot write to '\(path)': \(reason)"
      case let .notFound(path):
        return "Item not found at path: '\(path)'"
      case let .pathNotFound(path):
        return "Path not found: '\(path)'"
      case let .alreadyExists(path):
        return "Item already exists at path: '\(path)'"
      case let .invalidPath(path, reason):
        return "Invalid path '\(path)': \(reason)"
      case let .permissionDenied(path, reason):
        return "Permission denied for path: '\(path)'. \(reason)"
      case let .diskSpaceFull(path, bytesRequired, bytesAvailable):
        var message="Disk space full for operation on '\(path)'"
        if let required=bytesRequired {
          message += ", \(required) bytes required"
        }
        if let available=bytesAvailable {
          message += ", \(available) bytes available"
        }
        return message
      case let .operationInterrupted(path, reason):
        return "Operation interrupted for '\(path)': \(reason)"
      case let .securityError(path, reason):
        return "Security error for '\(path)': \(reason)"
      case let .attributeError(path, attribute, reason):
        return "Attribute error for '\(path)', attribute '\(attribute)': \(reason)"
      case let .extendedAttributeError(path, attribute, reason):
        return "Extended attribute error for '\(path)', attribute '\(attribute)': \(reason)"
      case let .metadataError(path, reason):
        return "Metadata error for '\(path)': \(reason)"
      case let .accessDenied(path, reason):
        return "Access denied for path: '\(path)'. \(reason)"
      case .fileLocked:
        return "File is locked or in use by another process."
      case let .securityViolation(path, constraint):
        return "Security constraint violated for '\(path)': \(constraint)"
      case let .pathUnavailable(path, reason):
        return "Path unavailable: '\(path)'. \(reason)"
      case let .dataCorruption(path, reason):
        return "Data corruption detected in '\(path)': \(reason)"
      case let .unsupportedFormat(path, format):
        return "Unsupported format '\(format)' for file: '\(path)'"
      case let .resourceExhausted(resource, operation):
        return "System resource '\(resource)' exhausted during operation: \(operation)"
      case let .timeout(path, operation, duration):
        return "Operation '\(operation)' on '\(path)' timed out after \(duration) seconds"
      case let .inconsistentState(path, reason):
        return "File system in inconsistent state for '\(path)': \(reason)"
      case let .operationNotSupported(path, operation):
        return "Operation '\(operation)' not supported for '\(path)'"
      case let .systemError(path, code, description):
        return "System error (code \(code)) for '\(path)': \(description)"
      case let .wrappedError(error, operation, path):
        let pathDesc=path.map { " on '\($0)'" } ?? ""
        return "Error during \(operation)\(pathDesc): \(error.localizedDescription)"
      case let .other(path, reason):
        let pathDesc=path.map { " for '\($0)'" } ?? ""
        return "File system error\(pathDesc): \(reason)"
      case let .unexpectedItemType(path, expected, actual):
        let actualDesc=actual.map { " (actual: \($0))" } ?? ""
        return "Unexpected item type at '\(path)': expected \(expected)\(actualDesc)"
      case let .deleteError(path, reason):
        return "Cannot delete '\(path)': \(reason)"
      case let .moveError(source, destination, reason):
        return "Cannot move '\(source)' to '\(destination)': \(reason)"
      case let .copyError(source, destination, reason):
        return "Cannot copy '\(source)' to '\(destination)': \(reason)"
      case let .pathAlreadyExists(path):
        return "Path '\(path)' already exists"
      case let .itemAlreadyExists(path):
        return "Item already exists at path: '\(path)'"
    }
  }
}

// MARK: - LocalizedError Extension

extension FileSystemError: LocalizedError {
  public var errorDescription: String? {
    description
  }

  public var failureReason: String? {
    switch self {
      case let .readError(_, reason):
        return reason
      case let .writeError(_, reason):
        return reason
      case .notFound:
        return "The specified item could not be found."
      case .pathNotFound:
        return "The specified path could not be found."
      case .alreadyExists:
        return "An item already exists at the specified path."
      case let .invalidPath(_, reason):
        return reason
      case let .permissionDenied(_, reason):
        return reason
      case let .accessDenied(_, reason):
        return reason
      case .diskSpaceFull:
        return "There is not enough disk space to complete the operation."
      case let .operationInterrupted(_, reason):
        return reason
      case let .securityError(_, reason):
        return reason
      case let .attributeError(_, _, reason):
        return reason
      case let .extendedAttributeError(_, _, reason):
        return reason
      case let .metadataError(_, reason):
        return reason
      case .fileLocked:
        return "The file is locked or in use by another process."
      case let .securityViolation(_, constraint):
        return "Security constraint violation: \(constraint)"
      case let .pathUnavailable(_, reason):
        return reason
      case let .dataCorruption(_, reason):
        return reason
      case let .unsupportedFormat(_, format):
        return "The format '\(format)' is not supported."
      case let .resourceExhausted(resource, _):
        return "The system resource '\(resource)' has been exhausted."
      case .timeout:
        return "The operation timed out."
      case let .inconsistentState(_, reason):
        return reason
      case let .operationNotSupported(_, operation):
        return "The operation '\(operation)' is not supported."
      case let .systemError(_, _, description):
        return description
      case let .wrappedError(error, _, _):
        return error.localizedDescription
      case let .other(_, reason):
        return reason
      case let .unexpectedItemType(_, expected, actual):
        let actualDesc=actual.map { " (actual: \($0))" } ?? ""
        return "Expected item type '\(expected)'\(actualDesc) but found something else."
      case let .deleteError(_, reason):
        return reason
      case let .moveError(_, _, reason):
        return reason
      case let .copyError(_, _, reason):
        return reason
      case .pathAlreadyExists:
        return "The specified path already exists."
      case .itemAlreadyExists:
        return "An item already exists at the specified path."
    }
  }

  public var recoverySuggestion: String? {
    switch self {
      case .notFound:
        "Check that the path exists and is spelled correctly."
      case .pathNotFound:
        "Check that the path exists and is spelled correctly."
      case .alreadyExists:
        "Choose a different path or remove the existing item first."
      case .permissionDenied:
        "Check file permissions or run the application with elevated privileges."
      case .accessDenied:
        "Check sandbox permissions and file access entitlements."
      case .diskSpaceFull:
        "Free up disk space or use a different volume."
      case .fileLocked:
        "Close any applications that might be using this file and try again."
      case .operationInterrupted:
        "Try the operation again."
      case .invalidPath:
        "Check that the path is correctly formatted and within allowed bounds."
      default:
        nil
    }
  }
}
