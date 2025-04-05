import BackupInterfaces
import Foundation
import LoggingTypes

/**
 * Defines the different operation types that can be performed by the snapshot service.
 *
 * This enum centralises all operation types in one place for consistency in logging,
 * metrics collection, and error handling.
 */
public enum SnapshotOperationType: String {
  case list
  case get
  case compare
  case updateTags
  case updateDescription
  case delete
  case copy
  case find
  case restore
  case lock
  case unlock
  case verify
  case export
  case `import`
}

/**
 * Base protocol for all snapshot operation parameters.
 *
 * This provides a common interface for all snapshot operations, enabling
 * consistent parameter validation and context creation.
 */
public protocol SnapshotOperationParameters {
  /// The type of operation being performed
  var operationType: SnapshotOperationType { get }

  /// Validates the parameters for the operation
  /// - Throws: BackupError if validation fails
  func validate() throws

  /// Creates a log context for the operation
  /// - Returns: A SnapshotLogContextAdapter for logging
  func createLogContext() -> SnapshotLogContextAdapter
}

/**
 * Parameters for listing snapshots with optional filtering.
 */
public struct SnapshotListParameters: SnapshotOperationParameters {
  public let repositoryID: String?
  public let tags: [String]?
  public let before: Date?
  public let after: Date?
  public let path: URL?
  public let limit: Int?

  public let operationType: SnapshotOperationType = .list

  public init(
    repositoryID: String?=nil,
    tags: [String]?=nil,
    before: Date?=nil,
    after: Date?=nil,
    path: URL?=nil,
    limit: Int?=nil
  ) {
    self.repositoryID=repositoryID
    self.tags=tags
    self.before=before
    self.after=after
    self.path=path
    self.limit=limit
  }

  public func validate() throws {
    // Validate limit if provided
    if let limit, limit < 0 {
      throw BackupError.invalidConfiguration(details: "Limit cannot be negative")
    }
  }

  public func createLogContext() -> SnapshotLogContextAdapter {
    let context=SnapshotLogContextAdapter(
      snapshotID: "multiple",
      operation: operationType.rawValue
    )

    return context
      .with(
        key: "repositoryID",
        value: repositoryID,
        privacy: LoggingTypes.PrivacyClassification.public
      )
      .with(
        key: "tags",
        value: tags.joined(separator: ", "),
        privacy: LoggingTypes.PrivacyClassification.public
      )
      .with(
        key: "beforeDate",
        value: before?.ISO8601Format() ?? "none",
        privacy: LoggingTypes.PrivacyClassification.public
      )
      .with(
        key: "afterDate",
        value: after?.ISO8601Format() ?? "none",
        privacy: LoggingTypes.PrivacyClassification.public
      )
      .with(
        key: "sources",
        value: path?.path != nil ? [path!.path].joined(separator: ", ") : "none",
        privacy: LoggingTypes.PrivacyClassification.sensitive
      )
      .with(
        key: "limit",
        value: limit != nil ? "\(limit!)" : "none",
        privacy: LoggingTypes.PrivacyClassification.public
      )
  }
}

/**
 * Parameters for retrieving a specific snapshot.
 */
public struct SnapshotGetParameters: SnapshotOperationParameters {
  public let snapshotID: String
  public let includeFileStatistics: Bool

  public let operationType: SnapshotOperationType = .get

  public init(
    snapshotID: String,
    includeFileStatistics: Bool=false
  ) {
    self.snapshotID=snapshotID
    self.includeFileStatistics=includeFileStatistics
  }

  public func validate() throws {
    if snapshotID.isEmpty {
      throw BackupError.invalidConfiguration(details: "Snapshot ID cannot be empty")
    }
  }

  public func createLogContext() -> SnapshotLogContextAdapter {
    let context=SnapshotLogContextAdapter(
      snapshotID: snapshotID,
      operation: operationType.rawValue
    )

    return context.with(
      key: "includeFileStatistics",
      value: String(includeFileStatistics),
      privacy: LoggingTypes.PrivacyClassification.public
    )
  }
}

/**
 * Parameters for comparing two snapshots.
 */
public struct SnapshotCompareParameters: SnapshotOperationParameters {
  public let snapshotID1: String
  public let snapshotID2: String
  public let path: URL?

  public let operationType: SnapshotOperationType = .compare

  public init(
    snapshotID1: String,
    snapshotID2: String,
    path: URL?=nil
  ) {
    self.snapshotID1=snapshotID1
    self.snapshotID2=snapshotID2
    self.path=path
  }

  public func validate() throws {
    if snapshotID1.isEmpty || snapshotID2.isEmpty {
      throw BackupError.invalidConfiguration(details: "Snapshot IDs cannot be empty")
    }

    if snapshotID1 == snapshotID2 {
      throw BackupError.invalidConfiguration(details: "Cannot compare a snapshot with itself")
    }
  }

