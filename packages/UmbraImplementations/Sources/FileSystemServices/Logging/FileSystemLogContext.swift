import Foundation
import LoggingInterfaces
import LoggingTypes

/**
 # FileSystem Log Context
 
 Provides structured logging context for file system operations with privacy controls.
 This context implements the LogContextDTO protocol to ensure proper handling of
 privacy-sensitive information in file system operations.
 
 ## Privacy Considerations
 
 - File paths may contain sensitive information and are treated as private data
 - Operation types and results are considered public information
 - File metadata such as sizes and timestamps are considered public
 - File contents and attributes may be sensitive and are handled accordingly
 
 ## Alpha Dot Five Architecture
 
 This implementation follows the Alpha Dot Five architecture principles:
 1. Using proper British spelling in documentation
 2. Implementing comprehensive privacy controls
 3. Supporting modern metadata handling with functional approach
 4. Using immutable data structures for thread safety
 */
public struct FileSystemLogContext: LogContextDTO {
    /// The operation being performed
    public let operation: String
    
    /// The source of the log entry
    public let source: String
    
    /// The metadata collection with privacy annotations
    public let metadata: LogMetadataDTOCollection
    
    /// Optional correlation ID for tracing related log events
    public let correlationID: String?
    
    /// The domain name for this context
    public let domainName: String = "FileSystem"
    
    /**
     Initialises a new FileSystemLogContext.
     
     - Parameters:
        - operation: The file system operation being performed
        - path: Optional file path (will be treated with appropriate privacy level)
        - source: The source component (defaults to "FileSystemService")
        - metadata: Privacy-aware metadata collection
        - correlationID: Optional correlation ID for tracing related events
        - isSecureOperation: Whether this is a secure file operation
     */
    public init(
        operation: String,
        path: String? = nil,
        source: String = "FileSystemService",
        metadata: LogMetadataDTOCollection = LogMetadataDTOCollection(),
        correlationID: String? = nil,
        isSecureOperation: Bool = false
    ) {
        self.operation = operation
        self.source = source
        self.correlationID = correlationID
        
        var enhancedMetadata = metadata
        
        // Add operation as public information
        enhancedMetadata = enhancedMetadata.withPublic(key: "operation", value: operation)
        
        // Add secure operation flag as public information
        if isSecureOperation {
            enhancedMetadata = enhancedMetadata.withPublic(key: "isSecure", value: "true")
        }
        
        // Handle path with privacy controls
        // Paths may contain sensitive information (usernames, project names)
        if let path = path {
            enhancedMetadata = enhancedMetadata.withPrivate(key: "path", value: path)
            
            // Also add file extension as public information if available
            if let ext = path.components(separatedBy: ".").last, ext != path {
                enhancedMetadata = enhancedMetadata.withPublic(key: "fileExtension", value: ext)
            }
            
            // Add directory flag as public information
            let isDirectory = path.hasSuffix("/")
            enhancedMetadata = enhancedMetadata.withPublic(key: "isDirectory", value: String(isDirectory))
        }
        
        self.metadata = enhancedMetadata
    }
    
    /**
     Creates a new context for a read operation.
     
     - Parameters:
        - path: The path being read
        - metadata: Additional metadata for the operation
        - correlationID: Optional correlation ID
     - Returns: A new log context configured for read operations
     */
    public static func forReadOperation(
        path: String,
        metadata: LogMetadataDTOCollection = LogMetadataDTOCollection(),
        correlationID: String? = nil
    ) -> FileSystemLogContext {
        FileSystemLogContext(
            operation: "read",
            path: path,
            metadata: metadata,
            correlationID: correlationID
        )
    }
    
    /**
     Creates a new context for a write operation.
     
     - Parameters:
        - path: The path being written to
        - size: Optional size of data being written
        - metadata: Additional metadata for the operation
        - correlationID: Optional correlation ID
     - Returns: A new log context configured for write operations
     */
    public static func forWriteOperation(
        path: String,
        size: Int? = nil,
        metadata: LogMetadataDTOCollection = LogMetadataDTOCollection(),
        correlationID: String? = nil
    ) -> FileSystemLogContext {
        var enhancedMetadata = metadata
        if let size = size {
            enhancedMetadata = enhancedMetadata.withPublic(key: "dataSize", value: String(size))
        }
        
        return FileSystemLogContext(
            operation: "write",
            path: path,
            metadata: enhancedMetadata,
            correlationID: correlationID
        )
    }
    
    /**
     Creates a new context for a secure operation.
     
     - Parameters:
        - secureOperation: The specific secure operation being performed
        - path: The path for the operation
        - metadata: Additional metadata for the operation
        - correlationID: Optional correlation ID
     - Returns: A new log context configured for secure operations
     */
    public static func forSecureOperation(
        secureOperation: String,
        path: String,
        metadata: LogMetadataDTOCollection = LogMetadataDTOCollection(),
        correlationID: String? = nil
    ) -> FileSystemLogContext {
        FileSystemLogContext(
            operation: secureOperation,
            path: path,
            source: "SecureFileSystem",
            metadata: metadata,
            correlationID: correlationID,
            isSecureOperation: true
        )
    }
    
    /**
     Creates a new context with updated metadata.
     
     - Parameter newMetadata: The new metadata to use
     - Returns: A new context with the updated metadata
     */
    public func withUpdatedMetadata(_ newMetadata: LogMetadataDTOCollection) -> FileSystemLogContext {
        FileSystemLogContext(
            operation: self.operation,
            source: self.source,
            metadata: newMetadata,
            correlationID: self.correlationID
        )
    }
    
    /**
     Adds a path to the context with appropriate privacy controls.
     
     - Parameter path: The path to add
     - Returns: A new context with the path added to metadata
     */
    public func withPath(_ path: String) -> FileSystemLogContext {
        let updatedMetadata = self.metadata.withPrivate(key: "path", value: path)
        return self.withUpdatedMetadata(updatedMetadata)
    }
    
    /**
     Adds a result status to the context.
     
     - Parameter status: The operation result status
     - Returns: A new context with the status added
     */
    public func withStatus(_ status: String) -> FileSystemLogContext {
        let updatedMetadata = self.metadata.withPublic(key: "status", value: status)
        return self.withUpdatedMetadata(updatedMetadata)
    }
    
    /**
     Adds file metadata to the context with appropriate privacy controls.
     
     - Parameters:
        - size: Optional file size
        - created: Optional creation date
        - modified: Optional modification date
     - Returns: A new context with file metadata added
     */
    public func withFileMetadata(
        size: UInt64? = nil,
        created: Date? = nil,
        modified: Date? = nil
    ) -> FileSystemLogContext {
        var updatedMetadata = self.metadata
        
        if let size = size {
            updatedMetadata = updatedMetadata.withPublic(key: "fileSize", value: String(size))
        }
        
        if let created = created {
            let formatter = ISO8601DateFormatter()
            updatedMetadata = updatedMetadata.withPublic(key: "creationDate", value: formatter.string(from: created))
        }
        
        if let modified = modified {
            let formatter = ISO8601DateFormatter()
            updatedMetadata = updatedMetadata.withPublic(key: "modificationDate", value: formatter.string(from: modified))
        }
        
        return self.withUpdatedMetadata(updatedMetadata)
    }
}
