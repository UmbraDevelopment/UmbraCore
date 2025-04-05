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

/// Data Transfer Object for privacy-enhanced error logging
///
/// This DTO encapsulates error information with privacy classifications,
/// following the Alpha Dot Five architecture for immutable data transfer objects.
public struct LoggableErrorDTO: Sendable, Equatable {
  /// The underlying error
  public let error: Error

  /// Privacy metadata for this error
  public let metadata: PrivacyMetadata

  /// Source information for this error
  public let source: String

  /// Custom log message for this error
  public let message: String?

  /// Optional domain context for the error
  public let context: LogContextDTO?

  /// Creates a new LoggableErrorDTO with privacy controls
  ///
  /// - Parameters:
  ///   - error: The underlying error
  ///   - source: Source information (e.g., file, function, line)
  ///   - metadataCollection: Privacy metadata for logging
  ///   - message: Optional custom log message
  ///   - context: Optional domain-specific logging context
  public init(
    error: Error,
    source: String,
    metadataCollection: PrivacyMetadata,
    message: String?=nil,
    context: LogContextDTO?=nil
  ) {
    self.error=error
    self.source=source
    self.metadata=metadataCollection
    self.message=message
    self.context=context
  }

  /// Creates a new LoggableErrorDTO with a LogMetadataDTOCollection
  ///
  /// - Parameters:
  ///   - error: The underlying error
  ///   - source: Source information (e.g., file, function, line)
  ///   - metadataCollection: Privacy-classified metadata collection
  ///   - message: Optional custom log message
  ///   - context: Optional domain-specific logging context
  public init(
    error: Error,
    source: String,
    metadataCollection: LogMetadataDTOCollection,
    message: String?=nil,
    context: LogContextDTO?=nil
  ) {
    self.error=error
    self.source=source
    metadata=metadataCollection.toPrivacyMetadata()
    self.message=message
    self.context=context
  }

  /// Equality cannot be automatically synthesized due to Error not conforming to Equatable
  public static func == (lhs: LoggableErrorDTO, rhs: LoggableErrorDTO) -> Bool {
    // Compare everything except the error itself (which may not be Equatable)
    lhs.source == rhs.source &&
      lhs.metadata == rhs.metadata &&
      lhs.message == rhs.message &&
      lhs.context?.domainName == rhs.context?.domainName
  }
}

/// Builder extension for LoggableErrorDTO following the Alpha Dot Five architecture pattern
extension LoggableErrorDTO {
  /// Returns a new LoggableErrorDTO with additional metadata
  ///
  /// - Parameter additionalMetadata: Additional metadata to include
  /// - Returns: A new DTO with merged metadata
  public func withAdditionalMetadata(_ additionalMetadata: PrivacyMetadata) -> LoggableErrorDTO {
    var newMetadata=metadata

    // Merge the additional metadata
    for key in additionalMetadata.entries() {
      if let value=additionalMetadata[key] {
        newMetadata[key]=value
      }
    }

    return LoggableErrorDTO(
      error: error,
      source: source,
      metadataCollection: newMetadata,
      message: message,
      context: context
    )
  }

  /// Returns a new LoggableErrorDTO with an updated message
  ///
  /// - Parameter message: The custom message to use
  /// - Returns: A new DTO with the specified message
  public func withMessage(_ message: String) -> LoggableErrorDTO {
    LoggableErrorDTO(
      error: error,
      source: source,
      metadataCollection: metadata,
      message: message,
      context: context
    )
  }

  /// Returns a new LoggableErrorDTO with a specific domain context
  ///
  /// - Parameter context: The domain-specific context to associate
  /// - Returns: A new DTO with the specified context
  public func withContext(_ context: LogContextDTO) -> LoggableErrorDTO {
    LoggableErrorDTO(
      error: error,
      source: source,
      metadataCollection: metadata,
      message: message,
      context: context
    )
  }
}

/// Extension to implement LoggableErrorProtocol
extension LoggableErrorDTO: LoggableErrorProtocol {
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
}
