import Foundation
import LoggingInterfaces
import LoggingTypes
import RepositoryInterfaces

/// Extension for RepositoryServiceImpl that adds maintenance functionality
extension RepositoryServiceImpl {
  /// Performs maintenance on a repository.
  ///
  /// - Parameters:
  ///   - identifier: The repository identifier.
  ///   - readData: Whether to read all data during maintenance.
  ///   - checkUnused: Whether to check for unused data.
  /// - Returns: Repository statistics after maintenance.
  /// - Throws: `RepositoryError.notFound` if the repository is not found,
  ///           or other repository errors if maintenance fails.
  public func performMaintenance(
    on identifier: String,
    readData: Bool,
    checkUnused: Bool
  ) async throws -> RepositoryStatistics {
    // Create privacy-aware metadata
    var metadata=PrivacyMetadata()
    metadata["repository_id"]=PrivacyMetadataValue(value: identifier, privacy: .public)
    metadata["read_data"]=PrivacyMetadataValue(value: String(describing: readData),
                                               privacy: .public)
    metadata["check_unused"]=PrivacyMetadataValue(value: String(describing: checkUnused),
                                                  privacy: .public)

    await logger.info(
      "Performing maintenance on repository",
      metadata: metadata,
      source: "RepositoryService"
    )

    guard let repository=repositories[identifier] else {
      await logger.error(
        "Repository not found",
        metadata: metadata,
        source: "RepositoryService"
      )
      throw RepositoryError.notFound
    }
    
    // Repository is already a RepositoryMaintenanceProtocol by definition
    do {
      let stats=try await repository.check(readData: readData, checkUnused: checkUnused)
      await logger.info(
        "Repository maintenance completed successfully",
        metadata: metadata,
        source: "RepositoryService"
      )
      return stats
    } catch {
      await logger.error(
        "Repository maintenance failed: \(error.localizedDescription)",
        metadata: metadata,
        source: "RepositoryService"
      )
      throw RepositoryError.internalError
    }
  }

  /// Repairs a repository.
  ///
  /// - Parameter identifier: The repository identifier.
  /// - Returns: `true` if repairs were made, `false` if no repairs were needed.
  /// - Throws: `RepositoryError.notFound` if the repository is not found,
  ///           or other repository errors if repair fails.
  public func repairRepository(identifier: String) async throws -> Bool {
    // Create privacy-aware metadata
    var metadata=PrivacyMetadata()
    metadata["repository_id"]=PrivacyMetadataValue(value: identifier, privacy: .public)

    await logger.info("Repairing repository", metadata: metadata, source: "RepositoryService")

    guard let repository = repositories[identifier] else {
      await logger.error(
        "Repository not found",
        metadata: metadata,
        source: "RepositoryService"
      )
      throw RepositoryError.notFound
    }
    
    // Repository is already a RepositoryMaintenanceProtocol by definition
    do {
      let successful = try await repository.repair()
      await logger.info(
        "Repository repair result: \(successful)",
        metadata: metadata,
        source: "RepositoryService"
      )
      return successful
    } catch {
      await logger.error(
        "Repository repair failed: \(error.localizedDescription)",
        metadata: metadata,
        source: "RepositoryService"
      )
      throw RepositoryError.internalError
    }
  }

  /// Deletes unused data from a repository.
  ///
  /// - Parameter identifier: The repository identifier.
  /// - Throws: `RepositoryError.notFound` if the repository is not found,
  ///           or other repository errors if pruning fails.
  public func pruneRepository(identifier: String) async throws {
    // Create privacy-aware metadata
    var metadata=PrivacyMetadata()
    metadata["repository_id"]=PrivacyMetadataValue(value: identifier, privacy: .public)

    await logger.info(
      "Pruning repository",
      metadata: metadata,
      source: "RepositoryService"
    )

    guard let repository = repositories[identifier] else {
      await logger.error(
        "Repository not found",
        metadata: metadata,
        source: "RepositoryService"
      )
      throw RepositoryError.notFound
    }
    
    // Repository is already a RepositoryMaintenanceProtocol by definition
    do {
      try await repository.prune()
      await logger.info(
        "Repository pruned successfully",
        metadata: metadata,
        source: "RepositoryService"
      )
    } catch {
      await logger.error(
        "Repository pruning failed: \(error.localizedDescription)",
        metadata: metadata,
        source: "RepositoryService"
      )
      throw RepositoryError.internalError
    }
  }

  /// Rebuilds the repository index.
  ///
  /// - Parameter identifier: The repository identifier.
  /// - Throws: `RepositoryError.notFound` if the repository is not found,
  ///           or other repository errors if rebuild fails.
  public func rebuildRepositoryIndex(identifier: String) async throws {
    // Create privacy-aware metadata
    var metadata=PrivacyMetadata()
    metadata["repository_id"]=PrivacyMetadataValue(value: identifier, privacy: .public)

    await logger.info(
      "Rebuilding repository index",
      metadata: metadata,
      source: "RepositoryService"
    )

    guard let repository=repositories[identifier] else {
      await logger.error(
        "Repository not found",
        metadata: metadata,
        source: "RepositoryService"
      )
      throw RepositoryError.notFound
    }
    
    // Repository is already a RepositoryMaintenanceProtocol by definition
    do {
      try await repository.rebuildIndex()
      await logger.info(
        "Repository index rebuilt successfully",
        metadata: metadata,
        source: "RepositoryService"
      )
    } catch {
      await logger.error(
        "Repository index rebuild failed: \(error.localizedDescription)",
        metadata: metadata,
        source: "RepositoryService"
      )
      throw RepositoryError.internalError
    }
  }
  
  /// Checks a repository for errors.
  ///
  /// - Parameter identifier: The repository identifier.
  /// - Throws: `RepositoryError.notFound` if the repository is not found,
  ///           or other repository errors if check fails.
  public func checkRepository(identifier: String) async throws {
    // Create privacy-aware metadata
    var metadata=PrivacyMetadata()
    metadata["repository_id"]=PrivacyMetadataValue(value: identifier, privacy: .public)

    await logger.info("Checking repository for errors", metadata: metadata, source: "RepositoryService")

    guard let repository = repositories[identifier] else {
      await logger.error(
        "Repository not found",
        metadata: metadata,
        source: "RepositoryService"
      )
      throw RepositoryError.notFound
    }
    
    // Repository is already a RepositoryMaintenanceProtocol by definition
    do {
      try await repository.check(readData: true, checkUnused: true)
      await logger.info(
        "Repository check completed successfully",
        metadata: metadata,
        source: "RepositoryService"
      )
    } catch {
      await logger.error(
        "Repository check failed: \(error.localizedDescription)",
        metadata: metadata,
        source: "RepositoryService"
      )
      throw RepositoryError.internalError
    }
  }
}
