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
  ///   - metadata: Privacy metadata as a PrivacyMetadata instance
  ///   - correlationID: Optional correlation ID
  public init(
    domainName: String,
    source: String?=nil,
    metadata: PrivacyMetadata=PrivacyMetadata(),
    correlationID: String?=nil
  ) {
    self.domainName=domainName
    self.source=source
    self.correlationID=correlationID

    // Convert PrivacyMetadata to LogMetadataDTOCollection
    var collection=LogMetadataDTOCollection()

    // Add all entries from the PrivacyMetadata
    for (key, value) in metadata.storage {
      switch value.privacy {
        case .public:
          collection=collection.withPublic(key: key, value: value.valueString)
        case .private:
          collection=collection.withPrivate(key: key, value: value.valueString)
        case .sensitive:
          collection=collection.withSensitive(key: key, value: value.valueString)
        case .hash:
          collection=collection.withHashed(key: key, value: value.valueString)
        case .auto:
          collection=collection.withAuto(key: key, value: value.valueString)
      }
    }

    self.metadata=collection
  }

  /// Create a new base log context DTO with a metadata collection
  /// - Parameters:
  ///   - domainName: The domain name
  ///   - source: Optional source information
  ///   - metadata: The metadata collection
  ///   - correlationID: Optional correlation ID
  public init(
    domainName: String,
    source: String?=nil,
    metadata: LogMetadataDTOCollection,
    correlationID: String?=nil
  ) {
    self.domainName=domainName
    self.source=source
    self.metadata=metadata
    self.correlationID=correlationID
  }
}
