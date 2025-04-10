import Foundation
import LoggingTypes

/**
 Security Metrics Context

 A specialized context implementation for security metrics logging that implements
 the LogContextDTO protocol to provide privacy-aware context information.

 This context type provides standardised metadata for security metrics collection
 with appropriate privacy levels for each field.
 */
struct SecurityMetricsContext: LogContextDTO {
  /// The domain name for this context
  let domainName: String="SecurityMetrics"

  /// Optional source information
  let source: String?

  /// Optional correlation ID for tracking related logs
  let correlationID: String?

  /// The metadata collection for this context
  private var metadataCollection: LogMetadataDTOCollection

  /// Access to the metadata collection
  var metadata: LogMetadataDTOCollection {
    metadataCollection
  }

  /**
   Creates a new security metrics context with operation information

   - Parameters:
     - operation: The security operation name
     - durationMs: The duration of the operation in milliseconds
     - success: Whether the operation was successful
     - source: Optional source information
     - correlationID: Optional correlation ID for tracking related logs
   */
  init(
    operation: String,
    durationMs: String,
    success: String,
    source: String?=nil,
    correlationID: String?=nil
  ) {
    var collection=LogMetadataDTOCollection()
    collection=collection.withPublic(key: "operation", value: operation)
    collection=collection.withPublic(key: "durationMs", value: durationMs)
    collection=collection.withPublic(key: "success", value: success)

    metadataCollection=collection
    self.source=source
    self.correlationID=correlationID
  }

  /**
   Creates a new security metrics context for anomaly reporting

   - Parameters:
     - operation: The security operation name
     - durationMs: The duration of the operation in milliseconds
     - percentAboveAverage: The percentage above average performance
     - averageDurationMs: The average duration for this operation
     - source: Optional source information
     - correlationID: Optional correlation ID for tracking related logs
   */
  init(
    operation: String,
    durationMs: String,
    percentAboveAverage: String,
    averageDurationMs: String,
    source: String?=nil,
    correlationID: String?=nil
  ) {
    var collection=LogMetadataDTOCollection()
    collection=collection.withPublic(key: "operation", value: operation)
    collection=collection.withPublic(key: "durationMs", value: durationMs)
    collection=collection.withPublic(key: "percentAboveAverage", value: percentAboveAverage)
    collection=collection.withPublic(key: "averageDurationMs", value: averageDurationMs)

    metadataCollection=collection
    self.source=source
    self.correlationID=correlationID
  }

  /**
   Adds a new key-value pair to the context with the specified privacy level

   - Parameters:
     - key: The metadata key
     - value: The metadata value
     - privacyLevel: The privacy level for this metadata
   - Returns: A new context with the added metadata
   */
  func adding(key: String, value: String, privacyLevel: LogPrivacyLevel) -> SecurityMetricsContext {
    var newContext=self
    switch privacyLevel {
      case .public:
        newContext.metadataCollection=metadataCollection.withPublic(key: key, value: value)
      case .private:
        newContext.metadataCollection=metadataCollection.withPrivate(key: key, value: value)
      case .sensitive:
        newContext.metadataCollection=metadataCollection.withSensitive(key: key, value: value)
      case .hash:
        // Use private level for hash since withHash is not available
        newContext.metadataCollection=metadataCollection.withPrivate(key: key, value: value)
      case .auto:
        // For auto, determine appropriate level based on key name
        if
          key.lowercased().contains("password") || key.lowercased().contains("secret") || key
            .lowercased().contains("key")
        {
          newContext.metadataCollection=metadataCollection.withSensitive(key: key, value: value)
        } else if
          key.lowercased().contains("id") || key.lowercased().contains("name") || key
            .lowercased().contains("email")
        {
          newContext.metadataCollection=metadataCollection.withPrivate(key: key, value: value)
        } else {
          newContext.metadataCollection=metadataCollection.withPublic(key: key, value: value)
        }
    }
    return newContext
  }

  /**
   Returns the metadata collection for this context

   - Returns: The LogMetadataDTOCollection for this context
   */
  func getMetadataCollection() -> LogMetadataDTOCollection {
    metadataCollection
  }
}
