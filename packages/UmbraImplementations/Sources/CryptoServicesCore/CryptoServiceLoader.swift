import Foundation
import LoggingInterfaces
import SecurityCoreInterfaces

/// Crypto Service Loader Protocol
///
/// Protocol for components that can create cryptographic service implementations.
/// This protocol defines the interface for service loaders that can instantiate
/// cryptographic services based on specific requirements.
///
/// Service loaders are responsible for creating the correct implementation based on
/// the requested configuration, including secure storage and logging.
public protocol CryptoServiceLoaderProtocol {
  /// Creates a cryptographic service implementation.
  ///
  /// This method should create and configure a service implementation based on the
  /// provided parameters. The implementation may vary based on the platform,
  /// environment, and other factors.
  ///
  /// - Parameters:
  ///   - secureStorage: The secure storage to use with the service
  ///   - logger: Optional logger to use for operations
  ///   - environment: Environment information for configuration
  /// - Returns: A configured crypto service implementation
  static func createService(
    secureStorage: SecureStorageProtocol,
    logger: LoggingProtocol?,
    environment: CryptoServicesCore.CryptoEnvironment
  ) async -> CryptoServiceProtocol
}

/// Dynamic service loader for cryptographic service implementations.
///
/// This actor provides methods to dynamically load cryptographic service implementations
/// from different modules without creating compile-time dependencies. It uses runtime
/// loading to find and instantiate the appropriate implementation.
///
/// The service loader supports loading:
/// - Apple CryptoKit-based implementations
/// - Ring-based cross-platform implementations
///
/// If a requested implementation cannot be loaded, the methods return nil, allowing
/// the caller to fall back to a different implementation.
public actor CryptoServiceLoader {
  /// Shared singleton instance of the CryptoServiceLoader.
  public static let shared=CryptoServiceLoader()

  /// Apple service loader class name
  private let appleServiceLoaderClassName="ApplePlatformCryptoServiceLoader"

  /// Ring service loader class name
  private let ringServiceLoaderClassName="CrossPlatformCryptoServiceLoader"

  /// Private initialiser to enforce singleton pattern
  private init() {}

  /// Loads the Apple CryptoKit-based cryptographic service.
  ///
  /// This method attempts to dynamically load and instantiate an Apple platform
  /// cryptographic service implementation. It uses runtime reflection to avoid
  /// compile-time dependencies on Apple-specific frameworks.
  ///
  /// - Parameters:
  ///   - secureStorage: The secure storage implementation to use
  ///   - logger: Optional logger for tracking operations
  ///   - environment: Environment configuration
  /// - Returns: An Apple-specific cryptographic service implementation, or nil if it couldn't be
  /// loaded
  public func loadAppleService(
    secureStorage: SecureStorageProtocol,
    logger: LoggingProtocol?,
    environment: CryptoServicesCore.CryptoEnvironment
  ) async -> CryptoServiceProtocol? {
    // Log the loading attempt
    await logger?.debug(
      "Attempting to load Apple CryptoKit service",
      context: BaseLogContextDTO(
        domainName: "CryptoService",
        operation: "loadAppleService",
        category: "Security",
        source: "CryptoServiceLoader",
        metadata: LogMetadataDTOCollection()
          .withPublic(key: "environment", value: environment.type.rawValue)
      )
    )

    // Check if we're on an Apple platform
    #if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
      // Try to dynamically load the Apple service loader class
      guard
        let loaderClass=NSClassFromString(
          "CryptoServicesApple.\(appleServiceLoaderClassName)"
        ) as? CryptoServiceLoaderProtocol
          .Type
      else {
        await logger?.error(
          "Failed to load Apple service loader class",
          context: BaseLogContextDTO(
            domainName: "CryptoService",
            operation: "loadAppleService",
            category: "Security",
            source: "CryptoServiceLoader"
          )
        )
        return nil
      }

      // Create the service using the loader
      let service=await loaderClass.createService(
        secureStorage: secureStorage,
        logger: logger,
        environment: environment
      )

      await logger?.debug(
        "Successfully loaded Apple CryptoKit service",
        context: BaseLogContextDTO(
          domainName: "CryptoService",
          operation: "loadAppleService",
          category: "Security",
          source: "CryptoServiceLoader"
        )
      )

      return service
    #else
      // Log that Apple services are not available on this platform
      await logger?.debug(
        "Apple CryptoKit services are not available on this platform",
        context: BaseLogContextDTO(
          domainName: "CryptoService",
          operation: "loadAppleService",
          category: "Security",
          source: "CryptoServiceLoader"
        )
      )

      return nil
    #endif
  }

  /// Loads the Ring-based cross-platform cryptographic service.
  ///
  /// This method attempts to dynamically load and instantiate a Ring-based
  /// cryptographic service implementation. It uses runtime reflection to avoid
  /// compile-time dependencies on Ring-specific frameworks.
  ///
  /// - Parameters:
  ///   - secureStorage: The secure storage implementation to use
  ///   - logger: Optional logger for tracking operations
  ///   - environment: Environment configuration
  /// - Returns: A Ring-based cryptographic service implementation, or nil if it couldn't be loaded
  public func loadRingService(
    secureStorage: SecureStorageProtocol,
    logger: LoggingProtocol?,
    environment: CryptoServicesCore.CryptoEnvironment
  ) async -> CryptoServiceProtocol? {
    // Log the loading attempt
    await logger?.debug(
      "Attempting to load Ring-based cross-platform service",
      context: BaseLogContextDTO(
        domainName: "CryptoService",
        operation: "loadRingService",
        category: "Security",
        source: "CryptoServiceLoader",
        metadata: LogMetadataDTOCollection()
          .withPublic(key: "environment", value: environment.type.rawValue)
      )
    )

    // Try to dynamically load the Ring service loader class
    guard
      let loaderClass=NSClassFromString(
        "CryptoServicesXfn.\(ringServiceLoaderClassName)"
      ) as? CryptoServiceLoaderProtocol
        .Type
    else {
      await logger?.error(
        "Failed to load Ring service loader class",
        context: BaseLogContextDTO(
          domainName: "CryptoService",
          operation: "loadRingService",
          category: "Security",
          source: "CryptoServiceLoader"
        )
      )
      return nil
    }

    // Create the service using the loader
    let service=await loaderClass.createService(
      secureStorage: secureStorage,
      logger: logger,
      environment: environment
    )

    await logger?.debug(
      "Successfully loaded Ring-based cross-platform service",
      context: BaseLogContextDTO(
        domainName: "CryptoService",
        operation: "loadRingService",
        category: "Security",
        source: "CryptoServiceLoader"
      )
    )

    return service
  }
}
