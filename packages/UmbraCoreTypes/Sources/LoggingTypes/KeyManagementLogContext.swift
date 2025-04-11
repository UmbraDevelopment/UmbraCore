/// A specialised log context for key management operations
///
/// This structure provides contextual information specific to key management
/// operations, with enhanced privacy controls for key identifiers.
public struct KeyManagementLogContext: LogContextDTO, Sendable {
  /// The name of the domain this context belongs to
  public let domainName: String="KeyManagement"

  /// Correlation identifier for tracing related logs
  public let correlationID: String?

  /// Source information for the log (e.g., file, function, line)
  public let source: String?

  /// Privacy-aware metadata for this log context
  public let metadata: LogMetadataDTOCollection

  /// The key identifier
  public let keyIdentifier: String

  /// The operation being performed
  public let operation: String
  
  /// The category for the log entry
  public let category: String

  /// Creates a new key management log context
  ///
  /// - Parameters:
  ///   - keyIdentifier: The key identifier
  ///   - operation: The operation being performed
  ///   - category: The category for the log entry
  ///   - correlationId: Optional correlation identifier for tracing related logs
  ///   - source: Optional source information (e.g., file, function, line)
  ///   - additionalContext: Optional additional context with privacy annotations
  public init(
    keyIdentifier: String,
    operation: String,
    category: String = "KeyManagement",
    correlationID: String?=nil,
    source: String?=nil,
    additionalContext: LogMetadataDTOCollection=LogMetadataDTOCollection()
  ) {
    self.keyIdentifier=keyIdentifier
    self.operation=operation
    self.category=category
    self.correlationID=correlationID
    self.source=source

    // Start with the additional context
    var contextMetadata=additionalContext

    // Add key identifier as private metadata (sensitive information)
    contextMetadata=contextMetadata.withPrivate(key: "keyIdentifier", value: keyIdentifier)

    // Add operation as public metadata
    contextMetadata=contextMetadata.withPublic(key: "operation", value: operation)
    
    // Add category as public metadata
    contextMetadata=contextMetadata.withPublic(key: "category", value: category)

    metadata=contextMetadata
  }
  
  /// Creates a new context with additional metadata merged with the existing metadata
  /// - Parameter additionalMetadata: Additional metadata to include
  /// - Returns: New context with merged metadata
  public func withMetadata(_ additionalMetadata: LogMetadataDTOCollection) -> KeyManagementLogContext {
    return KeyManagementLogContext(
      keyIdentifier: keyIdentifier,
      operation: operation,
      category: category,
      correlationID: correlationID,
      source: source,
      additionalContext: self.metadata.merging(with: additionalMetadata)
    )
  }

  /// Creates a new instance of this context with updated metadata
  ///
  /// - Parameter metadata: The metadata to add to the context
  /// - Returns: A new log context with the updated metadata
  public func withUpdatedMetadata(_ metadata: LogMetadataDTOCollection) -> KeyManagementLogContext {
    KeyManagementLogContext(
      keyIdentifier: keyIdentifier,
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
  public func withCorrelationID(_ correlationID: String) -> KeyManagementLogContext {
    KeyManagementLogContext(
      keyIdentifier: keyIdentifier,
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
  public func withSource(_ source: String) -> KeyManagementLogContext {
    KeyManagementLogContext(
      keyIdentifier: keyIdentifier,
      operation: operation,
      category: category,
      correlationID: correlationID,
      source: source,
      additionalContext: metadata
    )
  }
}
