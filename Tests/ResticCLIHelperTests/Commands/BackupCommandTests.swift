import Foundation
@testable import ResticCLIHelper
@testable import ResticCLIHelperCommands
@testable import ResticCLIHelperTypes
@testable import ResticTypes
import XCTest

/**
 * Tests for the BackupCommand class
 *
 * These tests verify that the BackupCommand properly constructs command arguments
 * and correctly validates inputs according to the requirements.
 */
final class BackupCommandTests: XCTestCase {
  /**
   * Test that the backup command correctly builds command arguments
   * from the provided configuration options.
   */
  func testBackupCommandArguments() {
    // Given
    let options=CommonOptions(repository: "/test/repo", password: "test")

    // When
    let command=BackupCommand(
      paths: ["/path/one"],
      excludes: ["*.tmp"],
      tags: ["daily", "test"],
      options: options
    )
    .withProgress()

    // Then
    let args=command.commandArguments
    XCTAssertTrue(args.contains("/path/one"), "Command should include the backup path")
    XCTAssertTrue(args.contains("--tag"), "Command should include the tag flag")
    XCTAssertTrue(args.contains("daily"), "Command should include the tag value")
    XCTAssertTrue(args.contains("--exclude"), "Command should include exclude flag")
    XCTAssertTrue(args.contains("*.tmp"), "Command should include exclude pattern")
    XCTAssertTrue(args.contains("--json"), "Progress enabled should add JSON flag")
    XCTAssertTrue(args.contains("--verbose"), "Progress enabled should add verbose flag")
  }

  /**
   * Test environment variable setting in the backup command
   */
  func testBackupCommandEnvironment() {
    // Given
    let options=CommonOptions(
      repository: "/test/repo",
      password: "testpassword",
      cachePath: "/test/cache"
    )

    // When
    let command=BackupCommand(paths: ["/path/one"], options: options)
    let env=command.environment

    // Then
    XCTAssertEqual(
      env["RESTIC_REPOSITORY"],
      "/test/repo",
      "Repository should be set in environment"
    )
    XCTAssertEqual(env["RESTIC_PASSWORD"], "testpassword", "Password should be set in environment")
    XCTAssertEqual(
      env["RESTIC_CACHE_DIR"],
      "/test/cache",
      "Cache path should be set in environment"
    )
  }

  /**
   * Test the fluent interface for building backup commands
   */
  func testBackupCommandFluentInterface() {
    // Given
    let options=CommonOptions(repository: "/test/repo", password: "test")

    // When
    let command=BackupCommand(paths: [], options: options)
      .addPath("/path/one")
      .addPath("/path/two")
      .tag("daily")
      .tag("important")
      .exclude("*.log")
      .host("testhost")
      .withProgress()

    // Then
    let args=command.commandArguments
    XCTAssertTrue(args.contains("/path/one"), "Should contain first added path")
    XCTAssertTrue(args.contains("/path/two"), "Should contain second added path")
    XCTAssertTrue(args.contains("daily"), "Should contain first tag")
    XCTAssertTrue(args.contains("important"), "Should contain second tag")
    XCTAssertTrue(args.contains("*.log"), "Should contain exclude pattern")
    XCTAssertTrue(args.contains("testhost"), "Should contain host name")
  }

  /**
   * Test validation with valid inputs passes
   */
  func testBackupCommandValidationWithValidInputs() throws {
    // Create a temporary file for testing
    let tempDirectory=FileManager.default.temporaryDirectory.path
    let tempFilePath="\(tempDirectory)/test-backup-file.txt"
    try "Test content".write(toFile: tempFilePath, atomically: true, encoding: .utf8)

    // Given
    let validCommand=BackupCommand(
      paths: [tempFilePath],
      tags: ["valid-tag"],
      options: CommonOptions(repository: "/test/repo", password: "test")
    )

    // Then
    XCTAssertNoThrow(try validCommand.validate(), "Validation should not throw with valid inputs")

    // Clean up
    try? FileManager.default.removeItem(atPath: tempFilePath)
  }

  /**
   * Test validation when paths is empty
   */
  func testBackupCommandValidationWithEmptyPaths() {
    // Given
    let emptyPathsCommand=BackupCommand(
      paths: [],
      options: CommonOptions(repository: "/test/repo", password: "test")
    )

    // Then
    XCTAssertThrowsError(try emptyPathsCommand.validate()) { error in
      XCTAssertTrue(error is ResticTypes.ResticError, "Should throw ResticError")
      guard let resticError=error as? ResticTypes.ResticError else {
        XCTFail("Expected ResticError")
        return
      }

      XCTAssertTrue(
        resticError.localizedDescription.contains("must be specified"),
        "Error message should mention that a path is required"
      )
    }
  }

  /**
   * Test validation with invalid repository
   */
  func testBackupCommandValidationWithInvalidRepository() {
    // Given
    let invalidRepoCommand=BackupCommand(
      paths: ["/some/path"],
      options: CommonOptions(repository: "", password: "test")
    )

    // Then
    XCTAssertThrowsError(try invalidRepoCommand.validate()) { error in
      XCTAssertTrue(error is ResticTypes.ResticError, "Should throw ResticError")
      guard let resticError=error as? ResticTypes.ResticError else {
        XCTFail("Expected ResticError")
        return
      }

      XCTAssertTrue(
        resticError.localizedDescription.contains("Repository"),
        "Error message should mention repository"
      )
    }
  }

  /**
   * Test validation with invalid tag format
   */
  func testBackupCommandValidationWithInvalidTag() {
    // Create a temporary file for testing
    let tempDirectory=FileManager.default.temporaryDirectory.path
    let tempFilePath="\(tempDirectory)/test-backup-file.txt"
    do {
      try "Test content".write(toFile: tempFilePath, atomically: true, encoding: .utf8)
    } catch {
      XCTFail("Failed to create test file: \(error)")
      return
    }

    // Given - A tag with invalid characters (spaces are not allowed)
    let invalidTagCommand=BackupCommand(
      paths: [tempFilePath],
      tags: ["invalid tag with spaces"],
      options: CommonOptions(repository: "/test/repo", password: "test")
    )

    // Then - This should throw an error since tag validation is implemented
    XCTAssertThrowsError(try invalidTagCommand.validate()) { error in
      XCTAssertTrue(error is ResticTypes.ResticError, "Should throw ResticError")
      guard let resticError=error as? ResticTypes.ResticError else {
        XCTFail("Expected ResticError")
        return
      }

      // Check that the error message mentions the invalid tag format
      XCTAssertTrue(
        resticError.localizedDescription.contains("Invalid tag format"),
        "Error message should mention invalid tag format"
      )
    }

    // Clean up
    try? FileManager.default.removeItem(atPath: tempFilePath)
  }
}
