/// Protocol defining the requirements for a log context DTO that
/// can be used across domain boundaries
///
/// This protocol ensures that all domain-specific log contexts
/// provide the necessary information for privacy-aware logging
public protocol LogContextDTO: Sendable {
  /// The domain name for this context
  var domainName: String { get }

  /// The operation being performed (e.g., "addDestination", "writeLog")
  var operation: String { get }
  
  /// The category for the log entry (e.g., "LoggingSystem", "Security")
  var category: String { get }

  /// Optional source information (class, file, etc.)
  var source: String? { get }

  /// Optional correlation ID for tracing related log events
  var correlationID: String? { get }

  /// The metadata collection for this context
  var metadata: LogMetadataDTOCollection { get }
  
  /// Creates a new context with additional metadata merged with the existing metadata
  /// - Parameter additionalMetadata: Additional metadata to include
  /// - Returns: New context with merged metadata
  func withMetadata(_ additionalMetadata: LogMetadataDTOCollection) -> Self
}

/// Base implementation of LogContextDTO for use in services
/// that don't require specialised context handling
public struct BaseLogContextDTO: LogContextDTO, Equatable {
  /// The domain name for this context
  public let domainName: String
  
  /// The operation being performed (e.g., "addDestination", "writeLog")
  public let operation: String
  
  /// The category for the log entry (e.g., "LoggingSystem", "Security")
  public let category: String

  /// Optional source information (class, file, etc.)
  public let source: String?

  /// Optional correlation ID for tracing related log events
  public let correlationID: String?

  /// The metadata collection for this context
  public let metadata: LogMetadataDTOCollection

  /// Create a new base log context DTO
  /// - Parameters:
  ///   - domainName: The domain name
  ///   - operation: The operation being performed
  ///   - category: The category for the log entry
  ///   - source: Optional source information
  ///   - metadata: Privacy metadata as a LogMetadataDTOCollection instance
  ///   - correlationID: Optional correlation ID
  public init(
    domainName: String,
    operation: String,
    category: String,
    source: String?=nil,
    metadata: LogMetadataDTOCollection=LogMetadataDTOCollection(),
    correlationID: String?=nil
  ) {
    self.domainName=domainName
    self.operation=operation
    self.category=category
    self.source=source
    self.correlationID=correlationID
    self.metadata=metadata
  }
  
  /// Creates a new context with additional metadata merged with the existing metadata
  /// - Parameter additionalMetadata: Additional metadata to include
  /// - Returns: New context with merged metadata
  public func withMetadata(_ additionalMetadata: LogMetadataDTOCollection) -> BaseLogContextDTO {
    return BaseLogContextDTO(
      domainName: self.domainName,
      operation: self.operation,
      category: self.category,
      source: self.source,
      metadata: self.metadata.merging(with: additionalMetadata),
      correlationID: self.correlationID
    )
  }
}
