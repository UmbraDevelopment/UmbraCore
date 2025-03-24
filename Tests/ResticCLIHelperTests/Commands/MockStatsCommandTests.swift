import Foundation
@testable import ResticCLIHelper
@testable import ResticCLIHelperCommands
@testable import ResticCLIHelperModels
@testable import ResticCLIHelperTypes
import ResticTypes
import TestKit
import UmbraTestKit
import XCTest

/// Mock tests for the stats command
/// These tests use a mock process executor instead of relying on the actual Restic CLI
final class MockStatsCommandTests: XCTestCase {
  private var processExecutor: ProcessExecutorProtocol!
  private var helper: MockableResticCLIHelper!

  override func setUp() {
    super.setUp()
    processExecutor=MockProcessExecutor()
    helper=MockableResticCLIHelper(
      executablePath: "/mock/path/to/restic",
      processExecutor: processExecutor
    )
  }

  override func tearDown() {
    processExecutor=nil
    helper=nil
    super.tearDown()
  }

  func testStatsCommandBuilder() throws {
    let options=CommonOptions(
      repository: "/tmp/repo",
      password: "test"
    )

    let command=StatsCommand(options: options)
      .mode(.restoreSize)
      .host("test-host")
      .tag("test-tag")
      .path("path1")
      .path("path2")

    // Verify command name and options
    XCTAssertEqual(command.commandName, "stats")
    XCTAssertEqual(command.options.repository, "/tmp/repo")
    XCTAssertEqual(command.options.password, "test")

    // Get all arguments as a single string for easier testing
    let allArguments=command.arguments.joined(separator: " ")

    // Verify all expected arguments are present
    XCTAssertTrue(allArguments.contains("--mode=restore-size"), "Arguments should contain mode")
    XCTAssertTrue(allArguments.contains("--host=test-host"), "Arguments should contain host")
    XCTAssertTrue(allArguments.contains("--tag=test-tag"), "Arguments should contain tag")
    XCTAssertTrue(allArguments.contains("path1"), "Arguments should contain path1")
    XCTAssertTrue(allArguments.contains("path2"), "Arguments should contain path2")
  }

  func testStatsCommandExecution() throws {
    // Configure mock process executor to handle our command types
    let mockExecutor=processExecutor as! MockProcessExecutor

    // Configure mock responses
    let statsJson="""
      {
        "total_size": 1024,
        "total_file_count": 10,
        "total_blob_count": 15,
        "total_uncompressed_size": 2048,
        "compression_ratio": 0.5,
        "compression_progress": 1.0,
        "compression_space_saving": 0.5,
        "snapshots_count": 1
      }
      """
    mockExecutor.configureResult(for: "stats", result: Result<String, Error>.success(statsJson))

    // Mock backup command success for setup
    mockExecutor.configureResult(for: "backup", result: Result<String, Error>.success(
      """
      {
        "message_type": "summary",
        "snapshot_id": "abcdef1234567890"
      }
      """
    ))

    // Set up repository path
    let repoPath="/mock/repo"

    // Create common options
    let commonOptions=CommonOptions(
      repository: repoPath,
      password: "test-password",
      jsonOutput: true
    )

    // First create a mock backup
    let backupCommand=ResticCommandTestHelpers.createTestBackupCommand(
      paths: ["/test/files"],
      options: commonOptions,
      tags: ["test-backup"]
    )

    // Verify that our mock backup command looks correct
    XCTAssertEqual(backupCommand.commandName, "backup")
    XCTAssertEqual(backupCommand.arguments.count, 2) // path + tag
    XCTAssertTrue(backupCommand.arguments.contains("/test/files"))
    XCTAssertTrue(backupCommand.arguments.contains("--tag=test-backup"))

    // Execute the backup command
    let backupOutput=try helper.execute(backupCommand)
    XCTAssertTrue(backupOutput.contains("snapshot_id"), "Backup output should contain snapshot_id")

    // Now run the stats command
    let statsCommand=StatsCommand(options: commonOptions)
      .mode(.restoreSize)
      .tag("test-backup")

    // Execute the stats command
    let statsOutput=try helper.execute(statsCommand)

    // Verify the stats output
    XCTAssertTrue(statsOutput.contains("total_size"), "Stats output should contain total_size")
    XCTAssertTrue(
      statsOutput.contains("compression_ratio"),
      "Stats output should contain compression_ratio"
    )

    // Parse the stats output to verify
    let statsData=Data(statsOutput.utf8)
    let statsInfo=try JSONDecoder().decode(RepositoryStats.self, from: statsData)

    // Verify the stats values
    XCTAssertEqual(statsInfo.totalSize, 1024)
    XCTAssertEqual(statsInfo.totalFileCount, 10)
    XCTAssertEqual(statsInfo.totalBlobCount, 15)
    XCTAssertEqual(statsInfo.compressionRatio, 0.5)
    XCTAssertEqual(statsInfo.snapshotsCount, 1)
  }
}
