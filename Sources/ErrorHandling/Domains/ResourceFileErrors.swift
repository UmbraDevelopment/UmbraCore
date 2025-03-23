import Foundation

// Local type declarations to replace imports
// These replace the removed ErrorHandling and ErrorHandlingDomains imports

/// Error domain namespace
public enum ErrorDomain {
  /// Security domain
  public static let security = "Security"
  /// Crypto domain
  public static let crypto = "Crypto"
  /// Application domain
  public static let application = "Application"
}

/// Error context protocol
public protocol ErrorContext {
  /// Domain of the error
  var domain: String { get }
  /// Code of the error
  var code: Int { get }
  /// Description of the error
  var description: String { get }
}

/// Base error context implementation
public struct BaseErrorContext: ErrorContext {
  /// Domain of the error
  public let domain: String
  /// Code of the error
  public let code: Int
  /// Description of the error
  public let description: String

  /// Initialise with domain, code and description
  public init(domain: String, code: Int, description: String) {
    self.domain = domain
    self.code = code
    self.description = description
  }
}

extension UmbraErrors.Resource {
  /// File system specific resource errors
  public enum File: Error, UmbraError, StandardErrorCapabilities {
    // File access errors
    /// File not found
    case fileNotFound(path: String)

    /// Directory not found
    case directoryNotFound(path: String)

    /// Permission denied for file operation
    case permissionDenied(path: String, operation: String)

    /// File already exists
    case fileAlreadyExists(path: String)

    /// Directory already exists
    case directoryAlreadyExists(path: String)

    // File operation errors
    /// Failed to read from file
    case readFailed(path: String, reason: String)

    /// Failed to write to file
    case writeFailed(path: String, reason: String)

    /// Failed to delete file
    case deleteFailed(path: String, reason: String)

    /// Failed to create directory
    case createDirectoryFailed(path: String, reason: String)

    /// Failed to move file
    case moveFailed(sourcePath: String, destinationPath: String, reason: String)

    /// Failed to copy file
    case copyFailed(sourcePath: String, destinationPath: String, reason: String)

    // File state errors
    /// File is in use by another process
    case fileInUse(path: String, processName: String?)

    /// File system is read-only
    case readOnlyFileSystem(path: String)

    /// Disk is full
    case diskFull(path: String, requiredBytes: Int64?, availableBytes: Int64?)

    /// File is corrupt
    case fileCorrupt(path: String, reason: String)

    /// Path is invalid
    case invalidPath(path: String, reason: String)

    // MARK: - UmbraError Protocol

    /// Domain identifier for file errors
    public var domain: String {
      "Resource.File"
    }

    /// Error code uniquely identifying the error type
    public var code: String {
      switch self {
        case .fileNotFound:
          "file_not_found"
        case .directoryNotFound:
          "directory_not_found"
        case .permissionDenied:
          "permission_denied"
        case .fileAlreadyExists:
          "file_already_exists"
        case .directoryAlreadyExists:
          "directory_already_exists"
        case .readFailed:
          "read_failed"
        case .writeFailed:
          "write_failed"
        case .deleteFailed:
          "delete_failed"
        case .createDirectoryFailed:
          "create_directory_failed"
        case .moveFailed:
          "move_failed"
        case .copyFailed:
          "copy_failed"
        case .fileInUse:
          "file_in_use"
        case .readOnlyFileSystem:
          "read_only_file_system"
        case .diskFull:
          "disk_full"
        case .fileCorrupt:
          "file_corrupt"
        case .invalidPath:
          "invalid_path"
      }
    }

