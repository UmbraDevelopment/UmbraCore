import Foundation
import XCTest

open class ResticHelperTestCase: XCTestCase {
  public var mockRepository: MockResticRepository!
  private var tempDirectoryURL: URL!

  open override func setUp() async throws {
    try await super.setUp()

    // Create temporary directory for test files
    tempDirectoryURL=FileManager.default.temporaryDirectory
      .appendingPathComponent(UUID().uuidString)
    try FileManager.default.createDirectory(
      at: tempDirectoryURL,
      withIntermediateDirectories: true
    )

    // Initialize mock repository
    mockRepository=MockResticRepository(
      path: tempDirectoryURL.appendingPathComponent("repo").path,
      password: "test-password-123",
      testFilesPath: tempDirectoryURL.appendingPathComponent("test-files").path,
      cachePath: tempDirectoryURL.appendingPathComponent("cache").path
    )

    // Initialize repository
    try await mockRepository.initialize()
  }

  open override func tearDown() async throws {
    if let tempDirectoryURL {
      try? FileManager.default.removeItem(at: tempDirectoryURL)
    }
    mockRepository=nil
    tempDirectoryURL=nil

    try await super.tearDown()
  }
}
