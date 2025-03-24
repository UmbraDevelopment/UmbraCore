import Foundation
@testable import ResticCLIHelper
@testable import ResticCLIHelperModels
import ResticTypes
import XCTest

final class SnapshotInfoTests: XCTestCase {
  func testParseSnapshotInfo() throws {
    let json="""
      {
          "id": "abc123",
          "time": "2023-08-01T12:00:00Z",
          "hostname": "test-host",
          "username": "test-user",
          "paths": ["/path/to/backup"],
          "tags": ["test", "sample"],
          "short_id": "abc123"
      }
      """

    let data=json.data(using: .utf8)!
    guard let snapshotDict=try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
      XCTFail("Failed to parse snapshot JSON")
      return
    }

    XCTAssertEqual(snapshotDict["hostname"] as? String, "test-host")
    XCTAssertEqual(snapshotDict["username"] as? String, "test-user")
    XCTAssertEqual(snapshotDict["paths"] as? [String], ["/path/to/backup"])
    XCTAssertEqual(snapshotDict["tags"] as? [String], ["test", "sample"])
    XCTAssertEqual(snapshotDict["id"] as? String, "abc123")
    XCTAssertEqual(snapshotDict["short_id"] as? String, "abc123")

    // Verify time string format
    let timeString=snapshotDict["time"] as? String
    XCTAssertEqual(timeString, "2023-08-01T12:00:00Z")

    // Verify we can parse the date if needed
    let formatter=ISO8601DateFormatter()
    formatter.formatOptions=[.withInternetDateTime]
    XCTAssertNotNil(
      formatter.date(from: timeString!),
      "Should be able to parse the time string as an ISO8601 date"
    )
  }
}
