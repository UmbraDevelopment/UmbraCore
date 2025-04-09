import Foundation

/// Protocol defining the requirements for a log context DTO that
/// can be used across domain boundaries
///
/// This protocol ensures that all domain-specific log contexts
/// provide the necessary information for privacy-aware logging
public protocol LogContextDTO: Sendable {
  /// The domain name for this context
  var domainName: String { get }

  /// Optional source information (class, file, etc.)
  var source: String? { get }

  /// Optional correlation ID for tracing related log events
  var correlationID: String? { get }

  /// The metadata collection for this context
  var metadata: LogMetadataDTOCollection { get }
}

/// Base implementation of LogContextDTO for use in services
/// that don't require specialised context handling
public struct BaseLogContextDTO: LogContextDTO, Equatable {
  /// The domain name for this context
  public let domainName: String

  /// Optional source information (class, file, etc.)
  public let source: String?

  /// Optional correlation ID for tracing related log events
  public let correlationID: String?

  /// The metadata collection for this context
  public let metadata: LogMetadataDTOCollection

  /// Create a new base log context DTO
  /// - Parameters:
  ///   - domainName: The domain name
  ///   - source: Optional source information
  ///   - metadata: Privacy metadata as a LogMetadataDTOCollection instance
  ///   - correlationID: Optional correlation ID
  public init(
    domainName: String,
    source: String?=nil,
    metadata: LogMetadataDTOCollection=LogMetadataDTOCollection(),
    correlationID: String?=nil
  ) {
    self.domainName=domainName
    self.source=source
    self.correlationID=correlationID
    self.metadata=metadata
  }
}
