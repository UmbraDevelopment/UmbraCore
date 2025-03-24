import Foundation
@testable import ResticCLIHelper
@testable import ResticCLIHelperCommands
@testable import ResticCLIHelperModels
@testable import ResticCLIHelperProtocols
@testable import ResticCLIHelperTypes
import ResticTypes
import TestKit
import UmbraTestKit
import XCTest

/// Tests for repository management using mocks
final class MockRepositoryManagementTests: XCTestCase {
  // Mock components
  private var processExecutor: MockProcessExecutor!
  private var helper: MockableResticCLIHelper!

  // Test repositories and paths
  private let sourceRepo="/mock/source/repo"
  private let targetRepo="/mock/target/repo"
  private let sourcePath="/test/source"
  private let targetPath="/test/target"
  private let password="test-password"

  override func setUp() {
    super.setUp()

    // Set up the mock executor and helper
    processExecutor=MockProcessExecutor()
    helper=MockableResticCLIHelper(
      executablePath: "/mock/path/to/restic",
      processExecutor: processExecutor
    )

    // Configure the mock executor to return successful results for commands
    configureSuccessfulCommands()
  }

  override func tearDown() {
    processExecutor=nil
    helper=nil
    super.tearDown()
  }

  // Helper method to set up successful mock responses for all commands
  private func configureSuccessfulCommands() {
    // Init command response
    processExecutor.configureResult(for: "init", result: .success(
      "repository 123456 at /mock/repo initialized"
    ))

    // Check command response
    processExecutor.configureResult(for: "check", result: .success(
      "repository 123456 at /mock/repo is valid"
    ))

    // Backup command response
    processExecutor.configureResult(for: "backup", result: .success(
      """
      {
        "message_type": "summary",
        "files_new": 10,
        "files_changed": 0,
        "files_unmodified": 0,
        "dirs_new": 2,
        "dirs_changed": 0,
        "dirs_unmodified": 0,
        "data_blobs": 5,
        "tree_blobs": 2,
        "data_added": 1024,
        "total_files_processed": 10,
        "total_bytes_processed": 2048,
        "total_duration": 1.5,
        "snapshot_id": "abcdef1234567890"
      }
      """
    ))

    // Snapshot command response
    processExecutor.configureResult(for: "snapshots", result: .success(
      """
      [
        {
          "time": "2025-03-15T12:00:00Z",
          "parent": null,
          "tree": "tree1234",
          "paths": ["/test/source"],
          "hostname": "test-host",
          "id": "abcdef1234567890",
          "short_id": "abcdef"
        }
      ]
      """
    ))

    // Restore command response
    processExecutor.configureResult(for: "restore", result: .success(
      "restoring <Snapshot abcdef1234567890> to /test/target"
    ))

    // Copy command response
    processExecutor.configureResult(for: "copy", result: .success(
      "copying snapshot abcdef1234567890 to target repository"
    ))
  }

  func testInitAndCheck() throws {
    // Create a repository
    let initCommand=InitCommand(
      options: CommonOptions(
        repository: sourceRepo,
        password: password
      )
    )

    let initOutput=try helper.execute(initCommand)
    XCTAssertTrue(
      initOutput.contains("initialized"),
      "Init output should confirm repository was initialized"
    )

    // Check the repository
    let checkCommand=CheckCommand(
      options: CommonOptions(
        repository: sourceRepo,
        password: password
      )
    )

    let checkOutput=try helper.execute(checkCommand)
    XCTAssertTrue(checkOutput.contains("valid"), "Check output should confirm repository is valid")

    // Verify the correct commands were executed
    XCTAssertEqual(processExecutor.executionHistory.count, 2, "Should have executed 2 commands")
    XCTAssertEqual(
      processExecutor.executionHistory[0].arguments[0],
      "init",
      "First command should be init"
    )
    XCTAssertEqual(
      processExecutor.executionHistory[1].arguments[0],
      "check",
      "Second command should be check"
    )
  }

