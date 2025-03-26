import XCTest
@testable import XPCProtocolsCore

final class XPCErrorTests: XCTestCase {
  func testXPCErrorDescription() {
    let errors: [XPCError]=[
      .connectionFailed("Failed to connect"),
      .messageFailed("Failed to send"),
      .invalidMessage("Invalid format")
    ]

    let expectedDescriptions=[
      "[Connection] XPC connection failed: Failed to connect",
      "[Message] Failed to send XPC message: Failed to send",
      "[Message] Invalid XPC message format: Invalid format"
    ]

    for (error, expectedDescription) in zip(errors, expectedDescriptions) {
      XCTAssertEqual(error.errorDescription, expectedDescription)
    }
  }
}
