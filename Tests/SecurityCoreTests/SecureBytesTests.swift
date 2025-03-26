@testable import Security
import XCTest

final class SecureBytesTests: XCTestCase {
  // MARK: - Properties

  private var emptyBytes: SecureBytes!
  private var sampleBytes: SecureBytes!

  // MARK: - Setup

  override func setUp() {
    super.setUp()
    emptyBytes=SecureBytes()
    sampleBytes=SecureBytes([0x01, 0x02, 0x03, 0x04, 0x05])
  }

  override func tearDown() {
    emptyBytes=nil
    sampleBytes=nil
    super.tearDown()
  }

  // MARK: - Initialisation Tests

  func testEmptyInitialisation() {
    XCTAssertNotNil(emptyBytes)
    XCTAssertEqual(emptyBytes.count, 0)
    XCTAssertTrue(emptyBytes.isEmpty)
  }

  func testArrayInitialization() {
    XCTAssertEqual(sampleBytes.count, 5)
    XCTAssertFalse(sampleBytes.isEmpty)
  }

  func testCountInitialization() {
    let countBytes=SecureBytes(count: 10)
    XCTAssertEqual(countBytes.count, 10)

    // Should be initialised with zeros
    for i in 0..<10 {
      XCTAssertEqual(countBytes[i], 0)
    }
  }

  func testRepeatingValueInitialization() {
    let repeatingBytes=SecureBytes(repeating: 0xFF, count: 5)
    XCTAssertEqual(repeatingBytes.count, 5)

    for i in 0..<5 {
      XCTAssertEqual(repeatingBytes[i], 0xFF)
    }
  }

  func testArrayLiteralInitialization() {
    let literalBytes: SecureBytes=[0x10, 0x20, 0x30]
    XCTAssertEqual(literalBytes.count, 3)
    XCTAssertEqual(literalBytes[0], 0x10)
    XCTAssertEqual(literalBytes[1], 0x20)
    XCTAssertEqual(literalBytes[2], 0x30)
  }

  // MARK: - Access Tests

  func testSubscriptAccess() {
    XCTAssertEqual(sampleBytes[0], 0x01)
    XCTAssertEqual(sampleBytes[4], 0x05)
  }

  func testOutOfBoundsSubscript() {
    // This should crash with a precondition failure
    XCTAssertThrowsAssertion { _=self.sampleBytes[10] }
  }

  func testRangeAccess() {
    let subRange=sampleBytes[1..<4]
    XCTAssertEqual(subRange.count, 3)
    XCTAssertEqual(subRange[0], 0x02)
    XCTAssertEqual(subRange[1], 0x03)
    XCTAssertEqual(subRange[2], 0x04)
  }

  func testOutOfBoundsRange() {
    // These should crash with precondition failures
    XCTAssertThrowsAssertion { _=self.sampleBytes[-1..<3] }
    XCTAssertThrowsAssertion { _=self.sampleBytes[2..<10] }
  }

  func testBytesMethod() {
    let bytes=sampleBytes.bytes()
    XCTAssertEqual(bytes.count, 5)
    XCTAssertEqual(bytes, [0x01, 0x02, 0x03, 0x04, 0x05])
  }

  func testUnsafeBytes() {
    let bytes=sampleBytes.unsafeBytes
    XCTAssertEqual(bytes.count, 5)
    XCTAssertEqual(bytes, [0x01, 0x02, 0x03, 0x04, 0x05])
  }

  // MARK: - Combination Tests

  func testAppending() {
    let bytes1=SecureBytes([0x01, 0x02])
    let bytes2=SecureBytes([0x03, 0x04])
    let combined=bytes1.appending(bytes2)

    XCTAssertEqual(combined.count, 4)
    XCTAssertEqual(combined[0], 0x01)
    XCTAssertEqual(combined[1], 0x02)
    XCTAssertEqual(combined[2], 0x03)
    XCTAssertEqual(combined[3], 0x04)
  }

  func testCombine() {
    let bytes1=SecureBytes([0x01, 0x02])
    let bytes2=SecureBytes([0x03, 0x04])
    let combined=SecureBytes.combine(bytes1, bytes2)

    XCTAssertEqual(combined.count, 4)
    XCTAssertEqual(combined.bytes(), [0x01, 0x02, 0x03, 0x04])
  }

