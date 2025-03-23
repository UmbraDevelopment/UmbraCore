import Foundation

public class MockResticRepository {
  public let path: String
  public let password: String
  public let cachePath: String
  public let testFilesPath: String

  public init() throws {
    let uuid=UUID().uuidString
    let baseDir=URL(fileURLWithPath: NSTemporaryDirectory())
      .appendingPathComponent("restic_tests_\(uuid)")
      .path

    // Create repository directory
    let repoPath=URL(fileURLWithPath: baseDir)
      .appendingPathComponent("repo")
      .path
    try FileManager.default.createDirectory(
      atPath: repoPath,
      withIntermediateDirectories: true
    )

    // Create cache directory
    let cachePath=URL(fileURLWithPath: baseDir)
      .appendingPathComponent("cache")
      .path
    try FileManager.default.createDirectory(
      atPath: cachePath,
      withIntermediateDirectories: true
    )

    // Create test files directory
    let testFilesPath=URL(fileURLWithPath: baseDir)
      .appendingPathComponent("files")
      .path
    try FileManager.default.createDirectory(
      atPath: testFilesPath,
      withIntermediateDirectories: true
    )

    path=repoPath
    password="test-password"
    self.cachePath=cachePath
    self.testFilesPath=testFilesPath

    // Initialize repository
    let process=Process()
    process.executableURL=URL(fileURLWithPath: "/opt/homebrew/bin/restic")
    process.arguments=[
      "init",
      "--repo", repoPath,
      "--password", "test-password"
    ]

    let pipe=Pipe()
    process.standardOutput=pipe
    process.standardError=pipe

    try process.run()
    process.waitUntilExit()

    guard process.terminationStatus == 0 else {
      let data=try pipe.fileHandleForReading.readToEnd() ?? Data()
      let output=String(data: data, encoding: .utf8) ?? ""
      throw NSError(
        domain: "MockResticRepository",
        code: Int(process.terminationStatus),
        userInfo: [NSLocalizedDescriptionKey: output]
      )
    }
  }

  deinit {
    try? FileManager.default
      .removeItem(atPath: URL(fileURLWithPath: path).deletingLastPathComponent().path)
  }
}
