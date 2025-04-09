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
  public let domainName: String = "CryptoServices"

  /// Optional source information (class, file, etc.)
  public let source: String?

  /// Optional correlation ID for tracing related log events
  public let correlationID: String?

  /// The type of cryptographic operation being performed
  public let operation: String

  /// Optional identifier for the data or key being operated on
  public let identifier: String?

  /// Status of the operation (success, failed, etc.)
  public let status: String?

  /// Metadata collection for additional context
  public let metadata: LogMetadataDTOCollection

  // MARK: - Initialization

  /**
   Creates a new crypto logging context.

   - Parameters:
      - operation: The type of operation (encrypt, decrypt, etc.)
      - identifier: Optional identifier for the data or key
      - status: Optional status of the operation
      - source: Optional source of the log entry
      - correlationID: Optional ID for correlation
      - metadata: Optional additional metadata
   */
  public init(
    operation: String,
    identifier: String? = nil,
    status: String? = nil,
    source: String? = "CryptoServices",
    correlationID: String? = nil,
    metadata: LogMetadataDTOCollection = LogMetadataDTOCollection()
  ) {
    self.operation = operation
    self.identifier = identifier
    self.status = status
    self.source = source
    self.correlationID = correlationID
    self.metadata = metadata
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
  
  // MARK: - Functional Update Methods
  
  /**
   Creates a new context with the specified status.
   
   - Parameter status: The new status value
   - Returns: A new context with the updated status
   */
  public func withStatus(_ status: String) -> CryptoLogContext {
    CryptoLogContext(
      operation: operation,
      identifier: identifier,
      status: status,
      source: source,
      correlationID: correlationID,
      metadata: metadata
    )
  }
  
  /**
   Creates a new context with the specified identifier.
   
   - Parameter identifier: The new identifier value
   - Returns: A new context with the updated identifier
   */
  public func withIdentifier(_ identifier: String) -> CryptoLogContext {
    CryptoLogContext(
      operation: operation,
      identifier: identifier,
      status: status,
      source: source,
      correlationID: correlationID,
      metadata: metadata
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
      status: status,
      source: source,
      correlationID: correlationID,
      metadata: metadata
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
      status: status,
      source: source,
      correlationID: correlationID,
      metadata: metadata.withPublic(key: key, value: value)
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
      status: status,
      source: source,
      correlationID: correlationID,
      metadata: metadata.withPrivate(key: key, value: value)
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
      status: status,
      source: source,
      correlationID: correlationID,
      metadata: metadata.withSensitive(key: key, value: value)
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
      status: status,
      source: source,
      correlationID: correlationID,
      metadata: metadata.withHashed(key: key, value: value)
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
    let newMetadata: LogMetadataDTOCollection
    
    switch privacy {
      case .public:
        newMetadata = metadata.withPublic(key: key, value: value)
      case .private:
        newMetadata = metadata.withPrivate(key: key, value: value)
      case .sensitive:
        newMetadata = metadata.withSensitive(key: key, value: value)
      case .hash:
        newMetadata = metadata.withHashed(key: key, value: value)
      @unknown default:
        newMetadata = metadata.withPublic(key: key, value: value)
    }
    
    return CryptoLogContext(
      operation: operation,
      identifier: identifier,
      status: status,
      source: source,
      correlationID: correlationID,
      metadata: newMetadata
    )
  }
  
  /**
   Creates a new context with merged metadata.
   
   - Parameter newMetadata: The metadata collection to merge
   - Returns: A new context with the merged metadata
   */
  public func withMergedMetadata(_ newMetadata: LogMetadataDTOCollection) -> CryptoLogContext {
    // Create a new metadata collection with all entries from both collections
    var mergedMetadata = metadata
    
    for entry in newMetadata.entries {
      switch entry.privacyLevel {
        case .public:
          mergedMetadata = mergedMetadata.withPublic(key: entry.key, value: entry.value)
        case .private:
          mergedMetadata = mergedMetadata.withPrivate(key: entry.key, value: entry.value)
        case .sensitive:
          mergedMetadata = mergedMetadata.withSensitive(key: entry.key, value: entry.value)
        case .hash:
          mergedMetadata = mergedMetadata.withHashed(key: entry.key, value: entry.value)
      }
    }
    
    return CryptoLogContext(
      operation: operation,
      identifier: identifier,
      status: status,
      source: source,
      correlationID: correlationID,
      metadata: mergedMetadata
    )
  }
}
