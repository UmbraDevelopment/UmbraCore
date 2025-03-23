@testable import UmbraKeychainService
import XCTest

final class KeychainServiceTests: XCTestCase {
  private var proxy: (any KeychainXPCProtocol)!

  override func setUp() async throws {
    try await super.setUp()
    proxy = try await MockXPCServiceHelper.getServiceProxy()
  }

  override func tearDown() async throws {
    await MockXPCServiceHelper.reset()
    proxy = nil
    try await super.tearDown()
  }

  func testServiceStartup() async throws {
    XCTAssertNotNil(proxy)
  }

  func testServiceConnection() async throws {
    XCTAssertNotNil(proxy)
  }

  func testAddItem() async throws {
    let testData = Data("test_data".utf8)
    try await proxy.addItem(
      account: "testAccount",
      service: "com.umbracore.tests",
      accessGroup: nil as String?,
      data: testData
    )

    let retrievedData = try await proxy.retrieveItem(
      account: "testAccount",
      service: "com.umbracore.tests",
      accessGroup: nil as String?
    )

    XCTAssertEqual(testData, retrievedData)
  }

  func testRemoveItem() async throws {
    // First add an item
    let testData = Data("test_data".utf8)
    try await proxy.addItem(
      account: "testAccount",
      service: "com.umbracore.tests",
      accessGroup: nil as String?,
      data: testData
    )

    // Then remove it
    try await proxy.removeItem(
      account: "testAccount",
      service: "com.umbracore.tests",
      accessGroup: nil as String?
    )

    // Verify it's gone
    do {
      _ = try await proxy.retrieveItem(
        account: "testAccount",
        service: "com.umbracore.tests",
        accessGroup: nil as String?
      )
      XCTFail("Expected itemNotFound error")
    } catch KeychainError.itemNotFound {
      // Expected error
    }
  }

  func testDuplicateItem() async throws {
    let testData = Data("test_data".utf8)

    // Add item first time
    try await proxy.addItem(
      account: "testAccount",
      service: "com.umbracore.tests",
      accessGroup: nil as String?,
      data: testData
    )

    // Try to add same item again
    do {
      try await proxy.addItem(
        account: "testAccount",
        service: "com.umbracore.tests",
        accessGroup: nil as String?,
        data: testData
      )
      XCTFail("Expected duplicateItem error")
    } catch KeychainError.duplicateItem {
      // Expected error
    }
  }

  func testUpdateItem() async throws {
    let initialData = Data("initial_data".utf8)
    let updatedData = Data("updated_data".utf8)

    // Add initial item
    try await proxy.addItem(
      account: "testAccount",
      service: "com.umbracore.tests",
      accessGroup: nil as String?,
      data: initialData
    )

    // Update item
    try await proxy.updateItem(
      account: "testAccount",
      service: "com.umbracore.tests",
      accessGroup: nil as String?,
      data: updatedData
    )

    // Verify update
    let retrievedData = try await proxy.retrieveItem(
      account: "testAccount",
      service: "com.umbracore.tests",
      accessGroup: nil as String?
    )

    XCTAssertEqual(updatedData, retrievedData)
  }
}
