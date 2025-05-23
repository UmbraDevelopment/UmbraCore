import Foundation

/// A specialised log context for error-related operations
///
/// This structure provides contextual information specific to error handling
/// with enhanced privacy controls for sensitive error information.
public struct ErrorLogContext: LogContextDTO, Sendable {
  /// The name of the domain this context belongs to
  public let domainName: String

  /// The operation being performed when the error occurred
  public let operation: String

  /// The category for the log entry
  public let category: String

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
  ///   - operation: The operation being performed when the error occurred
  ///   - category: The category for this error context
  ///   - correlationId: Optional correlation identifier for tracing related logs
  ///   - source: Optional source information (e.g., file, function, line)
  ///   - additionalContext: Optional additional context with privacy annotations
  public init(
    error: Error,
    domain: String="ErrorHandling",
    operation: String="handleError",
    category: String="Error",
    correlationID: String?=nil,
    source: String?=nil,
    additionalContext: LogMetadataDTOCollection=LogMetadataDTOCollection()
  ) {
    self.error=error
    domainName=domain
    self.operation=operation
    self.category=category
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

  /// Creates a new context with additional metadata merged with the existing metadata
  /// - Parameter additionalMetadata: Additional metadata to include
  /// - Returns: New context with merged metadata
  public func withMetadata(_ additionalMetadata: LogMetadataDTOCollection) -> ErrorLogContext {
    ErrorLogContext(
      error: error,
      domain: domainName,
      operation: operation,
      category: category,
      correlationID: correlationID,
      source: source,
      additionalContext: metadata.merging(with: additionalMetadata)
    )
  }

  /// Creates a new instance of this context with updated metadata
  ///
  /// - Parameter metadata: The metadata to add to the context
  /// - Returns: A new log context with the updated metadata
  public func withUpdatedMetadata(_ metadata: LogMetadataDTOCollection) -> ErrorLogContext {
    ErrorLogContext(
      error: error,
      domain: domainName,
      operation: operation,
      category: category,
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
      operation: operation,
      category: category,
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
      operation: operation,
      category: category,
      correlationID: correlationID,
      source: source,
      additionalContext: metadata
    )
  }

  /// Creates a new instance of this context with updated operation
  ///
  /// - Parameter operation: The new operation name
  /// - Returns: A new log context with the updated operation
  public func withOperation(_ operation: String) -> ErrorLogContext {
    ErrorLogContext(
      error: error,
      domain: domainName,
      operation: operation,
      category: category,
      correlationID: correlationID,
      source: source,
      additionalContext: metadata
    )
  }

  /// Creates a new instance of this context with updated category
  ///
  /// - Parameter category: The new category
  /// - Returns: A new log context with the updated category
  public func withCategory(_ category: String) -> ErrorLogContext {
    ErrorLogContext(
      error: error,
      domain: domainName,
      operation: operation,
      category: category,
      correlationID: correlationID,
      source: source,
      additionalContext: metadata
    )
  }

  /// Helper method to build context from an NSError
  ///
  /// - Parameters:
  ///   - nsError: The NSError to extract information from
  ///   - domain: The domain for the context
  ///   - correlationId: Optional correlation ID
  ///   - source: Optional source information
  /// - Returns: A configured ErrorLogContext
  public static func from(
    nsError: NSError,
    domain: String="ErrorHandling",
    operation: String="handleError",
    category: String="NSError",
    correlationID: String?=nil,
    source: String?=nil
  ) -> ErrorLogContext {
    var collection=LogMetadataDTOCollection()

    // Add error code if available
    collection=collection.withPublic(key: "errorCode", value: String(nsError.code))
    collection=collection.withPublic(key: "errorDomain", value: nsError.domain)

    // Add userInfo if available
    if !nsError.userInfo.isEmpty {
      for (key, value) in nsError.userInfo {
        collection=collection.withProtected(key: "userInfo.\(key)", value: "\(value)")
      }
    }

    return ErrorLogContext(
      error: nsError,
      domain: domain,
      operation: operation,
      category: category,
      correlationID: correlationID,
      source: source,
      additionalContext: collection
    )
  }
}
