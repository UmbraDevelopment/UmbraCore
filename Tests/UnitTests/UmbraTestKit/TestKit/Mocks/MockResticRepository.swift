import Foundation
import ResticCLIHelper
#if canImport(System)
  import System
#endif

/// A simple snapshot info structure for mock repository
public struct MockSnapshotInfo {
  public let id: String
  public let time: Date
  public let tree: String
  public let paths: [String]
  public let hostname: String
  public let username: String
  public let parent: String?

  public init(
    id: String,
    time: Date,
    tree: String,
    paths: [String],
    hostname: String,
    username: String,
    parent: String? = nil
  ) {
    self.id = id
    self.time = time
    self.tree = tree
    self.paths = paths
    self.hostname = hostname
    self.username = username
    self.parent = parent
  }
}

/// A mock Restic repository for testing purposes
public final class MockResticRepository {
  /// Repository path
  public let path: String

  /// Repository password
  public let password: String

  /// Cache directory location
  public let cachePath: String

  /// Temporary directory for test files
  public let testFilesPath: String

  /// FileManager instance
  private let fileManager: FileManager

  /// Initialise a new mock repository
  /// - Parameters:
  ///   - path: Path for the repository
  ///   - password: Password for the repository
  ///   - testFilesPath: Path for test files
  ///   - cachePath: Path for cache directory
  ///   - fileManager: FileManager instance to use
  public init(
    path: String,
    password: String,
    testFilesPath: String,
    cachePath: String,
    fileManager: FileManager = .default
  ) {
    self.path = path
    self.password = password
    self.testFilesPath = testFilesPath
    self.cachePath = cachePath
    self.fileManager = fileManager
  }

  /// Create the necessary directory structure
  private func createDirectoryStructure() throws {
    let paths = [path, cachePath, testFilesPath]

    for path in paths {
      try fileManager.createDirectory(
        atPath: path,
        withIntermediateDirectories: true,
        attributes: nil
      )
    }
  }

  /// Create a test file with specified content
  /// - Parameters:
  ///   - name: Name of the file
  ///   - content: Content to write to the file
  ///   - directory: Optional subdirectory within testFilesPath
  /// - Returns: Path to the created file
  @discardableResult
  public func createTestFile(
    name: String,
    content: String,
    inDirectory directory: String? = nil
  ) throws -> String {
    var targetPath = testFilesPath

    if let directory {
      targetPath = (targetPath as NSString).appendingPathComponent(directory)
      try fileManager.createDirectory(
        atPath: targetPath,
        withIntermediateDirectories: true,
        attributes: nil
      )
    }

    let filePath = (targetPath as NSString).appendingPathComponent(name)
    try content.write(toFile: filePath, atomically: true, encoding: .utf8)

    return filePath
  }

  /// Create a directory structure for testing
  /// - Parameter structure: Dictionary representing directory structure
  /// where keys are paths and values are file contents
  public func createDirectoryStructure(_ structure: [String: String]) throws {
    for (path, content) in structure {
      let directory = (path as NSString).deletingLastPathComponent
      try createTestFile(
        name: (path as NSString).lastPathComponent,
        content: content,
        inDirectory: directory
      )
    }
  }

  /// Initialize the repository
  public func initialize() async throws {
    try createDirectoryStructure()

    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/opt/homebrew/bin/restic")
    process.arguments = [
      "init",
      "--repo", path
    ]
    process.environment = [
      "RESTIC_PASSWORD": password,
      "PATH": ProcessInfo.processInfo.environment["PATH"] ?? ""
    ]

    let outputPipe = Pipe()
    let errorPipe = Pipe()
    process.standardOutput = outputPipe
    process.standardError = errorPipe

    try process.run()
    process.waitUntilExit()

    if process.terminationStatus != 0 {
      let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
      let errorMessage = String(data: errorData, encoding: .utf8) ?? "Unknown error"
      throw NSError(
        domain: "ResticError",
        code: Int(process.terminationStatus),
        userInfo: [NSLocalizedDescriptionKey: "Failed to initialize repository: \(errorMessage)"]
      )
    }
  }

  /// Create standard test files for basic testing
  public func createStandardTestFiles() throws {
    try createDirectoryStructure([
      "test1.txt": "This is test file 1",
      "test2.txt": "This is test file 2",
      "docs/doc1.md": "# Test Document 1",
      "docs/doc2.md": "# Test Document 2",
      "config/settings.json": """
        {
            "setting1": "value1",
            "setting2": "value2"
        }
        """
    ])
  }

  /// Create a large test dataset
  /// - Parameter fileCount: Number of test files to create
  public func createLargeTestDataset(fileCount: Int) throws {
    for index in 0..<fileCount {
      try createTestFile(
        name: "large_test_\(index).txt",
        content: """
          Test content for file \(index)
          \(String(repeating: "Additional content to make file larger\n", count: 10))
          """
      )
    }
  }

  /// Clean up test repository and associated files
  public func cleanup() throws {
    let paths = [path, cachePath, testFilesPath]

    for path in paths {
      try? fileManager.removeItem(atPath: path)
    }
  }

  /// Get environment variables for Restic commands
  public var environment: [String: String] {
    [
      "RESTIC_REPOSITORY": path,
      "RESTIC_PASSWORD": password,
      "RESTIC_CACHE_DIR": cachePath
    ]
  }

  /// Generate random snapshots for testing
  /// - Parameter count: Number of snapshots to generate
  /// - Returns: Array of snapshot information
  public func generateRandomSnapshots(count: Int) -> [MockSnapshotInfo] {
    var snapshots: [MockSnapshotInfo] = []
    for snapshotIndex in 0..<count {
      let snapshot = MockSnapshotInfo(
        id: "snapshot_\(snapshotIndex)",
        time: Date(),
        tree: "tree_\(snapshotIndex)",
        paths: ["\(testFilesPath)/file_\(snapshotIndex).txt"],
        hostname: "mock-host",
        username: "mock-user",
        parent: snapshotIndex > 0 ? "snapshot_\(snapshotIndex - 1)" : nil
      )
      snapshots.append(snapshot)
    }
    return snapshots
  }
}
