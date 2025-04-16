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
  public let domainName: String="FileSystem"

  /// Optional source information (class, file, etc.)
  public let source: String?

  /// Optional correlation ID for tracing related log events
  public let correlationID: String?

  /// The file system operation being performed
  public let operation: String

  /// The category for the log entry
  public let category: String

  /// The path being operated on (if applicable)
  public let path: String?

  /// The metadata collection for this context
  public let metadata: LogMetadataDTOCollection

  /**
   Initialises a new file system log context.

   - Parameters:
      - operation: The file system operation being performed
      - category: The category for the log entry
      - path: Optional path being operated on
      - source: Optional source information
      - correlationID: Optional correlation ID for tracing
      - additionalMetadata: Additional metadata for the operation
   */
  public init(
    operation: String,
    category: String="FileSystem",
    path: String?=nil,
    source: String?=nil,
    correlationID: String?=nil,
    additionalMetadata: [String: String]=[:]
  ) {
    self.operation=operation
    self.category=category
    self.path=path
    self.source=source
    self.correlationID=correlationID

    // Create metadata collection
    var collection=LogMetadataDTOCollection()

    // Add operation as public metadata
    collection=collection.withPublic(key: "operation", value: operation)

    // Add category as public metadata
    collection=collection.withPublic(key: "category", value: category)

    // Add path as private metadata (since paths might contain sensitive information)
    if let path {
      collection=collection.withPrivate(key: "path", value: path)
    }

    // Add all additional metadata as private by default
    for (key, value) in additionalMetadata {
      collection=collection.withPrivate(key: key, value: value)
    }

    metadata=collection
  }

  /**
   Private initialiser that allows direct setting of all properties including metadata.
   Used internally for creating copies with modified properties.

   - Parameters:
      - operation: The file system operation being performed
      - category: The category for the log entry
      - path: Optional path being operated on
      - source: Optional source information
      - correlationID: Optional correlation ID for tracing
      - metadata: The complete metadata collection
   */
  private init(
    operation: String,
    category: String,
    path: String?,
    source: String?,
    correlationID: String?,
    metadata: LogMetadataDTOCollection
  ) {
    self.operation=operation
    self.category=category
    self.path=path
    self.source=source
    self.correlationID=correlationID
    self.metadata=metadata
  }

  /**
   Creates a new context with additional metadata merged with the existing metadata

   - Parameter additionalMetadata: Additional metadata to include
   - Returns: New context with merged metadata
   */
  public func withMetadata(_ additionalMetadata: LogMetadataDTOCollection)
  -> FileSystemLogContextDTO {
    // Create a new instance with the same properties but with merged metadata
    FileSystemLogContextDTO(
      operation: operation,
      category: category,
      path: path,
      source: source,
      correlationID: correlationID,
      metadata: metadata.merging(with: additionalMetadata)
    )
  }
}