    /// Human-readable description of the error
    public var errorDescription: String {
      switch self {
        case let .fileNotFound(path):
          return "File not found: \(path)"
        case let .directoryNotFound(path):
          return "Directory not found: \(path)"
        case let .permissionDenied(path, operation):
          return "Permission denied for operation '\(operation)' on path: \(path)"
        case let .fileAlreadyExists(path):
          return "File already exists: \(path)"
        case let .directoryAlreadyExists(path):
          return "Directory already exists: \(path)"
        case let .readFailed(path, reason):
          return "Failed to read from file '\(path)': \(reason)"
        case let .writeFailed(path, reason):
          return "Failed to write to file '\(path)': \(reason)"
        case let .deleteFailed(path, reason):
          return "Failed to delete file '\(path)': \(reason)"
        case let .createDirectoryFailed(path, reason):
          return "Failed to create directory '\(path)': \(reason)"
        case let .moveFailed(sourcePath, destinationPath, reason):
          return "Failed to move file from '\(sourcePath)' to '\(destinationPath)': \(reason)"
        case let .copyFailed(sourcePath, destinationPath, reason):
          return "Failed to copy file from '\(sourcePath)' to '\(destinationPath)': \(reason)"
        case let .fileInUse(path, processName):
          if let process = processName {
            return "File '\(path)' is in use by process: \(process)"
          } else {
            return "File '\(path)' is in use by another process"
          }
        case let .readOnlyFileSystem(path):
          return "File system is read-only for path: \(path)"
        case let .diskFull(path, requiredBytes, availableBytes):
          var message = "Disk is full for path: \(path)"
          if let required = requiredBytes, let available = availableBytes {
            message += " (required: \(required) bytes, available: \(available) bytes)"
          }
          return message
        case let .fileCorrupt(path, reason):
          return "File is corrupt '\(path)': \(reason)"
        case let .invalidPath(path, reason):
          return "Invalid path '\(path)': \(reason)"
      }
    }

    /// Source information about where the error occurred
    public var source: ErrorHandlingInterfaces.ErrorSource? {
      nil // Source is typically set when the error is created with context
    }

    /// The underlying error, if any
    public var underlyingError: Error? {
      nil // Underlying error is typically set when the error is created with context
    }

    /// Additional context for the error
    public var context: ErrorHandlingInterfaces.ErrorContext {
      ErrorHandlingInterfaces.ErrorContext(
        source: domain,
        operation: "file_operation",
        details: errorDescription
      )
    }

    /// Creates a new instance of the error with additional context
    public func with(context _: ErrorHandlingInterfaces.ErrorContext) -> Self {
      // Since these are enum cases, we need to return a new instance with the same value
      switch self {
        case let .fileNotFound(path):
          .fileNotFound(path: path)
        case let .directoryNotFound(path):
          .directoryNotFound(path: path)
        case let .permissionDenied(path, operation):
          .permissionDenied(path: path, operation: operation)
        case let .fileAlreadyExists(path):
          .fileAlreadyExists(path: path)
        case let .directoryAlreadyExists(path):
          .directoryAlreadyExists(path: path)
        case let .readFailed(path, reason):
          .readFailed(path: path, reason: reason)
        case let .writeFailed(path, reason):
          .writeFailed(path: path, reason: reason)
        case let .deleteFailed(path, reason):
          .deleteFailed(path: path, reason: reason)
        case let .createDirectoryFailed(path, reason):
          .createDirectoryFailed(path: path, reason: reason)
        case let .moveFailed(sourcePath, destinationPath, reason):
          .moveFailed(sourcePath: sourcePath, destinationPath: destinationPath, reason: reason)
        case let .copyFailed(sourcePath, destinationPath, reason):
          .copyFailed(sourcePath: sourcePath, destinationPath: destinationPath, reason: reason)
        case let .fileInUse(path, processName):
          .fileInUse(path: path, processName: processName)
        case let .readOnlyFileSystem(path):
          .readOnlyFileSystem(path: path)
        case let .diskFull(path, requiredBytes, availableBytes):
          .diskFull(path: path, requiredBytes: requiredBytes, availableBytes: availableBytes)
        case let .fileCorrupt(path, reason):
          .fileCorrupt(path: path, reason: reason)
        case let .invalidPath(path, reason):
          .invalidPath(path: path, reason: reason)
      }
      // In a real implementation, we would attach the context
    }

    /// Creates a new instance of the error with a specified underlying error
    public func with(underlyingError _: Error) -> Self {
      // Similar to above, return a new instance with the same value
      self // In a real implementation, we would attach the underlying error
    }

    /// Creates a new instance of the error with source information
    public func with(source _: ErrorHandlingInterfaces.ErrorSource) -> Self {
      // Similar to above, return a new instance with the same value
      self // In a real implementation, we would attach the source information
    }
  }
}

// MARK: - Factory Methods

extension UmbraErrors.Resource.File {
  /// Create an error for a file that could not be found
  public static func makeFileNotFound(
    path: String,
    file _: String = #file,
    line _: Int = #line,
    function _: String = #function
  ) -> Self {
    .fileNotFound(path: path)
  }

