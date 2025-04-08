import Foundation
import LoggingTypes

/**
 Structured logging context for cryptographic operations.

 This context provides relevant metadata for cryptographic operations:
 - Operation type (encrypt, decrypt, etc.)
 - Identifiers (for keys, data, etc.)
 - Status information
 - Separation of context from log implementation
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
    identifier: String?=nil,
    status: String?=nil,
    source: String?="CryptoServices",
    correlationID: String?=nil,
    metadata: LogMetadataDTOCollection=LogMetadataDTOCollection()
  ) {
    self.operation=operation
    self.identifier=identifier
    self.status=status
    self.source=source
    self.correlationID=correlationID
    self.metadata=metadata
  }

  // MARK: - LogContextDTO Protocol

  /// Get the domain name for the log entry
  public func getDomainName() -> String {
    domainName
  }

  /// Get the source for the log entry
  public func getSource() -> String? {
    source
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
   Creates a new context with additional metadata.
   
   - Parameters:
     - key: The metadata key
     - value: The metadata value
     - privacy: Whether the metadata is private (true) or public (false)
   - Returns: A new context with the added metadata
   */
  public func withMetadata(
    key: String,
    value: String,
    privacy: Bool = false
  ) -> CryptoLogContext {
    // Use the appropriate method based on privacy
    let newMetadata = privacy 
      ? metadata.withPrivate(key: key, value: value)
      : metadata.withPublic(key: key, value: value)
    
    return CryptoLogContext(
      operation: operation,
      identifier: identifier,
      status: status,
      source: source,
      correlationID: correlationID,
      metadata: newMetadata
    )
  }
}
