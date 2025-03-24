import CoreTypesInterfaces
@testable import Resources
import ResourcesProtocols
import ResourcesTypes
import XCTest

/// State manager for test resources
private final class TestResourceStateManager: @unchecked Sendable {
  private let queue=DispatchQueue(label: "com.umbra.test.resource.state")
  private var _state: ResourcesProtocols.ResourceState

  init(initialState: ResourcesProtocols.ResourceState = .uninitialized) {
    _state=initialState
  }

  var state: ResourcesProtocols.ResourceState {
    get { queue.sync { _state } }
    set { queue.sync { _state=newValue } }
  }
}

/// Test implementation of BasicManagedResource
private actor TestResource: ResourcesProtocols.BasicManagedResource {
  nonisolated let id: String
  private nonisolated let stateManager: TestResourceStateManager
  nonisolated var state: ResourcesProtocols.ResourceState { stateManager.state }
  static var resourceType: String { "test" }

  private var error: Error?

  init(id: String) {
    self.id=id
    stateManager=TestResourceStateManager(initialState: .uninitialized)
  }

  func setError(_ error: Error) {
    self.error=error
  }

  private func updateState(_ newState: ResourcesProtocols.ResourceState) {
    stateManager.state=newState
  }

  func initialize() async throws {
    updateState(.initializing)
    if let error {
      throw error
    }
    updateState(.ready)
  }

  func acquire() async throws {
    if let error {
      throw error
    }
    updateState(ResourcesProtocols.ResourceState.inUse)
  }

  func release() async throws {
    updateState(ResourcesProtocols.ResourceState.ready)
  }

  func cleanup() async throws {
    updateState(ResourcesProtocols.ResourceState.released)
  }
}

class ResourcePoolTests: XCTestCase {
  func testResourcePoolBasicOperations() async throws {
    let pool=ResourcePool<TestResource>(maxSize: 2)
    let resource1=TestResource(id: "1")
    let resource2=TestResource(id: "2")

    try await pool.add(resource1)
    try await pool.add(resource2)

    let acquired1=try await pool.acquire()
    XCTAssertEqual(acquired1.id, "1")
    let acquired1State=acquired1.state
    XCTAssertEqual(acquired1State, ResourcesProtocols.ResourceState.inUse)

    let acquired2=try await pool.acquire()
    XCTAssertEqual(acquired2.id, "2")
    let acquired2State=acquired2.state
    XCTAssertEqual(acquired2State, ResourcesProtocols.ResourceState.inUse)

    // Release resources
    await pool.release(acquired1)
    let released1State=acquired1.state
    XCTAssertEqual(released1State, ResourcesProtocols.ResourceState.ready)

    await pool.release(acquired2)
    let released2State=acquired2.state
    XCTAssertEqual(released2State, ResourcesProtocols.ResourceState.ready)
  }

  func testResourcePoolMaxSize() async throws {
    let pool=ResourcePool<TestResource>(maxSize: 1)
    let resource1=TestResource(id: "1")
    let resource2=TestResource(id: "2")

    // Add first resource
    try await pool.add(resource1)

    // Try to add second resource, should fail
    do {
      try await pool.add(resource2)
      XCTFail("Expected ResourceError.poolExhausted")
    } catch let error as ResourcesProtocols.ResourceError {
      switch error {
        case .poolExhausted:
          // Expected error
          break
        default:
          XCTFail("Unexpected error: \(error)")
      }
    } catch {
      XCTFail("Unexpected error type: \(error)")
    }
  }

  func testResourceInitializationFailure() async {
    let pool=ResourcePool<TestResource>(maxSize: 1)
    let resource=TestResource(id: "1")
    await resource.setError(ResourcesProtocols.ResourceError.acquisitionFailed("Test error"))

    do {
      try await pool.add(resource)
      XCTFail("Expected ResourceError.acquisitionFailed")
    } catch let error as ResourcesProtocols.ResourceError {
      if case let .acquisitionFailed(message)=error {
        XCTAssertEqual(message, "Test error")
      } else {
        XCTFail("Unexpected error: \(error)")
      }
    } catch {
      XCTFail("Unexpected error type: \(error)")
    }
  }

  func testResourceErrorDescription() {
    let errors: [ResourcesProtocols.ResourceError]=[
      .acquisitionFailed("test"),
      .invalidState("test"),
      .timeout("test"),
      .poolExhausted("test"),
      .cleanupFailed("test")
    ]

    for error in errors {
      XCTAssertFalse(
        error.errorDescription?.isEmpty ?? true,
        "Error description should not be empty"
      )
    }
  }
}
