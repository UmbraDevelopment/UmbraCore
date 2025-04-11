/**
 # RepositoryLogContext

 A specialised log context for repository operations, providing
 structured metadata with appropriate privacy controls.

 This context contains repository-specific fields such as repository
 identifiers, paths, and operation names with privacy annotations.
 */
public struct RepositoryLogContext: LogContextDTO, Equatable {
  /// The domain name for this context (always "RepositoryService")
  public let domainName: String="RepositoryService"

  /// Source information (class, file, etc.)
  public let source: String?

  /// Optional correlation ID for tracing related log events
  public let correlationID: String?

  /// The metadata collection for this context
  public let metadata: LogMetadataDTOCollection

  /// The repository identifier
  public let repositoryID: String?

  /// The repository location path
  public let locationPath: String?

  /// The repository state
  public let state: String?

  /// The operation being performed
  public let operation: String
  
  /// The category for the log entry
  public let category: String

  /**
   Creates a new repository log context with the specified properties.

   - Parameters:
     - repositoryID: Optional identifier of the repository
     - locationPath: Optional path to the repository
     - state: Optional repository state
     - operation: The operation being performed
     - category: The category for the log entry
     - source: Optional source of the log event
     - correlationID: Optional correlation ID for tracing
     - additionalMetadata: Optional additional metadata to include
   */
  public init(
    repositoryID: String?=nil,
    locationPath: String?=nil,
    state: String?=nil,
    operation: String="repository",
    category: String="Repository",
    source: String?=nil,
    correlationID: String?=nil,
    additionalMetadata: [String: (String, PrivacyClassification)]=[:]
  ) {
    self.source=source
    self.correlationID=correlationID
    self.repositoryID=repositoryID
    self.locationPath=locationPath
    self.state=state
    self.operation=operation
    self.category=category

    // Build metadata collection with privacy annotations
    var collection=LogMetadataDTOCollection()

    // Add repository identifier with public privacy
    if let repositoryID {
      collection=collection.withPublic(key: "repository_id", value: repositoryID)
    }

    // Add location path with public privacy
    if let locationPath {
      collection=collection.withPublic(key: "location", value: locationPath)
    }

    // Add state with public privacy
    if let state {
      collection=collection.withPublic(key: "state", value: state)
    }

    // Add operation with public privacy
    collection=collection.withPublic(key: "operation", value: operation)
    
    // Add category with public privacy
    collection=collection.withPublic(key: "category", value: category)

    // Add any additional metadata
    for (key, (value, privacyLevel)) in additionalMetadata {
      collection=collection.with(key: key, value: value, privacyLevel: privacyLevel)
    }

    metadata=collection
  }
  
  /// Creates a new context with additional metadata merged with the existing metadata
  /// - Parameter additionalMetadata: Additional metadata to include
  /// - Returns: New context with merged metadata
  public func withMetadata(_ additionalMetadata: LogMetadataDTOCollection) -> RepositoryLogContext {
    return RepositoryLogContext(
      repositoryID: self.repositoryID,
      locationPath: self.locationPath, 
      state: self.state,
      operation: self.operation,
      category: self.category,
      source: self.source,
      correlationID: self.correlationID,
      additionalMetadata: [:]
    )
  }

  /**
   Creates a new repository log context from legacy metadata.

   - Parameters:
     - metadata: The legacy PrivacyMetadata object
     - source: Optional source of the log event
     - correlationID: Optional correlation ID for tracing
   */
  public init(
    metadata: PrivacyMetadata,
    source: String?=nil,
    correlationID: String?=nil
  ) {
    self.source=source
    self.correlationID=correlationID
    
    // Create a new metadata collection
    var collection = LogMetadataDTOCollection()
    
    // Extract repository ID from metadata if available
    let repositoryID = metadata.storage["repository_id"]?.valueString
    self.repositoryID = repositoryID
    
    // Extract location path from metadata if available
    let locationPath = metadata.storage["location"]?.valueString
    self.locationPath = locationPath
    
    // Extract state from metadata if available
    let state = metadata.storage["state"]?.valueString
    self.state = state
    
    // Extract operation from metadata if available
    let extractedOperation = metadata.storage["operation"]?.valueString
    self.operation = extractedOperation ?? "repository"
    
    // Use a default category
    self.category = "Repository"
    
    // Convert the privacy metadata to the DTO collection
    for (key, value) in metadata.storage {
      switch value.privacy {
        case .public:
          collection = collection.withPublic(key: key, value: value.valueString)
        case .private:
          collection = collection.withPrivate(key: key, value: value.valueString)
        case .sensitive:
          collection = collection.withSensitive(key: key, value: value.valueString)
        case .hash:
          collection = collection.withHashed(key: key, value: value.valueString)
        case .auto:
          collection = collection.withAuto(key: key, value: value.valueString)
      }
    }
    
    self.metadata = collection
  }
}
