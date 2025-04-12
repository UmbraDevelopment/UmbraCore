import CryptoInterfaces
import Foundation
import LoggingInterfaces
import LoggingTypes

/**
 # Enhanced Log Context for Crypto Operations

 Enhanced log context for crypto operations, conforming to LogContextDTO.

 This context provides structured metadata for cryptographic operations with
 comprehensive privacy controls following the Alpha Dot Five architecture.

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
public struct EnhancedLogContext: LogContextDTO {
  /// Domain name for the log context
  public let domainName: String

  /// Optional source information (class, file, etc.)
  public let source: String?

  /// Optional correlation ID for tracing related log events
  public let correlationID: String?

  /// The metadata collection for this context
  public let metadata: LogMetadataDTOCollection

  /// Operation name
  public let operationName: String
  
  /// The operation being performed (required by LogContextDTO)
  public var operation: String { operationName }
  
  /// The category for the log entry (required by LogContextDTO)
  public let category: String

  /**
   Initialise a new enhanced log context.

   - Parameters:
     - domainName: The domain name for this context
     - operationName: The operation name
     - source: Optional source information
     - correlationID: Optional correlation ID
     - category: The category for the log entry
     - metadata: Initial metadata collection
   */
  public init(
    domainName: String,
    operationName: String,
    source: String?=nil,
    correlationID: String?=nil,
    category: String,
    metadata: LogMetadataDTOCollection=LogMetadataDTOCollection()
  ) {
    self.domainName=domainName
    self.operationName=operationName
    self.source=source
    self.correlationID=correlationID
    self.category=category
    self.metadata=metadata
  }

  // MARK: - LogContextDTO Protocol Implementation

  /// Get the domain name for the log entry
  public func getDomainName() -> String {
    domainName
  }

  /// Get the source for the log entry
  public func getSource() -> String {
    source ?? domainName
  }

  /// Get the correlation ID for the log entry
  public func getCorrelationID() -> String? {
    correlationID
  }

  /// Get metadata as a collection
  public func getMetadata() -> LogMetadataDTOCollection {
    metadata
  }

  // MARK: - Functional Update Methods

  /**
   Creates a new context with the specified source.

   - Parameter source: The new source value
   - Returns: A new context with the updated source
   */
  public func withSource(_ source: String) -> EnhancedLogContext {
    EnhancedLogContext(
      domainName: domainName,
      operationName: operationName,
      source: source,
      correlationID: correlationID,
      category: category,
      metadata: metadata
    )
  }

  /**
   Creates a new context with the specified correlation ID.

   - Parameter correlationID: The new correlation ID value
   - Returns: A new context with the updated correlation ID
   */
  public func withCorrelationID(_ correlationID: String) -> EnhancedLogContext {
    EnhancedLogContext(
      domainName: domainName,
      operationName: operationName,
      source: source,
      correlationID: correlationID,
      category: category,
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
  public func withPublicMetadata(key: String, value: String) -> EnhancedLogContext {
    EnhancedLogContext(
      domainName: domainName,
      operationName: operationName,
      source: source,
      correlationID: correlationID,
      category: category,
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
  public func withPrivateMetadata(key: String, value: String) -> EnhancedLogContext {
    EnhancedLogContext(
      domainName: domainName,
      operationName: operationName,
      source: source,
      correlationID: correlationID,
      category: category,
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
  public func withSensitiveMetadata(key: String, value: String) -> EnhancedLogContext {
    EnhancedLogContext(
      domainName: domainName,
      operationName: operationName,
      source: source,
      correlationID: correlationID,
      category: category,
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
  public func withHashedMetadata(key: String, value: String) -> EnhancedLogContext {
    EnhancedLogContext(
      domainName: domainName,
      operationName: operationName,
      source: source,
      correlationID: correlationID,
      category: category,
      metadata: metadata.withHashed(key: key, value: value)
    )
  }

  /**
   Creates a new context with the provided metadata merged with this context's metadata.

   - Parameter additionalMetadata: Additional metadata to include
   - Returns: New context with merged metadata
   */
  public func withMetadata(_ additionalMetadata: LogMetadataDTOCollection) -> Self {
    // Create a new metadata collection with all entries from both collections
    var mergedMetadata=metadata

    for entry in additionalMetadata.entries {
      switch entry.privacyLevel {
        case .public:
          mergedMetadata=mergedMetadata.withPublic(key: entry.key, value: entry.value)
        case .private:
          mergedMetadata=mergedMetadata.withPrivate(key: entry.key, value: entry.value)
        case .sensitive:
          mergedMetadata=mergedMetadata.withSensitive(key: entry.key, value: entry.value)
        case .hash:
          mergedMetadata=mergedMetadata.withHash(key: entry.key, value: entry.value)
        default:
          // For any other privacy level, treat as private
          mergedMetadata=mergedMetadata.withPrivate(key: entry.key, value: entry.value)
      }
    }

    return EnhancedLogContext(
      domainName: self.domainName,
      operationName: self.operationName,
      source: self.source,
      correlationID: self.correlationID,
      category: self.category,
      metadata: mergedMetadata
    )
  }

  // Maintain the existing method for backward compatibility
  public func withMergedMetadata(_ newMetadata: LogMetadataDTOCollection) -> EnhancedLogContext {
    return withMetadata(newMetadata)
  }

  /**
   Get the privacy level for a specific metadata key.

   - Parameter key: The metadata key
   - Returns: The privacy level, or .auto if not specified
   */
  public func privacyLevel(for key: String) -> PrivacyClassification {
    // Search for the key in the metadata collection
    for entry in metadata.entries where entry.key == key {
      switch entry.privacyLevel {
        case .public:
          return .public
        case .private:
          return .private
        case .sensitive:
          return .sensitive
        case .hash:
          return .hash
        case .auto:
          // For auto, default to private
          return .private
      }
    }

    // Default to auto if not found
    return .auto
  }

  /**
   Updates metadata with new values and returns a new context.

   - Parameter metadataUpdates: Dictionary of metadata updates with privacy annotations
   - Returns: A new context with the updated metadata
   */
  public func withUpdatedMetadata(_ metadataUpdates: [String: PrivacyLevel]) -> EnhancedLogContext {
    var updatedMetadata=metadata

    for (key, privacyValue) in metadataUpdates {
      switch privacyValue {
        case let .public(value):
          updatedMetadata=updatedMetadata.withPublic(key: key, value: value)
        case let .private(value):
          updatedMetadata=updatedMetadata.withPrivate(key: key, value: value)
        case let .hash(value):
          updatedMetadata=updatedMetadata.withHashed(key: key, value: value)
      }
    }

    return EnhancedLogContext(
      domainName: domainName,
      operationName: operationName,
      source: source,
      correlationID: correlationID,
      category: category,
      metadata: updatedMetadata
    )
  }

  /**
   @deprecated Use withUpdatedMetadata(_:) instead.
   Updates metadata values with new values.

   - Parameter metadataUpdates: Dictionary of metadata updates with privacy annotations
   */
  @available(*, deprecated, message: "Use withUpdatedMetadata(_:) instead")
  public mutating func updateMetadata(_ metadataUpdates: [String: PrivacyLevel]) {
    var updatedMetadata=metadata

    for (key, privacyValue) in metadataUpdates {
      switch privacyValue {
        case let .public(value):
          updatedMetadata=updatedMetadata.withPublic(key: key, value: value)
        case let .private(value):
          updatedMetadata=updatedMetadata.withPrivate(key: key, value: value)
        case let .hash(value):
          updatedMetadata=updatedMetadata.withHashed(key: key, value: value)
      }
    }

    // This is not ideal as it mutates state, but needed for backward compatibility
    self=EnhancedLogContext(
      domainName: domainName,
      operationName: operationName,
      source: source,
      correlationID: correlationID,
      category: category,
      metadata: updatedMetadata
    )
  }

  /**
   Get metadata collection to use with loggers.

   - Returns: A metadata collection with privacy annotations
   */
  public func createMetadataCollection() -> LogMetadataDTOCollection {
    metadata
  }

  /**
   @deprecated Use createMetadataCollection() instead.
   */
  @available(*, deprecated, message: "Use createMetadataCollection() instead")
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
