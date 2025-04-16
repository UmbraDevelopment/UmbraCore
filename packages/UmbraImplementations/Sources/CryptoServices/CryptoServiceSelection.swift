import BuildConfig
import CryptoInterfaces
import CryptoServicesCore
import Foundation
import LoggingInterfaces
import SecurityCoreInterfaces

/// Primary entry point for creating cryptographic services in UmbraCore.
///
/// This module requires developers to explicitly select which cryptographic implementation
/// to use, based on their specific requirements. Each implementation has different
/// characteristics, security properties, and platform compatibility.
///
/// ## Implementation Types
///
/// - `standard`: Default implementation using AES encryption with Restic integration
/// - `crossPlatform`: Implementation using RingFFI with Argon2id for any environment
/// - `applePlatform`: Apple-native implementation using CryptoKit with optimisations
///
/// ## Selection Process
///
/// Developers must explicitly choose which implementation to use rather than relying
/// on automatic selection. This ensures conscious decision-making about the security
/// characteristics and platform compatibility of the cryptographic implementation.
///
/// ## Usage Example
///
/// ```swift
/// // Create a service with explicit type selection
/// let cryptoService = await CryptoServiceSelection.create(
///     implementationType: .applePlatform,
///     logger: myLogger
/// )
/// ```
public enum CryptoServiceSelection {
  /// Creates a crypto service with the specified implementation type.
  ///
  /// - Parameters:
  ///   - implementationType: The specific implementation to create
  ///   - secureStorage: Optional secure storage implementation
  ///   - logger: Optional logger for operation tracking
  ///   - environment: Optional environment configuration
  /// - Returns: A crypto service implementation of the selected type
  public static func create(
    implementationType: CryptoServiceType,
    secureStorage: SecureStorageProtocol?=nil,
    logger: LoggingProtocol?=nil,
    environment: CryptoServicesCore.CryptoEnvironment?=nil
  ) async -> CryptoServiceProtocol {
    // Call the registry to create the service with the explicit type
    await CryptoServiceRegistry.createService(
      type: implementationType.securityProviderType,
      secureStorage: secureStorage,
      logger: logger,
      environment: environment
    )
  }
}
