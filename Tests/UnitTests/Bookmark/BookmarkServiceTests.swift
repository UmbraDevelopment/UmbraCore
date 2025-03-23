import SecurityTypes
import SecurityUtils
import UmbraBookmarkService
import XCTest

@available(macOS 13.0, *)
@objcMembers
final class BookmarkServiceTests: XCTestCase {
  var bookmarkService: BookmarkService!
  var tempFileURL: URL!

  override func setUp() async throws {
    try await super.setUp()
    bookmarkService = await BookmarkService()

    // Create a temporary file for testing
    let tempDir = FileManager.default.temporaryDirectory
    tempFileURL = tempDir.appendingPathComponent("test_file.txt")
    try "Test content".write(to: tempFileURL, atomically: true, encoding: .utf8)

    // Resolve any symlinks in the path
    tempFileURL = tempFileURL.resolvingSymlinksInPath()
  }

  override func tearDown() async throws {
    try await super.tearDown()
    if let url = tempFileURL {
      try? FileManager.default.removeItem(at: url)
    }
    bookmarkService = nil
    tempFileURL = nil
  }

  func testCreateBookmark() async throws {
    let bookmarkData = try await bookmarkService.createBookmark(for: tempFileURL)
    XCTAssertFalse(bookmarkData.isEmpty)
  }

  func testResolveBookmark() async throws {
    let bookmarkData = try await bookmarkService.createBookmark(for: tempFileURL)
    let (resolvedURL, isStale) = try await bookmarkService.resolveBookmark(bookmarkData)

    // Compare resolved paths
    XCTAssertEqual(resolvedURL.resolvingSymlinksInPath().path, tempFileURL.path)
    XCTAssertFalse(isStale)
  }

  func testStartAccessing() async throws {
    try await bookmarkService.startAccessing(tempFileURL)
    let isAccessing = await bookmarkService.isAccessing(tempFileURL)
    XCTAssertTrue(isAccessing)
  }

  func testStopAccessing() async throws {
    try await bookmarkService.startAccessing(tempFileURL)
    await bookmarkService.stopAccessing(tempFileURL)
    let isAccessing = await bookmarkService.isAccessing(tempFileURL)
    XCTAssertFalse(isAccessing)
  }

  func testInvalidURL() async throws {
    let invalidURL = URL(string: "https://example.com")!
    do {
      _ = try await bookmarkService.createBookmark(for: invalidURL)
      XCTFail("Expected error not thrown")
    } catch let error as BookmarkError {
      if case .invalidBookmarkData = error {
        // Expected error
      } else {
        XCTFail("Unexpected error type: \(error)")
      }
    }
  }

  func testNonexistentFile() async throws {
    let nonexistentURL = FileManager.default.temporaryDirectory
      .appendingPathComponent("nonexistent.txt")
    do {
      _ = try await bookmarkService.createBookmark(for: nonexistentURL)
      XCTFail("Expected error not thrown")
    } catch let error as BookmarkError {
      if case .fileNotFound = error {
        // Expected error
      } else {
        XCTFail("Unexpected error type: \(error)")
      }
    }
  }

  func testBookmarkOperations() async throws {
    // TODO: Implement bookmark operations test
    XCTAssertTrue(true, "Test will be implemented")
  }
}
