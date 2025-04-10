import Foundation
import LoggingTypes

/**
 Random Data Service Context

 A specialized context implementation for random data service operations that implements
 the LogContextDTO protocol to provide privacy-aware context information.

 This context type provides standardised metadata for random data operations
 with appropriate privacy levels for each field.
 */
struct RandomDataServiceContext: LogContextDTO {
  /// The domain name for this context
  let domainName: String="RandomDataService"

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
   Creates a new random data service context with basic operation information

   - Parameters:
     - operation: The operation being performed
     - operationId: Unique identifier for the operation
     - source: Optional source information
     - correlationID: Optional correlation ID for tracking related logs
   */
  init(
    operation: String,
    operationID: String,
    source: String?=nil,
    correlationID: String?=nil
  ) {
    var collection=LogMetadataDTOCollection()
    collection=collection.withPublic(key: "operation", value: operation)
    collection=collection.withPublic(key: "operationId", value: operationID)

    metadataCollection=collection
    self.source=source
    self.correlationID=correlationID
  }

  /**
   Creates a new random data service context with entropy source information

   - Parameters:
     - operation: The operation being performed
     - operationId: Unique identifier for the operation
     - entropySource: The entropy source being used
     - source: Optional source information
     - correlationID: Optional correlation ID for tracking related logs
   */
  init(
    operation: String,
    operationID: String,
    entropySource: String,
    source: String?=nil,
    correlationID: String?=nil
  ) {
    var collection=LogMetadataDTOCollection()
    collection=collection.withPublic(key: "operation", value: operation)
    collection=collection.withPublic(key: "operationId", value: operationID)
    collection=collection.withPublic(key: "entropySource", value: entropySource)

    metadataCollection=collection
    self.source=source
    self.correlationID=correlationID
  }

  /**
   Creates a new random data service context with data length information

   - Parameters:
     - operation: The operation being performed
     - operationId: Unique identifier for the operation
     - dataLength: The length of data being generated
     - source: Optional source information
     - correlationID: Optional correlation ID for tracking related logs
   */
  init(
    operation: String,
    operationID: String,
    dataLength: String,
    source: String?=nil,
    correlationID: String?=nil
  ) {
    var collection=LogMetadataDTOCollection()
    collection=collection.withPublic(key: "operation", value: operation)
    collection=collection.withPublic(key: "operationId", value: operationID)
    collection=collection.withPublic(key: "dataLength", value: dataLength)

    metadataCollection=collection
    self.source=source
    self.correlationID=correlationID
  }

  /**
   Creates a new random data service context with range information

   - Parameters:
     - operation: The operation being performed
     - operationId: Unique identifier for the operation
     - lowerBound: The lower bound of the range
     - upperBound: The upper bound of the range
     - source: Optional source information
     - correlationID: Optional correlation ID for tracking related logs
   */
  init(
    operation: String,
    operationID: String,
    lowerBound: String,
    upperBound: String,
    source: String?=nil,
    correlationID: String?=nil
  ) {
    var collection=LogMetadataDTOCollection()
    collection=collection.withPublic(key: "operation", value: operation)
    collection=collection.withPublic(key: "operationId", value: operationID)
    collection=collection.withPublic(key: "lowerBound", value: lowerBound)
    collection=collection.withPublic(key: "upperBound", value: upperBound)

    metadataCollection=collection
    self.source=source
    self.correlationID=correlationID
  }

  /**
   Creates a new random data service context with result information

   - Parameters:
     - operation: The operation being performed
     - operationId: Unique identifier for the operation
     - result: The result value (with appropriate privacy controls)
     - source: Optional source information
     - correlationID: Optional correlation ID for tracking related logs
   */
  init(
    operation: String,
    operationID: String,
    result: String,
    source: String?=nil,
    correlationID: String?=nil
  ) {
    var collection=LogMetadataDTOCollection()
    collection=collection.withPublic(key: "operation", value: operation)
    collection=collection.withPublic(key: "operationId", value: operationID)
    collection=collection.withPublic(key: "result", value: result)

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
  func adding(
    key: String,
    value: String,
    privacyLevel: LogPrivacyLevel
  ) -> RandomDataServiceContext {
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
