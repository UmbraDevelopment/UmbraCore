import CoreInterfaces
import CryptoInterfaces
import Foundation
import SecurityInterfaces

/// Factory for creating core service instances
public enum CoreServiceFactory {
  /// Creates a new instance of the core service
  /// - Returns: Core service implementation
  public static func createCoreService() -> CoreServiceProtocol {
    CoreServiceImpl.shared
  }

  /// Creates a new service container
  /// - Returns: Service container implementation
  public static func createServiceContainer() -> ServiceContainerProtocol {
    ServiceContainerImpl()
  }

  /// Initialises the core framework
  /// - Throws: CoreError if initialisation fails
  public static func initialise() async throws {
    try await CoreServiceImpl.shared.initialise()
  }
}
