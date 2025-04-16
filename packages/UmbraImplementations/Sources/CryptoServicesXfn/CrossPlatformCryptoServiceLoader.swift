import BuildConfig
import CryptoInterfaces
import CryptoServicesCore
import Foundation
import LoggingInterfaces
import SecurityCoreInterfaces

/// A loader for the cross-platform Ring FFI-based crypto service implementation.
///
/// This loader creates instances of the CrossPlatformCryptoService, which provides
/// platform-agnostic cryptographic operations using the Ring cryptography library
/// and Argon2id for key derivation.
public enum CrossPlatformCryptoServiceLoader: CryptoServiceLoader {
  /// Creates a cross-platform crypto service implementation.
  ///
  /// - Parameters:
  ///   - secureStorage: The secure storage to use.
  ///   - logger: Optional logger for recording operations.
  ///   - environment: The environment configuration.
  /// - Returns: A CrossPlatformCryptoService implementation.
  public static func createService(
    secureStorage: SecureStorageProtocol,
    logger: LoggingProtocol?,
    environment: CryptoServicesCore.CryptoEnvironment
  ) async -> CryptoServiceProtocol {
    await CrossPlatformCryptoService(
      secureStorage: secureStorage,
      logger: logger,
      environment: environment
    )
  }
}
