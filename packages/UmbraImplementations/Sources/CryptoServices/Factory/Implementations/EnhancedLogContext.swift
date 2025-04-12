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
public struct EnhancedLogContext: LogContextDTO, Sendable {
    // MARK: - LogContextDTO Protocol Requirements
    
    /// The operation being performed (required by LogContextDTO)
    public var operation: String { operationName }
    
    /// The category of the operation (required by LogContextDTO)
    public var category: String
    
    /// Optional source information (class, file, etc.)
    public var source: String?
    
    /// Optional correlation ID for tracing related log events
    public var correlationID: String?
    
    /// The metadata collection for this log context (required by LogContextDTO)
    public let metadata: LogMetadataDTOCollection
    
    // MARK: - Additional Properties
    
    /// Domain name for the log context
    public let domainName: String
    
    /// The operation name
    public let operationName: String
    
    /**
     Creates a new enhanced log context.
     
     - Parameters:
        - domainName: The domain name for the log context
        - operationName: The name of the operation being performed
        - source: Source of the log (class, component, etc.)
        - correlationID: Optional correlation ID for request tracing
        - category: The category of the operation
        - metadata: Initial metadata collection for the context
     */
    public init(
        domainName: String,
        operationName: String,
        source: String? = nil,
        correlationID: String? = nil,
        category: String,
        metadata: LogMetadataDTOCollection = LogMetadataDTOCollection()
    ) {
        self.domainName = domainName
        self.operationName = operationName
        self.source = source
        self.correlationID = correlationID
        self.category = category
        self.metadata = metadata
    }
    
    /**
     Creates a new enhanced log context with additional metadata.
     Required by LogContextDTO protocol.
     
     - Parameter additionalMetadata: The metadata to add to the context
     - Returns: A new context with the combined metadata
     */
    public func withMetadata(_ additionalMetadata: LogMetadataDTOCollection) -> Self {
        var combinedMetadata = self.metadata
        
        // Add all entries from additionalMetadata
        for entry in additionalMetadata.entries {
            switch entry.privacyLevel {
            case .public:
                combinedMetadata = combinedMetadata.withPublic(key: entry.key, value: entry.value)
            case .private:
                combinedMetadata = combinedMetadata.withPrivate(key: entry.key, value: entry.value)
            case .sensitive:
                combinedMetadata = combinedMetadata.withSensitive(key: entry.key, value: entry.value)
            case .hash:
                combinedMetadata = combinedMetadata.withHashed(key: entry.key, value: entry.value)
            default:
                // Default to private for any other privacy level
                combinedMetadata = combinedMetadata.withPrivate(key: entry.key, value: entry.value)
            }
        }
        
        return EnhancedLogContext(
            domainName: domainName,
            operationName: operationName,
            source: source,
            correlationID: correlationID,
            category: category,
            metadata: combinedMetadata
        )
    }
    
    /**
     Creates a new context with a public metadata entry added.
     
     - Parameters:
        - key: The key for the metadata entry
        - value: The value for the metadata entry
     - Returns: A new context with the added metadata
     */
    public func withPublic(key: String, value: String) -> Self {
        withMetadata(LogMetadataDTOCollection().withPublic(key: key, value: value))
    }
    
    /**
     Creates a new context with a private metadata entry added.
     
     - Parameters:
        - key: The key for the metadata entry
        - value: The value for the metadata entry
     - Returns: A new context with the added metadata
     */
    public func withPrivate(key: String, value: String) -> Self {
        withMetadata(LogMetadataDTOCollection().withPrivate(key: key, value: value))
    }
    
    /**
     Creates a new context with a sensitive metadata entry added.
     
     - Parameters:
        - key: The key for the metadata entry
        - value: The value for the metadata entry
     - Returns: A new context with the added metadata
     */
    public func withSensitive(key: String, value: String) -> Self {
        withMetadata(LogMetadataDTOCollection().withSensitive(key: key, value: value))
    }
    
    /**
     Creates a new context with a hashed metadata entry added.
     
     - Parameters:
        - key: The key for the metadata entry
        - value: The value for the metadata entry
     - Returns: A new context with the added metadata
     */
    public func withHashed(key: String, value: String) -> Self {
        withMetadata(LogMetadataDTOCollection().withHashed(key: key, value: value))
    }
    
    /**
     Creates a new context with a new correlation ID.
     
     - Parameter correlationID: The new correlation ID
     - Returns: A new context with the updated correlation ID
     */
    public func withCorrelationID(_ correlationID: String) -> Self {
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
     Creates a new context with a new source.
     
     - Parameter source: The new source
     - Returns: A new context with the updated source
     */
    public func withSource(_ source: String) -> Self {
        EnhancedLogContext(
            domainName: domainName,
            operationName: operationName,
            source: source,
            correlationID: correlationID,
            category: category,
            metadata: metadata
        )
    }
}

/**
 Privacy value wrapper for log metadata with different privacy levels.
 */
public enum PrivacyValue: Sendable {
    /// Public information that can be logged in plain text
    case `public`(String)
    
    /// Private information that should be redacted in logs
    case `private`(String)
    
    /// Sensitive information that requires special handling
    case sensitive(String)
    
    /// Information that should be hashed in logs
    case hash(String)
}
