import Foundation
import BackupInterfaces
import LoggingTypes
import CoreDTOs
import UmbraErrors

/**
 A structure representing snapshot update configuration for API operations
 */
public struct SnapshotUpdateConfig: Sendable {
  public let tags: [String]?
  public let metadata: [String: SendableValue]?
  
  public init(
    tags: [String]?,
    metadata: [String: SendableValue]?
  ) {
    self.tags = tags
    self.metadata = metadata
  }
}

/**
 A structure representing restore configuration for API operations
 */
public struct RestoreConfig: Sendable {
  public let paths: [String]
  public let targetDirectory: URL
  public let overwriteExisting: Bool
  public let preserveAttributes: Bool
  
  public init(
    paths: [String],
    targetDirectory: URL,
    overwriteExisting: Bool = false,
    preserveAttributes: Bool = true
  ) {
    self.paths = paths
    self.targetDirectory = targetDirectory
    self.overwriteExisting = overwriteExisting
    self.preserveAttributes = preserveAttributes
  }
}

/**
 A structure representing a snapshot summary for API responses
 */
public struct SnapshotSummary: Sendable {
  public let fileCount: Int
  public let totalSize: UInt64
  public let compressionRatio: Double?
  
  public init(
    fileCount: Int,
    totalSize: UInt64,
    compressionRatio: Double? = nil
  ) {
    self.fileCount = fileCount
    self.totalSize = totalSize
    self.compressionRatio = compressionRatio
  }
}

/**
 A structure representing basic snapshot information for API responses
 */
public struct SnapshotInfo: Sendable {
  public let id: String
  public let repositoryID: String
  public let name: String?
  public let timestamp: Date
  public let tags: [String]
  public let summary: SnapshotSummary
  
  public init(
    id: String,
    repositoryID: String,
    name: String? = nil,
    timestamp: Date,
    tags: [String],
    summary: SnapshotSummary
  ) {
    self.id = id
    self.repositoryID = repositoryID
    self.name = name
    self.timestamp = timestamp
    self.tags = tags
    self.summary = summary
  }
}

/**
 Operation to list snapshots in a repository
 */
public struct ListSnapshotsOperation: APIOperation {
  public let operationType = "listSnapshots"
  public let repositoryID: String
  public let tagFilter: [String]?
  public let pathFilter: String?
  public let beforeDate: Date?
  public let afterDate: Date?
  public let limit: Int?
  
  public init(
    repositoryID: String,
    tagFilter: [String]? = nil,
    pathFilter: String? = nil,
    beforeDate: Date? = nil,
    afterDate: Date? = nil,
    limit: Int? = nil
  ) {
    self.repositoryID = repositoryID
    self.tagFilter = tagFilter
    self.pathFilter = pathFilter
    self.beforeDate = beforeDate
    self.afterDate = afterDate
    self.limit = limit
  }
}

/**
 Operation to get a specific snapshot's details
 */
public struct GetSnapshotOperation: APIOperation {
  public let operationType = "getSnapshot"
  public let repositoryID: String
  public let snapshotID: String
  public let includeFiles: Bool
  
  public init(
    repositoryID: String,
    snapshotID: String,
    includeFiles: Bool = false
  ) {
    self.repositoryID = repositoryID
    self.snapshotID = snapshotID
    self.includeFiles = includeFiles
  }
}

/**
 Parameters for creating a snapshot
 */
public struct CreateSnapshotParameters: Sendable {
  public let paths: [String]
  public let tags: [String]
  public let metadata: [String: SendableValue]?
  
  public init(
    paths: [String],
    tags: [String] = [],
    metadata: [String: SendableValue]? = nil
  ) {
    self.paths = paths
    self.tags = tags
    self.metadata = metadata
  }
}

/**
 Operation to create a new snapshot
 */
public struct CreateSnapshotOperation: APIOperation {
  public let operationType = "createSnapshot"
  public let repositoryID: String
  public let parameters: CreateSnapshotParameters
  
  public init(
    repositoryID: String,
    parameters: CreateSnapshotParameters
  ) {
    self.repositoryID = repositoryID
    self.parameters = parameters
  }
}

