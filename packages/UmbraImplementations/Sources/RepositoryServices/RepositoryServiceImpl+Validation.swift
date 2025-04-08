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
    // Create repository log context
    let context=RepositoryLogContext(
      repositoryID: identifier,
      operation: "validate"
    )

    await logger.info("Validating repository", context: context)

    guard let repository=repositories[identifier] else {
      await logger.error("Repository not found", context: context)
      throw RepositoryError.notFound
    }

    do {
      let isValid=try await repository.validate()
      await logger.info("Repository validation result: \(isValid)", context: context)
      return isValid
    } catch {
      await logger.error(
        "Repository validation error: \(error.localizedDescription)",
        context: context
      )
      throw RepositoryError.invalidOperation
    }
  }
}
