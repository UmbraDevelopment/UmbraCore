import UmbraErrors
import UmbraErrorsCore
import CoreServicesSecurityTypeAliases
import CoreServicesTypeAliases
import CoreServicesTypes
import CoreTypesInterfaces



import Foundation
import KeyManagementTypes
import ObjCBridgingTypesFoundation
import UmbraCoreTypes
import XPCProtocolsCore

/**
 # Core Service Container

 The service container manages all services in the CoreServices module. It provides
 a central registry for registering, initialising, and resolving services, as well
 as managing dependencies between services.

 Services can be registered with dependencies on other services, and the container
 ensures that dependencies are initialised before dependent services. It also provides
 mechanisms for initialising all registered services, shutting them down, and monitoring
 their states.
 */
public actor ServiceContainer {
  /// Shared instance of the service container
  public static let shared=ServiceContainer()

  /// XPC service for inter-process communication
  public private(set) var xpcService: (any XPCServiceProtocol)?

  /// Registered services keyed by their identifiers.
  private var services: [String: any UmbraService]

  /// Map of service identifiers to their dependencies
  private var dependencyGraph: [String: Set<String>]

  /// Map of service identifiers to their states
  private var serviceStates: [String: ServiceState]

  /// Initialise a new service container
  public init() {
    services=[:]
    dependencyGraph=[:]
    serviceStates=[:]
    xpcService=nil
  }

  /// Set the XPC service for inter-process communication
  /// - Parameter service: The XPC service to use
  public func setXPCService(_ service: any XPCServiceProtocol) {
    xpcService=service
  }

  /// Register a service with the container
  /// - Parameters:
  ///   - service: Service to register
  ///   - dependencies: Optional array of service identifiers that this service depends on
  /// - Throws: ErrorHandlingCore.ServiceError if registration fails.
  public func register<T: UmbraService>(_ service: T, dependencies: [String]=[]) async throws {
    let identifier=T.serviceIdentifier

    guard services[identifier] == nil else {
      throw ErrorHandlingCore.ServiceError.configurationError
    }

    // Store the service and its dependencies
    services[identifier]=service
    dependencyGraph[identifier]=Set(dependencies)

    // Set initial state
    await updateServiceState(identifier, newState: ServiceState.uninitialized)
  }

  /// Resolve a service by type
  /// - Returns: The requested service instance.
  /// - Throws: ErrorHandlingCore.ServiceError if service not found or unusable.
  public func resolve<T: UmbraService>(_: T.Type) async throws -> T {
    let identifier=T.serviceIdentifier

    guard let service=services[identifier] else {
      throw ErrorHandlingCore.ServiceError.initialisationFailed
    }

    guard let typedService=service as? T else {
      throw ErrorHandlingCore.ServiceError.invalidState
    }

    guard await service.isUsable() else {
      throw ErrorHandlingCore.ServiceError.invalidState
    }

    return typedService
  }

  /// Resolve a service by identifier
  /// - Parameter identifier: Unique identifier of the service
  /// - Returns: The requested service
  /// - Throws: ErrorHandlingCore.ServiceError if service not found or unusable
  public func resolveByID(_ identifier: String) async throws -> any UmbraService {
    guard let service=services[identifier] else {
      throw ErrorHandlingCore.ServiceError.initialisationFailed
    }

    guard await service.isUsable() else {
      throw ErrorHandlingCore.ServiceError.invalidState
    }

    return service
  }

  /// Initialise all registered services.
  /// - Throws: ErrorHandlingCore.ServiceError if any service fails to initialise.
  public func initialiseAllServices() async throws {
    let serviceIDs=try topologicalSort()

    // Initialise services in order
    for serviceID in serviceIDs {
      guard let service=services[serviceID] else { continue }
      guard service.state == ServiceState.uninitialized else { continue }

      let initializer: () async throws -> Void={ [weak self] in
        do {
          await self?.updateServiceState(
            serviceID,
            newState: ServiceState.uninitialized
          )
          try await service.initialize()
          await self?.updateServiceState(serviceID, newState: ServiceState.ready)
        } catch {
          await self?.updateServiceState(serviceID, newState: ServiceState.error)
          throw ErrorHandlingCore.ServiceError.initialisationFailed
        }
      }

      try await initializer()
    }
  }

  /// Initialise a specific service by identifier
  /// - Parameter identifier: Service identifier
  /// - Throws: ErrorHandlingCore.ServiceError if initialisation fails
  public func initialiseService(_ identifier: String) async throws {
    guard let service=services[identifier] else {
      throw ErrorHandlingCore.ServiceError.initialisationFailed
    }

    // Don't initialise if already initialised
    guard service.state == ServiceState.uninitialized else {
      return
    }

    // Initialise dependencies first
    for depID in dependencyGraph[identifier] ?? [] {
      try await initialiseService(depID)
    }

    // Initialise the service
    await updateServiceState(identifier, newState: ServiceState.uninitialized)
    do {
      try await service.initialize()
      await updateServiceState(identifier, newState: ServiceState.ready)
    } catch {
      await updateServiceState(identifier, newState: ServiceState.error)
      throw ErrorHandlingCore.ServiceError.initialisationFailed
    }
  }

  /// Shut down all registered services
  public func shutdownAllServices() async {
    // Shut down in reverse topological order (dependencies last)
    let serviceIDs=(try? topologicalSort().reversed()) ?? Array(services.keys)

    for serviceID in serviceIDs {
      guard let service=services[serviceID] else { continue }

      await updateServiceState(serviceID, newState: ServiceState.shuttingDown)
      await service.shutdown()
      await updateServiceState(serviceID, newState: ServiceState.shutdown)
    }
  }

  /// Shut down a specific service by identifier
  /// - Parameter identifier: Service identifier
  public func shutdownService(_ identifier: String) async {
    guard let service=services[identifier] else { return }

    // Shut down service
    await updateServiceState(identifier, newState: ServiceState.shuttingDown)
    await service.shutdown()
    await updateServiceState(identifier, newState: ServiceState.shutdown)
  }

  /// Update the state of a service and notify any observers
  /// - Parameters:
  ///   - identifier: Service identifier
  ///   - newState: New service state
  public func updateServiceState(
    _ identifier: String,
    newState: ServiceState
  ) async {
    guard services[identifier] != nil else { return }

    // Update the state
    serviceStates[identifier]=newState

    // Notify XPC service if available
    if xpcService != nil {
      // The notifyServiceStateChanged method is not available in XPCServiceProtocol
      // Just log the state change for now
      print("Service state changed for \(identifier): \(newState)")
      // In the future, implement proper notification via XPC protocol extension
    }
  }

  // MARK: - Private Methods

  /// Sort services in topological order (dependencies first)
  /// - Returns: Array of service identifiers in dependency order
  /// - Throws: ErrorHandlingCore.ServiceError if circular dependency detected
  private func topologicalSort() throws -> [String] {
    var visited=Set<String>()
    var visiting=Set<String>()
    var sorted=[String]()

    // Visit each service node in the dependency graph
    for serviceID in services.keys {
      if !visited.contains(serviceID) {
        try visit(serviceID, visited: &visited, visiting: &visiting, sorted: &sorted)
      }
    }

    return sorted
  }

  /// Visit a node in the dependency graph for topological sorting
  /// - Parameters:
  ///   - serviceId: Service identifier to visit
  ///   - visited: Set of visited nodes
  ///   - visiting: Set of nodes currently being visited (to detect cycles)
  ///   - sorted: Array of sorted nodes
  /// - Throws: ErrorHandlingCore.ServiceError if circular dependency detected
  private func visit(
    _ serviceID: String,
    visited: inout Set<String>,
    visiting: inout Set<String>,
    sorted: inout [String]
  ) throws {
    // Skip if already visited
    if visited.contains(serviceID) {
      return
    }

    if visiting.contains(serviceID) {
      throw ErrorHandlingCore.ServiceError.dependencyError
    }

    visiting.insert(serviceID)

    let deps=dependencyGraph[serviceID] ?? []
    for depID in deps {
      if !services.keys.contains(depID) {
        throw ErrorHandlingCore.ServiceError.dependencyError
      }
      try visit(depID, visited: &visited, visiting: &visiting, sorted: &sorted)
    }

    visiting.remove(serviceID)
    visited.insert(serviceID)
    sorted.append(serviceID)
  }
}
