import FeaturesLoggingModels
import Foundation

/// Logging Protocol
/// Defines the public interface for logging operations.
public protocol LoggingProtocol: Sendable {
  /// Initialize the logger with a file path
  /// - Parameter path: Path to log file
  /// - Throws: LoggingError if initialization fails
  func initialize(with path: String) async throws

  /// Log an entry
  /// - Parameter entry: Entry to log
  /// - Throws: LoggingError if logging fails
  func log(_ entry: LogEntry) async throws

  /// Stop logging and cleanup resources
  func stop() async
}

/// Errors that can occur during logging operations.
public enum LoggingError: LocalizedError, Sendable {
  /// Failed to write log entry with the given reason.
  case writeFailed(String)

  /// Invalid log entry format with the given reason.
  case invalidFormat(String)

  /// Storage error with the given reason.
  case storageError(String)

  public var errorDescription: String? {
    switch self {
      case let .writeFailed(reason):
        "Failed to write log entry: \(reason)"
      case let .invalidFormat(reason):
        "Invalid log entry format: \(reason)"
      case let .storageError(reason):
        "Storage error: \(reason)"
    }
  }
}
