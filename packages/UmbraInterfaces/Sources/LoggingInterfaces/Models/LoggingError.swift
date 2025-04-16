import Foundation

/**
 Errors that can occur during logging operations.

 This comprehensive set of errors provides detailed information about
 logging failures to facilitate proper handling and reporting.
 */
public enum LoggingError: Error, Equatable {
  /// Failed to write to log destination
  case writeFailure(String)

  /// Log destination not found
  case destinationNotFound(String)

  /// Invalid log destination configuration
  case invalidDestinationConfig(String)

  /// Permission denied for logging operation
  case permissionDenied(String)

  /// Log file rotation failed
  case rotationFailed(String)

  /// Log export failed
  case exportFailed(String)

  /// Log archiving failed
  case archiveFailed(String)

  /// Log retrieval failed
  case retrievalFailed(String)

  /// Failed to apply filter or redaction
  case filteringFailed(String)

  /// Failed to initialise logger
  case initialisationFailed(String)

  /// Log destination already exists
  case destinationAlreadyExists(String)

  /// Invalid log level
  case invalidLogLevel(String)

  /// Privacy policy violation
  case privacyViolation(String)

  /// Log storage full
  case storageFull(String)

  /// General logging error
  case general(String)

  /// Operation timed out
  case timeout(String)
}

// MARK: - LocalizedError Conformance

extension LoggingError: LocalizedError {
  public var errorDescription: String? {
    switch self {
      case let .writeFailure(message):
        "Failed to write to log destination: \(message)"
      case let .destinationNotFound(message):
        "Log destination not found: \(message)"
      case let .invalidDestinationConfig(message):
        "Invalid log destination configuration: \(message)"
      case let .permissionDenied(message):
        "Permission denied for logging operation: \(message)"
      case let .rotationFailed(message):
        "Log file rotation failed: \(message)"
      case let .exportFailed(message):
        "Log export failed: \(message)"
      case let .archiveFailed(message):
        "Log archiving failed: \(message)"
      case let .retrievalFailed(message):
        "Log retrieval failed: \(message)"
      case let .filteringFailed(message):
        "Failed to apply filter or redaction: \(message)"
      case let .initialisationFailed(message):
        "Failed to initialise logger: \(message)"
      case let .destinationAlreadyExists(message):
        "Log destination already exists: \(message)"
      case let .invalidLogLevel(message):
        "Invalid log level: \(message)"
      case let .privacyViolation(message):
        "Privacy policy violation in logging: \(message)"
      case let .storageFull(message):
        "Log storage full: \(message)"
      case let .general(message):
        "Logging error: \(message)"
      case let .timeout(message):
        "Logging operation timed out: \(message)"
    }
  }
}
