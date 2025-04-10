import Foundation

/// A specialised log context for error-related operations
///
/// This structure provides contextual information specific to error handling
/// with enhanced privacy controls for sensitive error information.
public struct ErrorLogContext: LogContextDTO, Sendable {
  /// The name of the domain this context belongs to
  public let domainName: String

  /// Correlation identifier for tracing related logs
  public let correlationID: String?

  /// Source information for the log (e.g., file, function, line)
  public let source: String?

  /// Privacy-aware metadata for this log context
  public let metadata: LogMetadataDTOCollection

  /// The error that occurred
  public let error: Error

  /// Creates a new error log context
  ///
  /// - Parameters:
  ///   - error: The error that occurred
  ///   - domain: The domain for this error context
  ///   - correlationId: Optional correlation identifier for tracing related logs
  ///   - source: Optional source information (e.g., file, function, line)
  ///   - additionalContext: Optional additional context with privacy annotations
  public init(
    error: Error,
    domain: String="ErrorHandling",
    correlationID: String?=nil,
    source: String?=nil,
    additionalContext: LogMetadataDTOCollection=LogMetadataDTOCollection()
  ) {
    self.error=error
    domainName=domain
    self.correlationID=correlationID
    self.source=source

    // Start with the additional context
    var contextMetadata=additionalContext

    // Add error information as metadata - we don't need to check for existence
    // since we're explicitly building the metadata here
    contextMetadata=contextMetadata
      .withPublic(key: "errorType", value: String(describing: type(of: error)))
      .withPrivate(key: "errorMessage", value: error.localizedDescription)

    // Add domain information for NSErrors
    if let domainError=error as? CustomNSError {
      contextMetadata=contextMetadata
        .withPrivate(
          key: "errorDomain",
          value: String(describing: type(of: domainError).errorDomain)
        )
        .withPrivate(key: "errorCode", value: "\(domainError.errorCode)")
    }

    metadata=contextMetadata
  }

  /// Creates a new instance of this context with updated metadata
  ///
  /// - Parameter metadata: The metadata to add to the context
  /// - Returns: A new log context with the updated metadata
  public func withUpdatedMetadata(_ metadata: LogMetadataDTOCollection) -> ErrorLogContext {
    ErrorLogContext(
      error: error,
      domain: domainName,
      correlationID: correlationID,
      source: source,
      additionalContext: self.metadata.merging(with: metadata)
    )
  }

  /// Creates a new instance of this context with a correlation ID
  ///
  /// - Parameter correlationId: The correlation ID to add
  /// - Returns: A new log context with the specified correlation ID
  public func withCorrelationID(_ correlationID: String) -> ErrorLogContext {
    ErrorLogContext(
      error: error,
      domain: domainName,
      correlationID: correlationID,
      source: source,
      additionalContext: metadata
    )
  }

  /// Creates a new instance of this context with source information
  ///
  /// - Parameter source: The source information to add
  /// - Returns: A new log context with the specified source
  public func withSource(_ source: String) -> ErrorLogContext {
    ErrorLogContext(
      error: error,
      domain: domainName,
      correlationID: correlationID,
      source: source,
      additionalContext: metadata
    )
  }

  /// Creates a metadata collection from this context
  ///
  /// - Returns: A LogMetadataDTOCollection with appropriate privacy annotations
  public func createMetadataCollection() -> LogMetadataDTOCollection {
    var collection=metadata

    // Add standard fields with appropriate privacy levels
    collection=collection.withPublic(key: "domain", value: domainName)

    if let correlationID {
      collection=collection.withPublic(key: "correlationId", value: correlationID)
    }

    if let source {
      collection=collection.withPublic(key: "source", value: source)
    }

    // Add error information
    collection=collection.withPublic(key: "errorType", value: String(describing: type(of: error)))
    collection=collection.withPrivate(key: "errorMessage", value: error.localizedDescription)

    // Add error code if available
    if let nsError=error as? NSError {
      collection=collection.withPublic(key: "errorCode", value: String(nsError.code))
      collection=collection.withPublic(key: "errorDomain", value: nsError.domain)
    }

    return collection
  }

  /// Gets the source of this log context
  ///
  /// - Returns: The source identifier for logging
  public func getSource() -> String {
    if let source {
      return source
    }
    return "\(domainName).error"
  }
}
