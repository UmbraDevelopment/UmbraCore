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
    // Create repository log context with maintenance-specific data
    let context=RepositoryLogContext(
      repositoryID: identifier,
      operation: "maintenance",
      additionalMetadata: [
        "read_data": (String(describing: readData), .public),
        "check_unused": (String(describing: checkUnused), .public)
      ]
    )

    await logger.info("Performing maintenance on repository", context: context)

    guard let repository=repositories[identifier] else {
      await logger.error("Repository not found", context: context)
      throw RepositoryError.notFound
    }

    // Repository is already a RepositoryMaintenanceProtocol by definition
    do {
      let stats=try await repository.check(readData: readData, checkUnused: checkUnused)
      await logger.info("Repository maintenance completed successfully", context: context)
      return stats
    } catch {
      await logger.error(
        "Repository maintenance failed: \(error.localizedDescription)",
        context: context
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
    // Create repository log context
    let context=RepositoryLogContext(
      repositoryID: identifier,
      operation: "repair"
    )

    await logger.info("Repairing repository", context: context)

    guard let repository=repositories[identifier] else {
      await logger.error("Repository not found", context: context)
      throw RepositoryError.notFound
    }

    // Repository is already a RepositoryMaintenanceProtocol by definition
    do {
      let successful=try await repository.repair()
      await logger.info("Repository repair result: \(successful)", context: context)
      return successful
    } catch {
      await logger.error(
        "Repository repair failed: \(error.localizedDescription)",
        context: context
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
    // Create repository log context
    let context=RepositoryLogContext(
      repositoryID: identifier,
      operation: "prune"
    )

    await logger.info("Pruning repository", context: context)

    guard let repository=repositories[identifier] else {
      await logger.error("Repository not found", context: context)
      throw RepositoryError.notFound
    }

    // Repository is already a RepositoryMaintenanceProtocol by definition
    do {
      try await repository.prune()
      await logger.info("Repository pruned successfully", context: context)
    } catch {
      await logger.error(
        "Repository pruning failed: \(error.localizedDescription)",
        context: context
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
    // Create repository log context
    let context=RepositoryLogContext(
      repositoryID: identifier,
      operation: "rebuildIndex"
    )

    await logger.info("Rebuilding repository index", context: context)

    guard let repository=repositories[identifier] else {
      await logger.error("Repository not found", context: context)
      throw RepositoryError.notFound
    }

    // Repository is already a RepositoryMaintenanceProtocol by definition
    do {
      try await repository.rebuildIndex()
      await logger.info("Repository index rebuilt successfully", context: context)
    } catch {
      await logger.error(
        "Repository index rebuild failed: \(error.localizedDescription)",
        context: context
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
    // Create repository log context
    let context=RepositoryLogContext(
      repositoryID: identifier,
      operation: "check"
    )

    await logger.info("Checking repository for errors", context: context)

    guard let repository=repositories[identifier] else {
      await logger.error("Repository not found", context: context)
      throw RepositoryError.notFound
    }

    // Repository is already a RepositoryMaintenanceProtocol by definition
    do {
      _=try await repository.check(readData: true, checkUnused: true)
      await logger.info("Repository check completed successfully", context: context)
    } catch {
      await logger.error("Repository check failed: \(error.localizedDescription)", context: context)
      throw RepositoryError.internalError
    }
  }
}
