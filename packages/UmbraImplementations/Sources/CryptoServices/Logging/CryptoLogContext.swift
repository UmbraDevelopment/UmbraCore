import Foundation
import LoggingTypes

/**
 # Crypto Log Context

 Structured logging context for cryptographic operations.

 This context provides relevant metadata for cryptographic operations:
 - Operation type (encrypt, decrypt, etc.)
 - Identifiers (for keys, data, etc.)
 - Status information
 - Separation of context from log implementation

 ## Privacy Controls

 This context implements comprehensive privacy controls for sensitive information:
 - Public information is logged normally
 - Private information is redacted in production builds
 - Sensitive information is always redacted
 - Hash values are specially marked

 ## Functional Updates

 Following the Alpha Dot Five architecture, this context uses functional methods
 that return new instances rather than mutating existing ones, ensuring thread
 safety and immutability.
 */
public struct CryptoLogContext: LogContextDTO, Sendable {
  // MARK: - Properties

  /// The domain name for this context
  public let domainName: String="CryptoServices"

  /// Optional source information (class, file, etc.)
  public let source: String?

  /// Optional correlation ID for tracing related log events
  public let correlationID: String?

  /// The type of cryptographic operation being performed
  public let operation: String
  
  /// The category for the log entry
  public let category: String

  /// Optional identifier for the data or key being operated on
  public let identifier: String?

  /// Status of the operation (success, failed, etc.)
  public let status: String?

  /// Metadata collection for additional context
  public let metadata: LogMetadataDTOCollection

  // MARK: - Initialization

  /**
   Creates a new log context with the given properties.

   - Parameters:
     - operation: The cryptographic operation being performed
     - identifier: Optional identifier for the operation or entity
     - source: Optional source component
     - status: Optional operation status
     - metadata: Optional initial metadata
     - correlationID: Optional correlation ID for tracing related logs
     - category: The category for the log entry
   */
  public init(
    operation: String,
    identifier: String?=nil,
    source: String?=nil,
    status: String?=nil,
    metadata: LogMetadataDTOCollection=LogMetadataDTOCollection(),
    correlationID: String?=nil,
    category: String="Security"
  ) {
    self.operation=operation
    self.identifier=identifier
    self.source=source
    self.status=status
    self.metadata=metadata
    self.correlationID=correlationID
    self.category=category
  }

  // MARK: - LogContextDTO Protocol

  /// Get the domain name for the log entry
  public func getDomainName() -> String {
    domainName
  }

  /// Get the source for the log entry
  public func getSource() -> String {
    source ?? "CryptoServices"
  }

  /// Get the correlation ID for the log entry
  public func getCorrelationID() -> String? {
    correlationID
  }

  /// Get metadata as a collection
  public func getMetadata() -> LogMetadataDTOCollection {
    metadata
  }

  /// Convert this context to a generic context
  public func toContext() -> LogContextDTO {
    self
  }

  /**
   Creates a metadata collection with all the context information.

   - Returns: A LogMetadataDTOCollection with all metadata entries
   */
  public func createMetadataCollection() -> LogMetadataDTOCollection {
    var collection=metadata

    // Add standard context information
    collection=collection.withPublic(key: "operation", value: operation)

    if let source {
      collection=collection.withPublic(key: "source", value: source)
    }

    if let correlationID {
      collection=collection.withPublic(key: "correlationID", value: correlationID)
    }

    if let identifier {
      collection=collection.withPrivate(key: "identifier", value: identifier)
    }

    if let status {
      collection=collection.withPublic(key: "status", value: status)
    }

    return collection
  }

  /**
   Creates a new context with additional metadata merged with the existing metadata
   
   - Parameter additionalMetadata: Additional metadata to include
   - Returns: New context with merged metadata
   */
  public func withMetadata(_ additionalMetadata: LogMetadataDTOCollection) -> Self {
    let mergedMetadata = metadata.merging(with: additionalMetadata)
    return CryptoLogContext(
      operation: operation,
      identifier: identifier,
      source: source,
      status: status,
      metadata: mergedMetadata,
      correlationID: correlationID,
      category: category
    )
  }

  // MARK: - Functional Update Methods

  /**
   Creates a new context with the specified operation.

   - Parameter operation: The new operation name
   - Returns: A new context with the updated operation
   */
  public func withOperation(_ operation: String) -> CryptoLogContext {
    CryptoLogContext(
      operation: operation,
      identifier: identifier,
      source: source,
      status: status,
      metadata: metadata,
      correlationID: correlationID,
      category: category
    )
  }

  /**
   Creates a new context with the specified identifier.

   - Parameter identifier: The new identifier
   - Returns: A new context with the updated identifier
   */
  public func withIdentifier(_ identifier: String?) -> CryptoLogContext {
    CryptoLogContext(
      operation: operation,
      identifier: identifier,
      source: source,
      status: status,
      metadata: metadata,
      correlationID: correlationID,
      category: category
    )
  }

  /**
   Creates a new context with the specified status.

   - Parameter status: The new status
   - Returns: A new context with the updated status
   */
  public func withStatus(_ status: String?) -> CryptoLogContext {
    CryptoLogContext(
      operation: operation,
      identifier: identifier,
      source: source,
      status: status,
      metadata: metadata,
      correlationID: correlationID,
      category: category
    )
  }

