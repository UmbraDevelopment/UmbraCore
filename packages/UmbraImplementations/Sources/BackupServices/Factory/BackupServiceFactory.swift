import BackupInterfaces
import Foundation
import LoggingInterfaces
import ResticInterfaces
import ResticServices

/// Factory for creating backup-related services
///
/// This factory provides methods for creating properly configured
/// backup and snapshot services with appropriate dependencies.
public struct BackupServiceFactory {
  /// Creates a new backup service factory
  public init() {}

  /// Creates a new backup service with the specified dependencies
  /// - Parameters:
  ///   - resticService: The Restic service to use for backend operations
  ///   - logger: Logger for operation tracking
  ///   - repositoryInfo: Repository information
  /// - Returns: A configured backup service
  public func createBackupService(
    resticService: ResticServiceProtocol,
    logger: any LoggingProtocol,
    repositoryInfo: RepositoryInfo
  ) -> BackupServiceProtocol {
    ModernBackupServiceImpl(
      resticService: resticService,
      logger: logger,
      repositoryInfo: repositoryInfo
    )
  }

  /// Creates a new snapshot service with the specified dependencies
  /// - Parameters:
  ///   - resticService: The Restic service to use for backend operations
  ///   - logger: Logger for operation tracking
  /// - Returns: A configured snapshot service following the Alpha Dot Five architecture
  public func createSnapshotService(
    resticService: ResticServiceProtocol,
    logger: any LoggingProtocol
  ) -> SnapshotServiceProtocol {
    ModernSnapshotServiceImpl(
      resticService: resticService,
      logger: logger
    )
  }

  /// Creates a new backup service using the Restic service factory
  /// - Parameters:
  ///   - resticServiceFactory: Factory for creating Restic services
  ///   - logger: Logger for operation tracking
  ///   - repositoryPath: Path to the repository
  ///   - repositoryPassword: Optional repository password
  /// - Returns: A configured backup service
  /// - Throws: Error if Restic service creation fails
  public func createBackupService(
    resticServiceFactory: ResticServiceFactory,
    logger: any LoggingProtocol,
    repositoryPath: String,
    repositoryPassword: String?=nil
  ) throws -> BackupServiceProtocol {
    // Create Restic service
    let resticService=try resticServiceFactory.createResticService(
      executablePath: "/usr/local/bin/restic",
      defaultRepository: repositoryPath,
      defaultPassword: repositoryPassword,
      progressDelegate: nil
    )

    // Create repository info
    let repositoryInfo=RepositoryInfo(
      location: repositoryPath,
      id: UUID().uuidString, // This would be obtained from the repository
      password: repositoryPassword
    )

    // Create backup service
    return createBackupService(
      resticService: resticService,
      logger: logger,
      repositoryInfo: repositoryInfo
    )
  }

  /// Creates a new snapshot service using the Restic service factory
  /// - Parameters:
  ///   - resticServiceFactory: Factory for creating Restic services
  ///   - logger: Logger for operation tracking
  ///   - repositoryPath: Path to the repository
  ///   - repositoryPassword: Optional repository password
  /// - Returns: A configured snapshot service
  /// - Throws: Error if Restic service creation fails
  public func createSnapshotService(
    resticServiceFactory: ResticServiceFactory,
    logger: any LoggingProtocol,
    repositoryPath: String,
    repositoryPassword: String?=nil
  ) throws -> SnapshotServiceProtocol {
    // Create Restic service
    let resticService=try resticServiceFactory.createResticService(
      executablePath: "/usr/local/bin/restic",
      defaultRepository: repositoryPath,
      defaultPassword: repositoryPassword,
      progressDelegate: nil
    )

    // Create snapshot service
    return createSnapshotService(
      resticService: resticService,
      logger: logger
    )
  }
}
