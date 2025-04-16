import Foundation
import LoggingInterfaces
import PersistenceInterfaces

/**
 Factory for creating persistence provider instances.

 This factory simplifies the creation of appropriate persistence providers
 based on the environment and requirements.
 */
public class PersistenceProviderFactory {
  /**
   Provider type enumeration.
   */
  public enum ProviderType {
    /// Apple-specific provider with sandbox support
    case apple

    /// Cross-platform provider for non-Apple environments
    case crossPlatform

    /// Default provider based on the current platform
    case `default`
  }

  /**
   Creates a new persistence provider.

   - Parameters:
      - type: Type of provider to create
      - databaseURL: URL to the database directory
   - Returns: The created provider
   */
  public static func createProvider(
    type: ProviderType,
    databaseURL: URL
  ) -> PersistenceProviderProtocol {
    switch type {
      case .apple:
        return ApplePersistenceProvider(databaseURL: databaseURL)

      case .crossPlatform:
        return CrossPlatformPersistenceProvider(databaseURL: databaseURL)

      case .default:
        #if os(macOS) || os(iOS) || os(tvOS) || os(watchOS)
          return ApplePersistenceProvider(databaseURL: databaseURL)
        #else
          return CrossPlatformPersistenceProvider(databaseURL: databaseURL)
        #endif
    }
  }

  /**
   Creates a new Restic backup provider.

   - Parameters:
      - repositoryLocation: Location of the Restic repository
      - resticPath: Path to the Restic executable
      - logger: Logger for operation logging
   - Returns: The created Restic provider
   */
  public static func createResticProvider(
    repositoryLocation: String,
    resticPath: String="/usr/local/bin/restic",
    logger: PrivacyAwareLoggingProtocol
  ) -> ResticBackupProvider {
    ResticBackupProvider(
      repositoryLocation: repositoryLocation,
      resticPath: resticPath,
      logger: logger
    )
  }
}
