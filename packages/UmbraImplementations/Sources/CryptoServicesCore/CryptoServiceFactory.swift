import CoreSecurityTypes
import Foundation
import LoggingInterfaces
import SecurityCoreInterfaces

/// Factory for creating CryptoServiceProtocol implementations.
///
/// This factory requires explicit selection of which cryptographic implementation to use,
/// enforcing a clear decision by the developer rather than relying on automatic selection.
/// Each implementation has different characteristics, security properties, and platform
/// compatibility that the developer must consider when making a selection.
///
/// ## Implementation Types
///
/// - `basic`: Default implementation using AES encryption
/// - `ring`: Implementation using Ring cryptography library for cross-platform environments
/// - `appleCryptoKit`: Apple-native implementation using CryptoKit with optimisations
/// - `platform`: Platform-specific implementation (selects best available for current platform)
///
/// ## Usage Examples
///
/// ```swift
/// // Create a factory with explicit service type selection
/// let factory = CryptoServiceFactory(serviceType: .basic)
///
/// // Create a service with the selected implementation
/// let cryptoService = await factory.createService(
///   secureStorage: mySecureStorage,
///   logger: myLogger
/// )
/// ```
///
/// ## Thread Safety
///
/// As an actor, this factory guarantees thread safety when used from multiple
/// concurrent contexts, preventing data races in service creation.
public actor CryptoServiceFactory {
  // MARK: - Properties

  /// The explicitly selected cryptographic service type
  private let serviceType: SecurityProviderType

  // MARK: - Initialisation

  /// Initialises a crypto service factory with the explicitly selected service type.
  ///
  /// - Parameter serviceType: The type of cryptographic service to create (required)
  public init(serviceType: SecurityProviderType) {
    self.serviceType=serviceType
  }

  // MARK: - Service Creation

  /// Creates a crypto service with the selected implementation type.
  ///
  /// - Parameters:
  ///   - secureStorage: Optional secure storage to use
  ///   - logger: Optional logger to use
  ///   - environment: Optional environment configuration
  /// - Returns: A CryptoServiceProtocol implementation of the selected type
  public func createService(
    secureStorage: SecureStorageProtocol?=nil,
    logger: LoggingProtocol?=nil,
    environment: String?=nil
  ) async -> CryptoServiceProtocol {
    // Create the appropriate secure storage if not provided
    let actualSecureStorage: SecureStorageProtocol=if let secureStorage {
      secureStorage
    } else {
      // This comment acknowledges we're deliberately using a deprecated method for testing
      // purposes.
      // We accept the warning as this is explicitly for testing environments.
      createMockSecureStorage()
    }

    // Log the explicitly selected service type
    if let logger {
      let context=BaseLogContextDTO(
        domainName: "CryptoService",
        operation: "createService",
        category: "Security",
        source: "CryptoServiceFactory",
        metadata: LogMetadataDTOCollection()
          .withPublic(key: "serviceType", value: serviceType.rawValue)
          .withPublic(key: "environment", value: environment ?? "production")
      )

      await logger.debug(
        "Creating crypto service with explicit type: \(serviceType.rawValue)",
        context: context
      )
    }

    // Determine environment type from string if provided
    let envType: CryptoServicesCore.CryptoEnvironment
      .EnvironmentType=if let environment=environment?.lowercased()
    {
      if environment.contains("dev") {
        .development
      } else if environment.contains("test") {
        .test
      } else if environment.contains("stag") {
        .staging
      } else {
        .production
      }
    } else {
      .production
    }

    // Create appropriate environment configuration
    let cryptoEnvironment=CryptoServicesCore.CryptoEnvironment(
      type: envType,
      hasHardwareSecurity: false,
      isLoggingEnhanced: logger != nil,
      platformIdentifier: "standard",
      parameters: [:]
    )

    // Create the actual implementation based on the selected type
    switch serviceType {
      case .basic:
        // Use a protocol-compliant standard implementation for basic type
        return StandardCryptoServiceProxy(
          secureStorage: actualSecureStorage,
          logger: logger,
          environment: cryptoEnvironment
        )
      case .appleCryptoKit:
        // Use the Apple-native implementation
        // This is loaded dynamically to avoid compile-time dependencies on Apple platforms
        if
          let service=await CryptoServiceLoader.shared.loadAppleService(
            secureStorage: actualSecureStorage,
            logger: logger,
            environment: cryptoEnvironment
          )
        {
          return service
        } else {
          // Fallback to standard implementation if Apple service couldn't be loaded
          return StandardCryptoServiceProxy(
            secureStorage: actualSecureStorage,
            logger: logger,
            environment: cryptoEnvironment
          )
        }
      case .ring:
        // Use the Ring-based cross-platform implementation
        // This is loaded dynamically to avoid compile-time dependencies on Ring
        if
          let service=await CryptoServiceLoader.shared.loadRingService(
            secureStorage: actualSecureStorage,
            logger: logger,
            environment: cryptoEnvironment
          )
        {
          return service
        } else {
          // Fallback to standard implementation if Ring service couldn't be loaded
          return StandardCryptoServiceProxy(
            secureStorage: actualSecureStorage,
            logger: logger,
            environment: cryptoEnvironment
          )
        }
      case .platform:
        // Automatically select the best implementation for the current platform
        // This will prioritise Apple CryptoKit on Apple platforms and Ring elsewhere
        #if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
          if
            let service=await CryptoServiceLoader.shared.loadAppleService(
              secureStorage: actualSecureStorage,
              logger: logger,
              environment: cryptoEnvironment
            )
          {
            return service
          }
        #endif

        // Try Ring implementation as second choice or primary on non-Apple platforms
        if
          let service=await CryptoServiceLoader.shared.loadRingService(
            secureStorage: actualSecureStorage,
            logger: logger,
            environment: cryptoEnvironment
          )
        {
          return service
        }

        // Fallback to standard implementation if others couldn't be loaded
        return StandardCryptoServiceProxy(
          secureStorage: actualSecureStorage,
          logger: logger,
          environment: cryptoEnvironment
        )
      default:
        // For any other types, use the standard implementation as a default
        return StandardCryptoServiceProxy(
          secureStorage: actualSecureStorage,
          logger: logger,
          environment: cryptoEnvironment
        )
    }
  }

  /// Creates a mock secure storage implementation for testing.
  ///
  /// - Returns: A mock secure storage implementation
  @available(*, deprecated, message: "Use only for testing")
  private func createMockSecureStorage() -> SecureStorageProtocol {
    // Create a default mock implementation for testing
    MockSecureStorage(
      behaviour: MockSecureStorage.MockBehaviour(
        shouldSucceed: true,
        logOperations: true
      )
    )
  }
}
