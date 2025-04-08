import Foundation
import LoggingTypes

/**
 # File System Log Context DTO
 
 Context information for file system operations logging.
 This type provides structured context for logging file system operations,
 following the Alpha Dot Five architecture principles.
 
 ## Thread Safety
 
 This type is designed to be thread-safe and can be safely used across
 actor boundaries as it is a value type with no shared state.
 
 ## British Spelling
 
 This implementation uses British spelling conventions where appropriate
 in documentation and public-facing elements.
 */
public struct FileSystemLogContextDTO: LogContextDTO, Sendable, Equatable {
    /// The domain name for this context
    public let domainName: String = "FileSystem"
    
    /// Optional source information (class, file, etc.)
    public let source: String?
    
    /// Optional correlation ID for tracing related log events
    public let correlationID: String?
    
    /// The file system operation being performed
    public let operation: String
    
    /// The path being operated on (if applicable)
    public let path: String?
    
    /// The metadata collection for this context
    public let metadata: LogMetadataDTOCollection
    
    /**
     Initialises a new file system log context.
     
     - Parameters:
        - operation: The file system operation being performed
        - path: Optional path being operated on
        - source: Optional source information
        - correlationID: Optional correlation ID for tracing
        - additionalMetadata: Additional metadata for the operation
     */
    public init(
        operation: String,
        path: String? = nil,
        source: String? = nil,
        correlationID: String? = nil,
        additionalMetadata: [String: String] = [:]
    ) {
        self.operation = operation
        self.path = path
        self.source = source
        self.correlationID = correlationID
        
        // Create metadata collection
        var collection = LogMetadataDTOCollection()
        
        // Add operation as public metadata
        collection = collection.withPublic(key: "operation", value: operation)
        
        // Add path as private metadata (since paths might contain sensitive information)
        if let path = path {
            collection = collection.withPrivate(key: "path", value: path)
        }
        
        // Add all additional metadata as private by default
        for (key, value) in additionalMetadata {
            collection = collection.withPrivate(key: key, value: value)
        }
        
        self.metadata = collection
    }
}
