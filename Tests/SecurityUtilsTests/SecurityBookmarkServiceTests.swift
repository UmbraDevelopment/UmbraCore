import Foundation
import SecurityTypes
@testable import UmbraSecurityUtils
import XCTest

final class SecurityBookmarkServiceTests: XCTestCase {
  var bookmarkService: SecurityBookmarkService!
  var testFileURL: URL!
  var testFileData: String!
  var testDirectory: URL!

  override func setUp() async throws {
    // Create test directory
    let tempDir=URL(fileURLWithPath: NSTemporaryDirectory())
    testDirectory=tempDir.appendingPathComponent("UmbraSecurityTests", isDirectory: true)
    try FileManager.default.createDirectory(at: testDirectory, withIntermediateDirectories: true)

    // Create test file
    testFileURL=URL(fileURLWithPath: testDirectory.path).appendingPathComponent("test_file.txt")
    testFileData="Test file content"
    try testFileData.write(to: testFileURL, atomically: true, encoding: .utf8)

    // Set file permissions
    try FileManager.default.setAttributes([
      .posixPermissions: 0o644
    ], ofItemAtPath: testFileURL.path)

    // Set up service
    bookmarkService=SecurityBookmarkService()
  }

  override func tearDown() async throws {
    try? FileManager.default.removeItem(at: testDirectory)
    bookmarkService=nil
  }

  func testBookmarkManagement() async throws {
    // Create bookmark
    let bookmarkData=try await bookmarkService.createBookmark(for: testFileURL)
    XCTAssertFalse(bookmarkData.isEmpty)

    // Resolve bookmark
    let (resolvedURL, isStale)=try await bookmarkService.resolveBookmark(bookmarkData)
    XCTAssertEqual(resolvedURL.path, testFileURL.path)
    XCTAssertFalse(isStale)
  }

  func testSecurityScopedAccess() async throws {
    let content=try await bookmarkService.withSecurityScopedAccess(to: testFileURL) {
      try String(contentsOf: testFileURL, encoding: .utf8)
    }
    XCTAssertEqual(content, testFileData)
  }
}
