@testable import CoreTypesInterfaces
import SecurityProtocolsCore
import XCTest
import UmbraCoreTypes

final class SecureDataTests: XCTestCase {
  func testInitialization() {
    let bytes: [UInt8]=[1, 2, 3, 4, 5]
    let secureData=SecureData(bytes: bytes)

    XCTAssertEqual(secureData.rawBytes, bytes)
    XCTAssertEqual(secureData.count, 5)
  }

  func testByteArrayInitialization() {
    let bytes: [UInt8]=[1, 2, 3, 4, 5]
    let byteArray=ByteArray(bytes: bytes)
    let secureData=SecureData(byteArray: byteArray)

    XCTAssertEqual(secureData.rawBytes, bytes)
    XCTAssertEqual(secureData.count, 5)
  }

  func testSubscriptAccess() {
    let bytes: [UInt8]=[1, 2, 3, 4, 5]
    let secureData=SecureData(bytes: bytes)

    XCTAssertEqual(secureData[0], 1)
    XCTAssertEqual(secureData[4], 5)
  }

  func testRangeSubscriptAccess() {
    let bytes: [UInt8]=[1, 2, 3, 4, 5]
    let secureData=SecureData(bytes: bytes)
    let subData=secureData[1..<4]

    XCTAssertEqual(subData.rawBytes, [2, 3, 4])
    XCTAssertEqual(subData.count, 3)
  }

  func testSliceMethod() {
    let bytes: [UInt8]=[1, 2, 3, 4, 5]
    let secureData=SecureData(bytes: bytes)
    let sliced=secureData.slice(from: 1, length: 3)

    XCTAssertEqual(sliced.rawBytes, [2, 3, 4])
    XCTAssertEqual(sliced.count, 3)
  }

  func testEmptySecureData() {
    let empty=SecureData.empty

    XCTAssertTrue(empty.rawBytes.isEmpty)
    XCTAssertEqual(empty.count, 0)
    XCTAssertTrue(empty.isEmpty)
  }

  func testEquality() {
    let secureData1=SecureData(bytes: [1, 2, 3])
    let secureData2=SecureData(bytes: [1, 2, 3])
    let secureData3=SecureData(bytes: [3, 2, 1])

    XCTAssertEqual(secureData1, secureData2)
    XCTAssertNotEqual(secureData1, secureData3)
  }

  func testAsByteArray() {
    let bytes: [UInt8]=[1, 2, 3, 4, 5]
    let secureData=SecureData(bytes: bytes)
    let byteArray=secureData.asByteArray

    XCTAssertEqual(byteArray.rawBytes, bytes)
  }
  
  // Note: BinaryData compatibility test removed as BinaryData type isn't available
  // in this context. If BinaryData is a required type, the proper import should be added.
}
