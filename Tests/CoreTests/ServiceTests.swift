import Core
import CoreErrors
import CoreServicesTypes
import CoreTypesInterfaces
import ErrorHandling
import Foundation
import ServiceTypes
import XCTest

/// Test cases for the ServiceContainer and UmbraService implementations
final class ServiceTests: XCTestCase {
  // MARK: - Properties

  private var container: MockServiceContainer!

  // MARK: - Test Lifecycle

  override func setUp() async throws {
    container=MockServiceContainer()
  }

  override func tearDown() async throws {
    container=nil
  }

  // MARK: - Tests

  func testServiceRegistration() async throws {
    let service=MockService(container: container)
    try await container.register(service)

    let resolvedService=try await container.resolveService(MockService.serviceIdentifier)
    XCTAssertTrue(
      resolvedService as AnyObject === service as AnyObject,
      "Resolved service should be the same instance that was registered"
    )
  }

  func testServiceInitialization() async throws {
    let service=MockService(container: container)
    try await container.register(service)

    // Check initial state
    let initialState=await service.state
    XCTAssertEqual(initialState, .uninitialized)

    // Initialize service
    try await container.initialiseService(MockService.serviceIdentifier)

    // Check state after initialization
    let finalState=await service.state
    XCTAssertEqual(finalState, .ready)
  }

  func testServiceDependencyResolution() async throws {
    // Create services
    let mainService=MockService(container: container)
    try await container.register(mainService)

    // Initialize main service
    try await container.initialiseService(MockService.serviceIdentifier)

    // Create dependent service after main service is initialized
    let dependentService=MockDependentService(
      container: container,
      dependencyID: MockService.serviceIdentifier
    )
    try await container.register(dependentService)

    // Initialize dependent service
    try await container.initialiseService(MockDependentService.serviceIdentifier)

    // Check states
    let mainState=await mainService.state
    let dependentState=await dependentService.state
    XCTAssertEqual(mainState, .ready)
    XCTAssertEqual(dependentState, .ready)
  }

  func testServiceShutdown() async throws {
    let service=MockService(container: container)
    try await container.register(service)

    // Initialize service
    try await container.initialiseService(MockService.serviceIdentifier)

    // Check state after initialization
    let initState=await service.state
    XCTAssertEqual(initState, .ready)

    // Shutdown service
    try await container.shutdownService(MockService.serviceIdentifier)

    // Check state after shutdown
    let finalState=await service.state
    XCTAssertEqual(finalState, .shutdown)
  }

  func testErrorHandling() async throws {
    // Create a service container
    let container=MockServiceContainer()

    // Create services
    let mockService=MockService(container: container)
    let dependentService=MockDependentService(
      container: container,
      dependencyID: MockService.serviceIdentifier
    )

    // Register services
    try await container.register(mockService)
    try await container.register(dependentService)

    // Try to resolve a non-existent service
    do {
      _=try await container.resolveService("non-existent-service")
      XCTFail("Expected service not found error")
    } catch {
      XCTAssertTrue(
        error.localizedDescription.lowercased().contains("service not found"),
        "Error should mention service not found"
      )
    }

    // Try to initialize the dependent service before its dependency
    do {
      try await container.initialiseService(MockDependentService.serviceIdentifier)
      XCTFail("Expected dependency not ready error")
    } catch {
      XCTAssertTrue(
        error.localizedDescription.lowercased().contains("dependency not ready"),
        "Error should mention dependency not ready"
      )
    }
  }
}

// MARK: - Mock Implementations

/// Mock UmbraService implementation for testing
actor MockService: ServiceTypes.UmbraService {
  static var serviceIdentifier="com.umbracore.service.mock"
  nonisolated let identifier: String=serviceIdentifier
  nonisolated let version: String="1.0.0"

  private nonisolated(unsafe) var _state: CoreServicesTypes.ServiceState = .uninitialized
  nonisolated var state: CoreServicesTypes.ServiceState { _state }

  private weak var container: MockServiceContainer?

  init(container: MockServiceContainer) {
    self.container=container
  }

  func validate() async throws -> Bool {
    if _state != .ready {
      _state = .ready
    }
    return true
  }

  func shutdown() async {
    _state = .shutdown
  }

  func getSomething() async throws -> String {
    guard _state == .ready else {
      throw NSError(
        domain: "ServiceError",
        code: 100,
        userInfo: [NSLocalizedDescriptionKey: "Service not ready"]
      )
    }
    return "Something"
  }
}

/// Mock dependent service that requires another service
actor MockDependentService: ServiceTypes.UmbraService {
  static var serviceIdentifier="com.umbracore.service.dependent.mock"
  nonisolated let identifier: String=serviceIdentifier
  nonisolated let version: String="1.0.0"

  private nonisolated(unsafe) var _state: CoreServicesTypes.ServiceState = .uninitialized
  nonisolated var state: CoreServicesTypes.ServiceState { _state }

  private weak var container: MockServiceContainer?
  private var dependencyID: String

  init(container: MockServiceContainer, dependencyID: String) {
    self.container=container
    self.dependencyID=dependencyID
  }

  func validate() async throws -> Bool {
    // Check dependency is ready
    guard let container else {
      throw NSError(
        domain: "ServiceError",
        code: 100,
        userInfo: [NSLocalizedDescriptionKey: "Container not available"]
      )
    }

    let dependentOn=try await container.resolveService(dependencyID)
    if await (dependentOn as? MockService)?.state != .ready {
      throw NSError(
        domain: "ServiceError",
        code: 101,
        userInfo: [NSLocalizedDescriptionKey: "Dependency not ready"]
      )
    }

    _state = .ready
    return true
  }

  func shutdown() async {
    _state = .shutdown
  }
}

/// Protocol for service container in tests
protocol ServiceContainer {
  func register<T>(_ service: T) async throws where T: ServiceTypes.UmbraService
  func resolveService(_ identifier: String) async throws -> any ServiceTypes.UmbraService
  func initialiseService(_ identifier: String) async throws
  func shutdownService(_ identifier: String) async throws
}

/// Mock service container for testing
actor MockServiceContainer: ServiceContainer {
  var services: [String: Any]=[:]
  var serviceStates: [String: CoreServicesTypes.ServiceState]=[:]

  func register(_ service: some ServiceTypes.UmbraService) async throws {
    services[service.identifier]=service
    if let mockService=service as? MockService {
      serviceStates[service.identifier]=await mockService.state
    } else if let mockDepService=service as? MockDependentService {
      serviceStates[service.identifier]=await mockDepService.state
    } else {
      serviceStates[service.identifier] = .uninitialized
    }
  }

  func resolveService(_ identifier: String) async throws -> any ServiceTypes.UmbraService {
    guard let service=services[identifier] as? any ServiceTypes.UmbraService else {
      throw NSError(
        domain: "ServiceError",
        code: 102,
        userInfo: [NSLocalizedDescriptionKey: "The requested service not found"]
      )
    }
    return service
  }

  func initialiseService(_ identifier: String) async throws {
    guard let service=services[identifier] as? any ServiceTypes.UmbraService else {
      throw CoreErrors.ServiceError.dependencyError
    }

    _=try await service.validate()
    serviceStates[identifier] = .ready
  }

  func shutdownService(_ identifier: String) async throws {
    guard let mockService=services[identifier] as? MockService else {
      throw CoreErrors.ServiceError.dependencyError
    }

    await mockService.shutdown()
    serviceStates[identifier] = .shutdown
  }
}
