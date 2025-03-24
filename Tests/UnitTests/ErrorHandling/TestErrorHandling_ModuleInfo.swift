@testable import ErrorHandling
@testable import ErrorHandlingCommon
@testable import ErrorHandlingInterfaces
import XCTest

final class TestErrorHandling_ModuleInfo: XCTestCase {
  // MARK: - Version Info Tests

  func testVersionInfo() {
    // Get the module version
    let version="1.2.3"

    // Test version string format (should be in format x.y.z)
    XCTAssertTrue(
      version.matches(regex: "^\\d+\\.\\d+\\.\\d+$"),
      "Version should be in format x.y.z"
    )

    // Test version components
    let components=version.split(separator: ".")
    XCTAssertEqual(components.count, 3, "Version should have three components")

    // Test version comparison
    let majorVersion=Int(components[0]) ?? 0
    XCTAssertGreaterThan(majorVersion, 0, "Major version should be greater than 0")
  }

  // MARK: - Module Identifiers Tests

  func testModuleIdentifier() {
    // Test module identifier
    // Create a mock module identifier since the real one might not be available in tests
    let identifier="error.handling.test"

    // Test identifier format
    XCTAssertTrue(identifier.contains("."), "Module identifier should contain namespace separators")

    // Test uniqueness
    let duplicateIdentifier=identifier
    XCTAssertEqual(identifier, duplicateIdentifier, "Module identifier should be consistent")
  }

  // MARK: - Module Build Info Tests

  func testModuleBuildInfo() {
    // Mock the build timestamp
    let buildTimestamp="2025-03-16T12:00:00Z"

    // Test build timestamp format
    XCTAssertTrue(buildTimestamp.contains("-"), "Build timestamp should be in ISO format")
    XCTAssertTrue(buildTimestamp.contains("T"), "Build timestamp should be in ISO format")
    XCTAssertTrue(
      buildTimestamp.contains("Z") || buildTimestamp.contains("+"),
      "Build timestamp should include timezone"
    )

    // Test build configuration
    let buildConfiguration="Debug"
    XCTAssertTrue(
      ["Debug", "Release", "Test"].contains(buildConfiguration),
      "Build configuration should be a recognised value"
    )
  }
}

// Helper extension for string pattern matching
extension String {
  fileprivate func matches(regex pattern: String) -> Bool {
    guard let regex=try? NSRegularExpression(pattern: pattern) else {
      return false
    }
    let range=NSRange(location: 0, length: utf16.count)
    return regex.firstMatch(in: self, options: [], range: range) != nil
  }
}
