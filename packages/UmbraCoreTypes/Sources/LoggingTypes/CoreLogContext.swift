import SecurityInterfacesTypes

/// CoreLogContext provides privacy-enhanced logging context for core framework operations
///
/// This specialised context collects metadata related to core framework operations
/// with appropriate privacy classifications for sensitive information.
public struct CoreLogContext: LogContextDTO, Equatable {
  /// The domain name for this context
  public let domainName: String="CoreFramework"

  /// The operation being performed (e.g., "initialise", "configure")
  public let operation: String

  /// The category for the log entry (e.g., "System", "Configuration")
  public let category: String

  /// Source information (class name, function, etc.)
  public let source: String?

  /// Correlation ID for tracing related operations
  public let correlationID: String?

  /// The metadata collection for this context
  public let metadata: LogMetadataDTOCollection

  /// Operational state being logged (initialised, configuring, etc.)
  public let operationalState: String?

  /// Component identifier within the core framework
  public let component: String?

  /// Create a new core log context with the specified parameters
  ///
  /// - Parameters:
  ///   - operation: The operation being performed
  ///   - category: The category for the log entry
  ///   - source: The source of the log (class name, function, etc.)
  ///   - correlationID: Optional ID for correlating related log entries
  ///   - metadata: Privacy-aware metadata collection
  ///   - operationalState: Current operational state of the framework
  ///   - component: Specific component within the framework
  public init(
    operation: String,
    category: String="Core",
    source: String?=nil,
    correlationID: String?=nil,
    metadata: LogMetadataDTOCollection=LogMetadataDTOCollection(),
    operationalState: String?=nil,
    component: String?=nil
  ) {
    // Process metadata with state and component information
    var processedMetadata=metadata

    if let operationalState {
      processedMetadata=processedMetadata.withPublic(key: "state", value: operationalState)
    }

    if let component {
      processedMetadata=processedMetadata.withPublic(key: "component", value: component)
    }

    self.operation=operation
    self.category=category
    self.source=source
    self.correlationID=correlationID
    self.metadata=processedMetadata
    self.operationalState=operationalState
    self.component=component
  }

  /// Creates a new context with additional metadata merged with the existing metadata
  /// - Parameter additionalMetadata: Additional metadata to include
  /// - Returns: New context with merged metadata
  public func withMetadata(_ additionalMetadata: LogMetadataDTOCollection) -> CoreLogContext {
    CoreLogContext(
      operation: operation,
      category: category,
      source: source,
      correlationID: correlationID,
      metadata: metadata.merging(with: additionalMetadata),
      operationalState: operationalState,
      component: component
    )
  }

  /// Create a context for initialisation operations
  ///
  /// - Parameters:
  ///   - source: The source of the log
  ///   - correlationID: Optional correlation ID
  ///   - metadata: Additional metadata for the log
  /// - Returns: A configured CoreLogContext
  public static func initialisation(
    source: String,
    correlationID: String?=nil,
    metadata: LogMetadataDTOCollection=LogMetadataDTOCollection()
  ) -> CoreLogContext {
    CoreLogContext(
      operation: "initialise",
      category: "System",
      source: source,
      correlationID: correlationID,
      metadata: metadata,
      operationalState: "initialising"
    )
  }

  /// Create a context for configuration operations
  ///
  /// - Parameters:
  ///   - source: The source of the log
  ///   - correlationID: Optional correlation ID
  ///   - metadata: Additional metadata for the log
  /// - Returns: A configured CoreLogContext
  public static func configuration(
    source: String,
    correlationID: String?=nil,
    metadata: LogMetadataDTOCollection=LogMetadataDTOCollection()
  ) -> CoreLogContext {
    CoreLogContext(
      operation: "configure",
      category: "Configuration",
      source: source,
      correlationID: correlationID,
      metadata: metadata,
      operationalState: "configuring"
    )
  }

  /// Create a context for service operations
  ///
  /// - Parameters:
  ///   - service: The service name
  ///   - operation: The operation being performed
  ///   - source: The source of the log
  ///   - correlationID: Optional correlation ID
  ///   - metadata: Additional metadata for the log
  /// - Returns: A configured CoreLogContext
  public static func service(
    service: String,
    operation: String,
    source: String,
    correlationID: String?=nil,
    metadata: LogMetadataDTOCollection=LogMetadataDTOCollection()
  ) -> CoreLogContext {
    var updatedMetadata=metadata
    updatedMetadata=updatedMetadata.withPublic(key: "service", value: service)

    return CoreLogContext(
      operation: operation,
      category: "Service",
      source: source,
      correlationID: correlationID,
      metadata: updatedMetadata,
      operationalState: "running"
    )
  }
}
