import Foundation

// Local type declarations to replace imports
// These replace the removed ErrorHandling and ErrorHandlingDomains imports

/// Error domain namespace
public enum ErrorDomain {
  /// Security domain
  public static let security="Security"
  /// Crypto domain
  public static let crypto="Crypto"
  /// Application domain
  public static let application="Application"
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
    self.domain=domain
    self.code=code
    self.description=description
  }
}

extension UmbraErrors.Logging {
  /// Core logging errors related to logging operations and management
  public enum Core: Error, UmbraError, StandardErrorCapabilities {
    // Initialisation errors
    /// Failed to initialise logging system
    case initialisationFailed(reason: String)

    /// Failed to initialise log file
    case logFileInitialisationFailed(filePath: String, reason: String)

    /// Failed to initialise log destination
    case destinationInitialisationFailed(destination: String, reason: String)

    // Operation errors
    /// Failed to write log entry
    case writeFailed(reason: String)

    /// Failed to flush log buffer
    case flushFailed(reason: String)

    /// Failed to rotate log file
    case rotationFailed(filePath: String, reason: String)

    /// Log entry exceeded maximum size
    case entrySizeLimitExceeded(entrySize: Int, maxSize: Int)

    /// Log formatter error
    case formatterError(reason: String)

    // Configuration errors
    /// Invalid log configuration
    case invalidConfiguration(reason: String)

    /// Invalid log level
    case invalidLogLevel(providedLevel: String, validLevels: [String])

    /// Unsupported log destination
    case unsupportedDestination(destination: String)

    /// Destination not available
    case destinationUnavailable(destination: String, reason: String)

    // Resource errors
    /// Insufficient disk space for logging
    case insufficientDiskSpace(requireBytes: Int64, availableBytes: Int64)

    /// Log file permission error
    case permissionDenied(filePath: String, operation: String)

    // MARK: - UmbraError Protocol

    /// Domain identifier for logging core errors
    public var domain: String {
      "Logging.Core"
    }

    /// Error code uniquely identifying the error type
    public var code: String {
      switch self {
        case .initialisationFailed:
          "initialisation_failed"
        case .logFileInitialisationFailed:
          "log_file_initialisation_failed"
        case .destinationInitialisationFailed:
          "destination_initialisation_failed"
        case .writeFailed:
          "write_failed"
        case .flushFailed:
          "flush_failed"
        case .rotationFailed:
          "rotation_failed"
        case .entrySizeLimitExceeded:
          "entry_size_limit_exceeded"
        case .formatterError:
          "formatter_error"
        case .invalidConfiguration:
          "invalid_configuration"
        case .invalidLogLevel:
          "invalid_log_level"
        case .unsupportedDestination:
          "unsupported_destination"
        case .destinationUnavailable:
          "destination_unavailable"
        case .insufficientDiskSpace:
          "insufficient_disk_space"
        case .permissionDenied:
          "permission_denied"
      }
    }

    /// Human-readable description of the error
    public var errorDescription: String {
      switch self {
        case let .initialisationFailed(reason):
          "Failed to initialise logging system: \(reason)"
        case let .logFileInitialisationFailed(filePath, reason):
          "Failed to initialise log file '\(filePath)': \(reason)"
        case let .destinationInitialisationFailed(destination, reason):
          "Failed to initialise log destination '\(destination)': \(reason)"
        case let .writeFailed(reason):
          "Failed to write log entry: \(reason)"
        case let .flushFailed(reason):
          "Failed to flush log buffer: \(reason)"
        case let .rotationFailed(filePath, reason):
          "Failed to rotate log file '\(filePath)': \(reason)"
        case let .entrySizeLimitExceeded(entrySize, maxSize):
          "Log entry size (\(entrySize) bytes) exceeds maximum size (\(maxSize) bytes)"
        case let .formatterError(reason):
          "Log formatter error: \(reason)"
        case let .invalidConfiguration(reason):
          "Invalid log configuration: \(reason)"
        case let .invalidLogLevel(providedLevel, validLevels):
          "Invalid log level '\(providedLevel)'. Valid levels: \(validLevels.joined(separator: ", "))"
        case let .unsupportedDestination(destination):
          "Unsupported log destination: '\(destination)'"
        case let .destinationUnavailable(destination, reason):
          "Log destination '\(destination)' is unavailable: \(reason)"
        case let .insufficientDiskSpace(requireBytes, availableBytes):
          "Insufficient disk space for logging: required \(requireBytes) bytes, available \(availableBytes) bytes"
        case let .permissionDenied(filePath, operation):
          "Permission denied for operation '\(operation)' on log file '\(filePath)'"
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
        operation: "logging_operation",
        details: errorDescription
      )
    }

    /// Creates a new instance of the error with additional context
    public func with(context _: ErrorHandlingInterfaces.ErrorContext) -> Self {
      // Since these are enum cases, we need to return a new instance with the same value
      switch self {
        case let .initialisationFailed(reason):
          .initialisationFailed(reason: reason)
        case let .logFileInitialisationFailed(filePath, reason):
          .logFileInitialisationFailed(filePath: filePath, reason: reason)
        case let .destinationInitialisationFailed(destination, reason):
          .destinationInitialisationFailed(destination: destination, reason: reason)
        case let .writeFailed(reason):
          .writeFailed(reason: reason)
        case let .flushFailed(reason):
          .flushFailed(reason: reason)
        case let .rotationFailed(filePath, reason):
          .rotationFailed(filePath: filePath, reason: reason)
        case let .entrySizeLimitExceeded(entrySize, maxSize):
          .entrySizeLimitExceeded(entrySize: entrySize, maxSize: maxSize)
        case let .formatterError(reason):
          .formatterError(reason: reason)
        case let .invalidConfiguration(reason):
          .invalidConfiguration(reason: reason)
        case let .invalidLogLevel(providedLevel, validLevels):
          .invalidLogLevel(providedLevel: providedLevel, validLevels: validLevels)
        case let .unsupportedDestination(destination):
          .unsupportedDestination(destination: destination)
        case let .destinationUnavailable(destination, reason):
          .destinationUnavailable(destination: destination, reason: reason)
        case let .insufficientDiskSpace(requireBytes, availableBytes):
          .insufficientDiskSpace(requireBytes: requireBytes, availableBytes: availableBytes)
        case let .permissionDenied(filePath, operation):
          .permissionDenied(filePath: filePath, operation: operation)
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

extension UmbraErrors.Logging.Core {
  /// Create an error for a failed logging system initialisation
  public static func makeInitialisationFailedError(
    reason: String,
    file _: String=#file,
    line _: Int=#line,
    function _: String=#function
  ) -> Self {
    .initialisationFailed(reason: reason)
  }

  /// Create an error for a failed log write operation
  public static func makeWriteFailedError(
    reason: String,
    file _: String=#file,
    line _: Int=#line,
    function _: String=#function
  ) -> Self {
    .writeFailed(reason: reason)
  }

  /// Create an error for an invalid configuration
  public static func makeInvalidConfigError(
    reason: String,
    file _: String=#file,
    line _: Int=#line,
    function _: String=#function
  ) -> Self {
    .invalidConfiguration(reason: reason)
  }

  /// Create an error for a failed log rotation
  public static func makeRotationFailedError(
    filePath: String,
    reason: String,
    file _: String=#file,
    line _: Int=#line,
    function _: String=#function
  ) -> Self {
    .rotationFailed(filePath: filePath, reason: reason)
  }
}
