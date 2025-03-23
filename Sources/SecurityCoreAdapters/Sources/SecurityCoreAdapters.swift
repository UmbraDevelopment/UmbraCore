import SecurityProtocolsCore
import UmbraCoreTypes

/// Factory for creating and managing security core adapters
/// This provides a consistent entry point for all adapter functionality
public enum SecurityCoreAdapters {
  /// Create a type-erased wrapper for a crypto service
  /// - Parameter service: The crypto service to wrap
  /// - Returns: A type-erased crypto service
  public static func createAnyCryptoService(_ service: some CryptoServiceProtocol & Sendable)
  -> AnyCryptoService {
    AnyCryptoService(service)
  }

  /// Create a type adapter for a crypto service with custom transformations
  /// - Parameters:
  ///   - service: The crypto service to adapt
  ///   - transformations: Optional transformations for type conversion
  /// - Returns: A type adapter for the crypto service
  public static func createCryptoServiceAdapter<T: CryptoServiceProtocol & Sendable>(
    service: T,
    transformations: CryptoServiceTypeAdapter<T>.Transformations = CryptoServiceTypeAdapter<T>
      .Transformations()
  ) -> CryptoServiceTypeAdapter<T> {
    CryptoServiceTypeAdapter(adaptee: service, transformations: transformations)
  }
}