  func testBackupAndRestore() throws {
    // Create common options for the source repository
    let sourceOptions=CommonOptions(
      repository: sourceRepo,
      password: password,
      jsonOutput: true
    )

    // Create a backup using our TestableBackupCommand via the helper
    let backupCommand=ResticCommandTestHelpers.createTestBackupCommand(
      paths: [sourcePath],
      options: sourceOptions,
      tags: ["test-tag"],
      hostname: "test-host"
    )

    // Verify the backup command is constructed correctly
    XCTAssertEqual(backupCommand.commandName, "backup")
    XCTAssertTrue(backupCommand.arguments.contains(sourcePath))
    XCTAssertTrue(backupCommand.arguments.contains("--tag=test-tag"))
    XCTAssertTrue(backupCommand.arguments.contains("--host=test-host"))

    // Execute the backup command
    let backupOutput=try helper.execute(backupCommand)
    XCTAssertTrue(backupOutput.contains("snapshot_id"), "Backup output should contain snapshot_id")

    // List snapshots
    let snapshotCommand=ResticCommandTestHelpers.createTestSnapshotCommand(
      options: sourceOptions,
      operation: .list
    )

    // Execute the snapshot command
    let snapshotOutput=try helper.execute(snapshotCommand)
    XCTAssertTrue(
      snapshotOutput.contains("abcdef1234567890"),
      "Snapshot output should contain the snapshot ID"
    )

    // Parse the snapshot ID (in a real test this would parse the JSON)
    let snapshotID="abcdef1234567890"

    // Restore from the snapshot
    let restoreCommand=RestoreCommand(
      options: sourceOptions,
      snapshotID: snapshotID,
      targetPath: targetPath
    )

    // Execute the restore command
    let restoreOutput=try helper.execute(restoreCommand)
    XCTAssertTrue(restoreOutput.contains("restoring"), "Restore output should contain 'restoring'")

    // Verify the correct commands were executed
    XCTAssertEqual(processExecutor.executionHistory.count, 3, "Should have executed 3 commands")
    XCTAssertEqual(
      processExecutor.executionHistory[0].arguments[0],
      "backup",
      "First command should be backup"
    )
    XCTAssertEqual(
      processExecutor.executionHistory[1].arguments[0],
      "snapshots",
      "Second command should be snapshots"
    )
    XCTAssertEqual(
      processExecutor.executionHistory[2].arguments[0],
      "restore",
      "Third command should be restore"
    )
  }

  func testRepositoryCopy() throws {
    // Create common options for the repositories
    let sourceOptions=CommonOptions(
      repository: sourceRepo,
      password: password,
      jsonOutput: true
    )

    // First create a backup to copy using our helper
    let backupCommand=ResticCommandTestHelpers.createTestBackupCommand(
      paths: ["/test/files"],
      options: sourceOptions,
      tags: ["test-tag"]
    )

    // Verify the backup command is constructed correctly
    XCTAssertEqual(backupCommand.commandName, "backup")
    XCTAssertTrue(backupCommand.arguments.contains("/test/files"))
    XCTAssertTrue(backupCommand.arguments.contains("--tag=test-tag"))

    // Execute the backup command
    let backupOutput=try helper.execute(backupCommand)
    XCTAssertTrue(backupOutput.contains("snapshot_id"), "Backup output should contain snapshot_id")

    // List snapshots
    let snapshotCommand=ResticCommandTestHelpers.createTestSnapshotCommand(
      options: sourceOptions,
      operation: .list
    )

    // Execute the snapshot command
    let snapshotOutput=try helper.execute(snapshotCommand)
    XCTAssertTrue(
      snapshotOutput.contains("abcdef1234567890"),
      "Snapshot output should contain the snapshot ID"
    )

    // Parse the snapshot ID (in a real test this would parse the JSON)
    let snapshotID="abcdef1234567890"

    // Copy the snapshot to another repository
    let copyCommand=CopyCommand(
      options: sourceOptions,
      snapshotIDs: [snapshotID],
      targetRepository: targetRepo,
      targetPassword: password
    )

    // Execute the copy command
    let copyOutput=try helper.execute(copyCommand)
    XCTAssertTrue(copyOutput.contains("copy"), "Copy output should contain 'copy'")

    // Verify the correct commands were executed
    XCTAssertEqual(processExecutor.executionHistory.count, 3, "Should have executed 3 commands")
    XCTAssertEqual(
      processExecutor.executionHistory[0].arguments[0],
      "backup",
      "First command should be backup"
    )
    XCTAssertEqual(
      processExecutor.executionHistory[1].arguments[0],
      "snapshots",
      "Second command should be snapshots"
    )
    XCTAssertEqual(
      processExecutor.executionHistory[2].arguments[0],
      "copy",
      "Third command should be copy"
    )
  }
}
