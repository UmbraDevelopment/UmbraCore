import Foundation

/// Core service that manages application-wide functionality
@MainActor
public final class CoreService {
  /// Shared instance
  public static let shared = CoreService()

  /// Service container for managing all services
  private let container: ServiceContainer

  /// Initialize the core service
  public init() {
    container = ServiceContainer()
  }

  /// Initialize all core services
  /// - Throws: ServiceError if initialization fails
  public func initialize() async throws {
    // Initialize crypto service
    let crypto = try await container.resolve(CryptoService.self)
    try await crypto.initialize()

    // Initialize security service
    let security = try await container.resolve(SecurityService.self)
    try await security.initialize()
  }

  /// Get the security service
  /// - Returns: The security service instance
  /// - Throws: ServiceError if service not found
  public func getSecurityService() async throws -> SecurityService {
    try await container.resolve(SecurityService.self)
  }

  /// Get the crypto service
  /// - Returns: The crypto service instance
  /// - Throws: ServiceError if service not found
  public func getCryptoService() async throws -> CryptoService {
    try await container.resolve(CryptoService.self)
  }

  /// Shutdown all services
  public func shutdown() async {
    // Shutdown will be handled by the container
    // in reverse dependency order
  }
}