  /**
   Creates a new context with the specified correlation ID.

   - Parameter correlationID: The new correlation ID value
   - Returns: A new context with the updated correlation ID
   */
  public func withCorrelationID(_ correlationID: String) -> CryptoLogContext {
    CryptoLogContext(
      operation: operation,
      identifier: identifier,
      source: source,
      status: status,
      metadata: metadata,
      correlationID: correlationID,
      category: category
    )
  }

  /**
   Creates a new context with additional public metadata.

   - Parameters:
     - key: The metadata key
     - value: The metadata value
   - Returns: A new context with the added public metadata
   */
  public func withPublicMetadata(key: String, value: String) -> CryptoLogContext {
    CryptoLogContext(
      operation: operation,
      identifier: identifier,
      source: source,
      status: status,
      metadata: metadata.withPublic(key: key, value: value),
      correlationID: correlationID,
      category: category
    )
  }

  /**
   Creates a new context with additional private metadata.

   - Parameters:
     - key: The metadata key
     - value: The metadata value
   - Returns: A new context with the added private metadata
   */
  public func withPrivateMetadata(key: String, value: String) -> CryptoLogContext {
    CryptoLogContext(
      operation: operation,
      identifier: identifier,
      source: source,
      status: status,
      metadata: metadata.withPrivate(key: key, value: value),
      correlationID: correlationID,
      category: category
    )
  }

  /**
   Creates a new context with additional sensitive metadata.

   - Parameters:
     - key: The metadata key
     - value: The metadata value
   - Returns: A new context with the added sensitive metadata
   */
  public func withSensitiveMetadata(key: String, value: String) -> CryptoLogContext {
    CryptoLogContext(
      operation: operation,
      identifier: identifier,
      source: source,
      status: status,
      metadata: metadata.withSensitive(key: key, value: value),
      correlationID: correlationID,
      category: category
    )
  }

  /**
   Creates a new context with additional hashed metadata.

   - Parameters:
     - key: The metadata key
     - value: The metadata value
   - Returns: A new context with the added hashed metadata
   */
  public func withHashedMetadata(key: String, value: String) -> CryptoLogContext {
    CryptoLogContext(
      operation: operation,
      identifier: identifier,
      source: source,
      status: status,
      metadata: metadata.withHashed(key: key, value: value),
      correlationID: correlationID,
      category: category
    )
  }

  /**
   Creates a new context with additional metadata.

   - Parameters:
     - key: The metadata key
     - value: The metadata value
     - privacy: The privacy level for the metadata
   - Returns: A new context with the added metadata
   */
  public func withMetadata(
    key: String,
    value: String,
    privacy: LogPrivacyLevel = .public
  ) -> CryptoLogContext {
    let newMetadata: LogMetadataDTOCollection=switch privacy {
      case .public:
        metadata.withPublic(key: key, value: value)
      case .private:
        metadata.withPrivate(key: key, value: value)
      case .sensitive:
        metadata.withSensitive(key: key, value: value)
      case .hash:
        metadata.withHashed(key: key, value: value)
      case .auto:
        metadata.withAuto(key: key, value: value)
    }

    return CryptoLogContext(
      operation: operation,
      identifier: identifier,
      source: source,
      status: status,
      metadata: newMetadata,
      correlationID: correlationID,
      category: category
    )
  }

  /**
   Creates a new context with merged metadata.

   - Parameter newMetadata: The metadata collection to merge
   - Returns: A new context with the merged metadata
   */
  public func withMergedMetadata(_ newMetadata: LogMetadataDTOCollection) -> CryptoLogContext {
    // Create a new metadata collection with all entries from both collections
    var mergedMetadata=metadata

    for entry in newMetadata.entries {
      switch entry.privacyLevel {
        case .public:
          mergedMetadata=mergedMetadata.withPublic(key: entry.key, value: entry.value)
        case .private:
          mergedMetadata=mergedMetadata.withPrivate(key: entry.key, value: entry.value)
        case .sensitive:
          mergedMetadata=mergedMetadata.withSensitive(key: entry.key, value: entry.value)
        case .hash:
          mergedMetadata=mergedMetadata.withHashed(key: entry.key, value: entry.value)
        case .auto:
          mergedMetadata=mergedMetadata.withAuto(key: entry.key, value: entry.value)
      }
    }

    return CryptoLogContext(
      operation: operation,
      identifier: identifier,
      source: source,
      status: status,
      metadata: mergedMetadata,
      correlationID: correlationID,
      category: category
    )
  }

  public func withKeyID(_ keyID: String) -> Self {
    var newMetadata=metadata
    newMetadata=newMetadata.withPublic(key: "keyID", value: keyID)

    return CryptoLogContext(
      operation: operation,
      identifier: identifier,
      source: source,
      status: status,
      metadata: newMetadata,
      correlationID: correlationID,
      category: category
    )
  }

  public func withErrorDetails(_ error: Error) -> Self {
    var mergedMetadata=metadata
    mergedMetadata=mergedMetadata.withPublic(key: "errorType", value: "\(type(of: error))")
    mergedMetadata=mergedMetadata.withPrivate(key: "errorMessage", value: error.localizedDescription)

    return CryptoLogContext(
      operation: operation,
      identifier: identifier,
      source: source,
      status: status,
      metadata: mergedMetadata,
      correlationID: correlationID,
      category: category
    )
  }
}
