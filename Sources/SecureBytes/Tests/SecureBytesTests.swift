@testable import SecureBytes
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

  // MARK: - Initialization Tests

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

    // Should be initialized with zeros
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
    let literalBytes: SecureBytes=[0xAA, 0xBB, 0xCC]
    XCTAssertEqual(literalBytes.count, 3)
    XCTAssertEqual(literalBytes[0], 0xAA)
    XCTAssertEqual(literalBytes[1], 0xBB)
    XCTAssertEqual(literalBytes[2], 0xCC)
  }

  // MARK: - Subscript Tests

  func testIndexSubscript() {
    XCTAssertEqual(sampleBytes[0], 0x01)
    XCTAssertEqual(sampleBytes[4], 0x05)
  }

  func testRangeSubscript() {
    let subBytes=sampleBytes[1..<4]
    XCTAssertEqual(subBytes.count, 3)
    XCTAssertEqual(subBytes[0], 0x02)
    XCTAssertEqual(subBytes[1], 0x03)
    XCTAssertEqual(subBytes[2], 0x04)
  }

  // MARK: - Methods Tests

  func testBytesMethod() {
    let bytes=sampleBytes.bytes()
    XCTAssertEqual(bytes, [0x01, 0x02, 0x03, 0x04, 0x05])
  }

  func testAppending() {
    let bytes1: SecureBytes=[0x01, 0x02, 0x03]
    let bytes2: SecureBytes=[0x04, 0x05]

    let combined=bytes1.appending(bytes2)
    XCTAssertEqual(combined.count, 5)
    XCTAssertEqual(combined[0], 0x01)
    XCTAssertEqual(combined[4], 0x05)
  }

  func testHexString() {
    let bytes: SecureBytes=[0x01, 0x23, 0x45, 0x67, 0x89, 0xAB, 0xCD, 0xEF]
    XCTAssertEqual(bytes.hexString(), "0123456789abcdef")
  }

  func testFromHexString() {
    let hex="0123456789abcdef"
    let bytes=SecureBytes.fromHexString(hex)

    XCTAssertNotNil(bytes)
    if let bytes {
      XCTAssertEqual(bytes.count, 8)
      XCTAssertEqual(bytes[0], 0x01)
      XCTAssertEqual(bytes[7], 0xEF)
    }
  }

  func testInvalidHexString() {
    // Odd length hex string
    XCTAssertNil(SecureBytes.fromHexString("123"))

    // Invalid hex characters
    XCTAssertNil(SecureBytes.fromHexString("12ZZ"))
  }

  // MARK: - Protocol Conformance Tests

  func testEquatable() {
    let bytes1: SecureBytes=[0x01, 0x02, 0x03]
    let bytes2: SecureBytes=[0x01, 0x02, 0x03]
    let bytes3: SecureBytes=[0x03, 0x02, 0x01]

    XCTAssertEqual(bytes1, bytes2)
    XCTAssertNotEqual(bytes1, bytes3)
  }

  func testHashable() {
    let bytes1: SecureBytes=[0x01, 0x02, 0x03]
    let bytes2: SecureBytes=[0x01, 0x02, 0x03]
    let bytes3: SecureBytes=[0x03, 0x02, 0x01]

    var hasher1=Hasher()
    var hasher2=Hasher()
    var hasher3=Hasher()

    bytes1.hash(into: &hasher1)
    bytes2.hash(into: &hasher2)
    bytes3.hash(into: &hasher3)

    let hash1=hasher1.finalize()
    let hash2=hasher2.finalize()
    let hash3=hasher3.finalize()

    XCTAssertEqual(hash1, hash2)
    XCTAssertNotEqual(hash1, hash3)
  }

  func testStringDescription() {
    let bytes=SecureBytes(count: 10)
    XCTAssertEqual(bytes.description, "SecureBytes(10 bytes)")
  }

  func testDebugDescription() {
    let smallBytes: SecureBytes=[0x01, 0x02, 0x03]
    XCTAssertEqual(smallBytes.debugDescription, "SecureBytes(3 bytes: 010203)")

    // Test truncation for larger data
    let largeBytes=SecureBytes(repeating: 0xAA, count: 100)
    XCTAssertTrue(largeBytes.debugDescription.contains("..."))
  }
}
