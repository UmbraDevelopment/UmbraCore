import Foundation
import LoggingTypes

/**
 * A domain-specific adapter for snapshot logging contexts that implements the standard
 * LogContextDTO protocol. This provides structured, privacy-aware logging for snapshot operations
 * following the Alpha Dot Five architecture principles.
 *
 * This adapter uses the LogMetadataDTOCollection to handle privacy annotations properly
 * and ensures proper separation between domain-specific metadata and core logging infrastructure.
 */
public struct SnapshotLogContextAdapter: LogContextDTO {
  /// The domain name of this context
  public let domainName: String="BackupServices.Snapshot"

  /// Correlation identifier for tracing related logs
  public let correlationID: String?

  /// The source identifier for this log context
  public let source: String?

  /// The operation being performed
  private let operationName: String

  /// The snapshot ID related to this operation
  private let snapshotID: String

  /// Metadata collection with privacy annotations
  public var metadata: LogMetadataDTOCollection

  /// Create a new snapshot log context
  /// - Parameters:
  ///   - snapshotID: The ID of the snapshot being operated on
  ///   - operation: The operation being performed
  ///   - additionalContext: Optional additional context information
  ///   - correlationID: Optional correlation ID for tracing
  public init(
    snapshotID: String,
    operation: String,
    additionalContext: [String: String]?=nil,
    correlationID: String?=nil
  ) {
    self.snapshotID=snapshotID
    operationName=operation
    self.correlationID=correlationID
    source="BackupServices.Snapshot.\(operation)"

    // Initialise metadata collection
    var metadataCollection=LogMetadataDTOCollection()

    // Add standard fields
    metadataCollection=metadataCollection.withPublic(key: "snapshotID", value: snapshotID)
    metadataCollection=metadataCollection.withPublic(key: "operation", value: operation)

    // Add any additional context if provided
    additionalContext?.forEach { key, value in
      metadataCollection=metadataCollection.withPublic(key: key, value: value)
    }

    metadata=metadataCollection
  }

  /// Get the source identifier for this log context
  /// - Returns: Source identifier for this log context
  public func getSource() -> String {
    source ?? "BackupServices.Snapshot.\(operationName)"
  }

  /// Creates a new instance of the context with updated metadata
  /// - Parameter metadata: New metadata to use
  /// - Returns: A new context with the updated metadata
  public func withUpdatedMetadata(_ metadata: LogMetadataDTOCollection)
  -> SnapshotLogContextAdapter {
    var newContext=self
    newContext.metadata=metadata
    return newContext
  }

  /// Get the metadata for this context
  /// - Returns: The metadata collection for this context
  public func toMetadata() -> LogMetadataDTOCollection {
    metadata
  }

  /// Add a new metadata entry with the specified privacy level
  /// - Parameters:
  ///   - key: The metadata key
  ///   - value: The metadata value
  ///   - privacy: The privacy level for this entry
  /// - Returns: A new context with the added metadata
  public func with(
    key: String,
    value: String,
    privacy: PrivacyClassification
  ) -> SnapshotLogContextAdapter {
    var newContext=self

    switch privacy {
      case .public:
        newContext.metadata=newContext.metadata.withPublic(key: key, value: value)
      case .private:
        newContext.metadata=newContext.metadata.withPrivate(key: key, value: value)
      case .sensitive:
        newContext.metadata=newContext.metadata.withSensitive(key: key, value: value)
      default:
        // Default to private for other privacy levels (like .auto, .hash)
        newContext.metadata=newContext.metadata.withPrivate(key: key, value: value)
    }

    return newContext
  }

  /// Add context information about a repository
  /// - Parameters:
  ///   - repositoryID: The repository ID
  ///   - additionalContext: Additional context information
  /// - Returns: A new context with the added repository information
  public func withRepositoryContext(
    repositoryID: String,
    additionalContext: [String: String]=[:]
  ) -> SnapshotLogContextAdapter {
    var newContext=self

    // Add the repository ID
    newContext.metadata=newContext.metadata.withPublic(key: "repositoryID", value: repositoryID)

    // Add additional context
    for (key, value) in additionalContext {
      // By default, treat additional context as public information
      newContext.metadata=newContext.metadata.withPublic(key: key, value: value)
    }
    return newContext
  }

