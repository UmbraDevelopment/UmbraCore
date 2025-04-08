import CryptoInterfaces
import Foundation
import LoggingInterfaces
import LoggingTypes

/**
 Enhanced log context for crypto operations, conforming to LogContextDTO.
 */
public struct EnhancedLogContext: LogContextDTO {
  /// Domain name for the log context
  public let domainName: String

  /// Optional source information (class, file, etc.)
  public let source: String?

  /// Optional correlation ID for tracing related log events
  public let correlationID: String?

  /// The metadata collection for this context
  public var metadata: LogMetadataDTOCollection

  /// Operation name
  public let operationName: String

  /**
   Initialize a new enhanced log context

   - Parameters:
     - domainName: The domain name for this context
     - operationName: The operation name
     - source: Optional source information
     - correlationID: Optional correlation ID
     - metadata: Initial metadata collection
   */
  public init(
    domainName: String,
    operationName: String,
    source: String?=nil,
    correlationID: String?=nil,
    metadata: LogMetadataDTOCollection=LogMetadataDTOCollection()
  ) {
    self.domainName=domainName
    self.operationName=operationName
    self.source=source
    self.correlationID=correlationID
    self.metadata=metadata
  }

  /**
   Get the privacy level for a specific metadata key

   - Parameter key: The metadata key
   - Returns: The privacy level, or .auto if not specified
   */
  public func privacyLevel(for _: String) -> PrivacyClassification {
    // This function needs to be updated to work with the new metadata collection
    // For now, it will always return .auto
    .auto
  }

  /**
   Updates metadata values with new values

   - Parameter metadataUpdates: Dictionary of metadata updates with privacy annotations
   */
  public mutating func updateMetadata(_ metadataUpdates: [String: PrivacyLevel]) {
    for (key, privacyValue) in metadataUpdates {
      switch privacyValue {
        case let .public(value):
          metadata=metadata.withPublic(key: key, value: value)
        case let .private(value):
          metadata=metadata.withPrivate(key: key, value: value)
        case let .hash(value):
          metadata=metadata.withHashed(key: key, value: value)
      }
    }
  }

  /**
   Get metadata collection to use with loggers

   - Returns: A metadata collection with privacy annotations
   */
  public func createMetadataCollection() -> LogMetadataDTOCollection {
    metadata
  }

  /**
   @deprecated Use createMetadataCollection() instead.
   */
  public func getMetadataCollection() -> LogMetadataDTOCollection {
    createMetadataCollection()
  }
}

/**
 Privacy level for logging sensitive information.
 */
public enum PrivacyLevel {
  /// Public information that can be logged in plain text
  case `public`(String)

  /// Private information that should be redacted in logs
  case `private`(String)

  /// Information that should be hashed in logs
  case hash(String)
}
