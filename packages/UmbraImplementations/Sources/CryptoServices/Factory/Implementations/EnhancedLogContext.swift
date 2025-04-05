import CryptoInterfaces
import Foundation
import LoggingInterfaces

/**
 Enhanced log context for crypto operations with privacy controls
 */
public struct EnhancedLogContext: LogContext {
  /// Domain name for the log context
  public let domainName: String

  /// Source of the log message
  public let source: String

  /// Correlation ID for tracing related logs
  public let correlationID: String?

  /// Metadata with privacy tags
  private var metadata: [String: PrivacyLevel]

  /**
   Initialises a new enhanced log context.

   - Parameters:
     - domainName: Domain name for the log context
     - source: Source of the log message
     - correlationID: Correlation ID for tracing related logs
     - metadata: Metadata with privacy tags
   */
  public init(
    domainName: String,
    source: String,
    correlationID: String?=nil,
    metadata: [String: PrivacyLevel]=[:]
  ) {
    self.domainName=domainName
    self.source=source
    self.correlationID=correlationID
    self.metadata=metadata
  }

  /**
   Updates metadata in the log context.

   - Parameter newMetadata: New metadata to add or update
   */
  public mutating func updateMetadata(_ newMetadata: [String: PrivacyLevel]) {
    for (key, value) in newMetadata {
      metadata[key]=value
    }
  }

  /**
   Creates a privacy metadata object from the current metadata.

   - Returns: A privacy metadata object
   */
  public func toPrivacyMetadata() -> LogMetadataDTO {
    var result=LogMetadataDTO()

    for (key, value) in metadata {
      switch value {
        case let .public(string):
          result.addPublic(key: key, value: string)
        case let .private(string):
          result.addPrivate(key: key, value: string)
        case let .hash(string):
          result.addHash(key: key, value: string)
      }
    }

    return result
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
