@testable import CoreTypesImplementation
import CoreTypesInterfaces
import Foundation
import UmbraCoreTypes
import XCTest

final class SecureDataAdaptersTests: XCTestCase {
  func testFoundationDataConversion() {
    // Test conversion between SecureData and Foundation Data
    let bytes: [UInt8] = [1, 2, 3, 4, 5]
    let data = Data(bytes)

    // Foundation Data to SecureData
    let secureData = SecureData(data: data)
    XCTAssertEqual(secureData.rawBytes, bytes)

    // SecureData to Foundation Data
    let roundTripData = secureData.toData()
    XCTAssertEqual(roundTripData, data)

    // Data extension method
    let fromExtension = data.toSecureData()
    XCTAssertEqual(fromExtension.rawBytes, bytes)
  }

  func testSecureBytesConversion() {
    // Test conversion between SecureData and UmbraCoreTypes.SecureBytes
    let bytes: [UInt8] = [1, 2, 3, 4, 5]
    let secureBytes = UmbraCoreTypes.SecureBytes(bytes: bytes)

    // SecureBytes to SecureData
    let secureData = SecureData(secureBytes: secureBytes)
    XCTAssertEqual(secureData.rawBytes, bytes)

    // SecureData to SecureBytes
    let roundTripBytes = secureData.toSecureBytes()

    // Verify roundTripBytes contains the same content as the original bytes
    // Since SecureBytes doesn't have rawBytes, we need to compare differently
    XCTAssertEqual(roundTripBytes.count, bytes.count)
    for i in 0..<roundTripBytes.count {
      XCTAssertEqual(roundTripBytes[i], bytes[i])
    }

    // SecureBytes extension method
    let fromExtension = secureBytes.toSecureData()
    XCTAssertEqual(fromExtension.rawBytes, bytes)

    // From static factory method
    let fromStatic = UmbraCoreTypes.SecureBytes.from(secureData: secureData)
    XCTAssertEqual(fromStatic.count, bytes.count)
    for i in 0..<fromStatic.count {
      XCTAssertEqual(fromStatic[i], bytes[i])
    }
  }

  func testSecureBytesEmptyConversion() {
    // Test edge case with empty bytes
    let emptyBytes: [UInt8] = []
    let emptySecureBytes = UmbraCoreTypes.SecureBytes(bytes: emptyBytes)

    // Empty SecureBytes to SecureData
    let secureData = SecureData(secureBytes: emptySecureBytes)
    XCTAssertEqual(secureData.rawBytes, emptyBytes)
    XCTAssertTrue(secureData.rawBytes.isEmpty)

    // Empty SecureData to SecureBytes
    let roundTripBytes = secureData.toSecureBytes()
    XCTAssertEqual(roundTripBytes.count, 0)
    XCTAssertTrue(roundTripBytes.isEmpty)
  }
}
