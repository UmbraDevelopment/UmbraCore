import Core
import CoreErrors
import CoreServicesTypes
import CoreTypesInterfaces
import ErrorHandling
import Foundation
import SecurityTypes
import ServiceTypes
import XCTest

final class SecurityTests: XCTestCase {
  // MARK: - Properties

  private var container: SecurityMockServiceContainer!
  private var service: MockSecurityService!

  // MARK: - Test Lifecycle

  override func setUp() async throws {
    container=SecurityMockServiceContainer()
    service=MockSecurityService(container: container)

    // Register service with container
    try await container.register(service)
  }

  override func tearDown() async throws {
    service=nil
    container=nil
  }

  // MARK: - Tests

  func testServiceInitialization() async throws {
    let initialState=await service.state
    XCTAssertEqual(initialState, CoreServicesTypes.ServiceState.uninitialized)

    try await container.initialiseAll()
    let readyState=await service.state
    XCTAssertEqual(readyState, CoreServicesTypes.ServiceState.ready)
  }

  func testBookmarkOperations() async throws {
    // Initialize service
    try await container.initialiseAll()

    // Test bookmark creation (using mock)
    let testPath="/test/path/file.txt"
    let bookmark=try await service.createBookmark(forPath: testPath)
    XCTAssertFalse(bookmark.isEmpty, "Bookmark data should not be empty")

    // Test bookmark resolution
    let resolvedPath=try await service.resolveBookmark(bookmark)
    XCTAssertEqual(resolvedPath, testPath, "Resolved path should match original path")

    // Test invalid bookmark handling
    do {
      _=try await service.resolveBookmark([])
      XCTFail("Expected error with empty bookmark")
    } catch {
      XCTAssertTrue(
        error.localizedDescription.lowercased().contains("invalid bookmark"),
        "Error should mention invalid bookmark"
      )
    }
  }

  func testSecurityScopedAccess() async throws {
    // Initialize service
    try await container.initialiseAll()

    // Test security-scoped resource access
    let testPath="/test/path/to/secure/file.txt"
    let accessGranted=try await service.verifyAccess(forPath: testPath)
    XCTAssertTrue(accessGranted, "Access should be granted for test path")
  }

  func testBookmarkStorage() async throws {
    let testID="test-bookmark-1"
    let testPath="/test/path/bookmark.txt"

    // Initialise the service
    try await container.initialiseAll()

    // Create and store a bookmark
    let bookmark=try await service.createBookmark(forPath: testPath)
    try await service.storeBookmark(bookmark, withIdentifier: testID)

    // Load the stored bookmark
    let loadedBookmark=try await service.loadBookmark(withIdentifier: testID)
    XCTAssertEqual(loadedBookmark, bookmark, "Loaded bookmark should match original")

    // Try to load a non-existent bookmark
    do {
      _=try await service.loadBookmark(withIdentifier: "non-existent")
      XCTFail("Expected error with non-existent bookmark")
    } catch {
      XCTAssertTrue(
        error.localizedDescription.lowercased().contains("bookmark not found"),
        "Error should mention bookmark not found"
      )
    }
  }

  func testErrorHandling() async throws {
    let initialState=await service.state
    XCTAssertEqual(initialState, .uninitialized)

    // Try operations before service is ready
    do {
      _=try await service.createBookmark(forPath: "/test/path")
      XCTFail("Expected error when service not ready")
    } catch {
      XCTAssertTrue(
        error.localizedDescription.lowercased().contains("service not ready"),
        "Error should mention service not ready"
      )
    }

    // Initialise the service for the invalid path test
    try await container.initialiseAll()

    // Test invalid path handling
    do {
      _=try await service.createBookmark(forPath: "")
      XCTFail("Expected invalid path error")
    } catch {
      XCTAssertTrue(
        error.localizedDescription.lowercased().contains("invalid path"),
        "Error should mention invalid path"
      )
    }
  }
}

// MARK: - Mock Implementations

