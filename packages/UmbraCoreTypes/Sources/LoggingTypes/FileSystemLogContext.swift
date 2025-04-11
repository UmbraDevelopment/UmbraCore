/// A specialised log context for file system operations
///
/// This structure provides contextual information specific to file system
/// operations, with enhanced privacy controls for sensitive file paths.
public struct FileSystemLogContext: LogContextDTO, Sendable, Equatable {
  /// The name of the domain this context belongs to
  public let domainName: String="FileSystem"

  /// Correlation identifier for tracing related logs
  public let correlationID: String?

  /// Source information for the log (e.g., file, function, line)
  public let source: String?

  /// Privacy-aware metadata for this log context
  public let metadata: LogMetadataDTOCollection

  /// The file system operation being performed
  public let operation: String
  
  /// The category for the log entry
  public let category: String

  /// The file path associated with the operation
  public let path: String?

  /// Creates a new file system log context
  ///
  /// - Parameters:
  ///   - operation: The file system operation being performed
  ///   - category: The category for the log entry
  ///   - path: Optional file path associated with the operation
  ///   - correlationId: Optional correlation identifier for tracing related logs
  ///   - source: Optional source information (e.g., file, function, line)
  ///   - additionalContext: Optional additional context with privacy annotations
  public init(
    operation: String,
    category: String = "FileSystem",
    path: String?=nil,
    correlationID: String?=nil,
    source: String?=nil,
    additionalContext: LogMetadataDTOCollection=LogMetadataDTOCollection()
  ) {
    self.operation=operation
    self.category=category
    self.path=path
    self.correlationID=correlationID
    self.source=source

    // Start with the additional context
    var contextMetadata=additionalContext

    // Add operation as public metadata
    contextMetadata=contextMetadata.withPublic(key: "operation", value: operation)
    
    // Add category as public metadata
    contextMetadata=contextMetadata.withPublic(key: "category", value: category)

    // Add path as private metadata if present
    if let path {
      contextMetadata=contextMetadata.withPrivate(key: "path", value: path)

      // Extract filename as public metadata if it doesn't appear sensitive
      let components=path.split(separator: "/")
      if let fileName=components.last {
        // Basic heuristic for non-sensitive filenames
        if !fileName.contains(".") || fileName.hasSuffix(".txt") || fileName.hasSuffix(".log") {
          contextMetadata=contextMetadata.withPublic(key: "fileName", value: String(fileName))
        }
      }
    }

    metadata=contextMetadata
  }
  
  /// Creates a new context with additional metadata merged with the existing metadata
  /// - Parameter additionalMetadata: Additional metadata to include
  /// - Returns: New context with merged metadata
  public func withMetadata(_ additionalMetadata: LogMetadataDTOCollection) -> FileSystemLogContext {
    return FileSystemLogContext(
      operation: operation,
      category: category,
      path: path,
      correlationID: correlationID,
      source: source,
      additionalContext: self.metadata.merging(with: additionalMetadata)
    )
  }

  /// Creates a new instance of this context with updated metadata
  ///
  /// - Parameter metadata: The metadata to add to the context
  /// - Returns: A new log context with the updated metadata
  public func withUpdatedMetadata(_ metadata: LogMetadataDTOCollection) -> FileSystemLogContext {
    FileSystemLogContext(
      operation: operation,
      category: category,
      path: path,
      correlationID: correlationID,
      source: source,
      additionalContext: self.metadata.merging(with: metadata)
    )
  }

  /// Creates a new instance of this context with a correlation ID
  ///
  /// - Parameter correlationId: The correlation ID to add
  /// - Returns: A new log context with the specified correlation ID
  public func withCorrelationID(_ correlationID: String) -> FileSystemLogContext {
    FileSystemLogContext(
      operation: operation,
      category: category,
      path: path,
      correlationID: correlationID,
      source: source,
      additionalContext: metadata
    )
  }

  /// Creates a new instance of this context with source information
  ///
  /// - Parameter source: The source information to add
  /// - Returns: A new log context with the specified source
  public func withSource(_ source: String) -> FileSystemLogContext {
    FileSystemLogContext(
      operation: operation,
      category: category,
      path: path,
      correlationID: correlationID,
      source: source,
      additionalContext: metadata
    )
  }

  /// Creates a new instance with operation result information
  ///
  /// - Parameter success: Whether the operation was successful
  /// - Returns: A new log context with the result information
  public func withResult(success: Bool) -> FileSystemLogContext {
    let updatedMetadata=metadata.withPublic(key: "success", value: String(success))
    return FileSystemLogContext(
      operation: operation,
      category: category,
      path: path,
      correlationID: correlationID,
      source: source,
      additionalContext: updatedMetadata
    )
  }

  /// Creates a new instance with file size information
  ///
  /// - Parameter size: The size of the file in bytes
  /// - Returns: A new log context with the file size information
  public func withFileSize(_ size: Int64) -> FileSystemLogContext {
    let updatedMetadata=metadata.withPublic(key: "fileSize", value: String(size))
    return FileSystemLogContext(
      operation: operation,
      category: category,
      path: path,
      correlationID: correlationID,
      source: source,
      additionalContext: updatedMetadata
    )
  }
}