  public func createLogContext() -> SnapshotLogContextAdapter {
    let context=SnapshotLogContextAdapter(
      snapshotID: "compare", // Special case for compare operation
      operation: operationType.rawValue
    )

    return context
      .with(
        key: "snapshotID1",
        value: snapshotID1,
        privacy: LoggingTypes.PrivacyClassification.public
      )
      .with(
        key: "snapshotID2",
        value: snapshotID2,
        privacy: LoggingTypes.PrivacyClassification.public
      )
      .with(
        key: "sources",
        value: path?.path != nil ? [path!.path].joined(separator: ", ") : "none",
        privacy: LoggingTypes.PrivacyClassification.sensitive
      )
  }
}

/**
 * Parameters for updating snapshot tags.
 */
public struct SnapshotUpdateTagsParameters: SnapshotOperationParameters {
  public let snapshotID: String
  public let addTags: [String]
  public let removeTags: [String]

  public let operationType: SnapshotOperationType = .updateTags

  public init(
    snapshotID: String,
    addTags: [String]=[],
    removeTags: [String]=[]
  ) {
    self.snapshotID=snapshotID
    self.addTags=addTags
    self.removeTags=removeTags
  }

  public func validate() throws {
    if snapshotID.isEmpty {
      throw BackupError.invalidConfiguration(details: "Snapshot ID cannot be empty")
    }

    if addTags.isEmpty && removeTags.isEmpty {
      throw BackupError.invalidConfiguration(details: "Must specify tags to add or remove")
    }
  }

  public func createLogContext() -> SnapshotLogContextAdapter {
    let context=SnapshotLogContextAdapter(
      snapshotID: snapshotID,
      operation: operationType.rawValue
    )

    return context
      .with(
        key: "addTags",
        value: addTags.isEmpty ? "none" : addTags.joined(separator: ", "),
        privacy: LoggingTypes.PrivacyClassification.public
      )
      .with(
        key: "removeTags",
        value: removeTags.joined(separator: ", "),
        privacy: LoggingTypes.PrivacyClassification.public
      )
  }
}

/**
 * Parameters for updating snapshot description.
 */
public struct SnapshotUpdateDescriptionParameters: SnapshotOperationParameters {
  public let snapshotID: String
  public let description: String

  public let operationType: SnapshotOperationType = .updateDescription

  public init(
    snapshotID: String,
    description: String
  ) {
    self.snapshotID=snapshotID
    self.description=description
  }

  public func validate() throws {
    if snapshotID.isEmpty {
      throw BackupError.invalidConfiguration(details: "Snapshot ID cannot be empty")
    }
  }

  public func createLogContext() -> SnapshotLogContextAdapter {
    let context=SnapshotLogContextAdapter(
      snapshotID: snapshotID,
      operation: operationType.rawValue
    )

    // Description might contain sensitive information, so mark as private
    return context.with(
      key: "description",
      value: description.count > 30 ? "\(description.prefix(30))..." : description,
      privacy: LoggingTypes.PrivacyClassification.private
    )
  }
}

/**
 * Parameters for deleting a snapshot.
 */
public struct SnapshotDeleteParameters: SnapshotOperationParameters, HasSnapshotID {
  public let snapshotID: String
  public let pruneAfterDelete: Bool
  public let operationType: SnapshotOperationType = .delete

  /**
   * Creates a new set of parameters for deleting a snapshot.
   *
   * - Parameters:
   *   - snapshotID: ID of the snapshot to delete
   *   - pruneAfterDelete: Whether to prune the repository after deletion
   */
  public init(
    snapshotID: String,
    pruneAfterDelete: Bool=false
  ) {
    self.snapshotID=snapshotID
    self.pruneAfterDelete=pruneAfterDelete
  }

  public func validate() throws {
    if snapshotID.isEmpty {
      throw BackupError.invalidConfiguration(details: "Snapshot ID cannot be empty")
    }
  }

  public func createLogContext() -> SnapshotLogContextAdapter {
    let context=SnapshotLogContextAdapter(
      snapshotID: snapshotID,
      operation: operationType.rawValue
    )

    return context.with(
      key: "pruneAfterDelete",
      value: String(pruneAfterDelete),
      privacy: LoggingTypes.PrivacyClassification.public
    )
  }
}

/**
 * Parameters for copying a snapshot to another repository.
 */
public struct SnapshotCopyParameters: SnapshotOperationParameters, HasSnapshotID {
  public let snapshotID: String
  public let targetRepositoryID: String
  public let operationType: SnapshotOperationType = .copy

  /**
   * Creates a new set of parameters for copying a snapshot.
   *
   * - Parameters:
   *   - snapshotID: ID of the snapshot to copy
   *   - targetRepositoryID: ID of the target repository
   */
  public init(
    snapshotID: String,
    targetRepositoryID: String
  ) {
    self.snapshotID=snapshotID
    self.targetRepositoryID=targetRepositoryID
  }

  public func validate() throws {
    if snapshotID.isEmpty {
      throw BackupError.invalidConfiguration(details: "Snapshot ID cannot be empty")
    }
    if targetRepositoryID.isEmpty {
      throw BackupError.invalidConfiguration(details: "Target repository ID cannot be empty")
    }
  }

