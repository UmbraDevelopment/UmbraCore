import SecurityCoreAdapters
import SecurityProtocolsCore
import UmbraCoreTypes

/// UmbraSecurityCore
///
/// Main entry point for the UmbraSecurityCore module.
/// This module provides foundation-free security implementations that can be used
/// across all UmbraCore components without introducing circular dependencies.
///
/// All types in this module are foundation-free, meaning they have no
/// dependencies on Foundation or other system frameworks. This allows the module
/// to be used at any level of the dependency graph.
public enum UmbraSecurityCore {
  /// Current module version
  public static let version = "1.0.0"

  /// Create a default foundation-free crypto service
  /// - Returns: A CryptoServiceProtocol implementation
  public static func createDefaultCryptoService() -> CryptoServiceProtocol {
    DefaultCryptoService()
  }

  /// Create a type-erased crypto service wrapper
  /// - Parameter service: The service to wrap
  /// - Returns: A type-erased wrapper around the provided service
  public static func createAnyCryptoService(_ service: some CryptoServiceProtocol & Sendable)
  -> AnyCryptoService {
    SecurityCoreAdapters.createAnyCryptoService(service)
  }

  /// Create a crypto service type adapter with custom transformations
  /// - Parameters:
  ///   - service: The service to adapt
  ///   - transformations: Custom transformations to apply
  /// - Returns: An adapter that applies the specified transformations
  public static func createCryptoServiceAdapter<T: CryptoServiceProtocol & Sendable>(
    _ service: T,
    transformations: CryptoServiceTypeAdapter<T>.Transformations = CryptoServiceTypeAdapter<T>
      .Transformations()
  ) -> CryptoServiceTypeAdapter<T> {
    SecurityCoreAdapters.createCryptoServiceAdapter(
      service: service,
      transformations: transformations
    )
  }
}
