import SecurityTypes
import XCTest

/// Base class for tests that need to simulate sandbox behavior
open class SandboxTestCase: XCTestCase {
  /// Mock file manager for simulating sandbox operations
  var mockFileManager: MockFileManager!

  /// Temporary directory for test files
  private var tempDirectory: URL!

  /// Set up sandbox test environment
  open override func setUp() async throws {
    try await super.setUp()

    // Create temporary directory
    tempDirectory=FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)

    // Initialize mock file manager
    mockFileManager=MockFileManager()

    // Use the real FileManager to create the directory
    try FileManager.default.createDirectory(
      at: tempDirectory,
      withIntermediateDirectories: true,
      attributes: nil
    )
  }

  /// Clean up sandbox test environment
  open override func tearDown() async throws {
    // Clean up temporary directory
    try? FileManager.default.removeItem(at: tempDirectory)
    tempDirectory=nil
    mockFileManager=nil

    try await super.tearDown()
  }

  // MARK: - Helper Methods

  /// Create a test file in the sandbox with specified content
  /// - Parameters:
  ///   - name: Name of the file
  ///   - content: Content to write to the file
  ///   - access: Access permissions to set
  /// - Returns: URL to the created file
  public func createTestFile(
    named name: String,
    content: String,
    access: FilePermission = .readWrite
  ) -> URL {
    let fileURL=tempDirectory.appendingPathComponent(name)
    mockFileManager.simulateSetFileContent(content, at: fileURL)
    _=mockFileManager.simulateSetAccess(access, for: fileURL)
    return fileURL
  }

  /// Create a directory for testing
  public func createDirectory(
    name: String,
    access: FilePermission = .readWrite
  ) throws -> URL {
    let dirURL=tempDirectory.appendingPathComponent(name)

    // Use the real FileManager to create the directory
    try FileManager.default.createDirectory(
      at: dirURL,
      withIntermediateDirectories: true,
      attributes: nil
    )

    // Set access via the mock manager
    _=mockFileManager.simulateSetAccess(access, for: dirURL)
    return dirURL
  }
}
