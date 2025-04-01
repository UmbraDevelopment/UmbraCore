import Foundation

/// Protocol for errors that provide enhanced logging information
///
/// This protocol allows errors to provide privacy-classified metadata
/// and other information needed for structured logging.
public protocol LoggableErrorProtocol: Error {
  /// Get the privacy metadata for this error
  /// - Returns: Privacy metadata for logging this error
  func getPrivacyMetadata() -> PrivacyMetadata

  /// Get the source information for this error
  /// - Returns: Source information (e.g., file, function, line)
  func getSource() -> String

  /// Get the log message for this error
  /// - Returns: A descriptive message appropriate for logging
  func getLogMessage() -> String
}

/// A concrete implementation of a loggable error with privacy controls
///
/// This structure wraps an error with additional metadata and privacy
/// classifications to enable privacy-aware error logging.
public struct LoggableError: LoggableErrorProtocol, Sendable {
  /// The underlying error
  public let error: Error

  /// Privacy metadata for this error
  private let metadata: PrivacyMetadata

  /// Source information for this error
  private let source: String

  /// Custom log message for this error
  private let message: String?

  /// Creates a new loggable error with privacy controls
  ///
  /// - Parameters:
  ///   - error: The underlying error
  ///   - source: Source information (e.g., file, function, line)
  ///   - metadata: Privacy metadata for logging
  ///   - message: Optional custom log message
  public init(
    error: Error,
    source: String,
    metadata: PrivacyMetadata,
    message: String?=nil
  ) {
    self.error=error
    self.source=source
    self.metadata=metadata
    self.message=message
  }

  /// Creates a new loggable error with a LogMetadataDTOCollection
  ///
  /// - Parameters:
  ///   - error: The underlying error
  ///   - source: Source information (e.g., file, function, line)
  ///   - metadataCollection: Privacy-classified metadata collection
  ///   - message: Optional custom log message
  public init(
    error: Error,
    source: String,
    metadataCollection: LogMetadataDTOCollection,
    message: String?=nil
  ) {
    self.error=error
    self.source=source
    metadata=metadataCollection.toPrivacyMetadata()
    self.message=message
  }

  /// Get the privacy metadata for this error
  /// - Returns: Privacy metadata for logging this error
  public func getPrivacyMetadata() -> PrivacyMetadata {
    metadata
  }

  /// Get the source information for this error
  /// - Returns: Source information (e.g., file, function, line)
  public func getSource() -> String {
    source
  }

  /// Get the log message for this error
  /// - Returns: A descriptive message appropriate for logging
  public func getLogMessage() -> String {
    message ?? "Error: \(error.localizedDescription)"
  }

  /// Get the underlying error
  /// - Returns: The wrapped error
  public func getError() -> Error {
    error
  }

  /// Convert to a loggable error with additional metadata
  ///
  /// - Parameter additionalMetadata: Additional metadata to include
  /// - Returns: A new loggable error with merged metadata
  public func withAdditionalMetadata(_ additionalMetadata: PrivacyMetadata) -> LoggableError {
    var newMetadata=metadata

    // Merge the additional metadata
    for key in additionalMetadata.entries() {
      if let value=additionalMetadata[key] {
        newMetadata[key]=value
      }
    }

    return LoggableError(
      error: error,
      source: source,
      metadata: newMetadata,
      message: message
    )
  }

  /// Convert to a loggable error with a custom message
  ///
  /// - Parameter message: The custom message to use
  /// - Returns: A new loggable error with the specified message
  public func withMessage(_ message: String) -> LoggableError {
    LoggableError(
      error: error,
      source: source,
      metadata: metadata,
      message: message
    )
  }
}
