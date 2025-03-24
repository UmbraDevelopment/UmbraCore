import Foundation
@testable import ResticCLIHelper
@testable import ResticCLIHelperModels
import ResticTypes
import XCTest

final class RepositoryStatsTests: XCTestCase {
  func testParseRepositoryStats() throws {
    let json="""
      {
          "total_size": 1073741824,
          "total_uncompressed_size": 2147483648,
          "total_file_count": 42,
          "total_blob_count": 128,
          "snapshots_count": 5,
          "compression_ratio": 0.5,
          "compression_progress": 100,
          "compression_space_saving": 50,
          "total_blob_size": 512000000,
          "total_restore_size": 1200000000
      }
      """

    let data=json.data(using: .utf8)!
    guard let statsDict=try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
      XCTFail("Failed to parse stats JSON")
      return
    }

    XCTAssertEqual(statsDict["total_size"] as? Int, 1_073_741_824)
    XCTAssertEqual(statsDict["total_uncompressed_size"] as? Int, 2_147_483_648)
    XCTAssertEqual(statsDict["total_file_count"] as? Int, 42)
    XCTAssertEqual(statsDict["total_blob_count"] as? Int, 128)
    XCTAssertEqual(statsDict["snapshots_count"] as? Int, 5)
    XCTAssertEqual(statsDict["compression_ratio"] as? Double, 0.5)
    XCTAssertEqual(statsDict["compression_progress"] as? Int, 100)
    XCTAssertEqual(statsDict["compression_space_saving"] as? Int, 50)
    XCTAssertEqual(statsDict["total_blob_size"] as? Int, 512_000_000)
    XCTAssertEqual(statsDict["total_restore_size"] as? Int, 1_200_000_000)
  }
}
