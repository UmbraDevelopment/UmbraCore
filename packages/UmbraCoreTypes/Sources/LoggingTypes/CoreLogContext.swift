import Foundation
import SecurityInterfacesTypes

/// CoreLogContext provides privacy-enhanced logging context for core framework operations
///
/// This specialised context collects metadata related to core framework operations
/// with appropriate privacy classifications for sensitive information.
public struct CoreLogContext: LogContextDTO, Equatable {
  /// The domain name for this context
  public let domainName: String="CoreFramework"

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
  ///   - source: The source of the log (class name, function, etc.)
  ///   - correlationID: Optional ID for correlating related log entries
  ///   - metadata: Privacy-aware metadata collection
  ///   - operationalState: Current operational state of the framework
  ///   - component: Specific component within the framework
  public init(
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

    self.source=source
    self.correlationID=correlationID
    self.metadata=processedMetadata
    self.operationalState=operationalState
    self.component=component
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
      source: source,
      correlationID: correlationID,
      metadata: metadata,
      operationalState: "configuring"
    )
  }

  /// Create a context for service operations
  ///
  /// - Parameters:
  ///   - serviceName: The name of the service
  ///   - operation: The operation being performed
  ///   - correlationID: Optional correlation ID
  ///   - metadata: Additional metadata for the log
  /// - Returns: A configured CoreLogContext
  public static func service(
    serviceName: String,
    operation: String,
    correlationID: String?=nil,
    metadata: LogMetadataDTOCollection=LogMetadataDTOCollection()
  ) -> CoreLogContext {
    var updatedMetadata=metadata
    updatedMetadata=updatedMetadata.withPublic(key: "operation", value: operation)

    return CoreLogContext(
      source: "ServiceContainer",
      correlationID: correlationID,
      metadata: updatedMetadata,
      component: serviceName
    )
  }

  /**
   Creates a new context by adding state information to the metadata.

   - Parameters:
     - operationalState: The operational state to add
     - component: Optional component name to add
   - Returns: The updated context
   */
  public func withState(
    operationalState: String?=nil,
    component: String?=nil
  ) -> CoreLogContext {
    var updatedMetadata=metadata

    if let operationalState {
      updatedMetadata=updatedMetadata.withPublic(key: "state", value: operationalState)
    }

    if let component {
      updatedMetadata=updatedMetadata.withPublic(key: "component", value: component)
    }

    return CoreLogContext(
      source: source,
      correlationID: correlationID,
      metadata: updatedMetadata
    )
  }

  /**
   Creates a new context specifically for operation status reporting.

   - Parameters:
     - source: Source of the log
     - operation: Operation name
     - metadata: Optional metadata to include
   - Returns: A context object configured for operation status
   */
  public static func operation(
    source: String,
    operation: String,
    metadata: LogMetadataDTOCollection=LogMetadataDTOCollection()
  ) -> CoreLogContext {
    var updatedMetadata=metadata
    updatedMetadata=updatedMetadata.withPublic(key: "operation", value: operation)

    return CoreLogContext(
      source: source,
      metadata: updatedMetadata
    )
  }
}
