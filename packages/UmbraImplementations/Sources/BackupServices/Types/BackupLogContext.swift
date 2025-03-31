import Foundation
import LoggingTypes

/**
 # Backup Log Context

 A structured context object for privacy-aware logging of backup operations.
 This follows the Alpha Dot Five architecture principles for privacy-enhanced
 logging with appropriate data classification.

 The context uses builder pattern methods that return a new instance,
 allowing for immutable context objects and thread safety.
 */
public struct BackupLogContext: LogContextDTO {
  /// Dictionary of metadata entries with privacy annotations
  private var entries: [String: PrivacyMetadataValue]=[:]

  /// Current operation being performed
  public var operation: String? {
    if let value=entries["operation"]?.valueString {
      return value
    }
    return nil
  }

  /// Initialises an empty backup log context
  public init() {}

  /// Gets the source of this log context
  /// - Returns: The source identifier for logging
  public func getSource() -> String {
    if let op=operation {
      return "BackupService.\(op)"
    }
    return "BackupService"
  }

  /// Converts the context to privacy metadata for logging
  /// - Returns: Privacy metadata with appropriate annotations
  public func toPrivacyMetadata() -> PrivacyMetadata {
    var metadata=PrivacyMetadata()

    for (key, value) in entries {
      metadata[key]=value
    }

    return metadata
  }

  /// Gets the metadata for this log context
  /// - Returns: Log metadata with appropriate privacy annotations
  public func getMetadata() -> PrivacyMetadata {
    toPrivacyMetadata()
  }

  /// Adds a general key-value pair to the context
  /// - Parameters:
  ///   - key: The metadata key
  ///   - value: The value to store
  ///   - privacy: Privacy level for the data
  /// - Returns: A new context with the added information
  public func with(key: String, value: String, privacy: LogPrivacyLevel) -> BackupLogContext {
    var newContext=self
    newContext.entries[key]=PrivacyMetadataValue(value: value, privacy: privacy)
    return newContext
  }

  /// Adds operation information to the context
  /// - Parameter operation: The operation being performed
  /// - Returns: A new context with the added information
  public func with(operation: String) -> BackupLogContext {
    var newContext=self
    newContext.entries["operation"]=PrivacyMetadataValue(value: operation, privacy: .public)
    return newContext
  }

  /// Adds sources information to the context
  /// - Parameters:
  ///   - sources: List of source paths
  ///   - privacy: The privacy level to apply
  /// - Returns: A new context with the added information
  public func with(sources: [URL], privacy: LogPrivacyLevel) -> BackupLogContext {
    var newContext=self

    newContext.entries["sources"]=PrivacyMetadataValue(
      value: sources.map(\.path).joined(separator: ", "),
      privacy: privacy
    )
    return newContext
  }

  /// Adds exclude paths information to the context
  /// - Parameters:
  ///   - excludePaths: Paths to exclude from backup
  ///   - privacy: The privacy level to apply
  /// - Returns: A new context with the added information
  public func with(excludePaths: [String], privacy: LogPrivacyLevel) -> BackupLogContext {
    var newContext=self

    newContext.entries["excludePaths"]=PrivacyMetadataValue(
      value: excludePaths.joined(separator: ", "),
      privacy: privacy
    )
    return newContext
  }

  /// Adds include paths information to the context
  /// - Parameters:
  ///   - includePaths: Paths to include in backup
  ///   - privacy: The privacy level to apply
  /// - Returns: A new context with the added information
  public func with(includePaths: [String], privacy: LogPrivacyLevel) -> BackupLogContext {
    var newContext=self

    newContext.entries["includePaths"]=PrivacyMetadataValue(
      value: includePaths.joined(separator: ", "),
      privacy: privacy
    )
    return newContext
  }

  /// Adds tags information to the context
  /// - Parameters:
  ///   - tags: List of tags
  ///   - privacy: The privacy level to apply
  /// - Returns: A new context with the added information
  public func with(tags: [String], privacy: LogPrivacyLevel) -> BackupLogContext {
    var newContext=self

    newContext.entries["tags"]=PrivacyMetadataValue(
      value: tags.joined(separator: ", "),
      privacy: privacy
    )
    return newContext
  }

  /// Adds repository ID to the context
  /// - Parameters:
  ///   - repositoryID: The repository identifier
  ///   - privacy: The privacy level to apply
  /// - Returns: A new context with the added information
  public func with(repositoryID: String?, privacy: LogPrivacyLevel) -> BackupLogContext {
    guard let repositoryID, !repositoryID.isEmpty else { return self }

    var newContext=self
    newContext.entries["repositoryID"]=PrivacyMetadataValue(value: repositoryID, privacy: privacy)
    return newContext
  }

  /// Adds snapshot ID to the context
  /// - Parameters:
  ///   - snapshotID: The snapshot identifier
  ///   - privacy: The privacy level to apply
  /// - Returns: A new context with the added information
  public func with(snapshotID: String, privacy: LogPrivacyLevel) -> BackupLogContext {
    var newContext=self
    newContext.entries["snapshotID"]=PrivacyMetadataValue(value: snapshotID, privacy: privacy)
    return newContext
  }
}
