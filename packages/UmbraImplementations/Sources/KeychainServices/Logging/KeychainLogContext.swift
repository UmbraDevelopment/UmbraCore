import Foundation
import LoggingInterfaces
import LoggingTypes

/**
 # Keychain Log Context
 
 A keychain-specific log context for structured logging of keychain operations.
 
 This provides metadata tailored for keychain operations including operation type,
 account information, and status with appropriate privacy controls.
 
 ## Privacy Controls
 
 This context implements comprehensive privacy controls for sensitive information:
 - Public information (like status) is logged normally
 - Private information (like operation type) is redacted in production builds
 - Sensitive information (like account identifiers) is always redacted
 
 ## Alpha Dot Five Compliance
 
 This implementation follows the Alpha Dot Five architecture principles by:
 1. Using proper British spelling in documentation
 2. Providing comprehensive privacy controls for sensitive data
 3. Supporting modern metadata handling with functional approach
 4. Using immutable data structures for thread safety
 */
public struct KeychainLogContext: LogContextDTO {
  /// The domain name for the log
  public let domainName: String

  /// The source of the log entry
  public let source: String?

  /// Correlation ID for tracking related log entries
  public let correlationID: String?

  /// The metadata collection for this log entry
  public let metadata: LogMetadataDTOCollection

  /// The type of keychain operation being performed
  public let operation: String

  /// The account identifier (with privacy protection)
  public let account: String

  /// The status of the operation
  public let status: String

  /**
   Creates a new keychain log context.
   
   - Parameters:
     - account: The account identifier (will be treated as sensitive)
     - operation: The type of keychain operation
     - status: The status of the operation (defaults to "started")
     - source: The source of the log (defaults to "KeychainServices")
     - domainName: The domain name for the log (defaults to "Keychain")
     - correlationID: Optional correlation ID for tracking related logs
     - additionalContext: Additional metadata for the log entry
   */
  public init(
    account: String,
    operation: String,
    status: String = "started",
    source: String? = "KeychainServices",
    domainName: String = "Keychain",
    correlationID: String? = nil,
    additionalContext: LogMetadataDTOCollection = LogMetadataDTOCollection()
  ) {
    self.operation = operation
    self.account = account
    self.status = status
    self.source = source
    self.domainName = domainName
    self.correlationID = correlationID

    // Create a new metadata collection with keychain-specific fields
    // Account is sensitive information
    var enhancedMetadata = additionalContext
    enhancedMetadata = enhancedMetadata.withSensitive(key: "account", value: account)
    // Operation is private information
    enhancedMetadata = enhancedMetadata.withPrivate(key: "operation", value: operation)
    // Status is public information
    enhancedMetadata = enhancedMetadata.withPublic(key: "status", value: status)

    self.metadata = enhancedMetadata
  }

  /**
   Creates an updated copy of this context with new metadata.
   
   - Parameter metadata: The new metadata collection
   - Returns: A new context with updated metadata
   */
  public func withUpdatedMetadata(_ metadata: LogMetadataDTOCollection) -> KeychainLogContext {
    KeychainLogContext(
      account: account,
      operation: operation,
      status: status,
      source: source,
      domainName: domainName,
      correlationID: correlationID,
      additionalContext: metadata
    )
  }

  /**
   Creates an updated copy of this context with a new status.
   
   - Parameter status: The new status
   - Returns: A new context with updated status
   */
  public func withStatus(_ status: String) -> KeychainLogContext {
    KeychainLogContext(
      account: account,
      operation: operation,
      status: status,
      source: source,
      domainName: domainName,
      correlationID: correlationID,
      additionalContext: metadata
    )
  }

  /**
   Returns the source of the log entry.
   
   - Returns: The source string
   */
  public func getSource() -> String {
    source ?? "KeychainServices"
  }
  
  /**
   Returns the domain name for the log.
   
   - Returns: The domain name
   */
  public func getDomain() -> String {
    domainName
  }

  /**
   Creates a metadata collection for this context.
   
   - Returns: A LogMetadataDTOCollection with privacy-aware metadata
   */
  public func createMetadataCollection() -> LogMetadataDTOCollection {
    // The metadata property already contains all the necessary information
    // with proper privacy annotations
    return metadata
  }

  /**
   Creates a new context with additional metadata entries.
   
   - Parameter additionalMetadata: The additional metadata to add
   - Returns: A new context with combined metadata
   */
  public func withAdditionalMetadata(_ additionalMetadata: LogMetadataDTOCollection) -> KeychainLogContext {
    // Use the merging method to combine metadata collections
    let combinedMetadata = createMetadataCollection().merging(with: additionalMetadata)
    
    return KeychainLogContext(
      operation: operation,
      account: account,
      status: status,
      source: source,
      domainName: domainName,
      correlationID: correlationID,
      metadata: combinedMetadata
    )
  }
  
  /**
   Adds a public metadata entry to the context.
   
   - Parameters:
     - key: The metadata key
     - value: The metadata value
   - Returns: A new context with the added metadata
   */
  public func withPublicMetadata(key: String, value: String) -> KeychainLogContext {
    let updatedMetadata = createMetadataCollection().withPublic(key: key, value: value)
    
    return KeychainLogContext(
      operation: operation,
      account: account,
      status: status,
      source: source,
      domainName: domainName,
      correlationID: correlationID,
      metadata: updatedMetadata
    )
  }
  
  /**
   Adds a private metadata entry to the context.
   
   - Parameters:
     - key: The metadata key
     - value: The metadata value
   - Returns: A new context with the added metadata
   */
  public func withPrivateMetadata(key: String, value: String) -> KeychainLogContext {
    let updatedMetadata = createMetadataCollection().withPrivate(key: key, value: value)
    
    return KeychainLogContext(
      operation: operation,
      account: account,
      status: status,
      source: source,
      domainName: domainName,
      correlationID: correlationID,
      metadata: updatedMetadata
    )
  }
  
  /**
   Adds a sensitive metadata entry to the context.
   
   - Parameters:
     - key: The metadata key
     - value: The metadata value
   - Returns: A new context with the added metadata
   */
  public func withSensitiveMetadata(key: String, value: String) -> KeychainLogContext {
    let updatedMetadata = createMetadataCollection().withSensitive(key: key, value: value)
    
    return KeychainLogContext(
      operation: operation,
      account: account,
      status: status,
      source: source,
      domainName: domainName,
      correlationID: correlationID,
      metadata: updatedMetadata
    )
  }
}