  /// Create an error for a directory that could not be found
  public static func makeDirectoryNotFound(
    path: String,
    file _: String = #file,
    line _: Int = #line,
    function _: String = #function
  ) -> Self {
    .directoryNotFound(path: path)
  }

  /// Create an error for a failed file read operation
  public static func makeReadError(
    path: String,
    reason: String,
    file _: String = #file,
    line _: Int = #line,
    function _: String = #function
  ) -> Self {
    .readFailed(path: path, reason: reason)
  }

  /// Create an error for a failed file write operation
  public static func makeWriteError(
    path: String,
    reason: String,
    file _: String = #file,
    line _: Int = #line,
    function _: String = #function
  ) -> Self {
    .writeFailed(path: path, reason: reason)
  }

  /// Create an error for a permission denied scenario
  public static func makePermissionError(
    path: String,
    operation: String,
    file _: String = #file,
    line _: Int = #line,
    function _: String = #function
  ) -> Self {
    .permissionDenied(path: path, operation: operation)
  }

  /// Create an error for a file that already exists
  public static func makeFileAlreadyExists(
    path: String,
    file _: String = #file,
    line _: Int = #line,
    function _: String = #function
  ) -> Self {
    .fileAlreadyExists(path: path)
  }

  /// Create an error for a directory that already exists
  public static func makeDirectoryAlreadyExists(
    path: String,
    file _: String = #file,
    line _: Int = #line,
    function _: String = #function
  ) -> Self {
    .directoryAlreadyExists(path: path)
  }

  /// Create an error for a failed file delete operation
  public static func makeDeleteError(
    path: String,
    reason: String,
    file _: String = #file,
    line _: Int = #line,
    function _: String = #function
  ) -> Self {
    .deleteFailed(path: path, reason: reason)
  }

  /// Create an error for a failed directory creation
  public static func makeCreateDirectoryError(
    path: String,
    reason: String,
    file _: String = #file,
    line _: Int = #line,
    function _: String = #function
  ) -> Self {
    .createDirectoryFailed(path: path, reason: reason)
  }

  /// Create an error for a failed file move operation
  public static func makeMoveError(
    sourcePath: String,
    destinationPath: String,
    reason: String,
    file _: String = #file,
    line _: Int = #line,
    function _: String = #function
  ) -> Self {
    .moveFailed(sourcePath: sourcePath, destinationPath: destinationPath, reason: reason)
  }

  /// Create an error for a failed file copy operation
  public static func makeCopyError(
    sourcePath: String,
    destinationPath: String,
    reason: String,
    file _: String = #file,
    line _: Int = #line,
    function _: String = #function
  ) -> Self {
    .copyFailed(sourcePath: sourcePath, destinationPath: destinationPath, reason: reason)
  }

  /// Create an error for a file in use scenario
  public static func makeFileInUseError(
    path: String,
    processName: String? = nil,
    file _: String = #file,
    line _: Int = #line,
    function _: String = #function
  ) -> Self {
    .fileInUse(path: path, processName: processName)
  }

  /// Create an error for a read-only file system scenario
  public static func makeReadOnlyFileSystemError(
    path: String,
    file _: String = #file,
    line _: Int = #line,
    function _: String = #function
  ) -> Self {
    .readOnlyFileSystem(path: path)
  }

  /// Create an error for a disk full scenario
  public static func makeDiskFullError(
    path: String,
    requiredBytes: Int64? = nil,
    availableBytes: Int64? = nil,
    file _: String = #file,
    line _: Int = #line,
    function _: String = #function
  ) -> Self {
    .diskFull(path: path, requiredBytes: requiredBytes, availableBytes: availableBytes)
  }

  /// Create an error for a file corrupt scenario
  public static func makeFileCorruptError(
    path: String,
    reason: String,
    file _: String = #file,
    line _: Int = #line,
    function _: String = #function
  ) -> Self {
    .fileCorrupt(path: path, reason: reason)
  }

  /// Create an error for an invalid path scenario
  public static func makeInvalidPathError(
    path: String,
    reason: String,
    file _: String = #file,
    line _: Int = #line,
    function _: String = #function
  ) -> Self {
    .invalidPath(path: path, reason: reason)
  }
}
