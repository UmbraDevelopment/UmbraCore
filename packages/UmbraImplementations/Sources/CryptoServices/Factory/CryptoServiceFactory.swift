import CryptoInterfaces
import Foundation
import LoggingInterfaces

/**
 # Crypto Service Factory

 This factory is responsible for creating instances of the CryptoServiceProtocol.
 It follows the factory pattern from the Alpha Dot Five architecture to provide
 clean dependency injection and service creation.

 Usage:
 ```swift
 let cryptoService = CryptoServiceFactory.createDefault()
 ```
 */
public enum CryptoServiceFactory {
  /**
   Creates a default implementation of the CryptoServiceProtocol.

   This factory method returns a new instance of the CryptoServiceImpl actor,
   properly configured for standard cryptographic operations.

   - Returns: A CryptoServiceProtocol implementation
   */
  public static func createDefault() -> any CryptoServiceProtocol {
    CryptoServiceImpl()
  }

  /**
   Creates a mock implementation of the CryptoServiceProtocol for testing.

   This factory method returns a new instance of a mock implementation
   that can be used for testing without relying on actual cryptographic operations.

   - Returns: A mock CryptoServiceProtocol implementation
   */
  public static func createMock() -> any CryptoServiceProtocol {
    MockCryptoService()
  }

  /**
   Creates a logging implementation that wraps another implementation.

   This factory method returns a new instance that adds logging around all
   cryptographic operations performed by the wrapped implementation.

   - Parameter wrapped: The implementation to wrap with logging
   - Parameter logger: The logger to use for logging operations
   - Returns: A logging CryptoServiceProtocol implementation
   */
  public static func createLogging(
    wrapping wrapped: any CryptoServiceProtocol,
    logger: any LoggingProtocol
  ) -> any CryptoServiceProtocol {
    LoggingCryptoService(wrapping: wrapped, logger: logger)
  }

  /**
   Creates a custom configured implementation of the CryptoServiceProtocol.

   This factory method returns a new instance of the CryptoServiceImpl actor,
   configured with the specified options.

   - Parameter options: Configuration options for the crypto service
   - Returns: A customised CryptoServiceProtocol implementation
   */
  public static func create(options: CryptoServiceOptions) -> any CryptoServiceProtocol {
    CryptoServiceImpl(options: options)
  }
}

/**
 Configuration options for the CryptoService implementation.

 These options control the behaviour of the cryptographic operations,
 allowing customisation of security parameters and algorithm choices.
 */
public struct CryptoServiceOptions: Sendable {
  /// Default iteration count for PBKDF2 key derivation
  public let defaultIterations: Int

  /// Preferred key size for AES encryption in bytes
  public let preferredKeySize: Int

  /// Size of initialisation vector in bytes
  public let ivSize: Int

  /// Creates a new CryptoServiceOptions instance with the specified parameters
  ///
  /// - Parameters:
  ///   - defaultIterations: Iteration count for PBKDF2 (default: 10000)
  ///   - preferredKeySize: Preferred key size in bytes (default: 32 for AES-256)
  ///   - ivSize: Size of initialisation vector in bytes (default: 12)
  public init(
    defaultIterations: Int=10000,
    preferredKeySize: Int=32,
    ivSize: Int=12
  ) {
    self.defaultIterations=defaultIterations
    self.preferredKeySize=preferredKeySize
    self.ivSize=ivSize
  }

  /// Default options suitable for most applications
  public static let `default`=CryptoServiceOptions()

  /// High security options with increased iteration count
  public static let highSecurity=CryptoServiceOptions(
    defaultIterations: 100_000,
    preferredKeySize: 32,
    ivSize: 16
  )
}
