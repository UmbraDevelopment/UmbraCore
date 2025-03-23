// Standard modules
import Foundation

// Internal modules
import ErrorHandlingDomains
import RepositoriesTypes
import UmbraLogging

/// Extension for repository health check functionality
extension RepositoryService {
  // MARK: - Health Check Types

  /// Options for repository health checks
  public struct HealthCheckOptions: Sendable {
    /// Whether to verify the actual data blobs
    public let readData: Bool

    /// Whether to check for unused data
    public let checkUnused: Bool

    public init(readData: Bool, checkUnused: Bool) {
      self.readData=readData
      self.checkUnused=checkUnused
    }

    /// Default options with basic integrity check
    public static let basic=HealthCheckOptions(
      readData: false,
      checkUnused: false
    )

    /// Full verification including data blobs
    public static let full=HealthCheckOptions(
      readData: true,
      checkUnused: true
    )
  }

  // MARK: - Health Check Operations

  /// Performs a health check on a specific repository.
  ///
  /// - Parameters:
  ///   - identifier: The identifier of the repository to check
  ///   - options: Health check options controlling the verification level
  /// - Throws: `UmbraErrors.Repository.Core.repositoryNotFound` if the repository is not
  /// found,
  ///           `UmbraErrors.Repository.Core.internalError` if the check fails
  public func checkHealth(
    of identifier: String,
    options: HealthCheckOptions = .basic
  ) async throws {
    let metadata=LogMetadata([
      "repository_id": identifier,
      "read_data": String(options.readData),
      "check_unused": String(options.checkUnused)
    ])

    await logger.info("Starting repository health check", metadata: metadata)

    guard let repository=repositories[identifier] else {
      await logger.error("Repository not found", metadata: metadata)
      throw UmbraErrors.Repository.Core.repositoryNotFound(resource: identifier)
    }

    do {
      _=try await repository.check(
        readData: options.readData,
        checkUnused: options.checkUnused
      )
      await logger.info(
        "Repository health check completed successfully",
        metadata: metadata
      )
    } catch {
      await logger.error(
        "Repository health check failed: \(error.localizedDescription)",
        metadata: metadata
      )
      throw UmbraErrors.Repository.Core.internalError(
        reason: "Health check failed: \(error.localizedDescription)"
      )
    }
  }

  /// Performs a health check on all registered repositories.
  ///
  /// - Parameters:
  ///   - options: Health check options controlling the verification level
  ///   - force: If true, continue checking other repositories even if some fail
  /// - Throws: `UmbraErrors.Repository.Core.internalError` if any repository check fails
  /// and force is false
  public func checkHealthAll(
    options: HealthCheckOptions = .basic,
    force: Bool=false
  ) async throws {
    let metadata=LogMetadata([
      "repository_count": String(repositories.count),
      "read_data": String(options.readData),
      "check_unused": String(options.checkUnused),
      "force": String(force)
    ])

    await logger.info(
      "Starting health check for all repositories",
      metadata: metadata
    )

    var errors: [String: Error]=[:]

    for (identifier, repository) in repositories {
      let repoMetadata=LogMetadata([
        "repository_id": identifier
      ])

      do {
        _=try await repository.check(
          readData: options.readData,
          checkUnused: options.checkUnused
        )
        await logger.info(
          "Health check completed for repository",
          metadata: repoMetadata
        )
      } catch {
        errors[identifier]=error
        await logger.error(
          "Health check failed for repository: \(error.localizedDescription)",
          metadata: repoMetadata
        )
        if !force {
          throw UmbraErrors.Repository.Core.internalError(
            reason: "Health check failed for repository '\(identifier)': \(error.localizedDescription)"
          )
        }
      }
    }

    if !errors.isEmpty {
      let errorSummary=errors.map {
        "'\($0)': \($1.localizedDescription)"
      }.joined(separator: ", ")

      throw UmbraErrors.Repository.Core.internalError(
        reason: "Health checks failed for repositories: \(errorSummary)"
      )
    }

    await logger.info(
      "Health check completed for all repositories",
      metadata: metadata
    )
  }
}
