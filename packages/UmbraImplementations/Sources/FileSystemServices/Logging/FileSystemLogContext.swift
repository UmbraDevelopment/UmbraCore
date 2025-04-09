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
 */
public struct FileSystemLogContext: LogContextDTO {
    /// The operation being performed
    public let operation: String
    
    /// The source of the log entry
    public let source: String
    
    /// The metadata collection with privacy annotations
    public let metadata: LogMetadataDTOCollection
    
    /**
     Initialises a new FileSystemLogContext.
     
     - Parameters:
        - operation: The file system operation being performed
        - source: The source component (defaults to "FileSystemService")
        - metadata: Privacy-aware metadata collection
     */
    public init(
        operation: String,
        source: String = "FileSystemService",
        metadata: LogMetadataDTOCollection = LogMetadataDTOCollection()
    ) {
        self.operation = operation
        self.source = source
        self.metadata = metadata
    }
    
    /**
     Adds a file path to the context with appropriate privacy controls.
     
     - Parameter path: The file path to add
     - Returns: A new context with the path added
     */
    public func withPath(_ path: String) -> FileSystemLogContext {
        return FileSystemLogContext(
            operation: operation,
            source: source,
            metadata: metadata.withPrivate(key: "path", value: path)
        )
    }
    
    /**
     Adds a destination path to the context with appropriate privacy controls.
     
     - Parameter path: The destination file path to add
     - Returns: A new context with the destination path added
     */
    public func withDestinationPath(_ path: String) -> FileSystemLogContext {
        return FileSystemLogContext(
            operation: operation,
            source: source,
            metadata: metadata.withPrivate(key: "destinationPath", value: path)
        )
    }
    
    /**
     Adds file size information to the context.
     
     - Parameter size: The file size in bytes
     - Returns: A new context with the file size added
     */
    public func withFileSize(_ size: Int64) -> FileSystemLogContext {
        return FileSystemLogContext(
            operation: operation,
            source: source,
            metadata: metadata.withPublic(key: "fileSize", value: "\(size)")
        )
    }
    
    /**
     Adds an error to the context with appropriate privacy controls.
     
     - Parameter error: The error to add
     - Returns: A new context with the error added
     */
    public func withError(_ error: Error) -> FileSystemLogContext {
        return FileSystemLogContext(
            operation: operation,
            source: source,
            metadata: metadata
                .withPublic(key: "errorType", value: "\(type(of: error))")
                .withPrivate(key: "errorMessage", value: error.localizedDescription)
        )
    }
    
    /**
     Adds a result status to the context.
     
     - Parameter success: Whether the operation succeeded
     - Returns: A new context with the result status added
     */
    public func withResult(success: Bool) -> FileSystemLogContext {
        return FileSystemLogContext(
            operation: operation,
            source: source,
            metadata: metadata.withPublic(key: "success", value: "\(success)")
        )
    }
}
