import Foundation
@testable import ResticCLIHelper
@testable import ResticCLIHelperCommands
@testable import ResticCLIHelperTypes
@testable import ResticTypes
import XCTest

/**
 * Tests for the RestoreCommand class
 *
 * These tests verify that the RestoreCommand properly constructs command arguments
 * and correctly validates inputs according to the requirements.
 */
final class RestoreCommandTests: XCTestCase {
  /**
   * Test that the restore command correctly builds command arguments
   * from the provided configuration options.
   */
  func testRestoreCommandArguments() {
    // Given
    let options=CommonOptions(repository: "/test/repo", password: "test")

    // When
    let command=RestoreCommand(
      options: options,
      snapshotID: "abcdef123456",
      targetPath: "/restore/path"
    )

    // Then
    let args=command.commandArguments
    XCTAssertTrue(args.contains("abcdef123456"), "Command should include the snapshot ID")
    XCTAssertTrue(args.contains("--target"), "Command should include target flag")
    XCTAssertTrue(args.contains("/restore/path"), "Command should include target path")
  }

  /**
   * Test environment variable setting in the restore command
   */
  func testRestoreCommandEnvironment() {
    // Given
    let options=CommonOptions(
      repository: "/test/repo",
      password: "testpassword",
      cachePath: "/test/cache"
    )

    // When
    let command=RestoreCommand(
      options: options,
      snapshotID: "abcdef123456",
      targetPath: "/restore/path"
    )
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
   * Test included and excluded paths
   */
  func testRestoreCommandWithIncludeExcludePaths() {
    // Given
    let options=CommonOptions(repository: "/test/repo", password: "test")
    let includePaths=["/include/path1", "/include/path2"]
    let excludePaths=["/exclude/path"]

    // When
    let command=RestoreCommand(
      options: options,
      snapshotID: "abcdef123456",
      targetPath: "/restore/path",
      includePaths: includePaths,
      excludePaths: excludePaths
    )

    // Then
    let args=command.commandArguments
    XCTAssertTrue(args.contains("--include"), "Should contain include flag")
    XCTAssertTrue(args.contains("/include/path1"), "Should contain first include path")
    XCTAssertTrue(args.contains("/include/path2"), "Should contain second include path")
    XCTAssertTrue(args.contains("--exclude"), "Should contain exclude flag")
    XCTAssertTrue(args.contains("/exclude/path"), "Should contain exclude path")
  }

  /**
   * Test validation with valid inputs passes
   */
  func testRestoreCommandValidationWithValidInputs() throws {
    // Create a temporary directory for testing
    let tempDirectory=FileManager.default.temporaryDirectory.path

    // Given
    let validCommand=RestoreCommand(
      options: CommonOptions(repository: "/test/repo", password: "test"),
      snapshotID: "abcdef123456",
      targetPath: tempDirectory
    )

    // Then
    XCTAssertNoThrow(try validCommand.validate(), "Validation should not throw with valid inputs")
  }

  /**
   * Test validation with empty snapshot
   */
  func testRestoreCommandValidationWithEmptySnapshot() {
    // Given
    let emptySnapshotCommand=RestoreCommand(
      options: CommonOptions(repository: "/test/repo", password: "test"),
      snapshotID: "",
      targetPath: "/restore/path"
    )

    // Then
    XCTAssertThrowsError(try emptySnapshotCommand.validate()) { error in
      XCTAssertTrue(error is ResticTypes.ResticError, "Should throw ResticError")
      guard let resticError=error as? ResticTypes.ResticError else {
        XCTFail("Expected ResticError")
        return
      }

      XCTAssertTrue(
        resticError.localizedDescription.contains("Snapshot"),
        "Error message should mention snapshot"
      )
    }
  }

  /**
   * Test validation with invalid target path
   */
  func testRestoreCommandValidationWithInvalidTargetPath() {
    // Given
    let invalidTargetCommand=RestoreCommand(
      options: CommonOptions(repository: "/test/repo", password: "test"),
      snapshotID: "abcdef123456",
      targetPath: ""
    )

    // Then
    XCTAssertThrowsError(try invalidTargetCommand.validate()) { error in
      XCTAssertTrue(error is ResticTypes.ResticError, "Should throw ResticError")
      guard let resticError=error as? ResticTypes.ResticError else {
        XCTFail("Expected ResticError")
        return
      }

      XCTAssertTrue(
        resticError.localizedDescription.contains("Target path"),
        "Error message should mention target path"
      )
    }
  }

  /**
   * Test validation with invalid repository
   */
  func testRestoreCommandValidationWithInvalidRepository() {
    // Given
    let invalidRepoCommand=RestoreCommand(
      options: CommonOptions(repository: "", password: "test"),
      snapshotID: "abcdef123456",
      targetPath: "/restore/path"
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
}
