import ErrorHandlingDomains
import SecurityTypes
@testable import UmbraCore
import UmbraTestKit
import XCTest

@available(macOS 14.0, *)
final class URLSecurityTests: XCTestCase {
  var mockSecurityProvider: MockSecurityProvider!
  var testFileURL: URL!
  var testFileData: String!

  override func setUp() async throws {
    // Create a temporary test file
    let tempDir=FileManager.default.temporaryDirectory
    testFileURL=tempDir.appendingPathComponent("test_file.txt")
    testFileData="Test file content"
    try testFileData.write(to: testFileURL, atomically: true, encoding: .utf8)

    // Initialize mock provider
    mockSecurityProvider=MockSecurityProvider()
  }

  override func tearDown() async throws {
    try? FileManager.default.removeItem(at: testFileURL)
    await mockSecurityProvider.reset()
  }

  nonisolated func testBookmarkCreationAndResolution() async throws {
    let bookmarkData=try await mockSecurityProvider.createBookmark(forPath: testFileURL.path)
    XCTAssertFalse(bookmarkData.isEmpty, "Bookmark data should not be empty")

    let (resolvedPath, isStale)=try await mockSecurityProvider.resolveBookmark(bookmarkData)
    XCTAssertEqual(resolvedPath, testFileURL.path, "Resolved path should match original")
    XCTAssertFalse(isStale, "Bookmark should not be stale")
  }

  nonisolated func testSecurityScopedAccess() async throws {
    try await mockSecurityProvider.withSecurityScopedAccess(
      to: testFileURL.path,
      perform: { @Sendable in
        let content=try String(contentsOf: testFileURL, encoding: .utf8)
        XCTAssertEqual(content, testFileData, "Should be able to read file content")

        let paths=await mockSecurityProvider.getAccessedPaths()
        XCTAssertTrue(
          paths.contains(testFileURL.path),
          "Path should be in accessed paths during operation"
        )
      }
    )

    let paths=await mockSecurityProvider.getAccessedPaths()
    XCTAssertFalse(
      paths.contains(testFileURL.path),
      "Path should not be in accessed paths after operation"
    )
  }

  nonisolated func testInvalidBookmark() async throws {
    let invalidData: [UInt8]=[0xFF, 0xFF, 0xFF, 0xFF] // Invalid UTF-8 sequence

    do {
      _=try await mockSecurityProvider.resolveBookmark(invalidData)
      XCTFail("Should throw error for invalid bookmark data")
    } catch let error as SecurityError {
      guard case .bookmarkResolutionFailed=error else {
        XCTFail("Expected bookmarkResolutionFailed error")
        return
      }
    }
  }

  nonisolated func testBookmarkValidation() async throws {
    let validData=try await mockSecurityProvider.createBookmark(forPath: testFileURL.path)
    let isValidBookmark=try await mockSecurityProvider.validateBookmark(validData)
    XCTAssertTrue(isValidBookmark, "Valid bookmark should pass validation")

    let invalidData: [UInt8]=[0xFF, 0xFF, 0xFF, 0xFF] // Invalid UTF-8 sequence
    let isInvalidBookmark=try await mockSecurityProvider.validateBookmark(invalidData)
    XCTAssertFalse(isInvalidBookmark, "Invalid bookmark should fail validation")
  }
}