/// Mock implementation of ServiceContainer for testing
actor SecurityMockServiceContainer {
  var services: [String: Any]=[:]
  var serviceStates: [String: CoreServicesTypes.ServiceState]=[:]

  func register(_ service: any ServiceTypes.UmbraService) async throws {
    services[service.identifier]=service
    serviceStates[service.identifier]=CoreServicesTypes.ServiceState.uninitialized
  }

  func initialiseAll() async throws {
    for serviceID in services.keys {
      serviceStates[serviceID]=CoreServicesTypes.ServiceState.ready
      if let service=services[serviceID] as? any ServiceTypes.UmbraService {
        try await service.validate()
      }
    }
  }

  func initialiseService(_ identifier: String) async throws {
    serviceStates[identifier]=CoreServicesTypes.ServiceState.ready
  }

  func resolve<T>(_: T.Type) async throws -> T where T: ServiceTypes.UmbraService {
    guard let service=services.values.first(where: { $0 is T }) as? T else {
      throw CoreErrors.ServiceError.dependencyError
    }
    return service
  }
}

/// Mock implementation of SecurityService for testing
actor MockSecurityService: ServiceTypes.UmbraService {
  static var serviceIdentifier: String="com.umbracore.security.mock"
  nonisolated let identifier: String=serviceIdentifier
  nonisolated let version: String="1.0.0"

  private nonisolated(unsafe) var _state: CoreServicesTypes.ServiceState = .uninitialized
  nonisolated var state: CoreServicesTypes.ServiceState { _state }

  private weak var container: SecurityMockServiceContainer?
  private var bookmarkStorage: [String: [UInt8]]=[:]

  init(container: SecurityMockServiceContainer) {
    self.container=container
  }

  func validate() async throws -> Bool {
    _state=CoreServicesTypes.ServiceState.ready
    return true
  }

  func shutdown() async {
    _state=CoreServicesTypes.ServiceState.shutdown
  }

  // Security operations
  func resolveBookmarkData(_: [UInt8]) async throws -> URL {
    // Mock implementation to return a temporary file URL
    URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("mock-file")
  }

  func processAccessRequest(for _: URL) async throws -> Bool {
    true
  }

  // Additional methods referenced in tests
  func createBookmark(forPath path: String) async throws -> [UInt8] {
    guard state == .ready else {
      throw NSError(
        domain: "SecurityService",
        code: 100,
        userInfo: [NSLocalizedDescriptionKey: "Service not ready"]
      )
    }

    guard !path.isEmpty else {
      throw NSError(
        domain: "SecurityService",
        code: 101,
        userInfo: [NSLocalizedDescriptionKey: "Invalid path: path cannot be empty"]
      )
    }

    // Mock bookmark creation by returning a simple representation of the path
    return Array(path.utf8)
  }

  func resolveBookmark(_ bookmark: [UInt8]) async throws -> String {
    guard state == .ready else {
      throw NSError(
        domain: "SecurityService",
        code: 100,
        userInfo: [NSLocalizedDescriptionKey: "Service not ready"]
      )
    }

    guard !bookmark.isEmpty else {
      throw NSError(
        domain: "SecurityService",
        code: 101,
        userInfo: [NSLocalizedDescriptionKey: "Invalid bookmark data"]
      )
    }

    // Mock bookmark resolution by converting bytes back to string
    if let path=String(bytes: bookmark, encoding: .utf8) {
      return path
    } else {
      throw NSError(
        domain: "SecurityService",
        code: 101,
        userInfo: [NSLocalizedDescriptionKey: "Invalid bookmark: could not resolve"]
      )
    }
  }

  func storeBookmark(_ bookmark: [UInt8], withIdentifier identifier: String) async throws {
    guard state == .ready else {
      throw NSError(
        domain: "SecurityService",
        code: 100,
        userInfo: [NSLocalizedDescriptionKey: "Service not ready"]
      )
    }

    bookmarkStorage[identifier]=bookmark
  }

  func loadBookmark(withIdentifier identifier: String) async throws -> [UInt8] {
    guard state == .ready else {
      throw NSError(
        domain: "SecurityService",
        code: 100,
        userInfo: [NSLocalizedDescriptionKey: "Service not ready"]
      )
    }

    guard let bookmark=bookmarkStorage[identifier] else {
      throw NSError(
        domain: "SecurityService",
        code: 102,
        userInfo: [NSLocalizedDescriptionKey: "Bookmark not found: \(identifier)"]
      )
    }

    return bookmark
  }

  func verifyAccess(forPath _: String) async throws -> Bool {
    guard state == .ready else {
      throw NSError(
        domain: "SecurityService",
        code: 100,
        userInfo: [NSLocalizedDescriptionKey: "Service not ready"]
      )
    }

    // For testing, always return true
    return true
  }
}
