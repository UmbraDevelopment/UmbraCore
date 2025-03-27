import Foundation
import UmbraErrorsCore

/// DTO for logging errors
public struct LoggingErrorDTO: Error, Hashable, Equatable, Sendable {
  /// The type of logging error
  public enum LoggingErrorType: String, Hashable, Equatable, Sendable {
    /// Failed to write to log
    case writeFailed = "WRITE_FAILED"
    /// Invalid log format
    case invalidFormat = "INVALID_FORMAT"
    /// Storage error
    case storageError = "STORAGE_ERROR"
    /// Log rotation error
    case rotationError = "ROTATION_ERROR"
    /// Log configuration error
    case configurationError = "CONFIGURATION_ERROR"
    /// Permission error
    case permissionError = "PERMISSION_ERROR"
    /// General failure
    case generalFailure = "GENERAL_FAILURE"
    /// Unknown logging error
    case unknown = "UNKNOWN"
  }

  /// The type of logging error
  public let type: LoggingErrorType

  /// Human-readable description of the error
  public let description: String

  /// Additional context information about the error
  public let context: ErrorContext

  /// The underlying error, if any
  public let underlyingError: Error?

  /// Creates a new LoggingErrorDTO
  /// - Parameters:
  ///   - type: The type of logging error
  ///   - description: Human-readable description
  ///   - context: Additional context information
  ///   - underlyingError: The underlying error
  public init(
    type: LoggingErrorType,
    description: String,
    context: ErrorContext = ErrorContext(),
    underlyingError: Error? = nil
  ) {
    self.type = type
    self.description = description
    self.context = context
    self.underlyingError = underlyingError
  }

  /// Creates a new LoggingErrorDTO with dictionary context
  /// - Parameters:
  ///   - type: The type of logging error
  ///   - description: Human-readable description
  ///   - contextDict: Additional context information as dictionary
  ///   - underlyingError: The underlying error
  public init(
    type: LoggingErrorType,
    description: String,
    contextDict: [String: Any] = [:],
    underlyingError: Error? = nil
  ) {
    self.type = type
    self.description = description
    context = ErrorContext(contextDict)
    self.underlyingError = underlyingError
  }

  /// Creates a LoggingErrorDTO from a generic error
  /// - Parameter error: The source error
  /// - Returns: A LoggingErrorDTO
  public static func from(_ error: Error) -> LoggingErrorDTO {
    if let loggingError = error as? LoggingErrorDTO {
      return loggingError
    }

    return LoggingErrorDTO(
      type: .unknown,
      description: "\(error)",
      context: ErrorContext(),
      underlyingError: error
    )
  }

  // MARK: - Hashable & Equatable

  public func hash(into hasher: inout Hasher) {
    hasher.combine(type)
    hasher.combine(description)
    // Not hashing context or underlyingError as they may not be Hashable
  }

  public static func == (lhs: LoggingErrorDTO, rhs: LoggingErrorDTO) -> Bool {
    lhs.type == rhs.type &&
      lhs.description == rhs.description
    // Not comparing context or underlyingError for equality
  }
}
