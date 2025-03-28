import Foundation

/// Protocol defining operations for managing repositories
public protocol RepositoryServiceProtocol: Actor {
  /// Registers a repository with the service.
  ///
  /// - Parameter repository: The repository to register. Must conform to the `RepositoryProtocol`.
  /// - Throws: Errors if the repository cannot be accessed or if a repository with the same
  ///           identifier already exists.
  func register(_ repository: some RepositoryProtocol) async throws

  /// Unregisters a repository from the service.
  ///
  /// - Parameter identifier: The identifier of the repository to unregister.
  /// - Throws: Errors if the repository doesn't exist or cannot be unregistered.
  func unregister(identifier: String) async throws

  /// Gets a registered repository by its identifier.
  ///
  /// - Parameter identifier: The repository identifier.
  /// - Returns: The repository if found.
  /// - Throws: Errors if the repository is not found.
  func getRepository(identifier: String) async throws -> any RepositoryProtocol

  /// Gets all registered repositories.
  ///
  /// - Returns: Dictionary of repositories keyed by their identifiers.
  func getAllRepositories() async -> [String: any RepositoryProtocol]

  /// Checks if a repository with the given identifier is registered.
  ///
  /// - Parameter identifier: The repository identifier to check.
  /// - Returns: `true` if the repository is registered, `false` otherwise.
  func isRegistered(identifier: String) async -> Bool

  /// Gets statistics for a repository.
  ///
  /// - Parameter identifier: The repository identifier.
  /// - Returns: Repository statistics.
  /// - Throws: Errors if the repository is not found or statistics cannot be retrieved.
  func getStats(for identifier: String) async throws -> RepositoryStatistics

  /// Locks a repository for exclusive access.
  ///
  /// - Parameter identifier: The repository identifier.
  /// - Throws: Errors if the repository is not found or cannot be locked.
  func lockRepository(identifier: String) async throws

  /// Unlocks a repository.
  ///
  /// - Parameter identifier: The repository identifier.
  /// - Throws: Errors if the repository is not found or cannot be unlocked.
  func unlockRepository(identifier: String) async throws

  /// Validates a repository's integrity.
  ///
  /// - Parameter identifier: The repository identifier.
  /// - Returns: `true` if the repository is valid, `false` otherwise.
  /// - Throws: Errors if the repository is not found or validation fails.
  func validateRepository(identifier: String) async throws -> Bool

  /// Performs maintenance on a repository.
  ///
  /// - Parameters:
  ///   - identifier: The repository identifier.
  ///   - readData: Whether to read all data during maintenance.
  ///   - checkUnused: Whether to check for unused data.
  /// - Returns: Repository statistics after maintenance.
  /// - Throws: Errors if the repository is not found or maintenance fails.
  func performMaintenance(
    on identifier: String,
    readData: Bool,
    checkUnused: Bool
  ) async throws -> RepositoryStatistics

  /// Repairs a repository.
  ///
  /// - Parameter identifier: The repository identifier.
  /// - Returns: `true` if repairs were made, `false` if no repairs were needed.
  /// - Throws: Errors if the repository is not found or repair fails.
  func repairRepository(identifier: String) async throws -> Bool

  /// Prunes unused data from a repository.
  ///
  /// - Parameter identifier: The repository identifier.
  /// - Throws: Errors if the repository is not found or pruning fails.
  func pruneRepository(identifier: String) async throws

  /// Rebuilds the index for a repository.
  ///
  /// - Parameter identifier: The repository identifier.
  /// - Throws: Errors if the repository is not found or index rebuilding fails.
  func rebuildRepositoryIndex(identifier: String) async throws

  /// Creates a new repository at the specified location.
  ///
  /// - Parameter url: The URL where the repository should be created.
  /// - Returns: The newly created repository.
  /// - Throws: Errors if creation fails.
  func createRepository(at url: URL) async throws -> any RepositoryProtocol
}