/**
 Parameters for updating a snapshot
 */
public struct UpdateSnapshotParameters: Sendable {
  public let tags: [String]?
  public let metadata: [String: SendableValue]?
  
  public init(
    tags: [String]? = nil,
    metadata: [String: SendableValue]? = nil
  ) {
    self.tags = tags
    self.metadata = metadata
  }
}

/**
 Operation to update an existing snapshot
 */
public struct UpdateSnapshotOperation: APIOperation {
  public let operationType = "updateSnapshot"
  public let repositoryID: String
  public let snapshotID: String
  public let parameters: UpdateSnapshotParameters
  
  public init(
    repositoryID: String,
    snapshotID: String,
    parameters: UpdateSnapshotParameters
  ) {
    self.repositoryID = repositoryID
    self.snapshotID = snapshotID
    self.parameters = parameters
  }
}

/**
 Operation to delete a snapshot
 */
public struct DeleteSnapshotOperation: APIOperation {
  public let operationType = "deleteSnapshot"
  public let repositoryID: String
  public let snapshotID: String
  
  public init(
    repositoryID: String,
    snapshotID: String
  ) {
    self.repositoryID = repositoryID
    self.snapshotID = snapshotID
  }
}

/**
 Parameters for restoring from a snapshot
 */
public struct RestoreSnapshotParameters: Sendable {
  public let paths: [String]
  public let targetDirectory: URL
  public let overwrite: Bool
  public let preservePermissions: Bool
  
  public init(
    paths: [String] = [],
    targetDirectory: URL,
    overwrite: Bool = false,
    preservePermissions: Bool = true
  ) {
    self.paths = paths
    self.targetDirectory = targetDirectory
    self.overwrite = overwrite
    self.preservePermissions = preservePermissions
  }
}

/**
 Operation to restore from a snapshot
 */
public struct RestoreSnapshotOperation: APIOperation {
  public let operationType = "restoreSnapshot"
  public let repositoryID: String
  public let snapshotID: String
  public let parameters: RestoreSnapshotParameters
  
  public init(
    repositoryID: String,
    snapshotID: String,
    parameters: RestoreSnapshotParameters
  ) {
    self.repositoryID = repositoryID
    self.snapshotID = snapshotID
    self.parameters = parameters
  }
}

/**
 Operation to forget a snapshot (potentially without deleting data)
 */
public struct ForgetSnapshotOperation: APIOperation {
  public let operationType = "forgetSnapshot"
  public let repositoryID: String
  public let snapshotID: String
  public let keepData: Bool
  
  public init(
    repositoryID: String,
    snapshotID: String,
    keepData: Bool = false
  ) {
    self.repositoryID = repositoryID
    self.snapshotID = snapshotID
    self.keepData = keepData
  }
}

/**
 A structure representing snapshot filters
 */
public struct SnapshotFilters: Sendable {
  public let tags: [String]
  public let path: String?
  public let before: Date?
  public let after: Date?
  public let limit: Int?
  
  public init(
    tags: [String] = [],
    path: String? = nil,
    before: Date? = nil,
    after: Date? = nil,
    limit: Int? = nil
  ) {
    self.tags = tags
    self.path = path
    self.before = before
    self.after = after
    self.limit = limit
  }
}

/**
 A structure representing a file entry in a snapshot for API responses
 */
public struct FileEntry: Sendable, Identifiable {
  public let id: String
  public let path: String
  public let size: UInt64
  public let modificationDate: Date
  public let isDirectory: Bool
  public let hash: String?
  
  public init(
    id: String,
    path: String,
    size: UInt64,
    modificationDate: Date,
    isDirectory: Bool = false,
    hash: String? = nil
  ) {
    self.id = id
    self.path = path
    self.size = size
    self.modificationDate = modificationDate
    self.isDirectory = isDirectory
    self.hash = hash
  }
}

/**
 A structure representing detailed snapshot information for API responses
 */
