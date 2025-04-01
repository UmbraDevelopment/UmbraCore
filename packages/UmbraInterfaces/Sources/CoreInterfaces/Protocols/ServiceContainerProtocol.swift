import Foundation
import UmbraErrors

/**
 # Service Container Protocol

 Protocol for a service container that manages service dependencies and facilitates
 dependency injection throughout the application.

 ## Actor-Based Implementation

 Implementations of this protocol MUST use Swift actors to ensure proper
 state isolation and thread safety for service registration and resolution:

 ```swift
 actor ServiceContainerActor: ServiceContainerProtocol {
     // Private state should be isolated within the actor
     private var services: [String: Any] = [:]
     private var factories: [String: () async throws -> Any] = [:]
     private let logger: PrivacyAwareLoggingProtocol

     // All function implementations must use 'await' appropriately when
     // accessing actor-isolated state or calling other actor methods
 }
 ```

 ## Protocol Forwarding

 To support proper protocol conformance while maintaining actor isolation,
 implementations should consider using the protocol forwarding pattern:

 ```swift
 // Public non-actor class that conforms to protocol
 public final class ServiceContainer: ServiceContainerProtocol {
     private let actor: ServiceContainerActor

     // Forward all protocol methods to the actor
     public func resolve<T>(_ type: T.Type) async throws -> T {
         try await actor.resolve(type)
     }
 }
 ```

 ## Type Safety and Registration Lifecycle

 The service container provides a strongly-typed dependency injection mechanism
 with defined lifecycle options for registered services:

 - **Transient**: A new instance is created for each resolution
 - **Scoped**: A new instance is created for each scope
 - **Singleton**: The same instance is used for all resolutions
 */
public protocol ServiceContainerProtocol: Sendable {
  /**
   Resolves a service by type

   - Parameter type: The type of service to resolve
   - Parameter options: Configuration options for resolution
   - Returns: Instance of the requested service
   - Throws: CoreError if service not found or cannot be instantiated
   */
  func resolve<T>(_ type: T.Type, options: ServiceResolutionOptions?) async throws -> T

  /**
   Registers a factory for creating service instances

   - Parameters:
     - type: The service type
     - options: Configuration options for registration
     - factory: Factory closure for creating service instances
   */
  func register<T>(
    _ type: T.Type,
    options: ServiceRegistrationOptions?,
    factory: @escaping () async throws -> T
  )

  /**
   Registers a singleton instance of a service

   - Parameters:
     - type: The service type
     - instance: The singleton instance
     - options: Configuration options for registration
   */
  func registerSingleton<T>(
    _ type: T.Type,
    instance: T,
    options: ServiceRegistrationOptions?
  )

  /**
   Checks if a service is registered

   - Parameter type: The type of service to check
   - Returns: True if the service is registered, false otherwise
   */
  func isRegistered<T>(_ type: T.Type) async -> Bool

  /**
   Removes a registered service

   - Parameter type: The type of service to remove
   - Returns: True if the service was removed, false if it wasn't registered
   */
  func removeRegistration<T>(_ type: T.Type) async -> Bool
}

/// Default implementations for optional methods
extension ServiceContainerProtocol {
  public func resolve<T>(_ type: T.Type) async throws -> T {
    try await resolve(type, options: nil)
  }

  public func register<T>(_ type: T.Type, factory: @escaping () async throws -> T) {
    register(type, options: nil, factory: factory)
  }

  public func registerSingleton<T>(_ type: T.Type, instance: T) {
    registerSingleton(type, instance: instance, options: nil)
  }
}

/**
 Options for service registration.
 */
public struct ServiceRegistrationOptions: Sendable, Equatable {
  /// Standard options for most registrations
  public static let standard=ServiceRegistrationOptions()

  /// Lifecycle of the service
  public enum Lifecycle: String, Sendable, Equatable {
    /// A new instance is created for each resolution
    case transient

    /// A new instance is created for each scope
    case scoped

    /// The same instance is used for all resolutions
    case singleton
  }

  /// Lifecycle of the service
  public let lifecycle: Lifecycle

  /// Whether to override existing registrations
  public let override: Bool

  /// Descriptive name for the service (for debugging)
  public let name: String?

  /// Identifier for grouping related services
  public let groupID: String?

  /// Creates new service registration options
  public init(
    lifecycle: Lifecycle = .transient,
    override: Bool=false,
    name: String?=nil,
    groupID: String?=nil
  ) {
    self.lifecycle=lifecycle
    self.override=override
    self.name=name
    self.groupID=groupID
  }
}

/**
 Options for service resolution.
 */
public struct ServiceResolutionOptions: Sendable, Equatable {
  /// Standard options for most resolutions
  public static let standard=ServiceResolutionOptions()

  /// Whether to attempt to create the service if not registered
  public let autoCreate: Bool

  /// Whether to accept service from parent containers
  public let cascadeFromParent: Bool

  /// Creates new service resolution options
  public init(
    autoCreate: Bool=false,
    cascadeFromParent: Bool=true
  ) {
    self.autoCreate=autoCreate
    self.cascadeFromParent=cascadeFromParent
  }
}