  public func createLogContext() -> SnapshotLogContextAdapter {
    let context=SnapshotLogContextAdapter(
      snapshotID: snapshotID,
      operation: operationType.rawValue
    )

    return context.with(
      key: "targetRepositoryID",
      value: targetRepositoryID,
      privacy: LoggingTypes.PrivacyClassification.public
    )
  }
}

/**
 * Parameters for locking a snapshot.
 */
public struct SnapshotLockParameters: SnapshotOperationParameters, HasSnapshotID {
  public let snapshotID: String
  public let operationType: SnapshotOperationType = .lock

  /**
   * Creates a new set of parameters for locking a snapshot.
   *
   * - Parameter snapshotID: ID of the snapshot to lock
   */
  public init(snapshotID: String) {
    self.snapshotID=snapshotID
  }

  public func validate() throws {
    if snapshotID.isEmpty {
      throw BackupError.invalidConfiguration(details: "Snapshot ID cannot be empty")
    }
  }

  public func createLogContext() -> SnapshotLogContextAdapter {
    SnapshotLogContextAdapter(
      snapshotID: snapshotID,
      operation: operationType.rawValue
    )
  }
}

/**
 * Parameters for unlocking a snapshot.
 */
public struct SnapshotUnlockParameters: SnapshotOperationParameters, HasSnapshotID {
  public let snapshotID: String
  public let operationType: SnapshotOperationType = .unlock

  /**
   * Creates a new set of parameters for unlocking a snapshot.
   *
   * - Parameter snapshotID: ID of the snapshot to unlock
   */
  public init(snapshotID: String) {
    self.snapshotID=snapshotID
  }

  public func validate() throws {
    if snapshotID.isEmpty {
      throw BackupError.invalidConfiguration(details: "Snapshot ID cannot be empty")
    }
  }

  public func createLogContext() -> SnapshotLogContextAdapter {
    SnapshotLogContextAdapter(
      snapshotID: snapshotID,
      operation: operationType.rawValue
    )
  }
}

/**
 * Parameters for restoring files from a snapshot.
 */
public struct SnapshotRestoreParameters: SnapshotOperationParameters, HasSnapshotID {
  public let snapshotID: String
  public let targetPath: URL
  public let includePattern: String?
  public let excludePattern: String?

  public let operationType: SnapshotOperationType = .restore

  public init(
    snapshotID: String,
    targetPath: URL,
    includePattern: String?=nil,
    excludePattern: String?=nil
  ) {
    self.snapshotID=snapshotID
    self.targetPath=targetPath
    self.includePattern=includePattern
    self.excludePattern=excludePattern
  }

  public func validate() throws {
    if snapshotID.isEmpty {
      throw BackupError.invalidConfiguration(details: "Snapshot ID cannot be empty")
    }
  }

  public func createLogContext() -> SnapshotLogContextAdapter {
    let context=SnapshotLogContextAdapter(
      snapshotID: snapshotID,
      operation: operationType.rawValue
    )

    var enrichedContext=context.with(
      key: "sources",
      value: targetPath.path,
      privacy: LoggingTypes.PrivacyClassification
        .sensitive // Target path may contain user-specific information
    )

    if let includePattern {
      enrichedContext=enrichedContext.with(
        key: "includePattern",
        value: includePattern,
        privacy: LoggingTypes.PrivacyClassification.public
      )
    }

    if let excludePattern {
      enrichedContext=enrichedContext.with(
        key: "excludePattern",
        value: excludePattern,
        privacy: LoggingTypes.PrivacyClassification.public
      )
    }

    return enrichedContext
  }
}

/**
 * Parameters for verifying a snapshot.
 */
public struct SnapshotVerifyParameters: SnapshotOperationParameters, HasSnapshotID {
  public let snapshotID: String
  public let level: VerificationLevel
  public let operationType: SnapshotOperationType = .verify

  /**
   * Creates a new set of parameters for verifying a snapshot.
   *
   * - Parameters:
   *   - snapshotID: ID of the snapshot to verify
   *   - level: Level of verification to perform
   */
  public init(
    snapshotID: String,
    level: VerificationLevel = .standard
  ) {
    self.snapshotID=snapshotID
    self.level=level
  }

  public func validate() throws {
    if snapshotID.isEmpty {
      throw BackupError.invalidConfiguration(details: "Snapshot ID cannot be empty")
    }
  }

  public func createLogContext() -> SnapshotLogContextAdapter {
    let context=SnapshotLogContextAdapter(
      snapshotID: snapshotID,
      operation: operationType.rawValue
    )

    return context.with(
      key: "verificationLevel",
      value: level.rawValue,
      privacy: LoggingTypes.PrivacyClassification.public
    )
  }
}

/**
 * Defines the level of verification to perform.
 */
public enum VerificationLevel: String, Sendable, Equatable {
  /// Light verification - checks index and structural integrity only
  case light

  /// Standard verification - checks about 10% of data blocks
  case standard

  /// Thorough verification - checks 100% of data blocks
  case thorough

  /// Returns the corresponding Restic command value
  var resticValue: String {
    switch self {
      case .light:
        "0%"
      case .standard:
        "10%"
      case .thorough:
        "100%"
    }
  }
}