public struct SnapshotDetails: Sendable {
  public let basicInfo: SnapshotInfo
  public let creationHostname: String
  public let options: [String: String]
  public let metadata: [String: String]
  public let files: [FileEntry]
  
  public init(
    basicInfo: SnapshotInfo,
    creationHostname: String,
    options: [String: String] = [:],
    metadata: [String: String] = [:],
    files: [FileEntry] = []
  ) {
    self.basicInfo = basicInfo
    self.creationHostname = creationHostname
    self.options = options
    self.metadata = metadata
    self.files = files
  }
}

/**
 A structure representing restoration result for API responses
 */
public struct RestoreResult: Sendable {
  public let snapshotID: String
  public let restoreTime: Date
  public let totalSize: UInt64
  public let fileCount: Int
  public let duration: TimeInterval
  public let targetPath: URL
  public let filesRestored: Int
  
  public init(
    snapshotID: String,
    restoreTime: Date,
    totalSize: UInt64,
    fileCount: Int,
    duration: TimeInterval,
    targetPath: URL,
    filesRestored: Int
  ) {
    self.snapshotID = snapshotID
    self.restoreTime = restoreTime
    self.totalSize = totalSize
    self.fileCount = fileCount
    self.duration = duration
    self.targetPath = targetPath
    self.filesRestored = filesRestored
  }
}

/**
 * Types to bridge between BackupServiceProtocol and API operations
 */

// For BackupInterfaces.BackupSnapshot to SnapshotInfo conversion
extension BackupSnapshot {
  func toSnapshotInfo(repositoryID: String) -> SnapshotInfo {
    return SnapshotInfo(
      id: id,
      repositoryID: repositoryID,
      name: "Snapshot \(id)",  // Default name when metadata not available
      timestamp: Date(),      // Default to current time when timestamp not available
      tags: tags,
      summary: SnapshotSummary(
        fileCount: fileCount,
        totalSize: UInt64(0)  // Default to zero when size not available
      )
    )
  }
}

/**
 Extension to BackupServiceProtocol to add snapshot operations
 */
extension BackupServiceProtocol {
  /**
   Gets a specific snapshot by ID from a repository
   */
  func getSnapshot(id: String, fromRepository repositoryID: String) async throws -> BackupSnapshot {
    let result = await listSnapshots(tags: nil, before: nil, after: nil, listOptions: nil)
    
    switch result {
      case .success(let snapshots):
        if let snapshot = try? snapshots.first(where: { $0.id == id }) {
          return snapshot
        }
        throw BackupOperationError.snapshotNotFound(id: id)
      case .failure(let error):
        throw error
    }
  }
  
  /**
   Lists snapshots with filtering
   */
  func listSnapshots(forRepository repositoryID: String, filters: SnapshotFilters) async throws -> [BackupSnapshot] {
    let result = await listSnapshots(
      tags: filters.tags.isEmpty ? nil : filters.tags,
      before: filters.before,
      after: filters.after,
      listOptions: filters.limit != nil ? ListOptions(limit: filters.limit!) : nil
    )
    
    switch result {
      case .success(let snapshots):
        return snapshots
      case .failure(let error):
        throw error
    }
  }
  
  /**
   Creates a snapshot with the given configuration
   */
  func createSnapshot(forRepository repositoryID: String, config: SnapshotCreationConfig) async throws -> BackupSnapshot {
    // Create the snapshot using config 
    let paths = config.paths.map { URL(fileURLWithPath: $0) }
    
    // Set up creation parameters
    let creationParams = CreateSnapshotParameters(
      paths: paths.map { $0.path },
      tags: config.tags,
      metadata: config.metadata as? [String: Data] ?? [:]
    )
    
    // Call the core backup service
    return try await createSnapshot(
      forRepository: repositoryID,
      config: creationParams
    )
  }
  
