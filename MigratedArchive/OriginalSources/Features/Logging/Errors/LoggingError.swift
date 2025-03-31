import Foundation

// import SecurityInterfaces

/// Errors that can occur during logging operations
public enum LoggingError: LocalizedError {
  /// Failed to initialize logging
  case initializationFailed(reason: String)

  /// Failed to write to log file
  case writeError(reason: String)

  /// Failed to read from log file
  case readError(reason: String)

  /// Failed to create log directory
  case directoryCreationFailed(path: String)

  /// Failed to access log file
  case accessDenied(path: String)

  /// Invalid log file path
  case invalidPath(path: String)

  public var errorDescription: String? {
    switch self {
      case let .initializationFailed(reason):
        "Failed to initialize logging: \(reason)"
      case let .writeError(reason):
        "Failed to write to log file: \(reason)"
      case let .readError(reason):
        "Failed to read from log file: \(reason)"
      case let .directoryCreationFailed(path):
        "Failed to create log directory at path: \(path)"
      case let .accessDenied(path):
        "Access denied to log file at path: \(path)"
      case let .invalidPath(path):
        "Invalid log file path: \(path)"
    }
  }
}
