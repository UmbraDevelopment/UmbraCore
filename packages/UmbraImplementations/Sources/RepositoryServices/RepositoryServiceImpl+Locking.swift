import Foundation
import LoggingInterfaces
import LoggingTypes
import RepositoryInterfaces

/// Extension for RepositoryServiceImpl that adds locking functionality
extension RepositoryServiceImpl {
  /// Locks a repository for exclusive access.
  ///
  /// - Parameter identifier: The repository identifier.
  /// - Throws: `RepositoryError.notFound` if the repository is not found,
  ///           or other repository errors if locking fails.
  public func lockRepository(identifier: String) async throws {
    let metadata=LogMetadata(["repository_id": identifier])

    await logger.info("Locking repository", metadata: metadata, source: "RepositoryService")

    guard let repository=repositories[identifier] as? RepositoryLockingProtocol else {
      await logger.error("Repository not found or does not support locking", metadata: metadata, source: "RepositoryService")
      throw RepositoryError.notFound
    }

    do {
      try await repository.lock()
      await logger.info("Repository locked successfully", metadata: metadata, source: "RepositoryService")
    } catch {
      await logger.error(
        "Failed to lock repository: \(error.localizedDescription)",
        metadata: metadata,
        source: "RepositoryService"
      )
      throw RepositoryError.invalidOperation
    }
  }

  /// Unlocks a repository.
  ///
  /// - Parameter identifier: The repository identifier.
  /// - Throws: `RepositoryError.notFound` if the repository is not found,
  ///           or other repository errors if unlocking fails.
  public func unlockRepository(identifier: String) async throws {
    let metadata=LogMetadata(["repository_id": identifier])

    await logger.info("Unlocking repository", metadata: metadata, source: "RepositoryService")

    guard let repository=repositories[identifier] as? RepositoryLockingProtocol else {
      await logger.error("Repository not found or does not support locking", metadata: metadata, source: "RepositoryService")
      throw RepositoryError.notFound
    }

    do {
      try await repository.unlock()
      await logger.info("Repository unlocked successfully", metadata: metadata, source: "RepositoryService")
    } catch {
      await logger.error(
        "Failed to unlock repository: \(error.localizedDescription)",
        metadata: metadata,
        source: "RepositoryService"
      )
      throw RepositoryError.invalidOperation
    }
  }
}
