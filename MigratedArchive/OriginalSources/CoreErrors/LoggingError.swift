import Foundation

/// LoggingError error type
public enum LoggingError: Error {
  case writeFailed
  case invalidFormat
  case storageError
}
