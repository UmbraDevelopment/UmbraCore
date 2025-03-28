import Foundation

/// Core repository operations that all repositories must support.
public protocol RepositoryCoreProtocol: Actor {
    /// The unique identifier for this repository.
    var identifier: String { get }

    /// The current operational state of the repository.
    var state: RepositoryState { get }

    /// The filesystem location where this repository is stored.
    var location: URL { get }

    /// Initialises the repository and prepares it for use.
    ///
    /// - Throws: Repository-specific errors if initialisation fails due to filesystem
    ///           permissions, corruption, or other errors.
    func initialise() async throws

    /// Validates the repository structure and integrity.
    ///
    /// - Returns: `true` if the repository is valid, `false` otherwise.
    /// - Throws: Repository-specific errors if validation cannot be completed.
    func validate() async throws -> Bool

    /// Checks if the repository is currently accessible.
    ///
    /// - Returns: `true` if the repository can be accessed, `false` otherwise.
    func isAccessible() async -> Bool
}

/// Protocol for repository locking operations.
public protocol RepositoryLockingProtocol: RepositoryCoreProtocol {
    /// Locks the repository for exclusive access.
    ///
    /// - Throws: Repository-specific errors if the lock cannot be acquired or if
    ///           the repository is in an invalid state.
    func lock() async throws

    /// Releases an exclusive lock on the repository.
    ///
    /// - Throws: Repository-specific errors if the lock cannot be released or if
    ///           the repository is in an invalid state.
    func unlock() async throws
    
    /// Checks if the repository is currently locked
    ///
    /// - Returns: `true` if the repository is locked, `false` otherwise
    func isLocked() async -> Bool
}

/// Protocol for repository statistics.
public protocol RepositoryStats: Sendable {
    /// Number of snapshots in the repository
    var snapshotsCount: Int { get }
    
    /// Total size of the repository in bytes
    var totalSize: Int64 { get }
}

/// Protocol for repository maintenance operations.
public protocol RepositoryMaintenanceProtocol: RepositoryCoreProtocol {
    /// Checks the repository health.
    ///
    /// - Parameters:
    ///   - readData: Whether to read all data during the check
    ///   - checkUnused: Whether to check for unused data
    /// - Returns: Repository statistics
    /// - Throws: Repository-specific errors if the check fails
    func check(readData: Bool, checkUnused: Bool) async throws -> RepositoryStatistics

    /// Repairs any issues found in the repository.
    ///
    /// - Returns: `true` if repairs were successful, `false` if no repairs were needed
    /// - Throws: Repository-specific errors if the repair fails
    func repair() async throws -> Bool

    /// Gets repository statistics.
    ///
    /// - Returns: Repository statistics
    /// - Throws: Repository-specific errors if stats cannot be retrieved
    func getStats() async throws -> RepositoryStatistics

    /// Removes unused data from the repository.
    ///
    /// - Throws: Repository-specific errors if pruning fails or cannot be completed
    func prune() async throws

    /// Rebuilds the repository index.
    ///
    /// - Throws: Repository-specific errors if index rebuilding fails or cannot be completed
    func rebuildIndex() async throws
}

/// Protocol for repository statistics operations.
public protocol RepositoryStatsProviderProtocol: RepositoryCoreProtocol {
    /// Retrieves current statistics about the repository.
    ///
    /// - Returns: A `RepositoryStatistics` object containing current metrics.
    /// - Throws: Repository-specific errors if statistics cannot be gathered.
    func getStats() async throws -> RepositoryStatistics
}

/// A complete repository that implements all repository functionality.
public typealias RepositoryProtocol = RepositoryCoreProtocol & RepositoryLockingProtocol & 
    RepositoryMaintenanceProtocol & RepositoryStatsProviderProtocol
