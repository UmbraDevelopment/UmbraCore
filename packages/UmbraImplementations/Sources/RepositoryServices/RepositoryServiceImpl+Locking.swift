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
    // Create repository log context
    let context = RepositoryLogContext(
      repositoryID: identifier,
      operation: "lock"
    )

    await logger.info("Locking repository", context: context)

    guard let repository=repositories[identifier] else {
      await logger.error("Repository not found", context: context)
      throw RepositoryError.notFound
    }

    // Repository is already a RepositoryLockingProtocol by definition
    do {
      try await repository.lock()
      await logger.info("Repository locked successfully", context: context)
    } catch {
      await logger.error("Failed to lock repository: \(error.localizedDescription)", context: context)
      throw RepositoryError.invalidOperation
    }
  }

  /// Unlocks a repository.
  ///
  /// - Parameter identifier: The repository identifier.
  /// - Throws: `RepositoryError.notFound` if the repository is not found,
  ///           or other repository errors if unlocking fails.
  public func unlockRepository(identifier: String) async throws {
    // Create repository log context
    let context = RepositoryLogContext(
      repositoryID: identifier,
      operation: "unlock"
    )

    await logger.info("Unlocking repository", context: context)

    guard let repository=repositories[identifier] else {
      await logger.error("Repository not found", context: context)
      throw RepositoryError.notFound
    }

    // Repository is already a RepositoryLockingProtocol by definition
    do {
      try await repository.unlock()
      await logger.info("Repository unlocked successfully", context: context)
    } catch {
      await logger.error("Failed to unlock repository: \(error.localizedDescription)", context: context)
      throw error
    }
  }
}
