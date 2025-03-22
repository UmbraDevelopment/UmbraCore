import Foundation
import KeyManagementTypes
import XCTest

final class KeyStatusTests: XCTestCase {
  // MARK: - Canonical Type Tests

  func testCanonicalKeyStatusEquality() {
    let active1=KeyManagementTypes.KeyStatus.active
    let active2=KeyManagementTypes.KeyStatus.active
    let compromised=KeyManagementTypes.KeyStatus.compromised
    let retired=KeyManagementTypes.KeyStatus.retired
    let date=Date()
    let pendingDeletion=KeyManagementTypes.KeyStatus.pendingDeletion(date)

    XCTAssertEqual(active1, active2)
    XCTAssertNotEqual(active1, compromised)
    XCTAssertNotEqual(active1, retired)
    XCTAssertNotEqual(active1, pendingDeletion)
    XCTAssertNotEqual(compromised, retired)
    XCTAssertNotEqual(compromised, pendingDeletion)
    XCTAssertNotEqual(retired, pendingDeletion)

    // Test that pendingDeletion with the same date is equal
    let pendingDeletion2=KeyManagementTypes.KeyStatus.pendingDeletion(date)
    XCTAssertEqual(pendingDeletion, pendingDeletion2)

    // Test that pendingDeletion with different dates is not equal
    let differentDate=Date(timeIntervalSince1970: date.timeIntervalSince1970 + 100)
    let pendingDeletion3=KeyManagementTypes.KeyStatus.pendingDeletion(differentDate)
    XCTAssertNotEqual(pendingDeletion, pendingDeletion3)
  }

  func testCanonicalKeyStatusTimestampConversion() {
    // Test timestamp-based creation and conversion
    let timestamp: Int64=1_627_084_800 // July 24, 2021 00:00:00 UTC
    let status=KeyManagementTypes.KeyStatus.pendingDeletionWithTimestamp(timestamp)

    // Extract the timestamp and check that it matches the original
    if let extractedTimestamp=status.getDeletionTimestamp() {
      XCTAssertEqual(extractedTimestamp, timestamp)
    } else {
      XCTFail("Failed to extract timestamp from pendingDeletion status")
    }

    // Verify other status types return nil for getDeletionTimestamp
    XCTAssertNil(KeyManagementTypes.KeyStatus.active.getDeletionTimestamp())
    XCTAssertNil(KeyManagementTypes.KeyStatus.compromised.getDeletionTimestamp())
    XCTAssertNil(KeyManagementTypes.KeyStatus.retired.getDeletionTimestamp())
  }

  func testCanonicalKeyStatusCodable() throws {
    // Test encoding and decoding simple status
    let active=KeyManagementTypes.KeyStatus.active
    let encoder=JSONEncoder()
    let activeData=try encoder.encode(active)
    let decoder=JSONDecoder()
    let decodedActive=try decoder.decode(KeyManagementTypes.KeyStatus.self, from: activeData)
    XCTAssertEqual(active, decodedActive)

    // Test encoding and decoding pendingDeletion with date
    let date=Date()
    let pendingDeletion=KeyManagementTypes.KeyStatus.pendingDeletion(date)
    let pendingData=try encoder.encode(pendingDeletion)
    let decodedPending=try decoder.decode(KeyManagementTypes.KeyStatus.self, from: pendingData)
    XCTAssertEqual(pendingDeletion, decodedPending)
  }

  // MARK: - Raw Status Conversion Tests

  func testRawStatusConversion() {
    let date=Date()
    let timestamp: Int64=1_627_084_800

    // Test conversion to raw status
    XCTAssertEqual(KeyManagementTypes.KeyStatus.active.toRawStatus(), .active)
    XCTAssertEqual(KeyManagementTypes.KeyStatus.compromised.toRawStatus(), .compromised)
    XCTAssertEqual(KeyManagementTypes.KeyStatus.retired.toRawStatus(), .retired)
    XCTAssertEqual(KeyManagementTypes.KeyStatus.pendingDeletion(date).toRawStatus(), .pendingDeletion(date))

    // Test creation from raw status
    XCTAssertEqual(KeyManagementTypes.KeyStatus.from(rawStatus: .active), .active)
    XCTAssertEqual(KeyManagementTypes.KeyStatus.from(rawStatus: .compromised), .compromised)
    XCTAssertEqual(KeyManagementTypes.KeyStatus.from(rawStatus: .retired), .retired)
    XCTAssertEqual(KeyManagementTypes.KeyStatus.from(rawStatus: .pendingDeletion(date)), .pendingDeletion(date))
    XCTAssertEqual(
      KeyManagementTypes.KeyStatus.from(rawStatus: .pendingDeletionWithTimestamp(timestamp)),
      .pendingDeletionWithTimestamp(timestamp)
    )
  }

  // MARK: - RawStatus Enum Tests

  func testRawStatusEquality() {
    // Create explicit dates using a specific reference time to ensure equality
    let referenceTime = 1616513654.0 // March 23, 2021 12:34:14 UTC
    let date1 = Date(timeIntervalSince1970: referenceTime)
    let date2 = Date(timeIntervalSince1970: referenceTime) // Should be identical to date1
    let date3 = Date(timeIntervalSince1970: referenceTime + 100) // Different by 100 seconds
    
    let timestamp1 = Int64(referenceTime)
    let timestamp2 = Int64(referenceTime)
    let timestamp3 = Int64(referenceTime + 100)

    // Test equality for simple cases
    XCTAssertEqual(KeyManagementTypes.KeyStatus.RawStatus.active, KeyManagementTypes.KeyStatus.RawStatus.active)
    XCTAssertNotEqual(KeyManagementTypes.KeyStatus.RawStatus.active, KeyManagementTypes.KeyStatus.RawStatus.compromised)

    // Test equality for date-based cases
    XCTAssertEqual(
      KeyManagementTypes.KeyStatus.RawStatus.pendingDeletion(date1),
      KeyManagementTypes.KeyStatus.RawStatus.pendingDeletion(date2)
    )
    XCTAssertNotEqual(
      KeyManagementTypes.KeyStatus.RawStatus.pendingDeletion(date1),
      KeyManagementTypes.KeyStatus.RawStatus.pendingDeletion(date3)
    )

    // Test equality for timestamp-based cases
    XCTAssertEqual(
      KeyManagementTypes.KeyStatus.RawStatus.pendingDeletionWithTimestamp(timestamp1),
      KeyManagementTypes.KeyStatus.RawStatus.pendingDeletionWithTimestamp(timestamp2)
    )
    XCTAssertNotEqual(
      KeyManagementTypes.KeyStatus.RawStatus.pendingDeletionWithTimestamp(timestamp1),
      KeyManagementTypes.KeyStatus.RawStatus.pendingDeletionWithTimestamp(timestamp3)
    )

    // Test equality between date and timestamp cases
    XCTAssertEqual(
      KeyManagementTypes.KeyStatus.RawStatus.pendingDeletion(date1),
      KeyManagementTypes.KeyStatus.RawStatus.pendingDeletionWithTimestamp(timestamp1)
    )
    XCTAssertEqual(
      KeyManagementTypes.KeyStatus.RawStatus.pendingDeletionWithTimestamp(timestamp1),
      KeyManagementTypes.KeyStatus.RawStatus.pendingDeletion(date1)
    )
  }
}
