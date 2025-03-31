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
  /// The source identifier for this log context
  private let source: String="BackupServices.Snapshot"

  /// The operation being performed
  private let operationName: String

  /// The snapshot ID related to this operation
  private let snapshotID: String

  /// Metadata collection with privacy annotations
  private var metadata: LogMetadataDTOCollection

  /// Create a new snapshot log context
  /// - Parameters:
  ///   - snapshotID: The ID of the snapshot being operated on
  ///   - operation: The operation being performed
  ///   - additionalContext: Optional additional context information
  public init(
    snapshotID: String,
    operation: String,
    additionalContext: [String: String]?=nil
  ) {
    self.snapshotID=snapshotID
    operationName=operation

    // Initialise metadata collection
    metadata=LogMetadataDTOCollection()

    // Add standard fields
    metadata.addPublic(key: "snapshotID", value: snapshotID)
    metadata.addPublic(key: "operation", value: operation)

    // Add any additional context if provided
    additionalContext?.forEach { key, value in
      metadata.addPublic(key: key, value: value)
    }
  }

  /// Get the source identifier for this log context
  public func getSource() -> String {
    source
  }

  /// Get metadata for this log context
  public func toPrivacyMetadata() -> PrivacyMetadata {
    metadata.toPrivacyMetadata()
  }

  /// Add a key-value pair to the context
  /// - Parameters:
  ///   - key: The key for the entry
  ///   - value: The value for the entry
  ///   - privacy: The privacy level for the entry
  /// - Returns: A new context with the added entry
  public func with(
    key: String,
    value: String,
    privacy: LogPrivacyLevel
  ) -> SnapshotLogContextAdapter {
    var newContext=self

    // Use the appropriate method based on privacy level
    switch privacy {
      case .public:
        newContext.metadata.addPublic(key: key, value: value)
      case .private:
        newContext.metadata.addPrivate(key: key, value: value)
      case .sensitive:
        newContext.metadata.addSensitive(key: key, value: value)
      default:
        // Default to private for other privacy levels (like .auto, .hash)
        newContext.metadata.addPrivate(key: key, value: value)
    }

    return newContext
  }

  /// Add a key-value pair to the context with public privacy
  /// - Parameters:
  ///   - key: The key for the entry
  ///   - value: The value for the entry
  /// - Returns: A new context with the added entry
  public func with(key: String, value: String) -> SnapshotLogContextAdapter {
    with(key: key, value: value, privacy: .public)
  }

  /// Add additional context information to the log context
  /// - Parameter additionalContext: The additional context
  /// - Returns: A new context with the additional values
  public func with(additionalContext: [String: String]) -> SnapshotLogContextAdapter {
    var newContext=self
    for (key, value) in additionalContext {
      // By default, treat additional context as public information
      newContext.metadata.addPublic(key: key, value: value)
    }
    return newContext
  }

  /// Create a new context with source paths information
  /// - Parameters:
  ///   - paths: The array of paths
  ///   - privacy: The privacy level
  /// - Returns: A new context with source paths information
  public func with(sources paths: [String], privacy: LogPrivacyLevel) -> SnapshotLogContextAdapter {
    guard !paths.isEmpty else {
      return self
    }

    var newContext=self
    newContext.metadata.addPublic(key: "sourceCount", value: String(paths.count))
    switch privacy {
      case .public:
        newContext.metadata.addPublic(key: "sources", value: paths.joined(separator: ", "))
      case .private:
        newContext.metadata.addPrivate(key: "sources", value: paths.joined(separator: ", "))
      case .sensitive:
        newContext.metadata.addSensitive(key: "sources", value: paths.joined(separator: ", "))
      default:
        // Default to private for other privacy levels (like .auto, .hash)
        newContext.metadata.addPrivate(key: "sources", value: paths.joined(separator: ", "))
    }

    return newContext
  }

  /// Create a new context with exclude paths information
  /// - Parameters:
  ///   - paths: The array of paths
  ///   - privacy: The privacy level
  /// - Returns: A new context with exclude paths information
  public func with(
    excludePaths paths: [String]?,
    privacy: LogPrivacyLevel
  ) -> SnapshotLogContextAdapter {
    guard let paths, !paths.isEmpty else {
      return self
    }

    var newContext=self
    newContext.metadata.addPublic(key: "excludeCount", value: String(paths.count))
    switch privacy {
      case .public:
        newContext.metadata.addPublic(key: "excludePaths", value: paths.joined(separator: ", "))
      case .private:
        newContext.metadata.addPrivate(key: "excludePaths", value: paths.joined(separator: ", "))
      case .sensitive:
        newContext.metadata.addSensitive(key: "excludePaths", value: paths.joined(separator: ", "))
      default:
        // Default to private for other privacy levels (like .auto, .hash)
        newContext.metadata.addPrivate(key: "excludePaths", value: paths.joined(separator: ", "))
    }

    return newContext
  }

  /// Create a new context with include paths information
  /// - Parameters:
  ///   - paths: The array of paths
  ///   - privacy: The privacy level
  /// - Returns: A new context with include paths information
  public func with(
    includePaths paths: [String]?,
    privacy: LogPrivacyLevel
  ) -> SnapshotLogContextAdapter {
    guard let paths, !paths.isEmpty else {
      return self
    }

    var newContext=self
    newContext.metadata.addPublic(key: "includeCount", value: String(paths.count))
    switch privacy {
      case .public:
        newContext.metadata.addPublic(key: "includePaths", value: paths.joined(separator: ", "))
      case .private:
        newContext.metadata.addPrivate(key: "includePaths", value: paths.joined(separator: ", "))
      case .sensitive:
        newContext.metadata.addSensitive(key: "includePaths", value: paths.joined(separator: ", "))
      default:
        // Default to private for other privacy levels (like .auto, .hash)
        newContext.metadata.addPrivate(key: "includePaths", value: paths.joined(separator: ", "))
    }

    return newContext
  }

  /// Create a new context with tags information
  /// - Parameters:
  ///   - tags: The array of tags
  ///   - privacy: The privacy level
  /// - Returns: A new context with tags information
  public func with(tags: [String]?, privacy: LogPrivacyLevel) -> SnapshotLogContextAdapter {
    guard let tags, !tags.isEmpty else {
      return self
    }

    var newContext=self
    newContext.metadata.addPublic(key: "tagCount", value: String(tags.count))
    switch privacy {
      case .public:
        newContext.metadata.addPublic(key: "tags", value: tags.joined(separator: ", "))
      case .private:
        newContext.metadata.addPrivate(key: "tags", value: tags.joined(separator: ", "))
      case .sensitive:
        newContext.metadata.addSensitive(key: "tags", value: tags.joined(separator: ", "))
      default:
        // Default to private for other privacy levels (like .auto, .hash)
        newContext.metadata.addPrivate(key: "tags", value: tags.joined(separator: ", "))
    }

    return newContext
  }

  /// Add a Date value to the context
  /// - Parameters:
  ///   - key: The key for the entry
  ///   - date: The date value
  ///   - privacy: The privacy level for the entry
  /// - Returns: A new context with the added entry
  public func with(
    key: String,
    date: Date?,
    privacy: LogPrivacyLevel
  ) -> SnapshotLogContextAdapter {
    guard let date else { return self }

    let formatter=ISO8601DateFormatter()
    formatter.formatOptions=[.withInternetDateTime]
    return with(key: key, value: formatter.string(from: date), privacy: privacy)
  }

  /// Add repository ID to the context
  /// - Parameters:
  ///   - repositoryID: The repository ID
  ///   - privacy: The privacy level for the entry
  /// - Returns: A new context with the added entry
  public func with(repositoryID: String?, privacy: LogPrivacyLevel) -> SnapshotLogContextAdapter {
    guard let repositoryID, !repositoryID.isEmpty else { return self }
    return with(key: "repositoryID", value: repositoryID, privacy: privacy)
  }

  /// Add before date to the context
  /// - Parameters:
  ///   - before: The before date
  ///   - privacy: The privacy level for the entry
  /// - Returns: A new context with the added entry
  public func with(beforeDate: Date?, privacy: LogPrivacyLevel) -> SnapshotLogContextAdapter {
    with(key: "beforeDate", date: beforeDate, privacy: privacy)
  }

  /// Add after date to the context
  /// - Parameters:
  ///   - after: The after date
  ///   - privacy: The privacy level for the entry
  /// - Returns: A new context with the added entry
  public func with(afterDate: Date?, privacy: LogPrivacyLevel) -> SnapshotLogContextAdapter {
    with(key: "afterDate", date: afterDate, privacy: privacy)
  }
}
