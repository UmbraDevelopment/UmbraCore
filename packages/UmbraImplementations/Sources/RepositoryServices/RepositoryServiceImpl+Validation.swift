import Foundation
import LoggingInterfaces
import LoggingTypes
import RepositoryInterfaces

/// Extension for RepositoryServiceImpl that adds validation functionality
extension RepositoryServiceImpl {
  /// Validates a repository's integrity.
  ///
  /// - Parameter identifier: The repository identifier.
  /// - Returns: `true` if the repository is valid, `false` otherwise.
  /// - Throws: `RepositoryError.notFound` if the repository is not found,
  ///           or other repository errors if validation fails.
  public func validateRepository(identifier: String) async throws -> Bool {
    let metadata=LogMetadata(["repository_id": identifier])

    await logger.info("Validating repository", metadata: metadata)

    guard let repository=repositories[identifier] else {
      await logger.error("Repository not found", metadata: metadata)
      throw RepositoryError.notFound
    }

    do {
      let isValid=try await repository.validate()
      await logger.info("Repository validation result: \(isValid)", metadata: metadata)
      return isValid
    } catch {
      await logger.error(
        "Repository validation error: \(error.localizedDescription)",
        metadata: metadata
      )
      throw RepositoryError.invalidOperation
    }
  }
}
