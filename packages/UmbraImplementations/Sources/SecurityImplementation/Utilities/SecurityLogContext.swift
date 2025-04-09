import Foundation
import LoggingTypes

/**
 Security Log Context
 
 A specialized context implementation for security operations that implements
 the LogContextDTO protocol to provide privacy-aware context information.
 
 This context type provides standardised metadata for security operations
 with appropriate privacy levels for each field.
 */
struct SecurityLogContext: LogContextDTO {
    /// The domain name for this context
    let domainName: String = "SecurityService"
    
    /// Optional source information
    let source: String?
    
    /// Optional correlation ID for tracking related logs
    let correlationID: String?
    
    /// The metadata collection for this context
    private var metadataCollection: LogMetadataDTOCollection
    
    /// Access to the metadata collection
    var metadata: LogMetadataDTOCollection {
        return metadataCollection
    }
    
    /**
     Creates a new security log context with operation information
     
     - Parameters:
       - operation: The operation being performed
       - component: The component performing the operation
       - correlationID: Optional correlation ID for tracking related logs
       - source: Optional source information
       - metadata: Optional additional metadata
     */
    init(
        operation: String,
        component: String,
        correlationID: String? = nil,
        source: String? = nil,
        metadata: LogMetadataDTOCollection = LogMetadataDTOCollection()
    ) {
        var collection = metadata
        collection = collection.withPublic(key: "operation", value: operation)
        collection = collection.withPublic(key: "component", value: component)
        
        self.metadataCollection = collection
        self.source = source
        self.correlationID = correlationID
    }
    
    /**
     Creates a new security log context with security level information
     
     - Parameters:
       - operation: The operation being performed
       - component: The component performing the operation
       - securityLevel: The security level for the operation
       - correlationID: Optional correlation ID for tracking related logs
       - source: Optional source information
     */
    init(
        operation: String,
        component: String,
        securityLevel: String,
        correlationID: String? = nil,
        source: String? = nil
    ) {
        var collection = LogMetadataDTOCollection()
        collection = collection.withPublic(key: "operation", value: operation)
        collection = collection.withPublic(key: "component", value: component)
        collection = collection.withPublic(key: "securityLevel", value: securityLevel)
        
        self.metadataCollection = collection
        self.source = source
        self.correlationID = correlationID
    }
    
    /**
     Creates a new security log context with operation ID information
     
     - Parameters:
       - operation: The operation being performed
       - component: The component performing the operation
       - operationId: Unique identifier for the operation
       - correlationID: Optional correlation ID for tracking related logs
       - source: Optional source information
     */
    init(
        operation: String,
        component: String,
        operationId: String,
        correlationID: String? = nil,
        source: String? = nil
    ) {
        var collection = LogMetadataDTOCollection()
        collection = collection.withPublic(key: "operation", value: operation)
        collection = collection.withPublic(key: "component", value: component)
        collection = collection.withPublic(key: "operationId", value: operationId)
        
        self.metadataCollection = collection
        self.source = source
        self.correlationID = correlationID
    }
    
    /**
     Adds a new key-value pair to the context with the specified privacy level
     
     - Parameters:
       - key: The metadata key
       - value: The metadata value
       - privacyLevel: The privacy level for this metadata
     - Returns: A new context with the added metadata
     */
    func adding(key: String, value: String, privacyLevel: LogPrivacyLevel) -> SecurityLogContext {
        var newContext = self
        switch privacyLevel {
        case .public:
            newContext.metadataCollection = metadataCollection.withPublic(key: key, value: value)
        case .private:
            newContext.metadataCollection = metadataCollection.withPrivate(key: key, value: value)
        case .sensitive:
            newContext.metadataCollection = metadataCollection.withSensitive(key: key, value: value)
        case .hash:
            // Use private level for hash since withHash is not available
            newContext.metadataCollection = metadataCollection.withPrivate(key: key, value: value)
        case .auto:
            // For auto, determine appropriate level based on key name
            if key.lowercased().contains("password") || key.lowercased().contains("secret") || key.lowercased().contains("key") {
                newContext.metadataCollection = metadataCollection.withSensitive(key: key, value: value)
            } else if key.lowercased().contains("id") || key.lowercased().contains("name") || key.lowercased().contains("email") {
                newContext.metadataCollection = metadataCollection.withPrivate(key: key, value: value)
            } else {
                newContext.metadataCollection = metadataCollection.withPublic(key: key, value: value)
            }
        }
        return newContext
    }
    
    /**
     Returns the metadata collection for this context
     
     - Returns: The LogMetadataDTOCollection for this context
     */
    func getMetadataCollection() -> LogMetadataDTOCollection {
        return metadataCollection
    }
}
