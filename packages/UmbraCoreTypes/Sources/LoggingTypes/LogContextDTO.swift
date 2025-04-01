import Foundation

/// Protocol for domain-specific log contexts with privacy controls
///
/// This protocol defines a common interface for log contexts that
/// contain domain-specific information with privacy controls.
public protocol LogContextDTO: Sendable {
  /// The name of the domain this context belongs to
  var domainName: String { get }

  /// Correlation identifier for tracing related logs
  var correlationID: String? { get }

  /// Source information for the log (e.g., file, function, line)
  var source: String? { get }

  /// Privacy-aware metadata for this log context
  var metadata: LogMetadataDTOCollection { get }

  /// Get the privacy metadata for logging purposes
  /// - Returns: The privacy metadata for this context
  func toPrivacyMetadata() -> PrivacyMetadata

  /// Get the source information
  /// - Returns: Source information for logs, or a default if not available
  func getSource() -> String

  /// Get the metadata collection
  /// - Returns: The metadata collection for this context
  func toMetadata() -> LogMetadataDTOCollection

  /// Creates a new instance of this context with updated metadata
  ///
  /// - Parameter metadata: The metadata to add to the context
  /// - Returns: A new log context with the updated metadata
  func withUpdatedMetadata(_ metadata: LogMetadataDTOCollection) -> Self
}

/// Default implementations for LogContextDTO
extension LogContextDTO {
  /// Get the privacy metadata for logging purposes
  /// - Returns: The privacy metadata for this context
  public func toPrivacyMetadata() -> PrivacyMetadata {
    metadata.toPrivacyMetadata()
  }

  /// Get the source information
  /// - Returns: Source information for logs, or a default if not available
  public func getSource() -> String {
    source ?? "\(domainName).Logger"
  }

  /// Get the metadata collection
  /// - Returns: The metadata collection for this context
  public func toMetadata() -> LogMetadataDTOCollection {
    metadata
  }
}

/// Base implementation of the LogContextDTO protocol
///
/// This structure provides a reusable implementation of the LogContextDTO
/// protocol that can be extended by domain-specific contexts.
public struct BaseLogContextDTO: LogContextDTO, Equatable {
  /// The name of the domain this context belongs to
  public let domainName: String

  /// Correlation identifier for tracing related logs
  public let correlationID: String?

  /// Source information for the log (e.g., file, function, line)
  public let source: String?

  /// Privacy-aware metadata for this log context
  public let metadata: LogMetadataDTOCollection

  /// Creates a new base log context
  ///
  /// - Parameters:
  ///   - domainName: The name of the domain this context belongs to
  ///   - correlationId: Optional correlation identifier for tracing related logs
  ///   - source: Optional source information (e.g., file, function, line)
  ///   - metadata: Privacy-aware metadata for this log context
  public init(
    domainName: String,
    correlationID: String?=nil,
    source: String?=nil,
    metadata: LogMetadataDTOCollection=LogMetadataDTOCollection()
  ) {
    self.domainName=domainName
    self.correlationID=correlationID
    self.source=source
    self.metadata=metadata
  }

  /// Creates a new instance of this context with updated metadata
  ///
  /// - Parameter metadata: The metadata to add to the context
  /// - Returns: A new log context with the updated metadata
  public func withUpdatedMetadata(_ metadata: LogMetadataDTOCollection) -> BaseLogContextDTO {
    BaseLogContextDTO(
      domainName: domainName,
      correlationID: correlationID,
      source: source,
      metadata: self.metadata.merging(with: metadata)
    )
  }

  /// Creates a new instance of this context with a correlation ID
  ///
  /// - Parameter correlationId: The correlation ID to add
  /// - Returns: A new log context with the specified correlation ID
  public func withCorrelationID(_ correlationID: String) -> BaseLogContextDTO {
    BaseLogContextDTO(
      domainName: domainName,
      correlationID: correlationID,
      source: source,
      metadata: metadata
    )
  }

  /// Creates a new instance of this context with source information
  ///
  /// - Parameter source: The source information to add
  /// - Returns: A new log context with the specified source
  public func withSource(_ source: String) -> BaseLogContextDTO {
    BaseLogContextDTO(
      domainName: domainName,
      correlationID: correlationID,
      source: source,
      metadata: metadata
    )
  }
}