  func testSplit() {
    do {
      let (first, second)=try sampleBytes.split(at: 2)
      XCTAssertEqual(first.count, 2)
      XCTAssertEqual(second.count, 3)
      XCTAssertEqual(first.bytes(), [0x01, 0x02])
      XCTAssertEqual(second.bytes(), [0x03, 0x04, 0x05])
    } catch {
      XCTFail("Split operation failed with error: \(error)")
    }
  }

  func testSplitAtZero() {
    do {
      let (first, second)=try sampleBytes.split(at: 0)
      XCTAssertEqual(first.count, 0)
      XCTAssertEqual(second.count, 5)
      XCTAssertTrue(first.isEmpty)
      XCTAssertEqual(second.bytes(), [0x01, 0x02, 0x03, 0x04, 0x05])
    } catch {
      XCTFail("Split operation failed with error: \(error)")
    }
  }

  func testSplitAtEnd() {
    do {
      let (first, second)=try sampleBytes.split(at: 5)
      XCTAssertEqual(first.count, 5)
      XCTAssertEqual(second.count, 0)
      XCTAssertEqual(first.bytes(), [0x01, 0x02, 0x03, 0x04, 0x05])
      XCTAssertTrue(second.isEmpty)
    } catch {
      XCTFail("Split operation failed with error: \(error)")
    }
  }

  func testSplitOutOfRange() {
    XCTAssertThrowsError(try sampleBytes.split(at: -1)) { error in
      XCTAssertEqual(error as? SecureBytesError, SecureBytesError.invalidRange)
    }

    XCTAssertThrowsError(try sampleBytes.split(at: 6)) { error in
      XCTAssertEqual(error as? SecureBytesError, SecureBytesError.invalidRange)
    }
  }

  // MARK: - String Representation Tests

  func testHexString() {
    let bytes=SecureBytes([0x01, 0x23, 0x45, 0x67, 0x89, 0xAB, 0xCD, 0xEF])
    XCTAssertEqual(bytes.hexString(), "0123456789abcdef")
  }

  func testFromHexString() {
    let hexString="0123456789abcdef"
    if let bytes=SecureBytes.fromHexString(hexString) {
      XCTAssertEqual(bytes.count, 8)
      XCTAssertEqual(bytes[0], 0x01)
      XCTAssertEqual(bytes[1], 0x23)
      XCTAssertEqual(bytes[2], 0x45)
      XCTAssertEqual(bytes[3], 0x67)
      XCTAssertEqual(bytes[4], 0x89)
      XCTAssertEqual(bytes[5], 0xAB)
      XCTAssertEqual(bytes[6], 0xCD)
      XCTAssertEqual(bytes[7], 0xEF)
    } else {
      XCTFail("Failed to create SecureBytes from hex string")
    }
  }

  func testFromInvalidHexString() {
    // Odd number of characters
    XCTAssertNil(SecureBytes.fromHexString("123"))

    // Invalid hex character
    XCTAssertNil(SecureBytes.fromHexString("12XY"))
  }

  // MARK: - Description Tests

  func testDescription() {
    XCTAssertEqual(emptyBytes.description, "SecureBytes(0 bytes)")
    XCTAssertEqual(sampleBytes.description, "SecureBytes(5 bytes)")
  }

  func testDebugDescription() {
    XCTAssertEqual(emptyBytes.debugDescription, "SecureBytes(0 bytes: )")
    XCTAssertEqual(sampleBytes.debugDescription, "SecureBytes(5 bytes: 0102030405)")

    // Test truncation for large byte arrays
    var largeArray=[UInt8]()
    for i in 0..<100 {
      largeArray.append(UInt8(i % 256))
    }
    let largeBytes=SecureBytes(largeArray)
    XCTAssertTrue(largeBytes.debugDescription.contains("..."))
  }
}

extension XCTestCase {
  func XCTAssertThrowsAssertion(
    _ expression: @escaping () -> Void,
    file: StaticString=#file,
    line: UInt=#line
  ) {
    // Set up an expectation for a assertion failure
    let exp=expectation(description: "Assertion failure occurred")

    // Create a new thread for running the expression
    // If the expression triggers an assertion, the process will terminate the thread
    // and the subsequent code will not be executed
    let thread=Thread {
      expression()
      // If we get here, no assertion occurred
      XCTFail("Expected assertion did not occur", file: file, line: line)
    }

    // Configure the thread to get terminated rather than the app
    thread.start()

    // Wait a bit for the thread to finish
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
      // Check if thread is still executing
      if !thread.isExecuting {
        // Thread terminated as expected
        exp.fulfill()
      }
    }

    // Wait for the expectation
    waitForExpectations(timeout: 0.5)
  }
}
