/**
 * Basic tests for the SecurityTestModule
 *
 * This file contains placeholder tests to ensure the module
 * structure is properly organised and can be built successfully.
 */

@testable import SecurityTestModule
import XCTest

class SecurityTestModuleTests: XCTestCase {
  func testModuleInitialisation() {
    // Test that the module can be initialised without errors
    SecurityTestModulePackage.initialise()
    XCTAssertEqual(
      SecurityTestModulePackage.version,
      "1.0.0",
      "Version should match expected value"
    )
  }
}
