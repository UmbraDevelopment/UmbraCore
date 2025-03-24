@testable import UmbraXPC
import XCTest

final class XPCErrorTests: XCTestCase {
  func testXPCErrorDescription() {
    let errors: [XPCError]=[
      .connectionFailed("Failed to connect"),
      .messageFailed("Failed to send"),
      .invalidMessage("Invalid format")
    ]

    let expectedDescriptions=[
      "XPC connection failed: Failed to connect",
      "Failed to send XPC message: Failed to send",
      "Invalid XPC message format: Invalid format"
    ]

    for (error, expectedDescription) in zip(errors, expectedDescriptions) {
      XCTAssertEqual(error.errorDescription, expectedDescription)
    }
  }
}
