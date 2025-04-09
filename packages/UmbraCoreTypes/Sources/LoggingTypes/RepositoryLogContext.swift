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
  public let operation: String?

  /**
   Creates a new repository log context with the specified properties.

   - Parameters:
     - repositoryID: Optional identifier of the repository
     - locationPath: Optional path to the repository
     - state: Optional repository state
     - operation: Optional operation being performed
     - source: Optional source of the log event
     - correlationID: Optional correlation ID for tracing
     - additionalMetadata: Optional additional metadata to include
   */
  public init(
    repositoryID: String?=nil,
    locationPath: String?=nil,
    state: String?=nil,
    operation: String?=nil,
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
    if let operation {
      collection=collection.withPublic(key: "operation", value: operation)
    }

    // Add any additional metadata
    for (key, (value, privacyLevel)) in additionalMetadata {
      collection=collection.with(key: key, value: value, privacyLevel: privacyLevel)
    }

    metadata=collection
  }

  /**
   Creates a new repository log context from legacy metadata.

   - Parameters:
     - metadata: The legacy PrivacyMetadata object
     - source: Optional source of the log event
     - correlationID: Optional correlation ID for tracing
   */
  public init(
    metadata: PrivacyMetadata?,
    source: String?,
    correlationID: String?=nil
  ) {
    self.source=source
    self.correlationID=correlationID

    // Extract known repository fields from metadata
    if let metadata {
      repositoryID=metadata.storage["repository_id"]?.valueString
      locationPath=metadata.storage["location"]?.valueString
      state=metadata.storage["state"]?.valueString
      operation=metadata.storage["operation"]?.valueString
    } else {
      repositoryID=nil
      locationPath=nil
      state=nil
      operation=nil
    }

    // Convert metadata to LogMetadataDTOCollection
    var collection=LogMetadataDTOCollection()

    if let metadata {
      for (key, value) in metadata.storage {
        switch value.privacy {
          case .public:
            collection=collection.withPublic(key: key, value: value.valueString)
          case .private:
            collection=collection.withPrivate(key: key, value: value.valueString)
          case .sensitive:
            collection=collection.withSensitive(key: key, value: value.valueString)
          case .hash:
            collection=collection.withHashed(key: key, value: value.valueString)
          case .auto:
            collection=collection.withAuto(key: key, value: value.valueString)
        }
      }
    }

    self.metadata=collection
  }
}