  /// Add source paths to the context
  /// - Parameters:
  ///   - paths: The source paths
  ///   - privacy: The privacy level for the paths
  /// - Returns: A new context with the source paths
  public func withSourcePaths(
    _ paths: [String]?,
    privacy: PrivacyClassification = .private
  ) -> SnapshotLogContextAdapter {
    guard let paths, !paths.isEmpty else {
      return self
    }

    var newContext=self
    newContext.metadata=newContext.metadata.withPublic(
      key: "sourceCount",
      value: String(paths.count)
    )
    switch privacy {
      case .public:
        newContext.metadata=newContext.metadata.withPublic(
          key: "sources",
          value: paths.joined(separator: ", ")
        )
      case .private:
        newContext.metadata=newContext.metadata.withPrivate(
          key: "sources",
          value: paths.joined(separator: ", ")
        )
      case .sensitive:
        newContext.metadata=newContext.metadata.withSensitive(
          key: "sources",
          value: paths.joined(separator: ", ")
        )
      default:
        // Default to private for other privacy levels (like .auto, .hash)
        newContext.metadata=newContext.metadata.withPrivate(
          key: "sources",
          value: paths.joined(separator: ", ")
        )
    }

    return newContext
  }

  /// Add exclude paths to the context
  /// - Parameters:
  ///   - paths: The exclude paths
  ///   - privacy: The privacy level for the paths
  /// - Returns: A new context with the exclude paths
  public func withExcludePaths(
    _ paths: [String]?,
    privacy: PrivacyClassification = .private
  ) -> SnapshotLogContextAdapter {
    guard let paths, !paths.isEmpty else {
      return self
    }

    var newContext=self
    newContext.metadata=newContext.metadata.withPublic(
      key: "excludeCount",
      value: String(paths.count)
    )
    switch privacy {
      case .public:
        newContext.metadata=newContext.metadata.withPublic(
          key: "excludePaths",
          value: paths.joined(separator: ", ")
        )
      case .private:
        newContext.metadata=newContext.metadata.withPrivate(
          key: "excludePaths",
          value: paths.joined(separator: ", ")
        )
      case .sensitive:
        newContext.metadata=newContext.metadata.withSensitive(
          key: "excludePaths",
          value: paths.joined(separator: ", ")
        )
      default:
        // Default to private for other privacy levels (like .auto, .hash)
        newContext.metadata=newContext.metadata.withPrivate(
          key: "excludePaths",
          value: paths.joined(separator: ", ")
        )
    }

    return newContext
  }

  /// Add include paths to the context
  /// - Parameters:
  ///   - paths: The include paths
  ///   - privacy: The privacy level for the paths
  /// - Returns: A new context with the include paths
  public func withIncludePaths(
    _ paths: [String]?,
    privacy: PrivacyClassification = .private
  ) -> SnapshotLogContextAdapter {
    guard let paths, !paths.isEmpty else {
      return self
    }

    var newContext=self
    newContext.metadata=newContext.metadata.withPublic(
      key: "includeCount",
      value: String(paths.count)
    )
    switch privacy {
      case .public:
        newContext.metadata=newContext.metadata.withPublic(
          key: "includePaths",
          value: paths.joined(separator: ", ")
        )
      case .private:
        newContext.metadata=newContext.metadata.withPrivate(
          key: "includePaths",
          value: paths.joined(separator: ", ")
        )
      case .sensitive:
        newContext.metadata=newContext.metadata.withSensitive(
          key: "includePaths",
          value: paths.joined(separator: ", ")
        )
      default:
        // Default to private for other privacy levels (like .auto, .hash)
        newContext.metadata=newContext.metadata.withPrivate(
          key: "includePaths",
          value: paths.joined(separator: ", ")
        )
    }

    return newContext
  }

  /// Add tags to the context
  /// - Parameters:
  ///   - tags: The tags
  ///   - privacy: The privacy level for the tags
  /// - Returns: A new context with the tags
  public func withTags(
    _ tags: [String]?,
    privacy: PrivacyClassification = .public
  ) -> SnapshotLogContextAdapter {
    guard let tags, !tags.isEmpty else {
      return self
    }

    var newContext=self
    newContext.metadata=newContext.metadata.withPublic(key: "tagCount", value: String(tags.count))
    switch privacy {
      case .public:
        newContext.metadata=newContext.metadata.withPublic(
          key: "tags",
          value: tags.joined(separator: ", ")
        )
      case .private:
        newContext.metadata=newContext.metadata.withPrivate(
          key: "tags",
          value: tags.joined(separator: ", ")
        )
      case .sensitive:
        newContext.metadata=newContext.metadata.withSensitive(
          key: "tags",
          value: tags.joined(separator: ", ")
        )
      default:
        // Default to private for other privacy levels (like .auto, .hash)
        newContext.metadata=newContext.metadata.withPrivate(
          key: "tags",
          value: tags.joined(separator: ", ")
        )
    }

    return newContext
  }
}
