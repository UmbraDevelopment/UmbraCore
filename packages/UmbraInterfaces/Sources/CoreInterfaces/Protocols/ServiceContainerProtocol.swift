import Foundation
import UmbraErrors

/// Protocol for a service container that manages service dependencies
public protocol ServiceContainerProtocol: Sendable {
  /// Resolves a service by type
  /// - Parameter type: The type of service to resolve
  /// - Returns: Instance of the requested service
  /// - Throws: CoreError if service not found or cannot be instantiated
  func resolve<T>(_ type: T.Type) async throws -> T

  /// Registers a factory for creating service instances
  /// - Parameters:
  ///   - type: The service type
  ///   - factory: Factory closure for creating service instances
  func register<T>(_ type: T.Type, factory: @escaping () async throws -> T)

  /// Registers a singleton instance of a service
  /// - Parameters:
  ///   - type: The service type
  ///   - instance: The singleton instance
  func registerSingleton<T>(_ type: T.Type, instance: T)
}
