import Foundation

/// Mock Restic repository for testing
public final class MockResticRepository {
  /// Path to the repository
  public let path: String

  /// Password for the repository
  public let password: String

  /// Path to the cache directory
  public let cachePath: String

  /// Path to test files
  public let testFilesPath: String

  /// Path to restore directory
  public let restorePath: String

  /// Initialize a new mock repository
  public init() throws {
    // Create temporary directories
    let tempDir = FileManager.default.temporaryDirectory
      .appendingPathComponent("restic_tests_\(UUID().uuidString)")

    try FileManager.default.createDirectory(
      at: tempDir,
      withIntermediateDirectories: true
    )

    // Setup paths
    path = tempDir.appendingPathComponent("repo").path
    cachePath = tempDir.appendingPathComponent("cache").path
    testFilesPath = tempDir.appendingPathComponent("files").path
    restorePath = tempDir.appendingPathComponent("restore").path
    password = "test-password"

    // Create directories
    try FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true)
    try FileManager.default.createDirectory(atPath: cachePath, withIntermediateDirectories: true)
    try FileManager.default.createDirectory(
      atPath: testFilesPath,
      withIntermediateDirectories: true
    )
    try FileManager.default.createDirectory(atPath: restorePath, withIntermediateDirectories: true)

    // Initialize repository
    let task = Process()
    task.executableURL = URL(fileURLWithPath: "/opt/homebrew/bin/restic")
    task.arguments = ["init"]
    task.environment = [
      "RESTIC_PASSWORD": password,
      "RESTIC_REPOSITORY": path,
      "RESTIC_CACHE_DIR": cachePath
    ]

    try task.run()
    task.waitUntilExit()

    guard task.terminationStatus == 0 else {
      throw NSError(domain: "ResticTest", code: Int(task.terminationStatus))
    }
  }

  /// Create standard test files for backup testing
  public func createStandardTestFiles() throws {
    let testData = "Test file content"

    // Create a few test files
    for fileIndex in 1...5 {
      let filePath = (testFilesPath as NSString)
        .appendingPathComponent("test_file_\(fileIndex).txt")
      try testData.write(toFile: filePath, atomically: true, encoding: .utf8)
    }

    // Create a subdirectory with files
    let subdir = (testFilesPath as NSString).appendingPathComponent("subdir")
    try FileManager.default.createDirectory(atPath: subdir, withIntermediateDirectories: true)

    for fileIndex in 1...3 {
      let filePath = (subdir as NSString)
        .appendingPathComponent("subdir_file_\(fileIndex).txt")
      try testData.write(toFile: filePath, atomically: true, encoding: .utf8)
    }
  }

  /// Create a larger test dataset
  public func createLargeTestDataset(fileCount: Int) throws {
    let testData = String(repeating: "Large test file content\n", count: 100)

    for fileIndex in 1...fileCount {
      let filePath = (testFilesPath as NSString)
        .appendingPathComponent("large_file_\(fileIndex).txt")
      try testData.write(toFile: filePath, atomically: true, encoding: .utf8)
    }
  }

  /// Clean up test files and directories
  public func cleanup() throws {
    let tempDir = (path as NSString).deletingLastPathComponent
    try FileManager.default.removeItem(atPath: tempDir)
  }
}
