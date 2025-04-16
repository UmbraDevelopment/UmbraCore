import BuildConfig
import CryptoInterfaces
import CryptoServicesCore
import Foundation
import LoggingInterfaces
import SecurityCoreInterfaces

/// This loader creates the standard cryptographic service implementation.
///
/// StandardCryptoService provides a default implementation of the
/// CryptoServiceProtocol using AES encryption for most platforms.
///
/// This implementation is optimised for compatibility rather than performance, providing
/// general-purpose cryptographic operations using AES for encryption and decryption.
public enum StandardCryptoServiceLoader: CryptoServiceLoader {
  /// Creates a standard crypto service implementation.
  ///
  /// This method instantiates a StandardCryptoService with the specified
  /// dependencies. It's the primary factory method for obtaining an instance
  /// of the standard implementation.
  ///
  /// - Parameters:
  ///   - secureStorage: Secure storage implementation to use
  ///   - logger: Optional logger for operation tracking
  ///   - environment: Environment configuration
  /// - Returns: A crypto service implementation
  public static func createService(
    secureStorage: SecureStorageProtocol,
    logger: LoggingProtocol?,
    environment: CryptoServicesCore.CryptoEnvironment
  ) async -> CryptoServiceProtocol {
    await StandardCryptoService(
      secureStorage: secureStorage,
      logger: logger,
      environment: environment
    )
  }
}
