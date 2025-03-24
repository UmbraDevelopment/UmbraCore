import Core
import ErrorHandlingDomains
import XCTest

/// Test cases for Security Error handling
final class SecurityErrorTests: XCTestCase {
  func testErrorDescription() {
    let error=SecTestError.accessDenied(reason: "Access denied to /test/path")
    XCTAssertEqual(
      error.description,
      "Access denied: Access denied to /test/path"
    )
  }

  func testErrorEquality() {
    let error1=SecTestError.accessDenied(reason: "Access denied to /test/path")
    let error2=SecTestError.accessDenied(reason: "Access denied to /test/path")
    let error3=SecTestError.accessDenied(reason: "Access denied to /different/path")
    let error4=SecTestError.invalidSecurityState(reason: "Invalid state")

    XCTAssertEqual(error1, error2)
    XCTAssertNotEqual(error1, error3)
    XCTAssertNotEqual(error1, error4)
  }
}
