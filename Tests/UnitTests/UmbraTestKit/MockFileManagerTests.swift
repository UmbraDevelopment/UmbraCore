@testable import UmbraTestKit
import XCTest

final class MockFileManagerTests: XCTestCase {
  private var mockFileManager: MockFileManager!
  private var tempURL: URL!

  override func setUp() async throws {
    try await super.setUp()
    mockFileManager = MockFileManager()
    tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    try mockFileManager.simulateCreateDirectory(at: tempURL, withIntermediateDirectories: true)
  }

  override func tearDown() async throws {
    mockFileManager = nil
    if let tempURL {
      try? FileManager.default.removeItem(at: tempURL)
    }
    tempURL = nil
    try await super.tearDown()
  }

  func testFileCreationAndAccess() async throws {
    // Create test file
    let testContent = "Test content"
    let fileName = "test.txt"
    let fileURL = tempURL.appendingPathComponent(fileName)

    mockFileManager.simulateSetFileContent(testContent, at: fileURL)
    XCTAssertTrue(mockFileManager.simulateSetAccess(.readWrite, for: fileURL))

    // Verify file exists and is readable
    XCTAssertTrue(mockFileManager.simulateFileExists(atPath: fileURL.path))
    XCTAssertTrue(mockFileManager.simulateIsReadableFile(atPath: fileURL.path))

    // Verify content
    if
      let data = try await mockFileManager.simulateContentsAsync(atPath: fileURL.path),
      let content = String(data: data, encoding: .utf8) {
      XCTAssertEqual(content, testContent)
    } else {
      XCTFail("Failed to read file content")
    }
  }

  func testSecurityScopedAccess() async throws {
    // Create a test file in the temp directory
    let fileName = "secure.txt"
    let fileURL = tempURL.appendingPathComponent(fileName)
    let testContent = "Secure content"

    // Set up initial file with no access
    mockFileManager.simulateSetFileContent(testContent, at: fileURL)
    XCTAssertTrue(mockFileManager.simulateSetAccess(.none, for: fileURL))

    // Verify file exists but is not readable initially
    XCTAssertTrue(mockFileManager.simulateFileExists(atPath: fileURL.path))
    XCTAssertFalse(mockFileManager.simulateIsReadableFile(atPath: fileURL.path))

    // Start security-scoped access
    XCTAssertTrue(mockFileManager.simulateStartAccessingSecurityScopedResource(fileURL))

    // Verify we can now read the file
    XCTAssertTrue(mockFileManager.simulateGetAccess(for: fileURL).canRead)

    // Stop access and verify we can no longer read
    mockFileManager.simulateStopAccessingSecurityScopedResource(fileURL)
    XCTAssertFalse(mockFileManager.simulateGetAccess(for: fileURL).canRead)
  }
}
