import ErrorHandlingDomains
import SecurityTypes
@testable import UmbraCore
import UmbraTestKit
import XCTest

actor CoreService {
  private let securityProvider: SecurityProvider

  init(securityProvider: SecurityProvider) {
    self.securityProvider=securityProvider
  }

  func createBookmark(forPath path: String) async throws -> [UInt8] {
    try await securityProvider.createBookmark(forPath: path)
  }

  func resolveBookmark(_ bookmarkData: [UInt8]) async throws -> (path: String, isStale: Bool) {
    try await securityProvider.resolveBookmark(bookmarkData)
  }

  func saveBookmark(_ bookmarkData: [UInt8], withIdentifier identifier: String) async throws {
    try await securityProvider.saveBookmark(bookmarkData, withIdentifier: identifier)
  }

  func loadBookmark(withIdentifier identifier: String) async throws -> [UInt8] {
    try await securityProvider.loadBookmark(withIdentifier: identifier)
  }

  func deleteBookmark(withIdentifier identifier: String) async throws {
    try await securityProvider.deleteBookmark(withIdentifier: identifier)
  }

  func withSecurityScopedAccess<T: Sendable>(
    to path: String,
    perform operation: @Sendable () async throws -> T
  ) async throws -> T {
    try await securityProvider.withSecurityScopedAccess(to: path, perform: operation)
  }
}

final class CoreServiceTests: XCTestCase {
  var mockSecurityProvider: MockSecurityProvider!
  var coreService: CoreService!

  override func setUp() async throws {
    mockSecurityProvider=MockSecurityProvider()
    coreService=CoreService(securityProvider: mockSecurityProvider)
  }

  override func tearDown() async throws {
    await mockSecurityProvider.reset()
    coreService=nil
  }

  func testBookmarkCreation() async throws {
    let testPath="/test/path"
    let bookmarkData=try await coreService.createBookmark(forPath: testPath)
    XCTAssertFalse(bookmarkData.isEmpty, "Bookmark data should not be empty")
  }

  func testBookmarkResolution() async throws {
    let testPath="/test/path"
    let bookmarkData=try await coreService.createBookmark(forPath: testPath)

    let (resolvedPath, isStale)=try await coreService.resolveBookmark(bookmarkData)
    XCTAssertEqual(resolvedPath, testPath, "Resolved path should match original")
    XCTAssertFalse(isStale, "Bookmark should not be stale")
  }

  func testSecurityScopedAccess() async throws {
    let testPath="/test/path"
    var accessGranted=false

    try await coreService.withSecurityScopedAccess(to: testPath) {
      accessGranted=true
      let paths=await mockSecurityProvider.getAccessedPaths()
      XCTAssertTrue(paths.contains(testPath), "Path should be in accessed paths during operation")
    }

    XCTAssertTrue(accessGranted, "Operation should be executed")
    let paths=await mockSecurityProvider.getAccessedPaths()
    XCTAssertFalse(paths.contains(testPath), "Path should not be in accessed paths after operation")
  }

  func testBookmarkStorage() async throws {
    let testPath="/test/path"
    let identifier="test_bookmark"

    let bookmarkData=try await coreService.createBookmark(forPath: testPath)
    try await coreService.saveBookmark(bookmarkData, withIdentifier: identifier)

    let loadedData=try await coreService.loadBookmark(withIdentifier: identifier)
    XCTAssertEqual(loadedData, bookmarkData, "Loaded bookmark data should match saved data")
  }

  func testBookmarkDeletion() async throws {
    let testPath="/test/path"
    let identifier="test_bookmark"

    let bookmarkData=try await coreService.createBookmark(forPath: testPath)
    try await coreService.saveBookmark(bookmarkData, withIdentifier: identifier)
    try await coreService.deleteBookmark(withIdentifier: identifier)

    do {
      _=try await coreService.loadBookmark(withIdentifier: identifier)
      XCTFail("Should throw error for deleted bookmark")
    } catch {
      XCTAssertTrue(error is SecurityError)
    }
  }
}