  /**
   Updates a snapshot with the given configuration
   */
  func updateSnapshot(
    id: String,
    forRepository repositoryID: String,
    with config: SnapshotUpdateConfig
  ) async throws -> BackupSnapshot {
    // Get the snapshot
    let snapshot = try await getSnapshot(id: id, fromRepository: repositoryID)
    
    // Update tags if provided
    if let newTags = config.tags {
      let tagResult = await updateTags(for: snapshot.id, tags: newTags)
      if case .failure(let error) = tagResult {
        throw error
      }
    }
    
    // Update metadata if provided
    if let newMeta = config.metadata {
      var stringMeta: [String: String] = [:]
      for (key, value) in newMeta {
        if let str = value.stringValue {
          stringMeta[key] = str
        }
      }
      
      if !stringMeta.isEmpty {
        let metaResult = await updateMetadata(for: snapshot.id, metadata: stringMeta)
        if case .failure(let error) = metaResult {
          throw error
        }
      }
    }
    
    // Return the updated snapshot
    return try await getSnapshot(id: id, fromRepository: repositoryID)
  }
  
  /**
   Gets the files in a snapshot
   */
  func getSnapshotFiles(snapshotID: String, repositoryID: String) async throws -> [FileEntry] {
    let result = await getFiles(for: snapshotID)
    
    switch result {
      case .success(let files):
        return files.map { file in
          FileEntry(
            id: file.id, // Using our extension property
            path: file.path,
            size: file.size,
            modificationDate: file.modificationDate ?? Date(), // Using our extension property
            isDirectory: file.type == .directory, // Using our extension property
            hash: file.hash // Using our extension property
          )
        }
      case .failure(let error):
        throw error
    }
  }
  
  /**
   Deletes a snapshot from a repository
   */
  func deleteSnapshot(
    id: String,
    fromRepository repositoryID: String
  ) async throws {
    // Get the snapshot
    let snapshot = try await getSnapshot(id: id, fromRepository: repositoryID)
    
    // Delete it
    return try await deleteSnapshot(
      id: snapshot.id,
      fromRepository: repositoryID
    )
  }
  
  /**
   Restores files from a snapshot
   */
  func restoreFromSnapshot(
    id: String,
    fromRepository repositoryID: String,
    config: RestoreConfig
  ) async throws -> RestoreResultDTO {
    // Get the snapshot
    let snapshot = try await getSnapshot(id: id, fromRepository: repositoryID)
    
    // Start restore
    // This method would be implemented to handle restore operations
    let restoreResult = RestoreResult(
      snapshotID: id,
      restoreTime: Date(),
      totalSize: 0,
      fileCount: 0,
      duration: 0.0,
      targetPath: config.targetDirectory,
      filesRestored: config.paths.count
    )
    
    return restoreResult
  }
  
  /**
   Forgets a snapshot without necessarily deleting its data
   */
  func forgetSnapshot(
    id: String,
    fromRepository repositoryID: String,
    keepData: Bool
  ) async throws {
    // Get the snapshot
    let snapshot = try await getSnapshot(id: id, fromRepository: repositoryID)
    
    // Forget it
    return try await forgetSnapshot(
      id: snapshot.id,
      fromRepository: repositoryID,
      keepData: keepData
    )
  }
  
  private func updateTags(for snapshotID: String, tags: [String]) async -> Result<Bool, Error> {
    // This would be implemented in the real service
    return .success(true)
  }
  
  private func updateMetadata(for snapshotID: String, metadata: [String: String]) async -> Result<Bool, Error> {
    // This would be implemented in the real service
    return .success(true)
  }
  
  private func getFiles(for snapshotID: String) async -> Result<[SnapshotFile], Error> {
    // This would be implemented in the real service
    return .success([])
  }
}

/**
 Configuration for creating a snapshot
 */
public struct SnapshotCreationConfig: Sendable {
  public let paths: [String]
  public let tags: [String]
  public let metadata: [String: SendableValue]?
  
  public init(
    paths: [String],
    tags: [String] = [],
    metadata: [String: SendableValue]? = nil
  ) {
    self.paths = paths
    self.tags = tags
    self.metadata = metadata
  }
}

/**
 DTO for snapshot data transfer
 */
public typealias SnapshotDTO = BackupSnapshot

/**
 DTO for restore result data transfer
 */
public typealias RestoreResultDTO = RestoreResult
