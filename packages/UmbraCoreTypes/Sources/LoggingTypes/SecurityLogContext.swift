/// A specialised log context for security-related operations
///
/// This structure provides contextual information specific to security
/// operations, with enhanced privacy controls for sensitive security data.
public struct SecurityLogContext: LogContextDTO, Sendable, Equatable {
  /// The name of the domain this context belongs to
  public let domainName: String="Security"

  /// Correlation identifier for tracing related logs
  public let correlationID: String?

  /// Source information for the log (e.g., file, function, line)
  public let source: String?

  /// Privacy-aware metadata for this log context
  public let metadata: LogMetadataDTOCollection

  /// The security operation being performed
  public let operation: String

  /// The category for the log entry
  public let category: String

  /// The security component involved
  public let component: String

  /// Creates a new security log context
  ///
  /// - Parameters:
  ///   - operation: The security operation being performed
  ///   - component: The security component involved
  ///   - category: The category for the log entry
  ///   - correlationId: Optional correlation identifier for tracing related logs
  ///   - source: Optional source information (e.g., file, function, line)
  ///   - metadata: Privacy-aware metadata for this log context
  public init(
    operation: String,
    component: String,
    category: String="Security",
    correlationID: String?=nil,
    source: String?=nil,
    metadata: LogMetadataDTOCollection=LogMetadataDTOCollection()
  ) {
    self.operation=operation
    self.component=component
    self.category=category
    self.correlationID=correlationID
    self.source=source

    // Add operation, component, and category as public metadata
    self.metadata=metadata
      .withPublic(key: "operation", value: operation)
      .withPublic(key: "component", value: component)
      .withPublic(key: "category", value: category)
  }

  /// Creates a new context with additional metadata merged with the existing metadata
  /// - Parameter additionalMetadata: Additional metadata to include
  /// - Returns: New context with merged metadata
  public func withMetadata(_ additionalMetadata: LogMetadataDTOCollection) -> SecurityLogContext {
    SecurityLogContext(
      operation: operation,
      component: component,
      category: category,
      correlationID: correlationID,
      source: source,
      metadata: metadata.merging(with: additionalMetadata)
    )
  }

  /// Creates a new instance of this context with updated metadata
  ///
  /// - Parameter metadata: The metadata to add to the context
  /// - Returns: A new log context with the updated metadata
  public func withUpdatedMetadata(_ metadata: LogMetadataDTOCollection) -> SecurityLogContext {
    SecurityLogContext(
      operation: operation,
      component: component,
      category: category,
      correlationID: correlationID,
      source: source,
      metadata: self.metadata.merging(with: metadata)
    )
  }

  /// Creates a new instance of this context with a correlation ID
  ///
  /// - Parameter correlationId: The correlation ID to add
  /// - Returns: A new log context with the specified correlation ID
  public func withCorrelationID(_ correlationID: String) -> SecurityLogContext {
    SecurityLogContext(
      operation: operation,
      component: component,
      category: category,
      correlationID: correlationID,
      source: source,
      metadata: metadata
    )
  }

  /// Creates a new instance of this context with source information
  ///
  /// - Parameter source: The source information to add
  /// - Returns: A new log context with the specified source
  public func withSource(_ source: String) -> SecurityLogContext {
    SecurityLogContext(
      operation: operation,
      component: component,
      category: category,
      correlationID: correlationID,
      source: source,
      metadata: metadata
    )
  }

  /// Creates a new instance with an operation result indicator
  ///
  /// - Parameter success: Whether the operation succeeded
  /// - Returns: A new log context with the operation result
  public func withResult(success: Bool) -> SecurityLogContext {
    let updatedMetadata=metadata.withPublic(key: "result", value: success ? "success" : "failure")
    return SecurityLogContext(
      operation: operation,
      component: component,
      category: category,
      correlationID: correlationID,
      source: source,
      metadata: updatedMetadata
    )
  }

  /// Creates a new instance with additional key identifier metadata
  ///
  /// - Parameter keyId: The identifier of the key involved in the operation
  /// - Returns: A new log context with the key identifier
  public func withKeyID(_ keyID: String) -> SecurityLogContext {
    let updatedMetadata=metadata.withPrivate(key: "keyId", value: keyID)
    return SecurityLogContext(
      operation: operation,
      component: component,
      category: category,
      correlationID: correlationID,
      source: source,
      metadata: updatedMetadata
    )
  }
}
